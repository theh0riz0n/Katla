//
//  EduVulcanModels.swift
//  Vulcanova
//

import Foundation

// MARK: - Envelope Response
public struct EduVulcanEnvelopeResponse<T: Decodable>: Decodable {
    public struct Status: Decodable {
        public let code: Int
        public let message: String
        
        enum CodingKeys: String, CodingKey {
            case code = "Code"
            case message = "Message"
        }
    }
    
    public let status: Status
    public let envelope: T?
    
    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case envelope = "Envelope"
    }
}

// MARK: - Empty Envelope (for endpoints returning no data)
public struct EmptyEnvelope: Decodable {}

// MARK: - Account Model
public struct EduVulcanAccount: Decodable, Identifiable {
    public var id: Int { pupil.id }
    
    public struct Pupil: Decodable {
        public let id: Int
        public let firstName: String
        public let surname: String
        public let sex: Bool?
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case firstName = "FirstName"
            case surname = "Surname"
            case sex = "Sex"
        }
    }
    
    public struct Unit: Decodable {
        public let id: Int
        public let symbol: String
        public let shortName: String?
        public let restUrl: String?
        public let name: String
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case symbol = "Symbol"
            case shortName = "Short"
            case restUrl = "RestURL"
            case name = "Name"
        }
    }
    
    public struct Period: Decodable {
        public let id: Int
        public let number: Int
        public let current: Bool
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case number = "Number"
            case current = "Current"
        }
    }
    
    public struct MessageBox: Decodable {
        public let id: Int
        public let globalKey: String
        public let name: String
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case globalKey = "GlobalKey"
            case name = "Name"
        }
    }
    
    public let pupil: Pupil
    public let unit: Unit
    public let periods: [Period]
    public let messageBox: MessageBox?
    
    enum CodingKeys: String, CodingKey {
        case pupil = "Pupil"
        case unit = "Unit"
        case periods = "Periods"
        case messageBox = "MessageBox"
    }
}

// MARK: - Message DTO (Wiadomości)
public struct EduVulcanMessageDTO: Decodable, Identifiable {
    public var id: String { globalKey.isEmpty ? messageId : globalKey }
    
    public struct MessageAddress: Decodable {
        public let globalKey: String?
        public let name: String
        public let hasRead: Bool?
        
        enum CodingKeys: String, CodingKey {
            case globalKey = "GlobalKey"
            case name = "Name"
            case hasRead = "HasRead"
        }
    }
    
    public let messageId: String
    public let globalKey: String
    public let threadKey: String?
    public let subject: String
    public let content: String
    public let sentAtString: String
    public let readAtString: String?
    public let sender: MessageAddress?
    public let receiver: [MessageAddress]?
    
    public var senderName: String {
        sender?.name ?? "Nieznany nadawca"
    }
    
    public var receiversJoined: String {
        guard let r = receiver, !r.isEmpty else { return "Odbiorcy" }
        return r.map { $0.name }.joined(separator: ", ")
    }
    
    public var isRead: Bool {
        readAtString != nil && !readAtString!.isEmpty
    }
    
    public var initials: String {
        let parts = senderName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(senderName.prefix(2)).uppercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case messageId = "Id"
        case globalKey = "GlobalKey"
        case threadKey = "ThreadKey"
        case subject = "Subject"
        case content = "Content"
        case sentAt = "SentAt"
        case readAt = "ReadAt"
        case sender = "Sender"
        case receiver = "Receiver"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.messageId = (try? container.decode(String.self, forKey: .messageId)) ?? UUID().uuidString
        self.globalKey = (try? container.decode(String.self, forKey: .globalKey)) ?? UUID().uuidString
        self.threadKey = try? container.decode(String.self, forKey: .threadKey)
        self.subject = (try? container.decode(String.self, forKey: .subject)) ?? "Bez tematu"
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        
        if let str = try? container.decode(String.self, forKey: .sentAt) {
            self.sentAtString = String(str.prefix(16)).replacingOccurrences(of: "T", with: " ")
        } else {
            self.sentAtString = ""
        }
        
        if let str = try? container.decode(String.self, forKey: .readAt) {
            self.readAtString = String(str.prefix(16)).replacingOccurrences(of: "T", with: " ")
        } else {
            self.readAtString = nil
        }
        
        self.sender = try? container.decode(MessageAddress.self, forKey: .sender)
        self.receiver = try? container.decode([MessageAddress].self, forKey: .receiver)
    }
}

