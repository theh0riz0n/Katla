//
//  EduVulcanClient.swift
//  Vulcanova
//

import Foundation
import Security

public final class EduVulcanClient {
    public static let baseUrl = "https://lekcjaplus.vulcan.net.pl"
    public static let appName = "DzienniczekPlus 3.0"
    public static let appVersion = "26.04.01 (G)"
    public static let appVersionCode = "946"
    public static let apiVersion = "1"
    public static let userAgent = "Dart/3.10 (dart:io)"
    
    private let keyId: String
    private let privateKey: SecKey
    private let session: URLSession
    
    public init(keyId: String, privateKey: SecKey, session: URLSession = .shared) {
        self.keyId = keyId
        self.privateKey = privateKey
        self.session = session
    }
    
    // MARK: - Execute Generic API Request
    public func request<T: Decodable>(
        method: String = "GET",
        endpoint: String,
        restUrl: String,
        pupilId: Int? = nil,
        queryParams: [String: String]? = nil,
        payloadEnvelope: [String: Any]? = nil
    ) async throws -> T {
        let fullUrlString = "\(restUrl)/\(endpoint)"
        
        var urlComponents = URLComponents(string: fullUrlString)
        if let queryParams = queryParams {
            urlComponents?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let requestUrl = urlComponents?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method
        
        // Build JSON body if payload provided
        var bodyString: String? = nil
        if let payloadEnvelope = payloadEnvelope {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampFormatted = formatter.string(from: Date())
            
            let fullBodyDict: [String: Any] = [
                "AppName": EduVulcanClient.appName,
                "AppVersion": EduVulcanClient.appVersion,
                "NotificationToken": "",
                "API": 1,
                "RequestId": UUID().uuidString.lowercased(),
                "Timestamp": Int(Date().timeIntervalSince1970),
                "TimestampFormatted": timestampFormatted,
                "Envelope": payloadEnvelope
            ]
            
            let bodyData = try JSONSerialization.data(withJSONObject: fullBodyDict, options: [])
            bodyString = String(data: bodyData, encoding: .utf8)
            request.httpBody = bodyData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        } else {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Sign headers using RequestSigner
        let signatureHeaders = try RequestSigner.shared.getSignatureHeaders(
            keyId: keyId,
            privateKey: privateKey,
            body: bodyString,
            fullUrlString: requestUrl.absoluteString
        )
        
        for (headerKey, headerVal) in signatureHeaders {
            request.setValue(headerVal, forHTTPHeaderField: headerKey)
        }
        
        // Vulcan Specific Headers
        request.setValue("Android", forHTTPHeaderField: "vOS")
        request.setValue(EduVulcanClient.appVersionCode, forHTTPHeaderField: "vVersionCode")
        request.setValue(EduVulcanClient.apiVersion, forHTTPHeaderField: "vAPI")
        request.setValue(EduVulcanClient.userAgent, forHTTPHeaderField: "User-Agent")
        
        if let pupilId = pupilId {
            request.setValue("\(pupilId)", forHTTPHeaderField: "vHint")
        }
        
        // Log Request to Xcode Console
        print("\n--------------------------------------------------")
        print("[VulcanovaAPI] 🌐 \(method) \(requestUrl.absoluteString)")
        print("[VulcanovaAPI] 🔑 KeyId / Fingerprint: \(keyId)")
        if let headers = request.allHTTPHeaderFields {
            print("[VulcanovaAPI] 📋 Headers:")
            for (k, v) in headers {
                print("   • \(k): \(v)")
            }
        }
        if let bodyString = bodyString {
            print("[VulcanovaAPI] 📤 Request Body:\n\(bodyString)")
        }
        
        // Perform URLSession Request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[VulcanovaAPI] ❌ Invalid HTTP URL Response")
            throw NSError(domain: "EduVulcanClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nieprawidłowa odpowiedź sieciowa"])
        }
        
        let responseStr = String(data: data, encoding: .utf8) ?? "Brak treści"
        print("[VulcanovaAPI] 📥 Response Status: \(httpResponse.statusCode)")
        print("[VulcanovaAPI] 📥 Response Body:\n\(responseStr)")
        print("--------------------------------------------------\n")
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "EduVulcanClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(responseStr)"])
        }
        
        // Decode Envelope Response
        let decodedEnvelope = try JSONDecoder().decode(EduVulcanEnvelopeResponse<T>.self, from: data)
        guard decodedEnvelope.status.code == 0 else {
            print("[VulcanovaAPI] ⚠️ EduVulcan Error Code \(decodedEnvelope.status.code): \(decodedEnvelope.status.message)")
            throw NSError(domain: "EduVulcanClient", code: decodedEnvelope.status.code, userInfo: [NSLocalizedDescriptionKey: "EduVulcan API Error (\(decodedEnvelope.status.code)): \(decodedEnvelope.status.message)"])
        }
        
        if let payloadResult = decodedEnvelope.envelope {
            return payloadResult
        } else if let emptyResult = EmptyEnvelope() as? T {
            return emptyResult
        } else {
            throw NSError(domain: "EduVulcanClient", code: -100, userInfo: [NSLocalizedDescriptionKey: "Envelope is empty in API response"])
        }
    }
}
