//
//  GradesView.swift
//  Katla
//

import SwiftUI

public struct SubjectGradesGroup: Identifiable {
    public var id: String { subjectName }
    public let subjectName: String
    public let grades: [Grade]
    public let summary: EduVulcanGradeSummaryDTO?
    
    public var average: Double {
        let plusVal = UserDefaults.standard.double(forKey: "plusValue") == 0 ? 0.33 : UserDefaults.standard.double(forKey: "plusValue")
        let minusVal = UserDefaults.standard.double(forKey: "minusValue") == 0 ? 0.33 : UserDefaults.standard.double(forKey: "minusValue")
        let countNp = UserDefaults.standard.bool(forKey: "countNpAsOne")
        return computedAverage(plusVal: plusVal, minusVal: minusVal, countNp: countNp)
    }
    
    public func computedAverage(plusVal: Double, minusVal: Double, countNp: Bool) -> Double {
        guard !grades.isEmpty else { return summary?.average ?? 0.0 }
        
        var totalWeight: Double = 0.0
        var totalWeightedValue: Double = 0.0
        
        for g in grades {
            let text = g.displayText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // Check NP (Nieprzygotowanie)
            if text.contains("np") {
                if countNp {
                    totalWeightedValue += 1.0 * Double(max(g.weight, 1))
                    totalWeight += Double(max(g.weight, 1))
                }
                continue
            }
            
            // Calculate base grade value with plus/minus adjustments
            var val = g.value
            if text.contains("+") {
                let base = floor(g.value)
                val = base > 0 ? base + plusVal : g.value + plusVal
            } else if text.contains("-") {
                let base = ceil(g.value)
                val = base > 0 ? base - minusVal : max(1.0, g.value - minusVal)
            }
            
            let weight = Double(max(g.weight, 1))
            totalWeightedValue += val * weight
            totalWeight += weight
        }
        
        if totalWeight > 0 {
            return totalWeightedValue / totalWeight
        }
        return summary?.average ?? 0.0
    }
}

public enum GradesViewTab: String, CaseIterable, Identifiable {
    case partial = "Cząstkowe"
    case summary = "Przewidywane i Końcowe"
    
    public var id: String { rawValue }
}