// MARK: - Exam DTO (Sprawdziany)
public struct EduVulcanExamDTO: Decodable, Identifiable {
    public var id: Int { examId }
    
    public struct Subject: Decodable {
        public let name: String
        
        enum CodingKeys: String, CodingKey {
            case name = "Name"
        }
    }
    
    public struct Creator: Decodable {
        public let displayName: String
        
        enum CodingKeys: String, CodingKey {
            case displayName = "DisplayName"
        }
    }
    
    public let examId: Int
    public let type: String
    public let content: String
    public let deadlineString: String
    public let subject: Subject?
    public let creator: Creator?
    
    enum CodingKeys: String, CodingKey {
        case examId = "Id"
        case type = "Type"
        case content = "Content"
        case deadline = "DeadlineAt"
        case subject = "Subject"
        case creator = "Creator"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.examId = (try? container.decode(Int.self, forKey: .examId)) ?? 0
        self.type = (try? container.decode(String.self, forKey: .type)) ?? "Sprawdzian"
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.subject = try? container.decode(Subject.self, forKey: .subject)
        self.creator = try? container.decode(Creator.self, forKey: .creator)
        
        if let str = try? container.decode(String.self, forKey: .deadline) {
            self.deadlineString = String(str.prefix(10))
        } else if let dateObj = try? container.decode(EduVulcanDateAt.self, forKey: .deadline) {
            self.deadlineString = dateObj.yyyyMMdd
        } else {
            self.deadlineString = ""
        }
    }
}

// MARK: - Homework DTO (Prace domowe)
public struct EduVulcanHomeworkDTO: Decodable, Identifiable {
    public var id: Int { homeworkId }
    
    public struct Subject: Decodable {
        public let name: String
        
        enum CodingKeys: String, CodingKey {
            case name = "Name"
        }
    }
    
    public struct Creator: Decodable {
        public let displayName: String
        
        enum CodingKeys: String, CodingKey {
            case displayName = "DisplayName"
        }
    }
    
    public let homeworkId: Int
    public let content: String
    public let deadlineString: String
    public let isAnswerRequired: Bool
    public let subject: Subject?
    public let creator: Creator?
    
    enum CodingKeys: String, CodingKey {
        case homeworkId = "Id"
        case content = "Content"
        case deadline = "DeadlineAt"
        case dateAt = "DateAt"
        case isAnswerRequired = "IsAnswerRequired"
        case subject = "Subject"
        case creator = "Creator"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.homeworkId = (try? container.decode(Int.self, forKey: .homeworkId)) ?? 0
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.isAnswerRequired = (try? container.decode(Bool.self, forKey: .isAnswerRequired)) ?? false
        self.subject = try? container.decode(Subject.self, forKey: .subject)
        self.creator = try? container.decode(Creator.self, forKey: .creator)
        
        if let str = try? container.decode(String.self, forKey: .deadline) {
            self.deadlineString = String(str.prefix(10))
        } else if let dateObj = try? container.decode(EduVulcanDateAt.self, forKey: .deadline) {
            self.deadlineString = dateObj.yyyyMMdd
        } else if let str = try? container.decode(String.self, forKey: .dateAt) {
            self.deadlineString = String(str.prefix(10))
        } else if let dateObj = try? container.decode(EduVulcanDateAt.self, forKey: .dateAt) {
            self.deadlineString = dateObj.yyyyMMdd
        } else {
            self.deadlineString = ""
        }
    }
}

// MARK: - Duty DTO (Dyżurni)
public struct EduVulcanDutyDTO: Decodable, Identifiable {
    public var id: Int { dutyId }
    
