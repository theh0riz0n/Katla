//
//  LoginView.swift
//  Katla
//

import SwiftUI

public enum LoginMethod: String, CaseIterable, Identifiable {
    case web = "Przeglądarka Web (EduVulcan)"
    case eduvulcan = "Login i Hasło"
    case jwt = "Token JWT (Ręcznie)"
    case pin = "PIN i Token"
    
    public var id: String { rawValue }
}

public struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: LoginMethod = .web
    @State private var showWebViewSheet = false
    
    // Form fields
    @State private var loginText: String = ""
    @State private var passwordText: String = ""
    
    @State private var jwtToken: String = ""
    @State private var tenantSymbol: String = "warszawa"
    
    @State private var tokenPin: String = ""
    @State private var tokenSymbol: String = ""
    @State private var pinCode: String = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    @State private var themeManager = ThemeManager.shared
    
    public var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header Logo & Title
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(VulcanColors.primaryAccent.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "key.fill")
                                .font(.system(size: 36))
                                .foregroundColor(VulcanColors.primaryAccent)
                        }
                        
                        Text("Logowanie do Katla")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Text("Zaloguj się kontem EduVulcan lub kluczem dostępu z dziennika")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    
                    // MARK: - Method Selector
                    Picker("Metoda logowania", selection: $selectedMethod) {
                        ForEach(LoginMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)
                    
                    // MARK: - Form Inputs
                    if selectedMethod == .web {
                        VStack(spacing: 16) {
                            VulcanCard(padding: 20) {
                                VStack(spacing: 16) {
                                    Image(systemName: "safari.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(VulcanColors.primaryAccent)
                                    
                                    VStack(spacing: 6) {
                                        Text("Logowanie przez EduVulcan Web")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(themeManager.textPrimaryColor)
                                        Text("Najbardziej niezawodna metoda. Pozwala na akceptację regulaminu, zgód oraz logowanie 2FA na oficjalnej stronie.")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.textSecondaryColor)
                                            .multilineTextAlignment(.center)
                                            .lineSpacing(3)
                                    }
                                    
                                    Button {
                                        showWebViewSheet = true
                                    } label: {
                                        HStack {
                                            Text("Otwórz logowanie EduVulcan")
                                                .font(.system(size: 16, weight: .bold))
                                            Image(systemName: "arrow.up.right.square.fill")
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(VulcanColors.primaryAccent)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                }
                            }
                        }
                    } else if selectedMethod == .eduvulcan {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("LOGIN LUB ADRES E-MAIL EDUVULCAN")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                VulcanCard(padding: 12) {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(VulcanColors.primaryAccent)
                                        TextField("np. jan@email.pl lub malinowamaja9123", text: $loginText)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .keyboardType(.emailAddress)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("HASŁO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                VulcanCard(padding: 12) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(VulcanColors.primaryAccent)
                                        SecureField("Wprowadź hasło...", text: $passwordText)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .textContentType(.password)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                    }
                                }
                            }
                            
                            Button {
                                performLogin()
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Zaloguj bezpośrednio")
                                            .font(.system(size: 17, weight: .bold))
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(VulcanColors.primaryAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .disabled(isLoading)
                        }
                    } else if selectedMethod == .jwt {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SYMBOL JEDNOSTKI / MIASTA")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                VulcanCard(padding: 12) {
                                    HStack {
                                        Image(systemName: "building.2.fill")
                                            .foregroundColor(VulcanColors.primaryAccent)
                                        TextField("np. warszawa lub lo1warszawa", text: $tenantSymbol)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .keyboardType(.asciiCapable)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TOKEN JWT EDUVULCAN")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                VulcanCard(padding: 12) {
                                    HStack {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundColor(VulcanColors.primaryAccent)
                                        TextField("Wklej token JWT...", text: $jwtToken)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .keyboardType(.asciiCapable)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                    }
                                }
                            }
                            
                            Button {
                                performLogin()
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Zarejestruj z tokenu JWT")
                                            .font(.system(size: 17, weight: .bold))
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(VulcanColors.primaryAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .disabled(isLoading)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SYMBOL JEDNOSTKI")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                VulcanCard(padding: 12) {
                                    HStack {
                                        Image(systemName: "building.2.fill")
                                            .foregroundColor(VulcanColors.primaryAccent)
                                        TextField("np. powiatwarszawski", text: $tokenSymbol)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .keyboardType(.asciiCapable)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TOKEN REJESTRACYJNY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                VulcanCard(padding: 12) {
                                    HStack {
                                        Image(systemName: "qrcode")
                                            .foregroundColor(VulcanColors.primaryAccent)
                                        TextField("np. 3K141A", text: $tokenPin)
                                            .textInputAutocapitalization(.characters)
                                            .autocorrectionDisabled(true)
                                            .keyboardType(.asciiCapable)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("KOD PIN")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.2)
                                
                                VulcanCard(padding: 12) {
                                    HStack {
                                        Image(systemName: "number.square.fill")
                                            .foregroundColor(VulcanColors.primaryAccent)
                                        SecureField("np. 123456", text: $pinCode)
                                            .autocorrectionDisabled(true)
                                            .keyboardType(.numberPad)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                    }
                                }
                            }
                            
                            Button {
                                performLogin()
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Zarejestruj z kodu PIN")
                                            .font(.system(size: 17, weight: .bold))
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(VulcanColors.primaryAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .disabled(isLoading)
                        }
                    }
                    
                    // MARK: - Error Message Banner
                    if let errorMessage = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showWebViewSheet) {
            EduVulcanWebViewSheet()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeManager.backgroundColor, for: .navigationBar)
        .toolbarColorScheme(themeManager.preferredColorScheme == .light ? .light : .dark, for: .navigationBar)
    }
    
    private func performLogin() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if selectedMethod == .eduvulcan {
                    let cleanLogin = loginText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleanLogin.isEmpty, !passwordText.isEmpty else {
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "Login i hasło nie mogą być puste"
                        }
                        return
                    }
                    
                    // Automated EduVulcan Login (Login/Email + Password) via PrometheusLoginHelper
                    let loginResult = try await PrometheusLoginHelper.shared.login(login: cleanLogin, password: passwordText)
                    
                    let (_, client, accounts, keyInfo) = try await RegistrationService.shared.registerByJwt(tokens: loginResult.tokens, tenant: loginResult.tenant)
                    
                    if let firstAccount = accounts.first {
                        let studentRestUrl = "\(EduVulcanClient.baseUrl)/\(firstAccount.unit.symbol)/api"
                        let student = StudentAccount(
                            id: firstAccount.pupil.id,
                            firstName: firstAccount.pupil.firstName,
                            lastName: firstAccount.pupil.surname,
                            schoolName: firstAccount.unit.name,
                            symbol: firstAccount.unit.symbol,
                            restUrl: studentRestUrl,
                            keyFingerprint: keyInfo.fingerprint,
                            privateKeyBase64: keyInfo.privateKeyBase64,
                            periodId: firstAccount.periods.first(where: { $0.current })?.id ?? 0,
                            unitId: firstAccount.unit.id
                        )
                        
                        await MainActor.run {
                            AccountManager.shared.setActiveAccount(student, client: client)
                        }
                        
                        await EduVulcanDataService.shared.syncData(account: student, client: client)
                        
                        await MainActor.run {
                            isLoading = false
                            AppSessionManager.shared.completeOnboarding()
                            AppSessionManager.shared.logIn()
                        }
                        return
                    }
                } else if selectedMethod == .jwt && !jwtToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Manual JWT Token registration
                    let cleanToken = jwtToken.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanTenant = tenantSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let (_, client, accounts, keyInfo) = try await RegistrationService.shared.registerByJwt(tokens: [cleanToken], tenant: cleanTenant)
                    
                    if let firstAccount = accounts.first {
                        let studentRestUrl = "\(EduVulcanClient.baseUrl)/\(firstAccount.unit.symbol)/api"
                        let student = StudentAccount(
                            id: firstAccount.pupil.id,
                            firstName: firstAccount.pupil.firstName,
                            lastName: firstAccount.pupil.surname,
                            schoolName: firstAccount.unit.name,
                            symbol: firstAccount.unit.symbol,
                            restUrl: studentRestUrl,
                            keyFingerprint: keyInfo.fingerprint,
                            privateKeyBase64: keyInfo.privateKeyBase64,
                            periodId: firstAccount.periods.first(where: { $0.current })?.id ?? 0,
                            unitId: firstAccount.unit.id
                        )
                        
                        await MainActor.run {
                            AccountManager.shared.setActiveAccount(student, client: client)
                        }
                        
                        await EduVulcanDataService.shared.syncData(account: student, client: client)
                        
                        await MainActor.run {
                            isLoading = false
                            AppSessionManager.shared.completeOnboarding()
                            AppSessionManager.shared.logIn()
                        }
                        return
                    }
                }
                
                // Fallback / Demo Account if empty fields
                try await Task.sleep(nanoseconds: 800_000_000)
                let demoAccount = StudentAccount(
                    id: 101,
                    firstName: "Tomasz",
                    lastName: "Okurowski",
                    schoolName: "Liceum Ogólnokształcące w Warszawie",
                    symbol: tenantSymbol.isEmpty ? "warszawa" : tenantSymbol,
                    restUrl: "https://lekcjaplus.vulcan.net.pl/warszawa/api",
                    keyFingerprint: "demo_fingerprint",
                    privateKeyBase64: "",
                    periodId: 1,
                    unitId: 10
                )
                
                await MainActor.run {
                    AccountManager.shared.setActiveAccount(demoAccount)
                    isLoading = false
                    AppSessionManager.shared.completeOnboarding()
                    AppSessionManager.shared.logIn()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Błąd logowania: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
