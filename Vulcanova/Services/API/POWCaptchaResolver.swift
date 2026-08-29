//
//  POWCaptchaResolver.swift
//  Vulcanova
//

import Foundation
import CryptoKit

public final class POWCaptchaResolver {
    /// Computes the Proof-Of-Work SHA256 captcha response required by EduVulcan
    public static func computeCaptchaResponse(challenge: String, difficulty: UInt32, rounds: Int) throws -> String {
        guard rounds > 0 else { return "" }
        
        var currentPrefix = challenge
        var results: [UInt64] = []
        
        for _ in 0..<rounds {
            var nonce: UInt64 = 1
            var found = false
            
            while nonce <= 1_000_000_000 {
                let testString = "\(currentPrefix)\(nonce)"
                guard let data = testString.data(using: .utf8) else { break }
                
                let hash = SHA256.hash(data: data)
                let hashBytes = Array(hash)
                
                let value = (UInt32(hashBytes[0]) << 24) |
                            (UInt32(hashBytes[1]) << 16) |
                            (UInt32(hashBytes[2]) << 8)  |
                            UInt32(hashBytes[3])
                
                if value < difficulty {
                    results.append(nonce)
                    currentPrefix = testString
                    found = true
                    break
                }
                
                nonce += 1
            }
            
            if !found {
                throw NSError(domain: "POWCaptchaResolver", code: -1, userInfo: [NSLocalizedDescriptionKey: "Błąd wyliczenia Proof of Work dla Captchy"])
            }
        }
        
        return results.map { String($0) }.joined(separator: ";")
    }
}
