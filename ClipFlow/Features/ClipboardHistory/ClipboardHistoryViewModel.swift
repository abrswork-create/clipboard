import AppKit
import Combine
import Foundation
import SwiftUI
import StoreKit

// MARK: - ClipboardHistoryViewModel
// Bridges ClipboardStore (data layer) to ClipboardHistoryView (UI layer).
// Owns only UI-specific state: selectedItemID.
// All data mutations delegate to ClipboardStore.

@MainActor
final class ClipboardHistoryViewModel: ObservableObject {

    // MARK: Published

    /// The active search query from the UI.
    @Published var searchQuery: String = ""
    @Published var selectedItemID: UUID? = nil
    @Published var showEngagementPrompt: Bool = false

    // MARK: Private
    private let store: ClipboardStore

    // MARK: Init
    init(store: ClipboardStore) {
        self.store = store
    }

    // MARK: - Selection

    func selectItem(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedItemID = selectedItemID == id ? nil : id
        }
        
        if let item = store.items.first(where: { $0.id == id }) {
            PasteService.paste(item)
            checkEngagement()
        }
    }

    // MARK: - Data Actions (delegate to store)

    func deleteItem(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedItemID == id { selectedItemID = nil }
            store.delete(id)
        }
    }

    func togglePin(_ id: UUID) {
        store.togglePin(id)
    }

    func toggleFavorite(_ id: UUID) {
        store.toggleFavorite(id)
    }

    func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedItemID = nil
            store.clearAll()
        }
    }

    /// Pastes the item (text or image) to the previous application.
    func paste(_ id: UUID) {
        guard let item = store.items.first(where: { $0.id == id }) else { return }
        PasteService.paste(item)
        checkEngagement()
    }
    
    private func checkEngagement() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "hasSeenEngagementPrompt") else { return }
        
        let count = defaults.integer(forKey: "successfulPasteCount") + 1
        defaults.set(count, forKey: "successfulPasteCount")
        
        if count >= 10 {
            defaults.set(true, forKey: "hasSeenEngagementPrompt")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let isAppStoreInstall: Bool = {
                    guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return false }
                    return FileManager.default.fileExists(atPath: receiptUrl.path)
                }()
                
                if isAppStoreInstall {
                    SKStoreReviewController.requestReview()
                } else {
                    self.showEngagementPrompt = true
                }
            }
        }
    }
}
