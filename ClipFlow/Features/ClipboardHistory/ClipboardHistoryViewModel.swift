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

    // MARK: - Multi-Selection
    @Published var isSelectionMode: Bool = false
    @Published var selectedItemIDs: Set<UUID> = []
    @Published var anchorItemID: UUID? = nil
    private var baseSelectedIDs: Set<UUID> = []

    // MARK: Private
    private let store: ClipboardStore

    // MARK: Init
    init(store: ClipboardStore) {
        self.store = store
    }

    // MARK: - Selection

    func selectItem(_ id: UUID) {
        // Enforce 7-day free trial or Pro access before pasting
        guard ProManager.shared.hasFullAccess else {
            ProManager.shared.triggerPaywall(reason: "Your 7-day free trial has expired. Upgrade to Clipmory Pro to paste items and continue using Clipmory.")
            return
        }

        withAnimation(.easeInOut(duration: 0.15)) {
            selectedItemID = selectedItemID == id ? nil : id
            anchorItemID = id
            baseSelectedIDs = selectedItemID != nil ? [id] : []
        }
        
        if let item = store.items.first(where: { $0.id == id }) {
            PasteService.paste(item)
            checkEngagement()
        }
    }

    func toggleSelection(for id: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedItemIDs.contains(id) {
                selectedItemIDs.remove(id)
            } else {
                selectedItemIDs.insert(id)
            }
            anchorItemID = id
            baseSelectedIDs = selectedItemIDs
            if !selectedItemIDs.isEmpty {
                isSelectionMode = true
            }
        }
    }

    func selectRange(to targetID: UUID, in items: [ClipboardItem]) {
        withAnimation(.easeInOut(duration: 0.15)) {
            let anchorID: UUID
            if let existing = anchorItemID {
                anchorID = existing
            } else {
                anchorID = targetID
                anchorItemID = targetID
                baseSelectedIDs = selectedItemIDs
            }
            
            guard let anchorIndex = items.firstIndex(where: { $0.id == anchorID }),
                  let targetIndex = items.firstIndex(where: { $0.id == targetID }) else {
                toggleSelection(for: targetID)
                return
            }
            
            let startIndex = min(anchorIndex, targetIndex)
            let endIndex = max(anchorIndex, targetIndex)
            let rangeIDs = Set(items[startIndex...endIndex].map { $0.id })
            
            selectedItemIDs = baseSelectedIDs.union(rangeIDs)
            isSelectionMode = true
        }
    }

    func selectAll(items: [ClipboardItem]) {
        withAnimation(.easeInOut(duration: 0.15)) {
            let ids = items.map { $0.id }
            if selectedItemIDs.count == ids.count {
                selectedItemIDs.removeAll()
                baseSelectedIDs.removeAll()
                anchorItemID = nil
            } else {
                selectedItemIDs = Set(ids)
                baseSelectedIDs = selectedItemIDs
                anchorItemID = items.first?.id
            }
        }
    }

    func clearSelection() {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedItemIDs.removeAll()
            baseSelectedIDs.removeAll()
            anchorItemID = nil
            isSelectionMode = false
        }
    }

    func pasteSelected(orderedItems: [ClipboardItem]) {
        guard ProManager.shared.hasFullAccess else {
            ProManager.shared.triggerPaywall(reason: "Your 7-day free trial has expired. Upgrade to Clipmory Pro to paste items and continue using Clipmory.")
            return
        }

        let itemsToPaste = orderedItems.filter { selectedItemIDs.contains($0.id) }
        guard !itemsToPaste.isEmpty else { return }

        PasteService.paste(items: itemsToPaste)
        checkEngagement()
        clearSelection()
    }

    func copySelected(orderedItems: [ClipboardItem]) {
        let itemsToCopy = orderedItems.filter { selectedItemIDs.contains($0.id) }
        guard !itemsToCopy.isEmpty else { return }

        PasteService.copy(items: itemsToCopy)
        clearSelection()
    }

    func deleteSelected() {
        let idsToDelete = selectedItemIDs
        withAnimation(.easeInOut(duration: 0.2)) {
            for id in idsToDelete {
                if selectedItemID == id { selectedItemID = nil }
                store.delete(id)
            }
            selectedItemIDs.removeAll()
            baseSelectedIDs.removeAll()
            anchorItemID = nil
            isSelectionMode = false
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
        guard let item = store.items.first(where: { $0.id == id }) else { return }
        
        // If currently pinned, allow unpinning freely
        if item.isPinned {
            store.togglePin(id)
            return
        }
        
        // Pinning requires full access (Pro or active 7-day trial)
        guard ProManager.shared.hasFullAccess else {
            ProManager.shared.triggerPaywall(reason: "Your 7-day free trial has expired. Upgrade to Clipmory Pro to pin items.")
            return
        }
        
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
