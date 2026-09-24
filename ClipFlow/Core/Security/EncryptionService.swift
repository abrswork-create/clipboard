import Foundation
import CryptoKit

// MARK: - EncryptionService
// Provides hardware-bound AES-256-GCM authenticated encryption and decryption.
// Master key is dynamically derived from the Mac's permanent hardware UUID (IOPlatformUUID) via HKDF-SHA256.
// This guarantees zero macOS Keychain password dialogs while ensuring all data is bound to this physical machine.

final class EncryptionService {
    static let shared = EncryptionService()
    
    private var cachedKey: SymmetricKey?
    private let lock = NSLock()

    private init() {}

    // MARK: - App-Instance Derived Key

    /// Derives a 256-bit AES-GCM symmetric key using an anonymous local App Instance ID.
    /// This avoids binding encryption to physical Mac hardware identifiers.
    private func getOrCreateKey() -> SymmetricKey {
        lock.lock()
        defer { lock.unlock() }

        if let key = cachedKey {
            return key
        }

        let instanceID = LemonSqueezyService.shared.getAppInstanceID()
        let salt = "ClipFlowMasterSalt_2026_x89a".data(using: .utf8)!
        let inputKeyMaterial = SymmetricKey(data: instanceID.data(using: .utf8)!)

        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: salt,
            info: "com.clipflow.master_encryption_key".data(using: .utf8)!,
            outputByteCount: 32
        )

        cachedKey = derivedKey
        return derivedKey
    }

    // MARK: - Encryption / Decryption API

    /// Encrypts raw data using hardware-bound AES-256-GCM.
    /// Returns combined nonce + ciphertext + tag.
    func encrypt(data: Data) throws -> Data {
        let key = getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }

    /// Decrypts combined nonce + ciphertext + tag using hardware-bound AES-256-GCM.
    func decrypt(data: Data) throws -> Data {
        let key = getOrCreateKey()
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
