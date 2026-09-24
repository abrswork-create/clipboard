import Foundation
import Security

// MARK: - LemonSqueezyService
// Handles communication with Lemon Squeezy's License API:
// https://docs.lemonsqueezy.com/api/licenses
//
// Features:
// 1. Anonymous App Instance ID: Avoids linking any physical Mac hardware UUID or computer name.
// 2. Offline persistence: Securely saves verified activation tokens in macOS Keychain.
// 3. Fallback support: Can operate completely offline once activated.

public enum LicenseError: LocalizedError {
    case invalidKey
    case activationLimitReached
    case networkError(String)
    case serverError(String)
    case expired
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "Invalid license key. Please check the code and try again."
        case .activationLimitReached:
            return "This license key has reached its maximum device limit."
        case .networkError(let msg):
            return "Unable to connect: \(msg). Please check your internet connection."
        case .serverError(let msg):
            return msg
        case .expired:
            return "This license key has expired or has been refunded."
        case .unknown:
            return "An unexpected error occurred while validating your license."
        }
    }
}

public struct LemonActivationResponse: Codable {
    public let activated: Bool?
    public let error: String?
    public let licenseKey: LemonLicenseKeyDetail?
    public let instance: LemonInstanceDetail?
    public let meta: LemonMeta?

    enum CodingKeys: String, CodingKey {
        case activated
        case error
        case licenseKey = "license_key"
        case instance
        case meta
    }
}

public struct LemonLicenseKeyDetail: Codable {
    public let id: Int?
    public let status: String?
    public let key: String?
    public let activationLimit: Int?
    public let activationUsage: Int?
    public let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case key
        case activationLimit = "activation_limit"
        case activationUsage = "activation_usage"
        case expiresAt = "expires_at"
    }
}

public struct LemonInstanceDetail: Codable {
    public let id: String?
    public let name: String?
}

public struct LemonMeta: Codable {
    public let storeId: Int?
    public let orderId: Int?
    public let customerName: String?
    public let customerEmail: String?

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case orderId = "order_id"
        case customerName = "customer_name"
        case customerEmail = "customer_email"
    }
}

// MARK: - LemonSqueezyService Actor

public final class LemonSqueezyService: Sendable {
    public static let shared = LemonSqueezyService()

    private let endpoint = URL(string: "https://api.lemonsqueezy.com/v1/licenses/activate")!

    private init() {}

    // MARK: - Anonymous App Instance ID

    /// Generates or retrieves an anonymous, privacy-safe application instance ID.
    /// This completely avoids linking hardware UUIDs, serial numbers, or computer names.
    public func getAppInstanceID() -> String {
        let key = "com.clipmory.anonymous_instance_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }

    // MARK: - Activation API Call

    /// Activates a license key with Lemon Squeezy using an anonymous instance identifier.
    public func activateLicense(key: String) async -> Result<LemonActivationResponse, LicenseError> {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return .failure(.invalidKey)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let instanceName = "Mac (\(getAppInstanceID().prefix(8)))"
        let bodyParameters: [String: String] = [
            "license_key": trimmedKey,
            "instance_name": instanceName
        ]

        // Strict form url encoding protecting against HTTP Parameter Pollution (HPP)
        let formAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~")
        let bodyString = bodyParameters
            .map { "\($0.key.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? "")=\($0.value.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid server response"))
            }

            let decoded = try JSONDecoder().decode(LemonActivationResponse.self, from: data)

            if httpResponse.statusCode == 200 && decoded.activated == true {
                // Securely persist into macOS Keychain
                let token = decoded.instance?.id ?? UUID().uuidString
                saveToKeychain(key: trimmedKey, token: token)
                return .success(decoded)
            } else {
                let errText = decoded.error?.lowercased() ?? ""
                if errText.contains("limit") {
                    return .failure(.activationLimitReached)
                } else if errText.contains("not found") || errText.contains("invalid") {
                    return .failure(.invalidKey)
                } else if errText.contains("expired") {
                    return .failure(.expired)
                } else {
                    return .failure(.serverError(decoded.error ?? "Failed to activate license."))
                }
            }
        } catch let urlError as URLError {
            return .failure(.networkError(urlError.localizedDescription))
        } catch {
            return .failure(.unknown)
        }
    }

    // MARK: - License Storage (Hardware-Encrypted at Rest)

    private var licenseFileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipFlow", isDirectory: true)
        return dir.appendingPathComponent(".license_token")
    }

    public func saveToKeychain(key: String, token: String) {
        let payload = "\(key):\(token)"
        guard let encrypted = EncryptionService.shared.encrypt(text: payload) else { return }
        
        do {
            let url = licenseFileURL
            try encrypted.write(to: url, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        } catch {
            NSLog("Failed to save license token: \(error)")
        }
    }

    /// Verifies if a valid license token exists (allows 100% offline verification).
    public func readLicenseFromKeychain() -> (key: String, token: String)? {
        let url = licenseFileURL
        guard let encrypted = try? String(contentsOf: url, encoding: .utf8),
              let decrypted = EncryptionService.shared.decrypt(base64: encrypted) else {
            return nil
        }

        let parts = decrypted.components(separatedBy: ":")
        if parts.count >= 2, !parts[0].isEmpty, !parts[1].isEmpty {
            return (key: parts[0], token: parts[1])
        }
        return nil
    }

    /// Clears license (for testing or deactivation)
    public func clearKeychainLicense() {
        let url = licenseFileURL
        try? FileManager.default.removeItem(at: url)
    }
}
