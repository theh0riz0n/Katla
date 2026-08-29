//
//  MoreMenuView.swift
//  Katla
//

import SwiftUI

public struct MoreMenuItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let icon: String
    public let color: Color
    public let destination: AnyView
}

public struct MoreMenuView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    @State private var accountManager = AccountManager.shared
    
    private var menuItems: [MoreMenuItem] {
        [
            MoreMenuItem(
                title: langManager.string(for: "msg_title"),
                subtitle: "Skrzynka odbiorcza, wysłane i kosz",
                icon: "envelope.fill",
                color: .blue,
                destination: AnyView(MessagesView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "att_title"),
                subtitle: "Statystyki obecności i spóźnień",
                icon: "checkmark.seal.fill",
                color: .green,
                destination: AnyView(AttendanceView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "more_exams"),
                subtitle: "Kalendarz kartkówek i testów",
                icon: "doc.plaintext.fill",
                color: .red,
                destination: AnyView(ExamsView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "more_homework"),
                subtitle: "Zadania i terminy oddania",
                icon: "book.fill",
                color: .orange,
                destination: AnyView(HomeworksView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "more_notes"),
                subtitle: "Wpisy nauczycieli i punktacja zachowania",
                icon: "exclamationmark.bubble.fill",
                color: .purple,
                destination: AnyView(NotesView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "more_meetings"),
                subtitle: "Spotkania z rodzicami i wywiadówki",
                icon: "person.3.fill",
                color: .teal,
                destination: AnyView(MeetingsView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "more_duties"),
                subtitle: "Grafik dyżurów szkolnych ucznia",
                icon: "person.badge.shield.checkmark.fill",
                color: .mint,
                destination: AnyView(DutiesView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "more_teachers"),
                subtitle: "Lista przedmiotów i kadry nauczycielskiej",
                icon: "person.text.rectangle.fill",
                color: .indigo,
                destination: AnyView(TeachersView())
            ),
            MoreMenuItem(
                title: langManager.string(for: "set_title"),
                subtitle: "Motyw, konto i preferencje",
                icon: "gearshape.fill",
                color: VulcanColors.primaryAccent,
                destination: AnyView(SettingsView())
            )
        ]
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // User Profile Summary Banner
                        if let account = accountManager.activeAccount {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(VulcanColors.primaryAccent.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(account.firstName.prefix(1)))
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(VulcanColors.primaryAccent)
                                    )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(account.firstName) \(account.lastName)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("\(account.schoolName) • Klasa \(account.symbol)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(themeManager.cardBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(themeManager.cardBorderColor, lineWidth: 1)
                            )
                        }
                        
                        // Menu Items List
                        VStack(spacing: 10) {
                            ForEach(menuItems) { item in
                                NavigationLink(destination: item.destination) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(item.color.opacity(0.15))
                                                .frame(width: 42, height: 42)
                                            
                                            Image(systemName: item.icon)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(item.color)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(themeManager.textPrimaryColor)
                                            
                                            Text(item.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundColor(themeManager.textSecondaryColor)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(VulcanColors.textMuted)
                                    }
                                    .padding(14)
                                    .background(themeManager.cardBackgroundColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(themeManager.cardBorderColor, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(langManager.string(for: "tab_more"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Generic Placeholder View for upcoming features
public struct GenericPlaceholderView: View {
    @Bindable private var themeManager = ThemeManager.shared
    public let title: String
    public let icon: String
    
    public var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(VulcanColors.primaryAccent)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text("Ta sekcja zostanie pobrana z serwera w najbliższej aktualizacji.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MoreMenuView()
}
