//
//  EduVulcanDataService.swift
//  Katla
//

import Foundation
import Observation

@Observable
public final class EduVulcanDataService {
    public static let shared = EduVulcanDataService()
    
    public var grades: [Grade] = []
    public var gradeSummaries: [EduVulcanGradeSummaryDTO] = []
    public var lessons: [Lesson] = []
    public var attendanceLessons: [AttendanceLesson] = []
    public var teachers: [EduVulcanTeacherDTO] = []
    public var notes: [EduVulcanNoteDTO] = []
    public var duties: [EduVulcanDutyDTO] = []
    public var meetings: [EduVulcanMeetingDTO] = []
    public var exams: [EduVulcanExamDTO] = []
    public var homeworks: [EduVulcanHomeworkDTO] = []
    public var receivedMessages: [EduVulcanMessageDTO] = []
    public var sentMessages: [EduVulcanMessageDTO] = []
    public var deletedMessages: [EduVulcanMessageDTO] = []
    public var luckyNumber: Int? = nil
    public var isLoading = false
    public var lastSyncError: String? = nil
    public var hasSynced = false
    
    private init() {}
    
    /// Syncs live data
    public func syncData(account: StudentAccount, client: EduVulcanClient, targetDate: Date = Date(), targetPeriodId: Int? = nil) async {
        await MainActor.run {
            isLoading = true
            lastSyncError = nil
        }
        
        var currentAccount = account
        
        print("\n==================================================")
        print("[VulcanovaDataSync] 🔄 Starting Full Data Sync for \(currentAccount.firstName) \(currentAccount.lastName)")
        print("[VulcanovaDataSync] 🏫 Account Symbol: '\(currentAccount.symbol)', REST URL: '\(currentAccount.restUrl)'")
        print("[VulcanovaDataSync] 🏫 Stored UnitID: \(currentAccount.unitId), Default PeriodID: \(currentAccount.periodId), Target PeriodID: \(targetPeriodId ?? currentAccount.periodId)")
        
        // 0. Self-Healing Unit Resolution via mobile/register/hebe
        do {
            print("[VulcanovaDataSync] 🔎 Resolving student school unit & message box via mobile/register/hebe...")
            let hebeAccounts: [EduVulcanAccount] = try await client.request(
                method: "GET",
                endpoint: "mobile/register/hebe",
                restUrl: currentAccount.restUrl,
                queryParams: ["mode": "2"]
            )
            
            if let matched = hebeAccounts.first(where: { $0.pupil.id == currentAccount.id }) ?? hebeAccounts.first {
                let realSymbol = matched.unit.symbol
                let realRestUrl = matched.unit.restUrl ?? (realSymbol.isEmpty ? currentAccount.restUrl : "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(realSymbol)/api")
                let studentPeriods = matched.periods.map { StudentPeriod(id: $0.id, number: $0.number, current: $0.current) }
                let boxKey = matched.messageBox?.globalKey ?? currentAccount.messageBoxKey
                
                print("[VulcanovaDataSync] 🎯 Resolved HEBE Unit: Symbol='\(realSymbol)', UnitID=\(matched.unit.id), RestURL='\(realRestUrl)'")
                print("[VulcanovaDataSync] 🎯 Resolved HEBE Periods: \(studentPeriods.map { "ID:\($0.id), Sem:\($0.number), Current:\($0.current)" }.joined(separator: ", "))")
                print("[VulcanovaDataSync] 🎯 Resolved MessageBox GlobalKey: '\(boxKey)'")
                
                let updatedAccount = StudentAccount(
                    id: matched.pupil.id,
                    firstName: matched.pupil.firstName,
                    lastName: matched.pupil.surname,
                    schoolName: matched.unit.name,
                    symbol: realSymbol,
                    restUrl: realRestUrl,
                    keyFingerprint: currentAccount.keyFingerprint,
                    privateKeyBase64: currentAccount.privateKeyBase64,
                    periodId: matched.periods.first(where: { $0.current })?.id ?? (matched.periods.first?.id ?? currentAccount.periodId),
                    unitId: matched.unit.id,
                    periods: studentPeriods,
                    messageBoxKey: boxKey
                )
                
                currentAccount = updatedAccount
                await MainActor.run {
                    AccountManager.shared.setActiveAccount(updatedAccount, client: client)
                }
            }
        } catch {
            print("[VulcanovaDataSync] ⚠️ Unit resolution notice: \(error.localizedDescription)")
        }
        
        let effectivePeriodId = targetPeriodId ?? currentAccount.periodId
        
        // 1. Fetch Lucky Number
        await fetchLuckyNumber(account: currentAccount, client: client, date: targetDate)
        
        // 2. Fetch Grades for effectivePeriodId
        await fetchGradesForPeriod(account: currentAccount, client: client, periodId: effectivePeriodId)
        
        // 3. Fetch Lessons Schedule for Target Date
        await fetchSchedule(account: currentAccount, client: client, aroundDate: targetDate)
        
        // 4. Fetch Attendance for Target Date
        await fetchAttendance(account: currentAccount, client: client, aroundDate: targetDate)
        
        // 5. Fetch Teachers List
        await fetchTeachers(account: currentAccount, client: client)
        
        // 6. Fetch Notes & Praise List
        await fetchNotes(account: currentAccount, client: client)
        
        // 7. Fetch Duties List
        await fetchDuties(account: currentAccount, client: client)
        
        // 8. Fetch Meetings List
        await fetchMeetings(account: currentAccount, client: client)
        
        // 9. Fetch Exams List
        await fetchExams(account: currentAccount, client: client, dateFromStr: "2025-09-01", dateToStr: "2027-08-31")
        
        // 10. Fetch Homeworks List
        await fetchHomeworks(account: currentAccount, client: client, dateFromStr: "2025-09-01", dateToStr: "2027-08-31")
        
        // 11. Fetch Messages List
        await fetchMessages(account: currentAccount, client: client)
        
        await MainActor.run {
            self.isLoading = false
            self.hasSynced = true
        }
        print("==================================================\n")
    }
    
