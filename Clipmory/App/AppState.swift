import Foundation
import Combine

// MARK: - AppState
// Observable application state shared across the SwiftUI view hierarchy.
// Kept intentionally minimal — only truly global UI state lives here.
// Feature-specific state lives in feature-level ViewModels.

@MainActor
final class AppState: ObservableObject {

    // MARK: Published Properties

    /// Whether the main clipboard history window is visible.
    @Published var isHistoryVisible: Bool = false

    /// Whether the Quick Clipboard overlay is visible.
    @Published var isQuickClipboardVisible: Bool = false

    /// Whether Private Mode is active (monitoring continues but items are not saved).
    @Published var isPrivateModeEnabled: Bool = false

    // MARK: Init

    init() {}
}
