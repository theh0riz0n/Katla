//
//  PrometheusLoginHelper.swift
//  Vulcanova
//

import Foundation

public struct PrometheusLoginResult {
    public let tenant: String
    public let tokens: [String]
    public let accessToken: String
}

public final class PrometheusLoginHelper {
    public static let shared = PrometheusLoginHelper()
    
    private init() {}
    
    /// Encodes string for application/x-www-form-urlencoded
    private func urlFormEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?#/")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
    
    /// Decodes tenant symbol from JWT payload
    public func extractTenant(from jwtToken: String) -> String {
        let components = jwtToken.components(separatedBy: ".")
        guard components.count >= 2 else { return "warszawa" }
        
        var base64 = components[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return "warszawa"
        }
        
        return json["tenant"] as? String ?? json["Tenant"] as? String ?? "warszawa"
    }
    
    /// Extracts attribute from input tag safely
    private func extractApValue(from html: String) -> String? {
        guard let apIndex = html.range(of: "id=\"ap\"")?.lowerBound ?? html.range(of: "name=\"ap\"")?.lowerBound else {
            return nil
        }
        
        let startTag = html[...apIndex].range(of: "<input", options: .backwards)?.lowerBound ?? apIndex
        let endTag = html[apIndex...].range(of: ">")?.upperBound ?? html.endIndex
        let inputTag = String(html[startTag..<endTag])
        
        guard let valueMatch = inputTag.range(of: "value=\"([^\"]*)\"", options: .regularExpression) else {
            return nil
        }
        
        let matched = String(inputTag[valueMatch])
        let valueStr = matched
            .replacingOccurrences(of: "value=\"", with: "")
            .dropLast() // remove trailing quote
        
        return String(valueStr)
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }
    
    /// Performs direct EduVulcan Login (Username or Email) + Password login with automatic Proof-of-Work Captcha solving
    public func login(login: String, password: String) async throws -> PrometheusLoginResult {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration)
        
        // 1. Fetch Login Page HTML & extract CSRF Token & Captcha Params
        guard let loginUrl = URL(string: "https://eduvulcan.pl/logowanie") else {
            throw URLError(.badURL)
        }
        
        var loginPageRequest = URLRequest(url: loginUrl)
        loginPageRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (loginPageData, _) = try await session.data(for: loginPageRequest)
        guard let loginPageHtml = String(data: loginPageData, encoding: .utf8) else {
            throw NSError(domain: "PrometheusLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nie można odczytać strony logowania"])
        }
        
        // Extract __RequestVerificationToken
        guard let csrfRange = loginPageHtml.range(of: "name=\"__RequestVerificationToken\"\\s+type=\"hidden\"\\s+value=\"([^\"]+)\"", options: .regularExpression),
              let valueRange = loginPageHtml[csrfRange].range(of: "value=\"([^\"]+)\"", options: .regularExpression) else {
            throw NSError(domain: "PrometheusLogin", code: -2, userInfo: [NSLocalizedDescriptionKey: "Nie odnaleziono tokenu CSRF EduVulcan"])
        }
        
        let rawValueMatch = String(loginPageHtml[valueRange])
        let csrfToken = rawValueMatch.replacingOccurrences(of: "value=\"", with: "").replacingOccurrences(of: "\"", with: "")
        
        // Extract & Solve Captcha if required
        var captchaResponseString = ""
        if loginPageHtml.contains("captcha-wrapper") {
            let challenge = extractAttribute("data-challenge", from: loginPageHtml) ?? ""
            let difficulty = UInt32(extractAttribute("data-difficulty", from: loginPageHtml) ?? "0") ?? 0
            let rounds = Int(extractAttribute("data-rounds", from: loginPageHtml) ?? "0") ?? 0
            
            if !challenge.isEmpty && difficulty > 0 && rounds > 0 {
                captchaResponseString = try POWCaptchaResolver.computeCaptchaResponse(
                    challenge: challenge,
                    difficulty: difficulty,
                    rounds: rounds
                )
            }
        }
        
        // 2. POST Username & Password to /logowanie
        var postRequest = URLRequest(url: loginUrl)
        postRequest.httpMethod = "POST"
        postRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        postRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let encodedLogin = urlFormEncode(login)
        let encodedPass = urlFormEncode(password)
        let encodedCsrf = urlFormEncode(csrfToken)
        let encodedCaptcha = urlFormEncode(captchaResponseString)
        
        let formBodyString = "UserName=\(encodedLogin)&Password=\(encodedPass)&captcha-response=\(encodedCaptcha)&__RequestVerificationToken=\(encodedCsrf)"
        postRequest.httpBody = formBodyString.data(using: .utf8)
        
        let (_, loginResponse) = try await session.data(for: postRequest)
        guard (loginResponse as? HTTPURLResponse) != nil else {
            throw NSError(domain: "PrometheusLogin", code: -3, userInfo: [NSLocalizedDescriptionKey: "Błąd serwera logowania"])
        }
        
        // 3. GET /api/ap to fetch tokens
        guard let apUrl = URL(string: "https://eduvulcan.pl/api/ap") else {
            throw URLError(.badURL)
        }
        
        var apRequest = URLRequest(url: apUrl)
        apRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (apData, _) = try await session.data(for: apRequest)
        guard let apHtml = String(data: apData, encoding: .utf8) else {
            throw NSError(domain: "PrometheusLogin", code: -4, userInfo: [NSLocalizedDescriptionKey: "Błąd odczytu danych ucznia z /api/ap"])
        }
        
        guard let rawApValue = extractApValue(from: apHtml) else {
            throw NSError(domain: "PrometheusLogin", code: -5, userInfo: [NSLocalizedDescriptionKey: "Błędny login lub hasło EduVulcan (brak zgody lub złe dane)"])
        }
        
        guard let apDataBytes = rawApValue.data(using: .utf8),
              let apDict = try? JSONSerialization.jsonObject(with: apDataBytes, options: []) as? [String: Any],
              let success = apDict["Success"] as? Bool, success == true,
              let tokens = apDict["Tokens"] as? [String], !tokens.isEmpty else {
            let errorMsg = (try? JSONSerialization.jsonObject(with: rawApValue.data(using: .utf8) ?? Data(), options: []) as? [String: Any])?["ErrorMessage"] as? String
            throw NSError(domain: "PrometheusLogin", code: -6, userInfo: [NSLocalizedDescriptionKey: errorMsg ?? "Błędny login/hasło lub brak uczniów na koncie EduVulcan"])
        }
        
        let firstToken = tokens.first ?? ""
        let tenant = extractTenant(from: firstToken)
        let mainAccessToken = apDict["AccessToken"] as? String ?? ""
        
        return PrometheusLoginResult(tenant: tenant, tokens: tokens, accessToken: mainAccessToken)
    }
    
    private func extractAttribute(_ attrName: String, from html: String) -> String? {
        guard let range = html.range(of: "\(attrName)=\"([^\"]+)\"", options: .regularExpression) else { return nil }
        let matched = String(html[range])
        guard let valRange = matched.range(of: "\"([^\"]+)\"", options: .regularExpression) else { return nil }
        return String(matched[valRange]).replacingOccurrences(of: "\"", with: "")
    }
}
