//
//  DashboardView.swift
//  Katla
//

import SwiftUI

public struct DashboardView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    @State private var accountManager = AccountManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var showProfileSheet = false
    
    @AppStorage("hidePersonalData") private var hidePersonalData: Bool = false
    
    private var displayedFirstName: String {
        guard let account = accountManager.activeAccount else { return "Uczeń" }
        if hidePersonalData {
            return "\(account.firstName.prefix(1))..."
        }
        return account.firstName
    }
    
    private var studentInitials: String {
        guard let account = accountManager.activeAccount else { return "TO" }
        let f = account.firstName.prefix(1)
        let l = account.lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }
    
    // Calculate current and next lessons for today
    private var todayLessons: [Lesson] {
        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        return dataService.lessons.filter { $0.dateString == todayStr }
    }
    
    private var currentLesson: Lesson? {
        let nowStr = DateFormatter.HHmm.string(from: Date())
        return todayLessons.first { lesson in
            nowStr >= lesson.timeStart && nowStr <= lesson.timeEnd
        } ?? todayLessons.first
    }
    
    private var nextLesson: Lesson? {
        guard let current = currentLesson,
              let index = todayLessons.firstIndex(where: { $0.id == current.id }),
              index + 1 < todayLessons.count else {
            return todayLessons.count > 1 ? todayLessons[1] : nil
        }
        return todayLessons[index + 1]
    }
    
    private var todayAttendance: [AttendanceLesson] {
        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        return dataService.attendanceLessons.filter { $0.dateString == todayStr }
    }
    
    private var recentGrades: [Grade] {
        Array(dataService.grades.prefix(4))
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header with GŁÓWNA & Cześć, [Imię]! 👋
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(langManager.string(for: "tab_dashboard").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            Text("Cześć, \(displayedFirstName)! 👋")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.textPrimaryColor)
                        }
                        
                        Spacer()
                        
                        // User Avatar
                        Button {
                            showProfileSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(VulcanColors.primaryAccent)
                                    .frame(width: 42, height: 42)
                                
                                Text(studentInitials)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: VulcanColors.primaryAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    
                    ScrollView {
                        VStack(spacing: 18) {
                            // MARK: - Lucky Number Card Banner
                            VulcanCard(padding: 16) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.green, Color.teal],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "clover.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(langManager.string(for: "dash_lucky").uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(VulcanColors.textMuted)
                                            .tracking(1.1)
                                        
                                        if let number = dataService.luckyNumber {
                                            Text("Dzisiaj twój numer to #\(number)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(themeManager.textPrimaryColor)
                                        } else {
                                            Text(langManager.string(for: "dash_no_lucky"))
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(themeManager.textSecondaryColor)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            // MARK: - Today's Lessons Hero Card
                            VStack(alignment: .leading, spacing: 10) {
                                Text(langManager.string(for: "dash_today_lessons"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                if todayLessons.isEmpty {
                                    VulcanCard(padding: 20) {
                                        HStack {
                                            Spacer()
                                            VStack(spacing: 8) {
                                                Image(systemName: "calendar.badge.clock")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(VulcanColors.textMuted)
                                                Text(langManager.string(for: "dash_no_lessons"))
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(themeManager.textPrimaryColor)
                                            }
                                            Spacer()
                                        }
                                    }
                                } else {
                                    ForEach(todayLessons.prefix(3)) { lesson in
                                        VulcanCard(padding: 14) {
                                            HStack(spacing: 14) {
                                                Text("\(lesson.number)")
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(themeManager.textPrimaryColor)
                                                    .frame(width: 28)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(lesson.subjectName)
                                                        .font(.system(size: 15, weight: .bold))
                                                        .foregroundColor(themeManager.textPrimaryColor)
                                                    Text("\(lesson.timeStart) - \(lesson.timeEnd) • Sala \(lesson.classroom)")
                                                        .font(.caption)
                                                        .foregroundColor(themeManager.textSecondaryColor)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // MARK: - Recent Grades Card
                            VStack(alignment: .leading, spacing: 10) {
                                Text(langManager.string(for: "dash_recent_grades"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                if recentGrades.isEmpty {
                                    VulcanCard(padding: 20) {
                                        Text("Brak ostatnich ocen")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.textSecondaryColor)
                                            .frame(maxWidth: .infinity)
                                    }
                                } else {
                                    ForEach(recentGrades) { grade in
                                        VulcanCard(padding: 14) {
                                            HStack(spacing: 14) {
                                                Text(grade.displayText)
                                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                                    .foregroundColor(VulcanColors.color(forGrade: grade.value))
                                                    .frame(width: 36, height: 36)
                                                    .background(VulcanColors.color(forGrade: grade.value).opacity(0.15))
                                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(grade.subjectName)
                                                        .font(.system(size: 15, weight: .bold))
                                                        .foregroundColor(themeManager.textPrimaryColor)
                                                    Text(grade.content)
                                                        .font(.caption)
                                                        .foregroundColor(themeManager.textSecondaryColor)
                                                }
                                                Spacer()
                                                
                                                Text("w: \(grade.weight)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(VulcanColors.primaryAccent)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(VulcanColors.primaryAccent.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        if let account = accountManager.activeAccount, let client = accountManager.validClient {
                            await dataService.syncData(account: account, client: client)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showProfileSheet) {
                UserProfileSheetView()
            }
        }
    }
}

public struct UserProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    @State private var accountManager = AccountManager.shared
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let account = accountManager.activeAccount {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [VulcanColors.primaryAccent, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(account.firstName.prefix(1)))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(spacing: 6) {
                            Text("\(account.firstName) \(account.lastName)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textPrimaryColor)
                            Text("\(account.schoolName) • Klasa \(account.symbol)")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Profil Ucznia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gotowe") { dismiss() }
                        .foregroundColor(VulcanColors.primaryAccent)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
