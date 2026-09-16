import Foundation
import CryptoKit
import Security

// MARK: - EncryptionService
// Provides AES-256-GCM authenticated encryption and decryption using Apple CryptoKit.
// Keys are generated and securely stored in the macOS Keychain with device-only bound security.

final class EncryptionService {
    static let shared = EncryptionService()
    
    private let serviceName = "com.clipflow.ClipFlow.encryption"
    private let accountName = "master_key"
    private var cachedKey: SymmetricKey?
    private let lock = NSLock()

    private init() {}

    // MARK: - Key Management

    /// Retrieves or generates a 256-bit AES-GCM symmetric key stored securely in the macOS Keychain.
    private func getOrCreateKey() throws -> SymmetricKey {
        lock.lock()
        defer { lock.unlock() }

        if let key = cachedKey {
            return key
        }

        // 1. Try to load from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let keyData = item as? Data {
            let key = SymmetricKey(data: keyData)
            cachedKey = key
            return key
        }

        // 2. If not found, generate a new 256-bit key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus != errSecSuccess && addStatus != errSecDuplicateItem {
            NSLog("Warning: Failed to save encryption key to Keychain (status: \(addStatus)). In-memory fallback will be used.")
        }

        cachedKey = newKey
        return newKey
    }

    // MARK: - Encryption / Decryption API

    /// Encrypts raw data using AES-256-GCM.
    /// Returns combined nonce + ciphertext + tag.
    func encrypt(data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }

    /// Decrypts combined nonce + ciphertext + tag using AES-256-GCM.
    func decrypt(data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Convenience: Encrypts UTF-8 string into a Base64-encoded encrypted string.
    func encrypt(text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        do {
            let encryptedData = try encrypt(data: data)
            return encryptedData.base64EncodedString()
        } catch {
            NSLog("Encryption error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Convenience: Decrypts Base64-encoded encrypted string back into UTF-8 string.
    func decrypt(base64: String) -> String? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        do {
            let decryptedData = try decrypt(data: data)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            NSLog("Decryption error: \(error.localizedDescription)")
            return nil
        }
    }

    enum CryptoError: LocalizedError {
        case encryptionFailed
        case decryptionFailed
        
        var errorDescription: String? {
            switch self {
            case .encryptionFailed:
                return "Failed to seal data with AES-GCM"
            case .decryptionFailed:
                return "Failed to open AES-GCM sealed box"
            }
        }
    }
}