    public let dutyId: Int
    public let dateString: String
    public let content: String?
    public let text: String?
    
    public var pupilNames: String {
        if let t = text, !t.trimmed.isEmpty { return t }
        if let c = content, !c.trimmed.isEmpty { return c }
        return "Brak przypisanych dyżurnych"
    }
    
    enum CodingKeys: String, CodingKey {
        case dutyId = "Id"
        case date = "DateAt"
        case content = "Content"
        case text = "Text"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dutyId = (try? container.decode(Int.self, forKey: .dutyId)) ?? 0
        self.content = try? container.decode(String.self, forKey: .content)
        self.text = try? container.decode(String.self, forKey: .text)
        
        if let str = try? container.decode(String.self, forKey: .date) {
            self.dateString = String(str.prefix(10))
        } else {
            self.dateString = ""
        }
    }
}

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Meeting DTO (Zebrania)
public struct EduVulcanMeetingDTO: Decodable, Identifiable {
    public var id: Int { meetingId }
    
    public let meetingId: Int
    public let whenString: String
    public let location: String
    public let reason: String
    public let agenda: String
    public let additionalInfo: String?
    public let online: String?
    
    enum CodingKeys: String, CodingKey {
        case meetingId = "Id"
        case when = "DateAt"
        case location = "Where"
        case reason = "Why"
        case agenda = "Agenda"
        case additionalInfo = "AdditionalInfo"
        case online = "Online"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.meetingId = (try? container.decode(Int.self, forKey: .meetingId)) ?? 0
        
        if let str = try? container.decode(String.self, forKey: .when) {
            self.whenString = String(str.prefix(16)).replacingOccurrences(of: "T", with: " ")
        } else {
            self.whenString = ""
        }
        
        self.location = (try? container.decode(String.self, forKey: .location)) ?? "Brak danych o sali"
        self.reason = (try? container.decode(String.self, forKey: .reason)) ?? "Zebranie z rodzicami"
        self.agenda = (try? container.decode(String.self, forKey: .agenda)) ?? ""
        self.additionalInfo = try? container.decode(String.self, forKey: .additionalInfo)
        self.online = try? container.decode(String.self, forKey: .online)
    }
}

// MARK: - Note DTO (Uwagi i Pochwały)
public struct EduVulcanNoteDTO: Decodable, Identifiable {
    public var id: Int { noteId }
    
    public struct Category: Decodable {
        public let id: Int
        public let name: String
        public let type: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case name = "Name"
            case type = "Type"
        }
    }
    
    public struct Creator: Decodable {
        public let displayName: String
        
        enum CodingKeys: String, CodingKey {
            case displayName = "DisplayName"
        }
    }
    
    public let noteId: Int
    public let positive: Bool
    public let content: String
    public let points: Int?
    public let category: Category?
    public let creator: Creator?
    public let dateValidString: String
    
    enum CodingKeys: String, CodingKey {
        case noteId = "Id"
        case positive = "Positive"
        case content = "Content"
        case points = "Points"
        case category = "Category"
        case creator = "Creator"
        case dateValid = "ValidAt"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.noteId = (try? container.decode(Int.self, forKey: .noteId)) ?? 0
        self.positive = (try? container.decode(Bool.self, forKey: .positive)) ?? false
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.points = try? container.decode(Int.self, forKey: .points)
        self.category = try? container.decode(Category.self, forKey: .category)
        self.creator = try? container.decode(Creator.self, forKey: .creator)
        
        if let str = try? container.decode(String.self, forKey: .dateValid) {
            self.dateValidString = String(str.prefix(10))
        } else if let dateObj = try? container.decode(EduVulcanDateAt.self, forKey: .dateValid) {
            self.dateValidString = dateObj.yyyyMMdd
        } else {
            self.dateValidString = ""
        }
    }
}

// MARK: - Teacher DTO
public struct EduVulcanTeacherDTO: Decodable, Identifiable {
    public let id: Int
    public let name: String?
    public let surname: String?
    public let displayName: String
    public let description: String
    
