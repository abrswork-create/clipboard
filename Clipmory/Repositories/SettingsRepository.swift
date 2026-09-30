import Foundation

// MARK: - SettingsRepository
// Persists and loads AppSettings using UserDefaults.

final class SettingsRepository {
    
    static let shared = SettingsRepository()
    private let defaults = UserDefaults.standard
    private let key = "Clipmory.AppSettings"
    private let legacyKey = "ClipFlow.AppSettings"
    
    private init() {}
    
    func load() -> AppSettings {
        let data = defaults.data(forKey: key) ?? defaults.data(forKey: legacyKey)
        guard let data = data,
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings() // Return defaults if none saved
        }
        return settings
    }
    
    func save(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
