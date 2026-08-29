//
//  TimetableView.swift
//  Katla
//

import SwiftUI

public struct TimetableView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    
    @AppStorage("skipWeekends") private var skipWeekends: Bool = true
    @AppStorage("ignoreHolidays") private var ignoreHolidays: Bool = false
    @AppStorage("hideExtraLessons") private var hideExtraLessons: Bool = false
    @AppStorage("hideTeacherData") private var hideTeacherData: Bool = false
    
    @State private var selectedDate: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pl_PL")
        cal.firstWeekday = 2 // Monday is 1st day of week!
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        // If today is Saturday (7) or Sunday (1), jump to Monday
        if weekday == 7 {
            return cal.date(byAdding: .day, value: 2, to: today) ?? today
        } else if weekday == 1 {
            return cal.date(byAdding: .day, value: 1, to: today) ?? today
        }
        return today
    }()
    
    @State private var isMonthPickerPresented = false
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pl_PL")
        cal.firstWeekday = 2 // Monday is 1st day of week!
        return cal
    }
    
    private var datesInWeek: [Date] {
        let cal = calendar
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        guard let monday = cal.date(from: components) else { return [selectedDate] }
        
        let daysCount = skipWeekends ? 5 : 7
        return (0..<daysCount).compactMap { dayIndex in
            cal.date(byAdding: .day, value: dayIndex, to: monday)
        }
    }
    
    private var monthYearHeaderString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    private var lessonsForSelectedDate: [Lesson] {
        let selectedStr = DateFormatter.yyyyMMdd.string(from: selectedDate)
        var list = dataService.lessons
            .filter { $0.dateString == selectedStr }
            .sorted(by: { $0.number < $1.number })
        
        if hideExtraLessons {
            list = list.filter { lesson in
                let lower = lesson.subjectName.lowercased()
                return !lower.contains("dodatkow") && !lower.contains("fakult") && !lower.contains("koło")
            }
        }
        return list
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Top Header (Title + Month Jump Button)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(langManager.string(for: "tt_title").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            Button {
                                isMonthPickerPresented = true
                            } label: {
                                HStack(spacing: 6) {
                                    Text(monthYearHeaderString)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(VulcanColors.primaryAccent)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                let today = Date()
                                let weekday = calendar.component(.weekday, from: today)
                                if skipWeekends && weekday == 7 {
                                    selectedDate = calendar.date(byAdding: .day, value: 2, to: today) ?? today
                                } else if skipWeekends && weekday == 1 {
                                    selectedDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
                                } else {
                                    selectedDate = today
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text(langManager.string(for: "tt_today"))
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(VulcanColors.primaryAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(VulcanColors.primaryAccent.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    
                    // MARK: - Horizontal Days Carousel (Monday to Friday/Sunday)
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(datesInWeek, id: \.self) { date in
                                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                    let isToday = calendar.isDateInToday(date)
                                    let dateStr = DateFormatter.yyyyMMdd.string(from: date)
                                    let lessonCount = dataService.lessons.filter { $0.dateString == dateStr }.count
                                    
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedDate = date
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(dayName(for: date))
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(isSelected ? .white : themeManager.textSecondaryColor)
                                            
                                            Text("\(calendar.component(.day, from: date))")
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundColor(isSelected ? .white : (isToday ? VulcanColors.primaryAccent : themeManager.textPrimaryColor))
                                            
                                            if lessonCount > 0 {
                                                Circle()
                                                    .fill(isSelected ? .white : VulcanColors.primaryAccent)
                                                    .frame(width: 4, height: 4)
                                            } else {
                                                Circle()
                                                    .fill(Color.clear)
                                                    .frame(width: 4, height: 4)
                                            }
                                        }
                                        .frame(width: 52, height: 66)
                                        .background(
                                            isSelected ? VulcanColors.primaryAccent : themeManager.cardBackgroundColor
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(isSelected ? VulcanColors.primaryAccent : (isToday ? VulcanColors.primaryAccent.opacity(0.5) : themeManager.cardBorderColor), lineWidth: isSelected || isToday ? 1.5 : 1)
                                        )
                                    }
                                    .id(date)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                        }
                        .onAppear {
                            proxy.scrollTo(selectedDate, anchor: .center)
                        }
                        .onChange(of: selectedDate) { _, newDate in
                            withAnimation {
                                proxy.scrollTo(newDate, anchor: .center)
                            }
                            fetchScheduleForSelectedDate()
                        }
                    }
                    
                    // MARK: - Lessons List Content
                    ScrollView {
                        VStack(spacing: 12) {
                            if dataService.isLoading {
                                ProgressView("Pobieranie planu lekcji...")
                                    .tint(VulcanColors.primaryAccent)
                                    .padding(.top, 40)
                            } else if lessonsForSelectedDate.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 44))
                                        .foregroundColor(VulcanColors.textMuted)
                                    Text("Brak lekcji w tym dniu")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Na wybrany dzień (\(selectedDate.formatted(.dateTime.day().month()))) nie zaplanowano żadnych zajęć.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(lessonsForSelectedDate) { lesson in
                                    VulcanCard(padding: 14) {
                                        HStack(spacing: 16) {
                                            VStack(spacing: 2) {
                                                Text("\(lesson.number)")
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(lesson.isCancelled ? .red : themeManager.textPrimaryColor)
                                                
                                                Text(lesson.timeStart)
                                                    .font(.caption2)
                                                    .foregroundColor(themeManager.textSecondaryColor)
                                                Text(lesson.timeEnd)
                                                    .font(.caption2)
                                                    .foregroundColor(VulcanColors.textMuted)
                                            }
                                            .frame(width: 44)
                                            
                                            Rectangle()
                                                .fill(lesson.isCancelled ? Color.red : (lesson.isSubstitution ? Color.orange : VulcanColors.primaryAccent))
                                                .frame(width: 3.5, height: 42)
                                                .clipShape(Capsule())
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(lesson.subjectName)
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(lesson.isCancelled ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)
                                                        .strikethrough(lesson.isCancelled)
                                                    
                                                    Spacer()
                                                    
                                                    if lesson.isCancelled {
                                                        Text("ODWOŁANA")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.red)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.red.opacity(0.12))
                                                            .clipShape(Capsule())
                                                    } else if lesson.isSubstitution {
                                                        Text("ZASTĘPSTWO")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.orange)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.orange.opacity(0.12))
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                                
                                                HStack(spacing: 8) {
                                                    let teacherDisplayName = hideTeacherData ? obfuscateTeacher(lesson.teacherName) : lesson.teacherName
                                                    
                                                    Text(teacherDisplayName)
                                                        .font(.caption)
                                                        .foregroundColor(themeManager.textSecondaryColor)
                                                    
                                                    Text("•")
                                                        .font(.caption)
                                                        .foregroundColor(VulcanColors.textMuted)
                                                    
                                                    Text("Sala \(lesson.classroom)")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(VulcanColors.primaryAccent)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 35, coordinateSpace: .local)
                                .onEnded { value in
                                    if value.translation.width < -50 {
                                        let step = (skipWeekends && calendar.component(.weekday, from: selectedDate) == 6) ? 3 : 1
                                        if let next = calendar.date(byAdding: .day, value: step, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = next
                                            }
                                        }
                                    } else if value.translation.width > 50 {
                                        let step = (skipWeekends && calendar.component(.weekday, from: selectedDate) == 2) ? -3 : -1
                                        if let prev = calendar.date(byAdding: .day, value: step, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = prev
                                            }
                                        }
                                    }
                                }
                        )
                    }
                    .refreshable {
                        fetchScheduleForSelectedDate()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isMonthPickerPresented) {
                MonthYearPickerSheetView(selectedDate: $selectedDate)
            }
            .task {
                fetchScheduleForSelectedDate()
            }
        }
    }
    
    private func fetchScheduleForSelectedDate() {
        if let account = accountManager.activeAccount, let client = accountManager.validClient {
            Task {
                await dataService.fetchSchedule(account: account, client: client, aroundDate: selectedDate)
            }
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
    
    private func obfuscateTeacher(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1)). \(parts[1].prefix(1))."
        } else if let first = parts.first {
            return "\(first.prefix(1))."
        }
        return name
    }
}

#Preview {
    TimetableView()
}
