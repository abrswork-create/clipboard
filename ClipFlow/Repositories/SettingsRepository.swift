import Foundation

// MARK: - SettingsRepository
// Persists and loads AppSettings using UserDefaults.

final class SettingsRepository {
    
    static let shared = SettingsRepository()
    private let defaults = UserDefaults.standard
    private let key = "ClipFlow.AppSettings"
    
    private init() {}
    
    func load() -> AppSettings {
        guard let data = defaults.data(forKey: key),
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
