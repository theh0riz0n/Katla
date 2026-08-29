//
//  RegistrationService.swift
//  Vulcanova
//

import Foundation
import Security

public final class RegistrationService {
    public static let shared = RegistrationService()
    
    private init() {}
    
    /// Registers device with EduVulcan using JWT tokens obtained from school portal
    public func registerByJwt(tokens: [String], tenant: String) async throws -> (restUrl: String, client: EduVulcanClient, accounts: [EduVulcanAccount], keyInfo: RequestSigner.KeyPairInfo) {
        print("\n==================================================")
        print("[VulcanovaRegister] 🚀 Starting JWT Registration for tenant: '\(tenant)'")
        print("[VulcanovaRegister] 🎫 Tokens count: \(tokens.count)")
        
        let keyInfo = try RequestSigner.shared.generateRSAKeyPair()
        print("[VulcanovaRegister] 🔑 KeyPair generated:")
        print("   • Fingerprint: \(keyInfo.fingerprint)")
        
        let client = EduVulcanClient(keyId: keyInfo.fingerprint, privateKey: keyInfo.privateKey)
        let restUrl = "\(EduVulcanClient.baseUrl)/\(tenant)/api"
        
        let payload: [String: Any] = [
            "OS": "Android",
            "Certificate": keyInfo.rawPublicBase64,
            "CertificateType": "RSA_PEM",
            "DeviceModel": "Pixel",
            "SelfIdentifier": UUID().uuidString.lowercased(),
            "CertificateThumbprint": keyInfo.fingerprint,
            "Tokens": tokens
        ]
        
        print("[VulcanovaRegister] 📡 Step 1: POST mobile/register/jwt to \(restUrl)")
        let _: EmptyEnvelope? = try await client.request(
            method: "POST",
            endpoint: "mobile/register/jwt",
            restUrl: restUrl,
            payloadEnvelope: payload
        )
        print("[VulcanovaRegister] ✅ Step 1 JWT registration successful!")
        
        print("[VulcanovaRegister] 📡 Step 2: GET mobile/register/hebe?mode=2")
        let accounts: [EduVulcanAccount] = try await client.request(
            method: "GET",
            endpoint: "mobile/register/hebe",
            restUrl: restUrl,
            queryParams: ["mode": "2"]
        )
        
        print("[VulcanovaRegister] ✅ Step 2 Accounts fetched: \(accounts.count) pupils found!")
        for (idx, acc) in accounts.enumerated() {
            print("[VulcanovaRegister] 🎒 Account #\(idx + 1): Pupil='\(acc.pupil.firstName) \(acc.pupil.surname)' (ID: \(acc.pupil.id))")
            print("[VulcanovaRegister]    • Unit ID: \(acc.unit.id), Symbol: '\(acc.unit.symbol)', Name: '\(acc.unit.name)', RestURL: '\(acc.unit.restUrl ?? "nil")'")
            print("[VulcanovaRegister]    • Periods (\(acc.periods.count)): \(acc.periods.map { "ID:\($0.id), Current:\($0.current)" }.joined(separator: ", "))")
        }
        print("==================================================\n")
        
        return (restUrl, client, accounts, keyInfo)
    }
}
