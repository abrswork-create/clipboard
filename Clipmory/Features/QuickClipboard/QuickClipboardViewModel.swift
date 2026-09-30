import Foundation
import Combine

// MARK: - QuickClipboardViewModel
// ViewModel for QuickClipboardView. Implemented in TASK 15.

@MainActor
final class QuickClipboardViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filteredItems: [ClipboardItem] = []
}
