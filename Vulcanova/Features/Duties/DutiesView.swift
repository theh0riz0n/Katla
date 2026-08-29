//
//  DutiesView.swift
//  Vulcanova
//

import SwiftUI

public struct DutiesView: View {
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
                            ProgressView("Pobieranie dyżurów...")
                                .tint(VulcanColors.primaryAccent)
                                .padding(.top, 40)
                        } else if dataService.duties.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "person.badge.shield.checkmark")
                                    .font(.system(size: 44))
                                    .foregroundColor(VulcanColors.textMuted)
                                Text("Brak wyznaczonych dyżurów")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                Text("W tym okresie brak wpisanych dyżurów szkolnych dla wybranego ucznia.")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textSecondaryColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .padding(.top, 50)
                        } else {
                            ForEach(dataService.duties) { duty in
                                VulcanCard(padding: 16) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.mint.opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "person.badge.shield.checkmark.fill")
                                                .font(.title3)
                                                .foregroundColor(.mint)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(duty.pupilNames)
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(themeManager.textPrimaryColor)
                                            
                                            Text("Data dyżuru: \(duty.dateString)")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.textSecondaryColor)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .refreshable {
                    if let account = accountManager.activeAccount, let client = accountManager.validClient {
                        await dataService.fetchDuties(account: account, client: client)
                    }
                }
            }
            .navigationTitle("Dyżurni")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient {
                    await dataService.fetchDuties(account: account, client: client)
                }
            }
        }
    }
}

#Preview {
    DutiesView()
}
