import Foundation
import Combine

// MARK: - SearchViewModel
// Drives the Search feature. Implemented in TASK 12.

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [ClipboardItem] = []
}