    public var teacherName: String {
        if let n = name, let s = surname, !n.isEmpty, !s.isEmpty {
            return "\(n) \(s)"
        }
        return displayName
    }
    
    public var subjectName: String {
        description.isEmpty ? "Nauczyciel" : description
    }
    
    public var initials: String {
        let parts = teacherName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(teacherName.prefix(2)).uppercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case surname = "Surname"
        case displayName = "DisplayName"
        case description = "Description"
    }
}

// MARK: - Grade DTO
public struct EduVulcanGradeDTO: Decodable, Identifiable {
    public var id: Int { globalId }
    
    public struct Subject: Decodable {
        public let id: Int
        public let name: String
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case name = "Name"
        }
    }
    
    public struct GradeColumn: Decodable {
        public let id: Int
        public let name: String
        public let weight: Double?
        public let subject: Subject
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case name = "Name"
            case weight = "Weight"
            case subject = "Subject"
        }
    }
    
    public let globalId: Int
    public let content: String?
    public let contentRaw: String?
    public let value: Double?
    public let column: GradeColumn
    
    enum CodingKeys: String, CodingKey {
        case globalId = "Id"
        case content = "Content"
        case contentRaw = "ContentRaw"
        case value = "Value"
        case column = "Column"
    }
}

// MARK: - Grade Summary DTO (Final / Proposed Semester Grades)
public struct EduVulcanGradeSummaryDTO: Decodable, Identifiable {
    public var id: Int { globalId }
    
    public let globalId: Int
    public let subject: EduVulcanGradeDTO.Subject
    public let entry1: String? // Proposed Grade (Ocena przewidywana)
    public let entry2: String? // Final Semester Grade (Ocena klasyfikacyjna)
    public let periodId: Int?
    
    public var predictedGrade: String? { entry1 }
    public var finalGrade: String? { entry2 }
    public var average: Double {
        if let val = entry2, let num = Double(val) { return num }
        if let val = entry1, let num = Double(val) { return num }
        return 0.0
    }
    
    enum CodingKeys: String, CodingKey {
        case globalId = "Id"
        case subject = "Subject"
        case entry1 = "Entry_1"
        case entry2 = "Entry_2"
        case periodId = "PeriodId"
    }
}

// MARK: - DateAt DTO
public struct EduVulcanDateAt: Decodable {
    public let date: String?
    public let dateFormatted: String?
    public let year: Int?
    public let month: Int?
    public let day: Int?
    
    public var yyyyMMdd: String {
        if let d = date, d.count >= 10 {
            return String(d.prefix(10))
        }
        if let y = year, let m = month, let d = day {
            return String(format: "%04d-%02d-%02d", y, m, d)
        }
        return ""
    }
    
    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case dateFormatted = "DateFormatted"
        case year = "Year"
        case month = "Month"
        case day = "Day"
    }
}

// MARK: - Lesson DTO
public struct EduVulcanLessonDTO: Decodable, Identifiable {
    public var id: Int { timeSlot.position }
    
    public struct TimeSlot: Decodable {
        public let position: Int
        public let start: String
        public let end: String
        
        enum CodingKeys: String, CodingKey {
            case position = "Position"
            case start = "Start"
            case end = "End"
        }
        
        public init(position: Int, start: String, end: String) {
            self.position = position
            self.start = start
            self.end = end
        }
    }
    
    public struct Subject: Decodable {
        public let name: String
        
        enum CodingKeys: String, CodingKey {
            case name = "Name"
        }
    }
    
    public struct Room: Decodable {
        public let code: String
        
        enum CodingKeys: String, CodingKey {
            case code = "Code"
        }
    }
    
    public struct Teacher: Decodable {
        public let displayName: String
        
        enum CodingKeys: String, CodingKey {
            case displayName = "DisplayName"
        }
    }
    
    public let dateAtString: String
    public let timeSlot: TimeSlot
    public let subject: Subject?
    public let room: Room?
    public let teacherPrimary: Teacher?
    public let isCancelled: Bool?
    public let isSubstitution: Bool?
    
