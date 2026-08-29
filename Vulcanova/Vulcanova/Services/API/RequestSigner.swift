//
//  RequestSigner.swift
//  Vulcanova
//

import Foundation
import CryptoKit
import Security

public final class RequestSigner {
    public static let shared = RequestSigner()
    
    private init() {}
    
    public struct KeyPairInfo {
        public let publicKeyPem: String
        public let rawPublicBase64: String
        public let privateKey: SecKey
        public let fingerprint: String
        public let privateKeyBase64: String
    }
    
    /// Converts iOS SecKey PKCS#1 RSA Public Key to X.509 SubjectPublicKeyInfo DER
    public func exportX509PublicKeyData(from rawPkcs1Data: Data) -> Data {
        if rawPkcs1Data.count == 270 {
            let x509Header: [UInt8] = [
                0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
                0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
                0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
            ]
            var result = Data(x509Header)
            result.append(rawPkcs1Data)
            return result
        }
        return rawPkcs1Data
    }
    
    /// Exports SecKey RSA Private Key to Base64 String
    public func exportPrivateKeyBase64(_ privateKey: SecKey) -> String? {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else { return nil }
        return data.base64EncodedString()
    }
    
    /// Restores SecKey RSA Private Key from Base64 String
    public func restorePrivateKey(from base64String: String) -> SecKey? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]
        var error: Unmanaged<CFError>?
        return SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error)
    }
    
    /// Generates a new 2048-bit RSA key pair with MD5 fingerprint matching Vulcan spec
    public func generateRSAKeyPair() throws -> KeyPairInfo {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error?.takeRetainedValue() ?? NSError(domain: "RequestSigner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate RSA KeyPair"])
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw error?.takeRetainedValue() ?? NSError(domain: "RequestSigner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to export public key"])
        }
        
        let x509Data = exportX509PublicKeyData(from: publicKeyData)
        let base64Public = x509Data.base64EncodedString()
        
        var chunkedPemLines: [String] = []
        var strIndex = base64Public.startIndex
        while strIndex < base64Public.endIndex {
            let nextIndex = base64Public.index(strIndex, offsetBy: 64, limitedBy: base64Public.endIndex) ?? base64Public.endIndex
            chunkedPemLines.append(String(base64Public[strIndex..<nextIndex]))
            strIndex = nextIndex
        }
        
        let pemContent = chunkedPemLines.joined(separator: "\n")
        let pem = "-----BEGIN PUBLIC KEY-----\n\(pemContent)\n-----END PUBLIC KEY-----\n"
        
        let md5 = Insecure.MD5.hash(data: pem.data(using: .utf8)!)
        let fingerprint = md5.map { String(format: "%02x", $0) }.joined()
        
        let privBase64 = exportPrivateKeyBase64(privateKey) ?? ""
        
        return KeyPairInfo(publicKeyPem: pem, rawPublicBase64: base64Public, privateKey: privateKey, fingerprint: fingerprint, privateKeyBase64: privBase64)
    }
    
    /// Computes SHA256 digest of body string in Base64
    public func computeDigest(_ bodyString: String?) -> String? {
        guard let bodyString = bodyString, let data = bodyString.data(using: .utf8) else { return nil }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
    }
    
    /// Extracts canonical path (api/mobile/...) and percent-encodes slashes matching Kotlin UrlEncoderUtil
    public func formatCanonicalUrl(from fullUrlString: String) -> String {
        let urlWithoutQuery = fullUrlString.components(separatedBy: "?").first ?? fullUrlString
        guard let range = urlWithoutQuery.range(of: "api/mobile/.*", options: .regularExpression) else {
            return urlWithoutQuery.lowercased()
        }
        let matched = String(urlWithoutQuery[range])
        
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.~"))
        let encoded = matched.addingPercentEncoding(withAllowedCharacters: allowed) ?? matched
        return encoded.lowercased()
    }
    
    /// Assembles required signature headers for EduVulcan request
    public func getSignatureHeaders(
        keyId: String,
        privateKey: SecKey,
        body: String?,
        fullUrlString: String,
        date: Date = Date()
    ) throws -> [String: String] {
        let canonicalUrl = formatCanonicalUrl(from: fullUrlString)
        let digestValue = computeDigest(body)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        let formattedDate = formatter.string(from: date)
        
        var signedHeaders: [(key: String, value: String)] = []
        signedHeaders.append(("vCanonicalUrl", canonicalUrl))
        if let digestValue = digestValue {
            signedHeaders.append(("Digest", digestValue))
        }
        signedHeaders.append(("vDate", formattedDate))
        
        let contentToSign = signedHeaders.map { $0.value }.joined()
        guard let dataToSign = contentToSign.data(using: .utf8) else {
            throw NSError(domain: "RequestSigner", code: -3, userInfo: [NSLocalizedDescriptionKey: "Encoding error"])
        }
        
        var error: Unmanaged<CFError>?
        guard let signatureData = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            dataToSign as CFData,
            &error
        ) as Data? else {
            throw error?.takeRetainedValue() ?? NSError(domain: "RequestSigner", code: -4, userInfo: [NSLocalizedDescriptionKey: "RSA signature failed"])
        }
        
        let signatureBase64 = signatureData.base64EncodedString()
        let headerKeys = signedHeaders.map { $0.key }.joined(separator: " ")
        let signatureHeaderValue = "keyId=\"\(keyId)\",headers=\"\(headerKeys)\",algorithm=\"sha256\",signature=Base64(sha256withrsa(\(signatureBase64)))"
        
        var headers: [String: String] = [
            "vCanonicalUrl": canonicalUrl,
            "vDate": formattedDate,
            "Signature": signatureHeaderValue
        ]
        
        if let digestValue = digestValue {
            headers["Digest"] = "SHA-256=\(digestValue)"
        }
        
        return headers
    }
}
