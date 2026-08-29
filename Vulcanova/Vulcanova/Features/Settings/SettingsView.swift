//
//  SettingsView.swift
//  Katla
//

import SwiftUI

// MARK: - Helper iOS Icon Badge View
public struct iOSIconBadge: View {
    public let icon: String
    public let color: Color
    
    public init(icon: String, color: Color) {
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    @State private var accountManager = AccountManager.shared
    
    // MARK: - Preferences State (AppStorage)
    @AppStorage("defaultStartTab") private var defaultStartTab: String = "Plan lekcji"
    @AppStorage("hidePersonalData") private var hidePersonalData: Bool = false
    @AppStorage("hideTeacherData") private var hideTeacherData: Bool = false
    
    // Grades Settings
    @AppStorage("forceLocalAverage") private var forceLocalAverage: Bool = false
    @AppStorage("plusValue") private var plusValue: Double = 0.33
    @AppStorage("minusValue") private var minusValue: Double = 0.33
    @AppStorage("countNpAsOne") private var countNpAsOne: Bool = false
    
    // Timetable Settings
    @AppStorage("skipWeekends") private var skipWeekends: Bool = true
    @AppStorage("ignoreHolidays") private var ignoreHolidays: Bool = false
    @AppStorage("hideExtraLessons") private var hideExtraLessons: Bool = false
    
    // Attendance & Excuse Settings
    @AppStorage("excuseHandlingMode") private var excuseHandlingMode: Int = 1
    
    // Notifications & Sync
    @AppStorage("notifyGrades") private var notifyGrades: Bool = true
    @AppStorage("notifyNotes") private var notifyNotes: Bool = true
    @AppStorage("notifyExams") private var notifyExams: Bool = true
    @AppStorage("backgroundSync") private var backgroundSync: Bool = true
    @AppStorage("useBiometrics") private var useBiometrics: Bool = false
    
    @State private var customPickedColor: Color = VulcanColors.primaryAccent
    @State private var showLogoutAlert = false
    @State private var isForceSyncing = false
    @State private var syncSuccessToast = false
    
    private var rawFullName: String {
        accountManager.activeAccount?.fullName ?? "Tomasz Okurowski"
    }
    
    private var displayedFullName: String {
        if hidePersonalData {
            let parts = rawFullName.split(separator: " ")
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))... \(parts[1].prefix(1)...)"
            } else {
                return "\(rawFullName.prefix(1))..."
            }
        }
        return rawFullName
    }
    
    private var schoolName: String {
        accountManager.activeAccount?.schoolName ?? "Zespół Szkół"
    }
    
    private var symbol: String {
        accountManager.activeAccount?.symbol ?? "4TL"
    }
    
    private var initials: String {
        guard let account = accountManager.activeAccount else { return "TO" }
        let f = account.firstName.prefix(1)
        let l = account.lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }
    
    /// Dynamic Version & Build from Xcode Bundle Info.plist
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Katla \(version) (Build \(build))"
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                List {
                    // MARK: - Account Profile Header
                    Section {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [themeManager.primaryAccent, Color.blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                Text(hidePersonalData ? "••" : initials)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayedFullName)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Text("\(schoolName) • Klasa \(symbol)")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textSecondaryColor)
                                    .lineLimit(1)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text("Konto EduVulcan aktywne")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.green)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 1: Wygląd i Motyw (Appearance & Accent Color)
                    Section {
                        // App Language Selector
                        HStack {
                            iOSIconBadge(icon: "globe", color: .blue)
                            
                            Text(langManager.string(for: "settings_language"))
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Spacer()
                            
                            Picker("", selection: $langManager.currentLanguage) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.displayName).tag(lang)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(themeManager.primaryAccent)
                        }
                        
                        // App Theme Selector
                        HStack {
                            iOSIconBadge(icon: "paintpalette.fill", color: .purple)
                            
                            Text(langManager.string(for: "settings_theme"))
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Spacer()
                            
                            Picker("", selection: $themeManager.currentTheme) {
                                ForEach(AppTheme.allCases) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(themeManager.primaryAccent)
                        }
                        
                        // Accent Color Presets & Custom Picker
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                iOSIconBadge(icon: "eyedropper", color: .pink)
                                
                                Text("Kolor akcentu")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Spacer()
                                
                                ColorPicker("", selection: $customPickedColor, supportsOpacity: false)
                                    .onChange(of: customPickedColor) { _, newColor in
                                        themeManager.accentHex = newColor.toHex()
                                    }
                            }
                            
                            // Color preset chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ThemeManager.presetAccents) { preset in
                                        let isSelected = themeManager.accentHex.lowercased() == preset.hex.lowercased()
                                        
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                themeManager.accentHex = preset.hex
                                                customPickedColor = preset.color
                                            }
                                        } label: {
                                            Circle()
                                                .fill(preset.color)
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                                )
                                                .shadow(color: isSelected ? preset.color.opacity(0.5) : Color.clear, radius: 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Default Start Tab
                        HStack {
                            iOSIconBadge(icon: "sidebar.left", color: .indigo)
                            
                            Text("Startowy ekran")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Spacer()
                            
                            Picker("", selection: $defaultStartTab) {
                                Text("Oceny").tag("Oceny")
                                Text("Plan lekcji").tag("Plan lekcji")
                                Text("Frekwencja").tag("Frekwencja")
                                Text("Więcej").tag("Więcej")
                            }
                            .pickerStyle(.menu)
                            .tint(themeManager.primaryAccent)
                        }
                    } header: {
                        Text(langManager.string(for: "set_sec_appearance"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 2: Prywatność (Privacy)
                    Section {
                        Toggle(isOn: $hidePersonalData) {
                            HStack {
                                iOSIconBadge(icon: "eye.slash.fill", color: .blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ukryj informacje osobiste")
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Maskuje imiona ucznia i rodziców (np. T... O...)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        
                        Toggle(isOn: $hideTeacherData) {
                            HStack {
                                iOSIconBadge(icon: "person.crop.circle.badge.exclamationmark.fill", color: .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ukryj dane nauczycieli")
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Skraca dane kadry (np. A. G.)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                        .tint(themeManager.primaryAccent)
                    } header: {
                        Text(langManager.string(for: "set_sec_privacy"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 3: Oceny (Grades Settings)
                    Section {
                        Toggle(isOn: $forceLocalAverage) {
                            HStack {
                                iOSIconBadge(icon: "calculator.fill", color: .green)
                                Text("Wymuś lokalne obliczanie średniej")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        
                        HStack {
                            iOSIconBadge(icon: "plus.circle.fill", color: .teal)
                            Text("Wartość plusa (+)")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                            Spacer()
                            Picker("", selection: $plusValue) {
                                Text("+0.25").tag(0.25)
                                Text("+0.33").tag(0.33)
                                Text("+0.50").tag(0.50)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        
                        HStack {
                            iOSIconBadge(icon: "minus.circle.fill", color: .red)
                            Text("Wartość minusa (-)")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                            Spacer()
                            Picker("", selection: $minusValue) {
                                Text("-0.25").tag(0.25)
                                Text("-0.33").tag(0.33)
                                Text("-0.50").tag(0.50)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        
                        Toggle(isOn: $countNpAsOne) {
                            HStack {
                                iOSIconBadge(icon: "exclamationmark.triangle.fill", color: .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Liczenie 'np' jako 1")
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Wlicza nieprzygotowanie jako ocenę 1.0")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                        .tint(themeManager.primaryAccent)
                    } header: {
                        Text(langManager.string(for: "set_sec_grades"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 4: Plan Lekcji (Timetable Settings)
                    Section {
                        Toggle(isOn: $skipWeekends) {
                            HStack {
                                iOSIconBadge(icon: "calendar.badge.clock", color: .purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pomijaj weekendy w planie")
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Przeskakuje bezpośrednio z piątku na poniedziałek")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        
                        Toggle(isOn: $ignoreHolidays) {
                            HStack {
                                iOSIconBadge(icon: "sun.haze.fill", color: .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ignoruj dni wolne")
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Wyświetla lekcje na dniach oznaczonych jako wolne")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        
                        Toggle(isOn: $hideExtraLessons) {
                            HStack {
                                iOSIconBadge(icon: "eye.slash.circle.fill", color: .indigo)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ukryj lekcje dodatkowe")
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Ukrywa nieobowiązkowe i dodatkowe zajęcia")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                        .tint(themeManager.primaryAccent)
                    } header: {
                        Text(langManager.string(for: "set_sec_timetable"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 5: Frekwencja i Zwolnienia (Attendance & Excuses)
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                iOSIconBadge(icon: "doc.badge.plus", color: .blue)
                                Text("Obsługa zwolnień")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                            
                            Picker("Tryb zwolnień", selection: $excuseHandlingMode) {
                                Text("1. Licz jako obecność").tag(1)
                                Text("2. Licz jako nieobecność").tag(2)
                                Text("3. Ignoruj zwolnienia").tag(3)
                            }
                            .pickerStyle(.menu)
                            .tint(themeManager.primaryAccent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if excuseHandlingMode == 1 {
                                    Text("• Licz jako obecność: Zwolnienie z lekcji / nieuczęszczanie na przedmiot liczy się jako obecność. (Stosowane w większości szkół)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                } else if excuseHandlingMode == 2 {
                                    Text("• Licz jako nieobecność: Zwolnienie wpisywane przez rodzica z lekcji liczy się jako nieobecność usprawiedliwiona.")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                } else {
                                    Text("• Ignoruj: Zwolnienia nie będą wyświetlane ani uwzględniane w podsumowaniu frekwencji.")
                                        .font(.caption)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text(langManager.string(for: "set_sec_attendance"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 6: Powiadomienia (Notifications)
                    Section {
                        Button {
                            Task {
                                let granted = await NotificationService.shared.requestAuthorization()
                                if granted {
                                    NotificationService.shared.scheduleNotification(
                                        title: "Test Powiadomień Katla 🚀",
                                        body: "Powiadomienia w aplikacji Katla zostały pomyślnie aktywowane!"
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                iOSIconBadge(icon: "bell.badge.fill", color: .purple)
                                Text("Poproś o uprawnienia iOS")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.textPrimaryColor)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(VulcanColors.textMuted)
                            }
                        }
                        
                        Toggle(isOn: $notifyGrades) {
                            HStack {
                                iOSIconBadge(icon: "graduationcap.fill", color: .red)
                                Text("Powiadomienia o ocenach")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        .onChange(of: notifyGrades) { _, newValue in
                            if newValue {
                                Task { _ = await NotificationService.shared.requestAuthorization() }
                            }
                        }
                        
                        Toggle(isOn: $notifyNotes) {
                            HStack {
                                iOSIconBadge(icon: "exclamationmark.bubble.fill", color: .orange)
                                Text("Powiadomienia o uwagach")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        .onChange(of: notifyNotes) { _, newValue in
                            if newValue {
                                Task { _ = await NotificationService.shared.requestAuthorization() }
                            }
                        }
                        
                        Toggle(isOn: $notifyExams) {
                            HStack {
                                iOSIconBadge(icon: "doc.plaintext.fill", color: .pink)
                                Text("Powiadomienia o sprawdzianach")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        .onChange(of: notifyExams) { _, newValue in
                            if newValue {
                                Task { _ = await NotificationService.shared.requestAuthorization() }
                            }
                        }
                        
                        Toggle(isOn: $backgroundSync) {
                            HStack {
                                iOSIconBadge(icon: "arrow.clockwise.circle.fill", color: .green)
                                Text("Odświeżanie w tle")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        .tint(themeManager.primaryAccent)
                    } header: {
                        Text(langManager.string(for: "set_sec_notifications"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 7: Bezpieczeństwo i Synchro
                    Section {
                        Toggle(isOn: $useBiometrics) {
                            HStack {
                                iOSIconBadge(icon: "faceid", color: .teal)
                                Text("Wymagaj Face ID / Touch ID")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        .tint(themeManager.primaryAccent)
                        
                        Button {
                            forceRefreshData()
                        } label: {
                            HStack {
                                iOSIconBadge(icon: "arrow.triangle.2.circlepath", color: .blue)
                                Text("Wymuś synchro z Vulcanem")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Spacer()
                                
                                if isForceSyncing {
                                    ProgressView()
                                        .tint(themeManager.primaryAccent)
                                } else if syncSuccessToast {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    } header: {
                        Text("BEZPIECZEŃSTWO")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 8: O Aplikacji (About & Legal)
                    Section {
                        HStack {
                            iOSIconBadge(icon: "info.circle.fill", color: .gray)
                            Text("Wersja aplikacji")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                            Spacer()
                            Text(appVersionString)
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                        
                        HStack {
                            iOSIconBadge(icon: "checkmark.seal.fill", color: .blue)
                            Text("Status serwera EduVulcan")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                            Spacer()
                            Text("Działa")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        }
                    } header: {
                        Text(langManager.string(for: "set_sec_info"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textMuted)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // MARK: - SECTION 9: Logout Button at the Bottom
                    Section {
                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(langManager.string(for: "set_logout"))
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(langManager.string(for: "set_title"))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Czy na pewno chcesz się wylogować?", isPresented: $showLogoutAlert) {
                Button("Wyloguj", role: .destructive) {
                    performLogout()
                }
                Button("Anuluj", role: .cancel) {}
            } message: {
                Text("Twój zapisany klucz i konto zostaną usunięte z tego urządzenia.")
            }
        }
    }
    
    private func forceRefreshData() {
        guard let account = accountManager.activeAccount, let client = accountManager.validClient else { return }
        isForceSyncing = true
        syncSuccessToast = false
        
        Task {
            await EduVulcanDataService.shared.syncData(account: account, client: client)
            await MainActor.run {
                isForceSyncing = false
                syncSuccessToast = true
                
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run { syncSuccessToast = false }
                }
            }
        }
    }
    
    private func performLogout() {
        accountManager.clearAccount()
        AppSessionManager.shared.logOut()
    }
}

#Preview {
    SettingsView()
}
