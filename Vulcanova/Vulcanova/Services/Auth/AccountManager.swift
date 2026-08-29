//
//  AccountManager.swift
//  Vulcanova
//

import Foundation
import Observation

@Observable
public final class AccountManager {
    public static let shared = AccountManager()
    
    public var activeAccount: StudentAccount? {
        didSet {
            if let account = activeAccount, let data = try? JSONEncoder().encode(account) {
                UserDefaults.standard.set(data, forKey: "active_student_account")
            } else {
                UserDefaults.standard.removeObject(forKey: "active_student_account")
            }
        }
    }
    
    public var activeClient: EduVulcanClient?
    
    public var validClient: EduVulcanClient? {
        if let client = activeClient {
            return client
        }
        if let account = activeAccount {
            restoreClientIfNeeded(for: account)
            return activeClient
        }
        return nil
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "active_student_account"),
           let account = try? JSONDecoder().decode(StudentAccount.self, from: data) {
            self.activeAccount = account
            restoreClientIfNeeded(for: account)
        }
    }
    
    public func setActiveAccount(_ account: StudentAccount, client: EduVulcanClient? = nil) {
        self.activeAccount = account
        if let client = client {
            self.activeClient = client
        } else {
            restoreClientIfNeeded(for: account)
        }
    }
    
    private func restoreClientIfNeeded(for account: StudentAccount) {
        let privKeyBase64 = account.privateKeyBase64
        if let restoredKey = RequestSigner.shared.restorePrivateKey(from: privKeyBase64) {
            self.activeClient = EduVulcanClient(keyId: account.keyFingerprint, privateKey: restoredKey)
            print("[AccountManager] ✅ Restored active API client for fingerprint: \(account.keyFingerprint)")
        } else {
            print("[AccountManager] ⚠️ Failed to restore privateKey for account: \(account.id)")
        }
    }
    
    public func clearAccount() {
        self.activeAccount = nil
        self.activeClient = nil
    }
}
