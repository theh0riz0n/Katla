//
//  HomeworksView.swift
//  Vulcanova
//

import SwiftUI

public struct HomeworksView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    
    @State private var selectedDate: Date = Date()
    @State private var isMonthPickerPresented = false
    @State private var selectedHomework: EduVulcanHomeworkDTO? = nil
    
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
    
    private var homeworksForSelectedDate: [EduVulcanHomeworkDTO] {
        dataService.homeworks.filter { hw in
            hw.deadlineString == selectedDateString
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
                            Text("PRACE DOMOWE")
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
                                    let hwCount = dataService.homeworks.filter { $0.deadlineString == DateFormatter.yyyyMMdd.string(from: date) }.count
                                    
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
                                            
                                            if hwCount > 0 {
                                                Circle()
                                                    .fill(isSelected ? .white : Color.orange)
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
                    
                    // MARK: - Homeworks List Content
                    ScrollView {
                        VStack(spacing: 14) {
                            if dataService.isLoading {
                                ProgressView("Pobieranie prac domowych...")
                                    .tint(VulcanColors.primaryAccent)
                                    .padding(.top, 40)
                            } else if homeworksForSelectedDate.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "book")
                                        .font(.system(size: 44))
                                        .foregroundColor(VulcanColors.textMuted)
                                    Text("Brak zadań domowych w tym dniu")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Na wybrany dzień (\(selectedDateString)) nie wyznaczono żądnych prac domowych.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(homeworksForSelectedDate) { hw in
                                    Button {
                                        selectedHomework = hw
                                    } label: {
                                        VulcanCard(padding: 16) {
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack {
                                                    Text(hw.subject?.name ?? "Przedmiot")
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundColor(themeManager.textPrimaryColor)
                                                    
                                                    Spacer()
                                                    
                                                    if hw.isAnswerRequired {
                                                        Text("ODPOWIEDŹ WYMAGANA")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.orange)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(Color.orange.opacity(0.12))
                                                            .clipShape(Capsule())
                                                    }
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(VulcanColors.textMuted)
                                                }
                                                
                                                Text(hw.content)
                                                    .font(.subheadline)
                                                    .foregroundColor(themeManager.textSecondaryColor)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                if let creator = hw.creator?.displayName {
                                                    Text("Zadał/a: \(creator)")
                                                        .font(.caption)
                                                        .foregroundColor(VulcanColors.textMuted)
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
                            await dataService.fetchHomeworks(account: account, client: client, dateFromStr: "2025-09-01", dateToStr: "2027-08-31")
                        }
                    }
                }
            }
            .navigationTitle("Prace Domowe")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isMonthPickerPresented) {
                MonthYearPickerSheetView(selectedDate: $selectedDate)
            }
            .sheet(item: $selectedHomework) { hw in
                HomeworkDetailSheetView(homework: hw)
            }
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient {
                    await dataService.fetchHomeworks(account: account, client: client, dateFromStr: "2025-09-01", dateToStr: "2027-08-31")
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

// MARK: - Dedicated Homework Detail Modal Sheet
public struct HomeworkDetailSheetView: View {
    public let homework: EduVulcanHomeworkDTO
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    
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
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "book.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            
                            Text("ZADANIE DOMOWE")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.orange)
                                .tracking(1.4)
                            
                            Text(homework.subject?.name ?? "Przedmiot szkolny")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.textPrimaryColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
                        Divider()
                            .overlay(themeManager.cardBorderColor)
                        
                        // MARK: - Full Content Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TREŚĆ ZADANIA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            Text(homework.content.isEmpty ? "Brak treści zadania." : homework.content)
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
                        
                        // MARK: - Meta Details Card (Teacher, Deadline)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("INFORMACJE O ZADANIU")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            if let creator = homework.creator?.displayName {
                                HDetailRow(title: "Nauczyciel zadający", value: creator)
                            }
                            
                            if !homework.deadlineString.isEmpty {
                                HDetailRow(title: "Termin oddania", value: homework.deadlineString)
                            }
                            
                            HDetailRow(title: "Wymagana odpowiedź", value: homework.isAnswerRequired ? "Tak" : "Nie")
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
            .navigationTitle("Szczegóły zadania")
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
    HomeworksView()
}
