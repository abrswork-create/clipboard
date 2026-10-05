import Foundation
import Security

// MARK: - CreemService
// Handles communication with Creem.io's License Key API:
// https://docs.creem.io/features/addons/licenses
//
// Features:
// 1. Anonymous App Instance ID: Avoids linking any physical Mac hardware UUID or computer name.
// 2. Offline persistence: Securely saves verified activation tokens in macOS Keychain / local encrypted storage.
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
            return "This license key has expired or has been revoked."
        case .unknown:
            return "An unexpected error occurred while validating your license."
        }
    }
}

public struct CreemLicenseResponse: Codable {
    public let id: String?
    public let mode: String?
    public let status: String?
    public let key: String?
    public let activation: Int?
    public let activationLimit: Int?
    public let expiresAt: String?
    public let instance: CreemInstanceEntity?

    enum CodingKeys: String, CodingKey {
        case id, mode, status, key, activation
        case activationLimit = "activation_limit"
        case expiresAt = "expires_at"
        case instance
    }

    public init(id: String? = nil, mode: String? = nil, status: String? = "active", key: String? = nil, activation: Int? = 1, activationLimit: Int? = nil, expiresAt: String? = nil, instance: CreemInstanceEntity? = nil) {
        self.id = id
        self.mode = mode
        self.status = status
        self.key = key
        self.activation = activation
        self.activationLimit = activationLimit
        self.expiresAt = expiresAt
        self.instance = instance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try? container.decodeIfPresent(String.self, forKey: .id)
        self.mode = try? container.decodeIfPresent(String.self, forKey: .mode)
        self.status = try? container.decodeIfPresent(String.self, forKey: .status)
        self.key = try? container.decodeIfPresent(String.self, forKey: .key)
        self.activation = try? container.decodeIfPresent(Int.self, forKey: .activation)
        self.activationLimit = try? container.decodeIfPresent(Int.self, forKey: .activationLimit)
        self.expiresAt = try? container.decodeIfPresent(String.self, forKey: .expiresAt)

        // Handle both dictionary {"id": "..."} and array [{"id": "..."}] representations safely
        if let single = try? container.decodeIfPresent(CreemInstanceEntity.self, forKey: .instance) {
            self.instance = single
        } else if let array = try? container.decodeIfPresent([CreemInstanceEntity].self, forKey: .instance) {
            self.instance = array.first
        } else {
            self.instance = nil
        }
    }
}

public struct CreemInstanceEntity: Codable {
    public let id: String?
    public let name: String?
    public let status: String?
    public let mode: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, mode
    }
}

public struct CreemErrorResponse: Codable {
    public let status: Int?
    public let error: String?
    public let message: [String]?
}

// MARK: - CreemService Actor

public final class CreemService: Sendable {
    public static let shared = CreemService()

    /// Creem API Key for license activation/validation.
    public var apiKey: String {
        return "creem_3FfXK8rrR5Rr1aOVyvzjK1"
    }

    /// Automatically select sandbox or production endpoint based on API key prefix.
    private var endpoint: URL {
        if apiKey.contains("_test_") {
            return URL(string: "https://test-api.creem.io/v1/licenses/activate")!
        } else {
            return URL(string: "https://api.creem.io/v1/licenses/activate")!
        }
    }

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

    /// Activates a license key with Creem using an anonymous instance identifier.
    public func activateLicense(key: String) async -> Result<CreemLicenseResponse, LicenseError> {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return .failure(.invalidKey)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let instanceName = "Mac (\(getAppInstanceID().prefix(8)))"
        let payload: [String: String] = [
            "key": trimmedKey,
            "instance_name": instanceName
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            return .failure(.unknown)
        }
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid server response"))
            }

            if httpResponse.statusCode == 200 {
                let decoded = try? JSONDecoder().decode(CreemLicenseResponse.self, from: data)
                let status = decoded?.status?.lowercased() ?? "active"

                if status == "active" {
                    let token = decoded?.instance?.id ?? decoded?.id ?? UUID().uuidString
                    saveToKeychain(key: trimmedKey, token: token)
                    let responseObj = decoded ?? CreemLicenseResponse(key: trimmedKey)
                    return .success(responseObj)
                } else if status == "expired" {
                    return .failure(.expired)
                } else {
                    return .failure(.serverError("License status: \(status)"))
                }
            } else {
                let errorObj = try? JSONDecoder().decode(CreemErrorResponse.self, from: data)
                let errorMsg = errorObj?.message?.first ?? errorObj?.error ?? ""
                let lower = errorMsg.lowercased()

                if httpResponse.statusCode == 403 || lower.contains("limit") {
                    return .failure(.activationLimitReached)
                } else if httpResponse.statusCode == 404 || lower.contains("not found") || lower.contains("invalid") {
                    return .failure(.invalidKey)
                } else if httpResponse.statusCode == 410 || lower.contains("expired") || lower.contains("revoked") {
                    return .failure(.expired)
                } else {
                    return .failure(.serverError(errorMsg.isEmpty ? "Failed to activate license (Code \(httpResponse.statusCode))." : errorMsg))
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
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let legacyDir = base.appendingPathComponent("ClipFlow", isDirectory: true)
        let dir = base.appendingPathComponent("Clipmory", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let legacyToken = legacyDir.appendingPathComponent(".license_token")
        let targetToken = dir.appendingPathComponent(".license_token")
        if !FileManager.default.fileExists(atPath: targetToken.path) && FileManager.default.fileExists(atPath: legacyToken.path) {
            try? FileManager.default.copyItem(at: legacyToken, to: targetToken)
        }
        return targetToken
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