    /// Fetches messages (Received, Sent, Deleted)
    public func fetchMessages(account: StudentAccount, client: EduVulcanClient) async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        let boxKey = account.messageBoxKey
        print("[VulcanovaMessagesLogger] ✉️ Fetching Messages for Pupil \(account.id) [boxKey='\(boxKey)']")
        
        for candidateUrl in candidateUrls {
            var fetchedAny = false
            
            do {
                let rxDTOs: [EduVulcanMessageDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/messages/received/byBox",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "box": boxKey,
                        "pupilId": "\(account.id)",
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                await MainActor.run {
                    self.receivedMessages = rxDTOs
                }
                fetchedAny = true
            } catch {}
            
            do {
                let txDTOs: [EduVulcanMessageDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/messages/sent/byBox",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "box": boxKey,
                        "pupilId": "\(account.id)",
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                await MainActor.run {
                    self.sentMessages = txDTOs
                }
                fetchedAny = true
            } catch {}
            
            do {
                let delDTOs: [EduVulcanMessageDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/messages/deleted/byBox",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "box": boxKey,
                        "pupilId": "\(account.id)",
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                await MainActor.run {
                    self.deletedMessages = delDTOs
                }
                fetchedAny = true
            } catch {}
            
            if fetchedAny {
                return
            }
        }
    }
    
    /// Fetches lucky number
    public func fetchLuckyNumber(account: StudentAccount, client: EduVulcanClient, date: Date) async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let luckyResult: EduVulcanLuckyNumberDTO = try await client.request(
                    method: "GET",
                    endpoint: "mobile/school/lucky",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "pupilId": "\(account.id)",
                        "constituentId": "\(account.unitId)",
                        "day": DateFormatter.yyyyMMdd.string(from: date)
                    ]
                )
                await MainActor.run {
                    self.luckyNumber = luckyResult.number
                }
                break
            } catch {}
        }
    }
    
    /// Fetches exams
    public func fetchExams(account: StudentAccount, client: EduVulcanClient, dateFromStr: String = "2025-09-01", dateToStr: String = "2027-08-31") async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let examDTOs: [EduVulcanExamDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/exam/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "pupilId": "\(account.id)",
                        "dateFrom": dateFromStr,
                        "dateTo": dateToStr,
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                
                await MainActor.run {
                    self.exams = examDTOs
                }
                return
            } catch {}
        }
    }
    
    /// Fetches homeworks
    public func fetchHomeworks(account: StudentAccount, client: EduVulcanClient, dateFromStr: String = "2025-09-01", dateToStr: String = "2027-08-31") async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        let paramVariants: [[String: String]] = [
            [
                "pupilId": "\(account.id)",
                "dateFrom": dateFromStr,
                "dateTo": dateToStr,
                "lastId": "-2147483648",
                "pageSize": "500",
                "lastSyncDate": "1970-01-01 00:00:00"
            ],
            [
                "pupilId": "\(account.id)",
                "from": dateFromStr,
                "to": dateToStr,
                "lastId": "-2147483648",
                "pageSize": "500",
                "lastSyncDate": "1970-01-01 00:00:00"
            ]
        ]
        
        for candidateUrl in candidateUrls {
            for params in paramVariants {
                do {
                    let hwDTOs: [EduVulcanHomeworkDTO] = try await client.request(
                        method: "GET",
                        endpoint: "mobile/homework/byPupil",
                        restUrl: candidateUrl,
                        pupilId: account.id,
                        queryParams: params
                    )
                    
                    await MainActor.run {
                        self.homeworks = hwDTOs
                    }
                    return
                } catch {}
            }
        }
    }
    
    /// Fetches school duties
    public func fetchDuties(account: StudentAccount, client: EduVulcanClient) async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let dutyDTOs: [EduVulcanDutyDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/school/duty/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "pupilId": "\(account.id)",
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                
                await MainActor.run {
                    self.duties = dutyDTOs
                }
                return
            } catch {}
        }
    }
    
    /// Fetches meetings
    public func fetchMeetings(account: StudentAccount, client: EduVulcanClient) async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let meetingDTOs: [EduVulcanMeetingDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/meetings/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "pupilId": "\(account.id)",
                        "from": "2025-09-01",
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                
                await MainActor.run {
                    self.meetings = meetingDTOs
                }
                return
            } catch {}
        }
    }
    
    /// Fetches notes
    public func fetchNotes(account: StudentAccount, client: EduVulcanClient) async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let noteDTOs: [EduVulcanNoteDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/note/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "pupilId": "\(account.id)",
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                
                await MainActor.run {
                    self.notes = noteDTOs
                }
                return
            } catch {}
        }
    }
    
    /// Fetches teachers
    public func fetchTeachers(account: StudentAccount, client: EduVulcanClient) async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let teacherDTOs: [EduVulcanTeacherDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/teacher/byPeriod",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "periodId": "\(account.periodId)",
                        "pupilId": "\(account.id)",
                        "unitId": "\(account.unitId)",
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                
                await MainActor.run {
                    self.teachers = teacherDTOs
                }
                return
            } catch {}
        }
    }
    
    /// Fetches grades for period
    public func fetchGradesForPeriod(account: StudentAccount, client: EduVulcanClient, periodId: Int) async {
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let gradeDTOs: [EduVulcanGradeDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/grade/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "unitId": "\(account.unitId)",
                        "pupilId": "\(account.id)",
                        "periodId": "\(periodId)",
                        "lastSyncDate": "1970-01-01 00:00:00",
                        "lastId": "-2147483648",
                        "pageSize": "500"
                    ]
                )
                
                let mappedGrades = gradeDTOs.compactMap { dto -> Grade? in
                    let gradeStr = dto.content ?? dto.contentRaw ?? "0"
                    let val = dto.value ?? Double(gradeStr.prefix(1)) ?? 0.0
                    
                    return Grade(
                        id: UUID(),
                        subjectName: dto.column.subject.name,
                        content: dto.column.name,
                        value: val,
                        displayText: gradeStr,
                        weight: Int(dto.column.weight ?? 1.0),
                        categoryName: dto.column.name,
                        dateCreated: Date(),
                        teacher: "Nauczyciel"
                    )
                }
                
                await MainActor.run {
                    self.grades = mappedGrades
                }
                break
            } catch {}
        }
        
        for candidateUrl in candidateUrls {
            do {
                let summaries: [EduVulcanGradeSummaryDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/grade/summary/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "unitId": "\(account.unitId)",
                        "pupilId": "\(account.id)",
                        "periodId": "\(periodId)",
                        "lastId": "-2147483648",
                        "pageSize": "500"
                    ]
                )
                await MainActor.run {
                    self.gradeSummaries = summaries
                }
                break
            } catch {}
        }
    }
    
    /// Fetches schedule for 14-day window around selectedDate (Monday to Sunday) with merging
    public func fetchSchedule(account: StudentAccount, client: EduVulcanClient, aroundDate: Date) async {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pl_PL")
        cal.firstWeekday = 2 // Monday is 1st day!
        
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: aroundDate)
        guard let monday = cal.date(from: components) else { return }
        
        // Fetch 14 days (-7 days to +14 days to cover previous/next week seamlessly)
        let dateFrom = cal.date(byAdding: .day, value: -7, to: monday) ?? monday
        let dateTo = cal.date(byAdding: .day, value: 14, to: monday) ?? monday
        
        let dateFromStr = DateFormatter.yyyyMMdd.string(from: dateFrom)
        let dateToStr = DateFormatter.yyyyMMdd.string(from: dateTo)
        
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        print("[KatlaSchedule] 📅 Fetching Schedule from \(dateFromStr) to \(dateToStr) for Pupil \(account.id)")
        
        for candidateUrl in candidateUrls {
            do {
                let lessonDTOs: [EduVulcanLessonDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/schedule/withchanges/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "pupilId": "\(account.id)",
                        "dateFrom": dateFromStr,
                        "dateTo": dateToStr,
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                
                let fetchedLessons = lessonDTOs.map { dto -> Lesson in
                    Lesson(
                        id: UUID(),
                        number: dto.timeSlot.position,
                        subjectName: dto.subject?.name ?? "Lekcja",
                        teacherName: dto.teacherPrimary?.displayName ?? "Nauczyciel",
                        classroom: dto.room?.code ?? "-",
                        timeStart: dto.timeSlot.start,
                        timeEnd: dto.timeSlot.end,
                        dateString: dto.dateAtString,
                        isCancelled: dto.isCancelled ?? false,
                        isSubstitution: dto.isSubstitution ?? false
                    )
                }
                
                await MainActor.run {
                    // Merge fetched lessons into self.lessons without losing other dates
                    var currentDict = Dictionary(grouping: self.lessons, by: { "\($0.dateString)_\($0.number)" })
                    for newL in fetchedLessons {
                        currentDict["\(newL.dateString)_\(newL.number)"] = [newL]
                    }
                    self.lessons = currentDict.values.compactMap { $0.first }
                }
                print("[KatlaSchedule] 🎉 SUCCESS! Fetched \(fetchedLessons.count) lessons via \(candidateUrl)")
                return
            } catch {
                print("[KatlaSchedule] ⚠️ Schedule fetch notice (\(candidateUrl)): \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetches attendance
    public func fetchAttendance(account: StudentAccount, client: EduVulcanClient, aroundDate: Date) async {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pl_PL")
        cal.firstWeekday = 2
        
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: aroundDate)
        guard let monday = cal.date(from: components) else { return }
        
        let dateFrom = cal.date(byAdding: .day, value: -14, to: monday) ?? monday
        let dateTo = cal.date(byAdding: .day, value: 21, to: monday) ?? monday
        
        let dateFromStr = DateFormatter.yyyyMMdd.string(from: dateFrom)
        let dateToStr = DateFormatter.yyyyMMdd.string(from: dateTo)
        
        let candidateUrls = [
            "\(EduVulcanClient.baseUrl)/powiatsochaczewski/\(account.symbol)/api",
            account.restUrl,
            "\(EduVulcanClient.baseUrl)/\(account.symbol)/api"
        ]
        
        for candidateUrl in candidateUrls {
            do {
                let attendanceDTOs: [EduVulcanAttendanceDTO] = try await client.request(
                    method: "GET",
                    endpoint: "mobile/lesson/byPupil",
                    restUrl: candidateUrl,
                    pupilId: account.id,
                    queryParams: [
                        "pupilId": "\(account.id)",
                        "dateFrom": dateFromStr,
                        "dateTo": dateToStr,
                        "lastId": "-2147483648",
                        "pageSize": "500",
                        "lastSyncDate": "1970-01-01 00:00:00"
                    ]
                )
                
                let mapped = attendanceDTOs.map { dto -> AttendanceLesson in
                    let presence = dto.presenceType
                    let symbolLower = (presence?.symbol ?? "").lowercased()
                    let nameLower = (presence?.name ?? "").lowercased()
                    
                    let isSchool = symbolLower.contains("zs") || nameLower.contains("szkol")
                    let isLateJust = symbolLower.contains("su") || (presence?.late == true && presence?.absenceJustified == true)
                    
                    return AttendanceLesson(
                        id: UUID(),
                        lessonNumber: dto.lessonNumber ?? (dto.timeSlot?.position ?? 1),
                        subjectName: dto.subject?.name ?? "Lekcja",
                        teacherName: dto.teacherPrimary?.displayName ?? "Nauczyciel",
                        topic: dto.topic ?? "",
                        timeStart: dto.timeSlot?.start ?? "08:00",
                        timeEnd: dto.timeSlot?.end ?? "08:45",
                        dateString: dto.dateAtString,
                        presenceSymbol: presence?.symbol ?? "",
                        presenceName: presence?.name ?? "Obecny",
                        isPresence: presence?.presence ?? true,
                        isAbsence: presence?.absence ?? false,
                        isAbsenceJustified: presence?.absenceJustified ?? false,
                        isLate: presence?.late ?? false,
                        isLateJustified: isLateJust,
                        isLegalAbsence: presence?.legalAbsence ?? false,
                        isSchoolAbsence: isSchool
                    )
                }
                
                await MainActor.run {
                    var currentDict = Dictionary(grouping: self.attendanceLessons, by: { "\($0.dateString)_\($0.lessonNumber)" })
                    for newA in mapped {
                        currentDict["\(newA.dateString)_\(newA.lessonNumber)"] = [newA]
                    }
                    self.attendanceLessons = currentDict.values.compactMap { $0.first }
                }
                return
            } catch {}
        }
    }
}

extension DateFormatter {
    public static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    public static let HHmm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