    enum CodingKeys: String, CodingKey {
        case dateAt = "DateAt"
        case timeSlot = "TimeSlot"
        case subject = "Subject"
        case room = "Room"
        case teacherPrimary = "TeacherPrimary"
        case isCancelled = "IsCancelled"
        case isSubstitution = "IsSubstitution"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let str = try? container.decode(String.self, forKey: .dateAt) {
            self.dateAtString = String(str.prefix(10))
        } else if let dateObj = try? container.decode(EduVulcanDateAt.self, forKey: .dateAt) {
            self.dateAtString = dateObj.yyyyMMdd
        } else {
            self.dateAtString = ""
        }
        
        self.timeSlot = (try? container.decode(TimeSlot.self, forKey: .timeSlot)) ?? TimeSlot(position: 1, start: "08:00", end: "08:45")
        self.subject = try? container.decode(Subject.self, forKey: .subject)
        self.room = try? container.decode(Room.self, forKey: .room)
        self.teacherPrimary = try? container.decode(Teacher.self, forKey: .teacherPrimary)
        self.isCancelled = try? container.decode(Bool.self, forKey: .isCancelled)
        self.isSubstitution = try? container.decode(Bool.self, forKey: .isSubstitution)
    }
}

// MARK: - Attendance DTO
public struct EduVulcanAttendanceDTO: Decodable, Identifiable {
    public var id: Int { lessonId }
    
    public struct PresenceType: Decodable {
        public let symbol: String?
        public let name: String?
        public let presence: Bool?
        public let absence: Bool?
        public let absenceJustified: Bool?
        public let late: Bool?
        public let legalAbsence: Bool?
        
        enum CodingKeys: String, CodingKey {
            case symbol = "Symbol"
            case name = "Name"
            case presence = "Presence"
            case absence = "Absence"
            case absenceJustified = "AbsenceJustified"
            case late = "Late"
            case legalAbsence = "LegalAbsence"
        }
    }
    
    public let lessonId: Int
    public let presenceType: PresenceType?
    public let dateAtString: String
    public let lessonNumber: Int?
    public let timeSlot: EduVulcanLessonDTO.TimeSlot?
    public let subject: EduVulcanLessonDTO.Subject?
    public let teacherPrimary: EduVulcanLessonDTO.Teacher?
    public let topic: String?
    
    enum CodingKeys: String, CodingKey {
        case lessonId = "Id"
        case presenceType = "PresenceType"
        case dateAt = "DayAt"
        case lessonNumber = "LessonNumber"
        case timeSlot = "TimeSlot"
        case subject = "Subject"
        case teacherPrimary = "TeacherPrimary"
        case topic = "Topic"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lessonId = (try? container.decode(Int.self, forKey: .lessonId)) ?? 0
        self.presenceType = try? container.decode(PresenceType.self, forKey: .presenceType)
        
        if let str = try? container.decode(String.self, forKey: .dateAt) {
            self.dateAtString = String(str.prefix(10))
        } else if let dateObj = try? container.decode(EduVulcanDateAt.self, forKey: .dateAt) {
            self.dateAtString = dateObj.yyyyMMdd
        } else {
            self.dateAtString = ""
        }
        
        self.lessonNumber = try? container.decode(Int.self, forKey: .lessonNumber)
        self.timeSlot = try? container.decode(EduVulcanLessonDTO.TimeSlot.self, forKey: .timeSlot)
        self.subject = try? container.decode(EduVulcanLessonDTO.Subject.self, forKey: .subject)
        self.teacherPrimary = try? container.decode(EduVulcanLessonDTO.Teacher.self, forKey: .teacherPrimary)
        self.topic = try? container.decode(String.self, forKey: .topic)
    }
}

// MARK: - Lucky Number DTO
public struct EduVulcanLuckyNumberDTO: Decodable {
    public let day: String
    public let number: Int
    
    enum CodingKeys: String, CodingKey {
        case day = "Day"
        case number = "Number"
    }
}
