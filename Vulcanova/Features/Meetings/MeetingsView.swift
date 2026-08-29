//
//  MeetingsView.swift
//  Vulcanova
//

import SwiftUI

public struct MeetingsView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        if dataService.isLoading {
                            ProgressView("Pobieranie zebrań...")
                                .tint(VulcanColors.primaryAccent)
                                .padding(.top, 40)
                        } else if dataService.meetings.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "person.3")
                                    .font(.system(size: 44))
                                    .foregroundColor(VulcanColors.textMuted)
                                Text("Brak zaplanowanych zebrań")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                Text("W tym okresie szkoła nie zaplanowała zebrań z rodzicami ani wywiadówek.")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textSecondaryColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .padding(.top, 50)
                        } else {
                            ForEach(dataService.meetings) { meeting in
                                VulcanCard(padding: 16) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.teal.opacity(0.15))
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: "person.3.fill")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.teal)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(meeting.reason)
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(themeManager.textPrimaryColor)
                                                Text("Miejsce: \(meeting.location)")
                                                    .font(.subheadline)
                                                    .foregroundColor(themeManager.textSecondaryColor)
                                            }
                                            Spacer()
                                            
                                            Text(meeting.whenString)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(VulcanColors.primaryAccent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(VulcanColors.primaryAccent.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                        
                                        if !meeting.agenda.isEmpty {
                                            Divider()
                                                .overlay(themeManager.cardBorderColor)
                                            Text("Porządek zebrania:")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(VulcanColors.textMuted)
                                            Text(meeting.agenda)
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.textPrimaryColor)
                                        }
                                        
                                        if let info = meeting.additionalInfo, !info.isEmpty {
                                            Text("Dodatkowe informacje: \(info)")
                                                .font(.caption)
                                                .foregroundColor(themeManager.textSecondaryColor)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .refreshable {
                    if let account = accountManager.activeAccount, let client = accountManager.validClient {
                        await dataService.fetchMeetings(account: account, client: client)
                    }
                }
            }
            .navigationTitle("Zebrania z rodzicami")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient {
                    await dataService.fetchMeetings(account: account, client: client)
                }
            }
        }
    }
}

#Preview {
    MeetingsView()
}
