//
//  AttendanceView.swift
//  Katla
//

import SwiftUI

public enum AttendanceViewMode: String, CaseIterable, Identifiable {
    case carousel = "Dzienny"
    case monthGrid = "Miesięczny"
    
    public var id: String { rawValue }
}

public struct AttendanceView: View {
    @State private var selectedDate: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        if (components.month ?? 8) < 9 {
            components.month = 9
            components.day = 1
            components.year = 2026
        }
        return calendar.date(from: components) ?? Date()
    }()
    
    @State private var viewMode: AttendanceViewMode = .carousel
    @Bindable private var themeManager = ThemeManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    
    @AppStorage("excuseHandlingMode") private var excuseHandlingMode: Int = 1
    
    // Generate dates range from late August through October 2026
    private var dateRange: [Date] {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 8
        startComponents.day = 24
        
        guard let startDate = calendar.date(from: startComponents) else { return [selectedDate] }
        return (0..<60).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }
    
    private var currentMonthHeader: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    private var displayAttendance: [AttendanceLesson] {
        let selectedStr = DateFormatter.yyyyMMdd.string(from: selectedDate)
        let rawList = dataService.attendanceLessons
            .filter { $0.dateString == selectedStr }
            .sorted { $0.lessonNumber < $1.lessonNumber }
        
        if excuseHandlingMode == 3 {
            // Mode 3: Ignore / Hide excuses completely
            return rawList.filter { !isExcuseEntry($0) }
        }
        return rawList
    }
    
    private func isExcuseEntry(_ entry: AttendanceLesson) -> Bool {
        let sym = entry.presenceSymbol.lowercased()
        let name = entry.presenceName.lowercased()
        return sym.contains("zw") || name.contains("zwoln") || entry.isLegalAbsence
    }
    
    private func statusBadgeColor(for entry: AttendanceLesson) -> Color {
        if isExcuseEntry(entry) {
            return excuseHandlingMode == 2 ? Color.red : Color.green
        }
        return entry.statusBadgeColor
    }
    
    private func statusBadgeText(for entry: AttendanceLesson) -> String {
        if isExcuseEntry(entry) {
            return excuseHandlingMode == 2 ? "Nieobecny (Zwolniony)" : "Obecny (Zwolniony)"
        }
        return entry.presenceName
    }
    
    // Dynamic month grid days calculation for currently selectedDate's month
    private var daysInCurrentMonth: [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header & Mode Picker
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FREKWENCJA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            Text(currentMonthHeader)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.textPrimaryColor)
                        }
                        
                        Spacer()
                        
                        Picker("Widok", selection: $viewMode) {
                            ForEach(AttendanceViewMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    if viewMode == .carousel {
                        // MARK: - Horizontally Scrollable Date Carousel
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(dateRange, id: \.self) { date in
                                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                        let dayName = date.formatted(.dateTime.weekday(.short)).uppercased()
                                        let dayNum = date.formatted(.dateTime.day())
                                        let monthShort = date.formatted(.dateTime.month(.abbreviated)).lowercased()
                                        
                                        VStack(spacing: 4) {
                                            Text(dayName)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(isSelected ? .white : VulcanColors.textMuted)
                                            
                                            Text(dayNum)
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(isSelected ? .white : themeManager.textPrimaryColor)
                                            
                                            Text(monthShort)
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundColor(isSelected ? .white.opacity(0.9) : VulcanColors.textSecondary)
                                        }
                                        .frame(width: 58, height: 68)
                                        .background(isSelected ? VulcanColors.primaryAccent : themeManager.cardBackgroundColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(isSelected ? VulcanColors.primaryAccent : themeManager.cardBorderColor, lineWidth: 1)
                                        )
                                        .id(date)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = date
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                            .onAppear {
                                proxy.scrollTo(selectedDate, anchor: .center)
                                fetchAttendanceForSelectedDate()
                            }
                            .onChange(of: selectedDate) { _, newDate in
                                withAnimation {
                                    proxy.scrollTo(newDate, anchor: .center)
                                }
                                fetchAttendanceForSelectedDate()
                            }
                        }
                    }
                    
                    Divider()
                        .overlay(themeManager.cardBorderColor)
                        .padding(.top, 4)
                    
                    if viewMode == .monthGrid {
                        // MARK: - Full Monthly Grid View with Month Switching
                        ScrollView {
                            VStack(spacing: 16) {
                                // Month Switcher Bar
                                HStack {
                                    Button {
                                        if let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = prevMonth
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("Poprzedni")
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(VulcanColors.primaryAccent)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(currentMonthHeader.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                        .tracking(1.1)
                                    
                                    Spacer()
                                    
                                    Button {
                                        if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = nextMonth
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("Następny")
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(VulcanColors.primaryAccent)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                                    ForEach(daysInCurrentMonth, id: \.self) { date in
                                        let dayNum = Calendar.current.component(.day, from: date)
                                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                        let dateStr = DateFormatter.yyyyMMdd.string(from: date)
                                        let rawEntries = dataService.attendanceLessons.filter { $0.dateString == dateStr }
                                        let entries = excuseHandlingMode == 3 ? rawEntries.filter { !isExcuseEntry($0) } : rawEntries
                                        
                                        let hasAbsence = entries.contains(where: { $0.isAbsence })
                                        let hasLate = entries.contains(where: { $0.isLate })
                                        
                                        VStack(spacing: 4) {
                                            Text("\(dayNum)")
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(isSelected ? .white : themeManager.textPrimaryColor)
                                            
                                            HStack(spacing: 3) {
                                                if entries.isEmpty {
                                                    Circle()
                                                        .fill(VulcanColors.textMuted.opacity(0.3))
                                                        .frame(width: 4, height: 4)
                                                } else if hasAbsence {
                                                    Circle()
                                                        .fill(Color.red)
                                                        .frame(width: 5, height: 5)
                                                } else if hasLate {
                                                    Circle()
                                                        .fill(Color.orange)
                                                        .frame(width: 5, height: 5)
                                                } else {
                                                    Circle()
                                                        .fill(Color.green)
                                                        .frame(width: 5, height: 5)
                                                }
                                            }
                                        }
                                        .frame(height: 48)
                                        .frame(maxWidth: .infinity)
                                        .background(isSelected ? VulcanColors.primaryAccent : themeManager.cardBackgroundColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(isSelected ? VulcanColors.primaryAccent : themeManager.cardBorderColor, lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedDate = date
                                            viewMode = .carousel
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 20)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                                .onEnded { value in
                                    if value.translation.width < -50 {
                                        if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = nextMonth
                                            }
                                        }
                                    } else if value.translation.width > 50 {
                                        if let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = prevMonth
                                            }
                                        }
                                    }
                                }
                        )
                    } else {
                        // MARK: - Attendance List for Selected Day with Swipe Gesture
                        ScrollView {
                            VStack(spacing: 12) {
                                if dataService.isLoading {
                                    ProgressView("Pobieranie frekwencji...")
                                        .tint(VulcanColors.primaryAccent)
                                        .padding(.top, 40)
                                } else if displayAttendance.isEmpty {
                                    VStack(spacing: 14) {
                                        Image(systemName: "checkmark.seal")
                                            .font(.system(size: 44))
                                            .foregroundColor(VulcanColors.textMuted)
                                        Text("Brak zarejestrowanej frekwencji")
                                            .font(.headline)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                        Text("Na dzień \(selectedDate.formatted(.dateTime.day().month())) nie odnotowano wpisów obecności.")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.textSecondaryColor)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                    }
                                    .padding(.top, 50)
                                } else {
                                    ForEach(displayAttendance) { entry in
                                        let badgeColor = statusBadgeColor(for: entry)
                                        let badgeText = statusBadgeText(for: entry)
                                        
                                        VulcanCard(padding: 14) {
                                            HStack(spacing: 14) {
                                                // Status Circle Badge
                                                Circle()
                                                    .fill(badgeColor.opacity(0.18))
                                                    .frame(width: 42, height: 42)
                                                    .overlay(
                                                        Text(entry.shortSymbol)
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(badgeColor)
                                                    )
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text("\(entry.lessonNumber). \(entry.subjectName)")
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(themeManager.textPrimaryColor)
                                                        
                                                        Spacer()
                                                        
                                                        Text(badgeText)
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(badgeColor)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 3)
                                                            .background(badgeColor.opacity(0.12))
                                                            .clipShape(Capsule())
                                                    }
                                                    
                                                    if !entry.topic.isEmpty {
                                                        Text("Temat: \(entry.topic)")
                                                            .font(.caption)
                                                            .foregroundColor(themeManager.textSecondaryColor)
                                                            .lineLimit(1)
                                                    }
                                                    
                                                    Text("\(entry.teacherName) • \(entry.timeStart) - \(entry.timeEnd)")
                                                        .font(.caption2)
                                                        .foregroundColor(VulcanColors.textMuted)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                                    .onEnded { value in
                                        if value.translation.width < -50 {
                                            if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedDate = next
                                                }
                                            }
                                        } else if value.translation.width > 50 {
                                            if let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedDate = prev
                                                }
                                            }
                                        }
                                    }
                            )
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.backgroundColor, for: .navigationBar)
            .toolbarColorScheme(themeManager.preferredColorScheme == .light ? .light : .dark, for: .navigationBar)
            .task {
                fetchAttendanceForSelectedDate()
            }
        }
    }
    
    private func fetchAttendanceForSelectedDate() {
        if let account = accountManager.activeAccount, let client = accountManager.validClient {
            Task {
                await dataService.fetchAttendance(account: account, client: client, aroundDate: selectedDate)
            }
        }
    }
}

#Preview {
    AttendanceView()
}
