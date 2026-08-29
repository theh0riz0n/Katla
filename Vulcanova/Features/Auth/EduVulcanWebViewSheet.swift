//
//  EduVulcanWebViewSheet.swift
//  Vulcanova
//

import SwiftUI
import WebKit

public struct EduVulcanWebViewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var statusMessage: String = "Ładowanie strony EduVulcan..."
    @State private var errorMessage: String? = nil
    
    public var body: some View {
        NavigationStack {
            ZStack {
                VulcanColors.darkBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let errorMessage = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(themeManager.textPrimaryColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Spróbuj ponownie") {
                                self.errorMessage = nil
                                self.isLoading = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VulcanColors.primaryAccent)
                        }
                        .padding()
                    }
                    
                    EduVulcanWebViewRepresentable(
                        isLoading: $isLoading,
                        statusMessage: $statusMessage,
                        onTokensIntercepted: { tokens, tenant in
                            handleTokens(tokens: tokens, tenant: tenant)
                        }
                    )
                }
                
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(VulcanColors.primaryAccent)
                            .scaleEffect(1.2)
                        Text(statusMessage)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(VulcanColors.textSecondary)
                    }
                    .padding(20)
                    .background(VulcanColors.cardBackground.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .navigationTitle("Logowanie EduVulcan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                    .foregroundColor(VulcanColors.textSecondary)
                }
            }
        }
    }
    
    private var themeManager: ThemeManager { ThemeManager.shared }
    
    private func handleTokens(tokens: [String], tenant: String) {
        Task {
            do {
                let (tenantRestUrl, client, accounts, keyInfo) = try await RegistrationService.shared.registerByJwt(tokens: tokens, tenant: tenant)
                if let firstAccount = accounts.first {
                    let studentRestUrl = firstAccount.unit.restUrl ?? tenantRestUrl
                    print("[VulcanovaRegister] 🏫 Unit ID: \(firstAccount.unit.id), Symbol: '\(firstAccount.unit.symbol)'")
                    print("[VulcanovaRegister] 🏫 Unit RestURL: '\(firstAccount.unit.restUrl ?? "none")'")
                    print("[VulcanovaRegister] 🏫 Final Student RestURL: '\(studentRestUrl)'")
                    
                    let student = StudentAccount(
                        id: firstAccount.pupil.id,
                        firstName: firstAccount.pupil.firstName,
                        lastName: firstAccount.pupil.surname,
                        schoolName: firstAccount.unit.name,
                        symbol: firstAccount.unit.symbol,
                        restUrl: studentRestUrl,
                        keyFingerprint: keyInfo.fingerprint,
                        privateKeyBase64: keyInfo.privateKeyBase64,
                        periodId: firstAccount.periods.first(where: { $0.current })?.id ?? (firstAccount.periods.first?.id ?? 0),
                        unitId: firstAccount.unit.id
                    )
                    
                    await MainActor.run {
                        AccountManager.shared.setActiveAccount(student, client: client)
                    }
                    
                    // Immediately fetch live grades, schedule, and lucky number
                    await EduVulcanDataService.shared.syncData(account: student, client: client)
                    
                    await MainActor.run {
                        dismiss()
                        AppSessionManager.shared.completeOnboarding()
                        AppSessionManager.shared.logIn()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Zalogowano w przeglądarce, ale nie znaleziono przypisanych kont uczniów."
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Błąd rejestracji konta: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - WKWebView Representable
struct EduVulcanWebViewRepresentable: UIViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var statusMessage: String
    let onTokensIntercepted: ([String], String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "tokenHandler")
        
        let pollingScript = WKUserScript(
            source: """
            setInterval(function() {
                var apVal = document.getElementById('ap')?.value || '';
                if (apVal && apVal.length > 10) {
                    window.webkit.messageHandlers.tokenHandler.postMessage(apVal);
                }
            }, 400);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(pollingScript)
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.websiteDataStore = .default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: "https://eduvulcan.pl/logowanie") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: EduVulcanWebViewRepresentable
        private var isProcessingTokens = false
        
        init(_ parent: EduVulcanWebViewRepresentable) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "tokenHandler", let jsonString = message.body as? String else { return }
            processApJson(jsonString)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.statusMessage = "Ładowanie strony..."
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            
            let currentUrl = webView.url?.absoluteString ?? ""
            
            if !currentUrl.contains("/logowanie") {
                fetchApTokensViaJS(webView: webView)
            } else {
                checkDomForTokens(webView: webView)
            }
        }
        
        private func fetchApTokensViaJS(webView: WKWebView) {
            guard !isProcessingTokens else { return }
            
            let jsFetch = """
            fetch('https://eduvulcan.pl/api/ap')
                .then(response => response.text())
                .then(html => {
                    var parser = new DOMParser();
                    var doc = parser.parseFromString(html, 'text/html');
                    var apVal = doc.getElementById('ap')?.value || '';
                    if (apVal) {
                        window.webkit.messageHandlers.tokenHandler.postMessage(apVal);
                    }
                })
                .catch(err => {});
            """
            
            webView.evaluateJavaScript(jsFetch, completionHandler: nil)
        }
        
        private func checkDomForTokens(webView: WKWebView) {
            guard !isProcessingTokens else { return }
            
            let jsScript = "document.getElementById('ap')?.value || ''"
            webView.evaluateJavaScript(jsScript) { [weak self] result, error in
                guard let self = self, let jsonString = result as? String, !jsonString.isEmpty else { return }
                self.processApJson(jsonString)
            }
        }
        
        private func processApJson(_ jsonString: String) {
            guard !isProcessingTokens else { return }
            
            let cleanJson = jsonString
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&amp;", with: "&")
            
            guard let data = cleanJson.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let success = dict["Success"] as? Bool, success == true,
                  let tokens = dict["Tokens"] as? [String], !tokens.isEmpty else { return }
            
            isProcessingTokens = true
            
            let firstToken = tokens.first ?? ""
            let tenant = PrometheusLoginHelper.shared.extractTenant(from: firstToken)
            
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.statusMessage = "Wykryto tokeny! Pobieranie Twoich ocen i planu lekcji..."
                self.parent.onTokensIntercepted(tokens, tenant)
            }
        }
    }
}

#Preview {
    EduVulcanWebViewSheet()
}
