//
//  ExamsView.swift
//  Vulcanova
//

import SwiftUI

public struct ExamsView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    
    @State private var selectedDate: Date = Date()
    @State private var isMonthPickerPresented = false
    @State private var selectedExam: EduVulcanExamDTO? = nil
    
    private var calendar: Calendar { Calendar.current }
    
    private var datesInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let days = calendar.range(of: .day, in: .month, for: selectedDate) else {
            return [selectedDate]
        }
        
        return days.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
        }
    }
    
    private var selectedDateString: String {
        DateFormatter.yyyyMMdd.string(from: selectedDate)
    }
    
    private var examsForSelectedDate: [EduVulcanExamDTO] {
        dataService.exams.filter { exam in
            exam.deadlineString == selectedDateString
        }
    }
    
    private var monthYearHeaderString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Top Header (Title + Month Jump Button)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SPRAWDZIANY I KARTKÓWKI")
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
                                selectedDate = Date()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Dzisiaj")
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
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // MARK: - Horizontal Days Carousel
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(datesInMonth, id: \.self) { date in
                                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                    let isToday = calendar.isDateInToday(date)
                                    let examCount = dataService.exams.filter { $0.deadlineString == DateFormatter.yyyyMMdd.string(from: date) }.count
                                    
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedDate = date
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(dayName(for: date))
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(isSelected ? .white : themeManager.textSecondaryColor)
                                            
                                            Text("\(calendar.component(.day, from: date))")
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundColor(isSelected ? .white : (isToday ? VulcanColors.primaryAccent : themeManager.textPrimaryColor))
                                            
                                            if examCount > 0 {
                                                Circle()
                                                    .fill(isSelected ? .white : Color.red)
                                                    .frame(width: 5, height: 5)
                                            } else {
                                                Circle()
                                                    .fill(Color.clear)
                                                    .frame(width: 5, height: 5)
                                            }
                                        }
                                        .frame(width: 52, height: 68)
                                        .background(
                                            isSelected ? VulcanColors.primaryAccent : themeManager.cardBackgroundColor
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(isSelected ? VulcanColors.primaryAccent : (isToday ? VulcanColors.primaryAccent.opacity(0.5) : themeManager.cardBorderColor), lineWidth: isSelected || isToday ? 1.5 : 1)
                                        )
                                    }
                                    .id(DateFormatter.yyyyMMdd.string(from: date))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                        }
                        .onAppear {
                            proxy.scrollTo(selectedDateString, anchor: .center)
                        }
                        .onChange(of: selectedDate) { _, newDate in
                            withAnimation {
                                proxy.scrollTo(DateFormatter.yyyyMMdd.string(from: newDate), anchor: .center)
                            }
                        }
                    }
                    
                    // MARK: - Exams List Content
                    ScrollView {
                        VStack(spacing: 14) {
                            if dataService.isLoading {
                                ProgressView("Pobieranie sprawdzianów...")
                                    .tint(VulcanColors.primaryAccent)
                                    .padding(.top, 40)
                            } else if examsForSelectedDate.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "doc.plaintext")
                                        .font(.system(size: 44))
                                        .foregroundColor(VulcanColors.textMuted)
                                    Text("Brak sprawdzianów w tym dniu")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Na wybrany dzień (\(selectedDateString)) nie zaplanowano żądnych sprawdzianów ani kartkówek.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(examsForSelectedDate) { exam in
                                    let isKartkowka = exam.type.localizedCaseInsensitiveContains("kartk")
                                    let badgeColor: Color = isKartkowka ? .purple : .red
                                    
                                    Button {
                                        selectedExam = exam
                                    } label: {
                                        VulcanCard(padding: 16) {
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: isKartkowka ? "bolt.fill" : "doc.text.fill")
                                                            .font(.caption2)
                                                        Text(exam.type.uppercased())
                                                            .font(.system(size: 11, weight: .bold))
                                                    }
                                                    .foregroundColor(badgeColor)
                                                    .padding(.horizontal, 9)
                                                    .padding(.vertical, 4.5)
                                                    .background(badgeColor.opacity(0.14))
                                                    .clipShape(Capsule())
                                                    
                                                    Spacer()
                                                    
                                                    if let creator = exam.creator?.displayName {
                                                        Text(creator)
                                                            .font(.caption)
                                                            .foregroundColor(themeManager.textSecondaryColor)
                                                    }
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(VulcanColors.textMuted)
                                                }
                                                
                                                Text(exam.subject?.name ?? "Przedmiot")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(themeManager.textPrimaryColor)
                                                
                                                if !exam.content.isEmpty {
                                                    Text(exam.content)
                                                        .font(.subheadline)
                                                        .foregroundColor(themeManager.textSecondaryColor)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
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
                                        if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = nextDay
                                            }
                                        }
                                    } else if value.translation.width > 50 {
                                        if let prevDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = prevDay
                                            }
                                        }
                                    }
                                }
                        )
                    }
                    .refreshable {
                        if let account = accountManager.activeAccount, let client = accountManager.validClient {
                            await dataService.fetchExams(account: account, client: client, dateFromStr: "2025-09-01", dateToStr: "2027-08-31")
                        }
                    }
                }
            }
            .navigationTitle("Sprawdziany")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isMonthPickerPresented) {
                MonthYearPickerSheetView(selectedDate: $selectedDate)
            }
            .sheet(item: $selectedExam) { exam in
                ExamDetailSheetView(exam: exam)
            }
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient {
                    await dataService.fetchExams(account: account, client: client, dateFromStr: "2025-09-01", dateToStr: "2027-08-31")
                }
            }
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Dedicated Exam Detail Modal Sheet
public struct ExamDetailSheetView: View {
    public let exam: EduVulcanExamDTO
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    
    private var isKartkowka: Bool {
        exam.type.localizedCaseInsensitiveContains("kartk")
    }
    
    private var accentColor: Color {
        isKartkowka ? .purple : .red
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header Status Badge
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: isKartkowka ? "bolt.fill" : "doc.text.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(accentColor)
                            }
                            
                            Text(exam.type.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(accentColor)
                                .tracking(1.4)
                            
                            Text(exam.subject?.name ?? "Przedmiot szkolny")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.textPrimaryColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
                        Divider()
                            .overlay(themeManager.cardBorderColor)
                        
                        // MARK: - Full Content Card (Scope / Topic)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ZAKRES / ZAGADNIENIA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            Text(exam.content.isEmpty ? "Brak wpisanego szczegółowego zakresu materiału." : exam.content)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.textPrimaryColor)
                                .lineSpacing(4)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(themeManager.cardBorderColor, lineWidth: 1)
                        )
                        
                        // MARK: - Meta Details Card (Teacher, Date)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("INFORMACJE O WPISIE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            if let creator = exam.creator?.displayName {
                                HDetailRow(title: "Nauczyciel wpisujący", value: creator)
                            }
                            
                            HDetailRow(title: "Typ pracy", value: exam.type)
                            
                            if !exam.deadlineString.isEmpty {
                                HDetailRow(title: "Termin sprawdzianu", value: exam.deadlineString)
                            }
                        }
                        .padding(18)
                        .background(themeManager.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(themeManager.cardBorderColor, lineWidth: 1)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Szczegóły praca/sprawdzian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(VulcanColors.primaryAccent)
                }
            }
        }
    }
}

#Preview {
    ExamsView()
}