public struct GradesView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    @State private var selectedSemester: Int = 1
    @State private var selectedTab: GradesViewTab = .partial
    
    // MARK: - Grades AppStorage Preferences
    @AppStorage("forceLocalAverage") private var forceLocalAverage: Bool = false
    @AppStorage("plusValue") private var plusValue: Double = 0.33
    @AppStorage("minusValue") private var minusValue: Double = 0.33
    @AppStorage("countNpAsOne") private var countNpAsOne: Bool = false
    
    private var groupedSubjects: [SubjectGradesGroup] {
        let gradesToGroup = dataService.grades
        let dictionary = Dictionary(grouping: gradesToGroup, by: { $0.subjectName })
        let summaryDict = Dictionary(grouping: dataService.gradeSummaries, by: { $0.subject.name })
        
        let allSubjects = Set(dictionary.keys).union(summaryDict.keys)
        
        return allSubjects.map { subject -> SubjectGradesGroup in
            let subjectGrades = dictionary[subject] ?? []
            let subjectSummary = summaryDict[subject]?.first
            return SubjectGradesGroup(subjectName: subject, grades: subjectGrades, summary: subjectSummary)
        }.sorted { $0.subjectName < $1.subjectName }
    }
    
    private var overallAverage: Double {
        let validAverages = groupedSubjects.map { $0.computedAverage(plusVal: plusValue, minusVal: minusValue, countNp: countNpAsOne) }.filter { $0 > 0 }
        guard !validAverages.isEmpty else { return 0.0 }
        return validAverages.reduce(0.0, +) / Double(validAverages.count)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Top Semester Picker + Tab Switcher
                    VStack(spacing: 12) {
                        HStack {
                            Text(langManager.string(for: "gr_title").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            Spacer()
                            
                            // Semester Selector (Semestr I / II)
                            Picker("Semestr", selection: $selectedSemester) {
                                Text(langManager.string(for: "gr_sem1")).tag(1)
                                Text(langManager.string(for: "gr_sem2")).tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 190)
                            .onChange(of: selectedSemester) { _, newSemester in
                                reloadGradesForSemester(newSemester)
                            }
                        }
                        
                        Picker("Widok", selection: $selectedTab) {
                            Text(langManager.string(for: "gr_partial")).tag(GradesViewTab.partial)
                            Text(langManager.string(for: "gr_summary")).tag(GradesViewTab.summary)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // MARK: - Overall Average Hero Card
                            if overallAverage > 0 {
                                VulcanCard(padding: 20) {
                                    HStack(spacing: 18) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [VulcanColors.primaryAccent, Color.blue],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 68, height: 68)
                                            
                                            Text(String(format: "%.2f", overallAverage))
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(langManager.string(for: "gr_avg"))
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(themeManager.textPrimaryColor)
                                            
                                            Text("Na podstawie ocen z Semestru \(selectedSemester)")
                                                .font(.caption)
                                                .foregroundColor(themeManager.textSecondaryColor)
                                            
                                            if forceLocalAverage {
                                                Text("• Obliczanie lokalne aktywne (+:\(String(format: "%.2f", plusValue)), -:\(String(format: "%.2f", minusValue)))")
                                                    .font(.caption2)
                                                    .foregroundColor(VulcanColors.primaryAccent)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            
                            // MARK: - Subject Cards List
                            if dataService.isLoading {
                                ProgressView("Pobieranie ocen...")
                                    .tint(VulcanColors.primaryAccent)
                                    .padding(.top, 40)
                            } else if groupedSubjects.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "graduationcap")
                                        .font(.system(size: 44))
                                        .foregroundColor(VulcanColors.textMuted)
                                    Text("Brak ocen w tym semestrze")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Nie pobrano jeszcze ocen dla wybranego okresu klasyfikacyjnego.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(groupedSubjects) { group in
                                    let avg = group.computedAverage(plusVal: plusValue, minusVal: minusValue, countNp: countNpAsOne)
                                    
                                    NavigationLink {
                                        SubjectGradesDetailView(group: group)
                                    } label: {
                                        VulcanCard(padding: 16) {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Text(group.subjectName)
                                                        .font(.system(size: 17, weight: .bold))
                                                        .foregroundColor(themeManager.textPrimaryColor)
                                                    
                                                    Spacer()
                                                    
                                                    if avg > 0 {
                                                        Text(String(format: "Średnia: %.2f", avg))
                                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                                            .foregroundColor(VulcanColors.color(forGrade: avg))
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 4)
                                                            .background(VulcanColors.color(forGrade: avg).opacity(0.12))
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                                
                                                if selectedTab == .partial {
                                                    if group.grades.isEmpty {
                                                        Text("Brak ocen cząstkowych")
                                                            .font(.caption)
                                                            .foregroundColor(themeManager.textSecondaryColor)
                                                    } else {
                                                        ScrollView(.horizontal, showsIndicators: false) {
                                                            HStack(spacing: 8) {
                                                                ForEach(group.grades) { grade in
                                                                    GradeChip(grade: grade)
                                                                }
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    // Predicted & Final Grades View
                                                    HStack(spacing: 16) {
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("Przewidywana")
                                                                .font(.caption2)
                                                                .foregroundColor(VulcanColors.textMuted)
                                                            Text(group.summary?.predictedGrade ?? "-")
                                                                .font(.system(size: 16, weight: .bold))
                                                                .foregroundColor(themeManager.textPrimaryColor)
                                                        }
                                                        
                                                        Divider().frame(height: 24)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("Klasyfikacyjna")
                                                                .font(.caption2)
                                                                .foregroundColor(VulcanColors.textMuted)
                                                            Text(group.summary?.finalGrade ?? "-")
                                                                .font(.system(size: 16, weight: .bold))
                                                                .foregroundColor(VulcanColors.primaryAccent)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        reloadGradesForSemester(selectedSemester)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if let account = accountManager.activeAccount {
                    selectedSemester = account.periods.first(where: { $0.current })?.number ?? 1
                    reloadGradesForSemester(selectedSemester)
                }
            }
        }
    }
    
    private func reloadGradesForSemester(_ sem: Int) {
        guard let account = accountManager.activeAccount, let client = accountManager.validClient else { return }
        let periodId = sem == 1 ? account.semester1PeriodId : account.semester2PeriodId
        
        Task {
            await dataService.fetchGradesForPeriod(account: account, client: client, periodId: periodId)
        }
    }
}

// MARK: - Individual Grade Chip View
public struct GradeChip: View {
    public let grade: Grade
    @Bindable private var themeManager = ThemeManager.shared
    
    private var gradeColor: Color {
        VulcanColors.color(forGrade: grade.value)
    }
    
    public var body: some View {
        VStack(spacing: 3) {
            Text(grade.displayText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(gradeColor)
            
            Text("w: \(grade.weight)")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(width: 44, height: 44)
        .background(gradeColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(gradeColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    GradesView()
}
