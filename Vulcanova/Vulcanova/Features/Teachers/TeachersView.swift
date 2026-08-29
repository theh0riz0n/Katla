//
//  TeachersView.swift
//  Katla
//

import SwiftUI

public struct GroupedTeacher: Identifiable {
    public var id: String { teacherName }
    public let teacherName: String
    public let initials: String
    public let subjects: [String]
    
    public var subjectsJoined: String {
        subjects.joined(separator: ", ")
    }
}

public struct TeachersView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    @AppStorage("hideTeacherData") private var hideTeacherData: Bool = false
    @State private var searchText = ""
    
    private var groupedTeachers: [GroupedTeacher] {
        let dictionary = Dictionary(grouping: dataService.teachers, by: { $0.teacherName })
        
        let groups = dictionary.map { name, teacherDTOs -> GroupedTeacher in
            let initials = teacherDTOs.first?.initials ?? "N"
            let uniqueSubjects = Array(Set(teacherDTOs.map { $0.subjectName })).sorted()
            return GroupedTeacher(teacherName: name, initials: initials, subjects: uniqueSubjects)
        }
        
        return groups.sorted { $0.teacherName.localizedStandardCompare($1.teacherName) == .orderedAscending }
    }
    
    private var filteredTeachers: [GroupedTeacher] {
        if searchText.isEmpty {
            return groupedTeachers
        }
        return groupedTeachers.filter { teacher in
            teacher.teacherName.localizedCaseInsensitiveContains(searchText) ||
            teacher.subjectsJoined.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(VulcanColors.textMuted)
                        TextField("Szukaj nauczyciela lub przedmiotu...", text: $searchText)
                            .foregroundColor(themeManager.textPrimaryColor)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(VulcanColors.textMuted)
                            }
                        }
                    }
                    .padding(12)
                    .background(themeManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(themeManager.cardBorderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if dataService.isLoading {
                                ProgressView("Pobieranie listy nauczycieli...")
                                    .tint(VulcanColors.primaryAccent)
                                    .padding(.top, 40)
                            } else if filteredTeachers.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "person.text.rectangle")
                                        .font(.system(size: 44))
                                        .foregroundColor(VulcanColors.textMuted)
                                    Text("Brak danych nauczycieli")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Nie odnaleziono wpisów spełniających wybrane kryteria.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(filteredTeachers) { teacher in
                                    let displayName = hideTeacherData ? obfuscateTeacher(teacher.teacherName) : teacher.teacherName
                                    
                                    VulcanCard(padding: 14) {
                                        HStack(spacing: 14) {
                                            // Avatar Circle with Initials
                                            ZStack {
                                                Circle()
                                                    .fill(VulcanColors.primaryAccent.opacity(0.15))
                                                    .frame(width: 48, height: 48)
                                                Text(teacher.initials)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(VulcanColors.primaryAccent)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(displayName)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(themeManager.textPrimaryColor)
                                                
                                                HStack(spacing: 6) {
                                                    Image(systemName: "book.closed.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(VulcanColors.primaryAccent)
                                                    Text(teacher.subjectsJoined)
                                                        .font(.subheadline)
                                                        .foregroundColor(themeManager.textSecondaryColor)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        if let account = accountManager.activeAccount, let client = accountManager.validClient {
                            await dataService.fetchTeachers(account: account, client: client)
                        }
                    }
                }
            }
            .navigationTitle("Nauczyciele")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient {
                    await dataService.fetchTeachers(account: account, client: client)
                }
            }
        }
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
    TeachersView()
}
