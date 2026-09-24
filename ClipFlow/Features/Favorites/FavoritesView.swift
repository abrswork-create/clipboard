import SwiftUI

// MARK: - FavoritesView
// Shows items marked as favorites. Implemented in TASK 14.

struct FavoritesView: View {
    @ObservedObject var store: ClipboardStore
    @State private var selectedItemID: UUID? = nil
    @State private var interfaceStyle: InterfaceStyle = SettingsRepository.shared.load().interfaceStyle
    
    // Multi-Selection State
    @State private var isSelectionMode: Bool = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var isSelectHovered = false
    @State private var anchorItemID: UUID? = nil
    @State private var baseSelectedIDs: Set<UUID> = []

    private var favorites: [ClipboardItem] {
        store.items.filter { $0.isFavorite }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .padding(.horizontal, 12)
                .opacity(0.5)

            if favorites.isEmpty {
                emptyState
            } else {
                itemList(favorites)
            }
        }
        .overlay(alignment: .bottom) {
            if isSelectionMode || !selectedItemIDs.isEmpty {
                batchActionBar(favorites)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelectionMode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedItemIDs.count)
        .onExitCommand {
            if isSelectionMode || !selectedItemIDs.isEmpty {
                selectedItemIDs.removeAll()
                baseSelectedIDs.removeAll()
                anchorItemID = nil
                isSelectionMode = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowInterfaceStyleChanged"))) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                interfaceStyle = SettingsRepository.shared.load().interfaceStyle
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowWindowWillOpen"))) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                interfaceStyle = SettingsRepository.shared.load().interfaceStyle
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Favorites")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CFColor.primaryText)

                if !favorites.isEmpty {
                    Text("\(favorites.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CFColor.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                        )
                }
            }

            Spacer()

            if !favorites.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isSelectionMode {
                            selectedItemIDs.removeAll()
                            baseSelectedIDs.removeAll()
                            anchorItemID = nil
                            isSelectionMode = false
                        } else {
                            isSelectionMode = true
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isSelectionMode ? Color.accentColor : CFColor.secondaryText)
                        Text(isSelectionMode ? "Done" : "Select")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CFColor.primaryText)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelectionMode ? CFColor.cardHover : (isSelectHovered ? CFColor.cardHover : CFColor.cardBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(isSelectionMode ? Color.accentColor.opacity(0.35) : (isSelectHovered ? Color.primary.opacity(0.18) : Color.primary.opacity(0.08)), lineWidth: 1)
                    )
                    .cfShadow(CFShadow.card)
                }
                .buttonStyle(.plain)
                .onHover { isSelectHovered = $0 }
                .pointingHandCursor()
                .help(isSelectionMode ? "Exit selection mode" : "Select multiple items to paste or copy")
                .fixedSize()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private func itemList(_ favorites: [ClipboardItem]) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8) {
                ForEach(favorites) { item in
                    cardRow(item)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .padding(.bottom, (isSelectionMode || !selectedItemIDs.isEmpty) ? 58 : 0)
            .animation(.easeInOut(duration: 0.2), value: favorites)
        }
    }

    private func cardRow(_ item: ClipboardItem) -> some View {
        ClipboardItemRow(
            item: item,
            isSelected: selectedItemID == item.id,
            onSelect: {
                if isSelectionMode {
                    toggleMultiSelect(item.id)
                } else {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedItemID = selectedItemID == item.id ? nil : item.id
                        anchorItemID = item.id
                        baseSelectedIDs = selectedItemID != nil ? [item.id] : []
                    }
                }
            },
            onDelete: { store.delete(item.id) },
            onPin: {
                if !item.isPinned && !ProManager.shared.hasFullAccess {
                    ProManager.shared.triggerPaywall(reason: "Your 7-day free trial has expired. Upgrade to Clipmory Pro to pin cards.")
                    return
                }
                store.togglePin(item.id)
            },
            onFavorite: { store.toggleFavorite(item.id) },
            onPaste: {
                guard ProManager.shared.hasFullAccess else {
                    ProManager.shared.triggerPaywall(reason: "Your 7-day free trial has expired. Upgrade to Clipmory Pro to paste items.")
                    return
                }
                PasteService.paste(item)
            },
            style: interfaceStyle,
            isSelectionMode: isSelectionMode,
            isInMultiSelect: selectedItemIDs.contains(item.id),
            onToggleMultiSelect: { toggleMultiSelect(item.id) },
            onShiftSelect: { selectRange(to: item.id) },
            onCommandSelect: { toggleMultiSelect(item.id) }
        )
    }

    private func toggleMultiSelect(_ id: UUID) {
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

    private func selectRange(to targetID: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) {
            let anchorID: UUID
            if let existing = anchorItemID {
                anchorID = existing
            } else {
                anchorID = targetID
                anchorItemID = targetID
                baseSelectedIDs = selectedItemIDs
            }
            
            guard let anchorIndex = favorites.firstIndex(where: { $0.id == anchorID }),
                  let targetIndex = favorites.firstIndex(where: { $0.id == targetID }) else {
                toggleMultiSelect(targetID)
                return
            }
            
            let startIndex = min(anchorIndex, targetIndex)
            let endIndex = max(anchorIndex, targetIndex)
            let rangeIDs = Set(favorites[startIndex...endIndex].map { $0.id })
            
            selectedItemIDs = baseSelectedIDs.union(rangeIDs)
            isSelectionMode = true
        }
    }

    // MARK: - Batch Action Bar (Icon-only, compact & docked)
    private func batchActionBar(_ favorites: [ClipboardItem]) -> some View {
        HStack(spacing: 8) {
            // Selected Count Badge
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text("\(selectedItemIDs.count)")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(CFColor.primaryText)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.06))
            )
            .help("\(selectedItemIDs.count) items selected")

            Spacer()

            // Select All / Deselect (Icon button)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if selectedItemIDs.count == favorites.count {
                        selectedItemIDs.removeAll()
                        baseSelectedIDs.removeAll()
                        anchorItemID = nil
                    } else {
                        selectedItemIDs = Set(favorites.map { $0.id })
                        baseSelectedIDs = selectedItemIDs
                        anchorItemID = favorites.first?.id
                    }
                }
            } label: {
                Image(systemName: selectedItemIDs.count == favorites.count ? "checklist.checked" : "checklist")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(selectedItemIDs.count == favorites.count ? Color.accentColor : CFColor.primaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help(selectedItemIDs.count == favorites.count ? "Deselect All" : "Select All")

            // Copy button (Icon button)
            Button {
                let items = favorites.filter { selectedItemIDs.contains($0.id) }
                guard !items.isEmpty else { return }
                PasteService.copy(items: items)
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedItemIDs.removeAll()
                    baseSelectedIDs.removeAll()
                    anchorItemID = nil
                    isSelectionMode = false
                }
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CFColor.primaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(selectedItemIDs.isEmpty)
            .opacity(selectedItemIDs.isEmpty ? 0.4 : 1.0)
            .help("Copy selected items to clipboard")

            // Delete button (Icon button)
            Button {
                let idsToDelete = selectedItemIDs
                withAnimation(.easeInOut(duration: 0.2)) {
                    for id in idsToDelete {
                        store.delete(id)
                    }
                    selectedItemIDs.removeAll()
                    baseSelectedIDs.removeAll()
                    anchorItemID = nil
                    isSelectionMode = false
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CFColor.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(selectedItemIDs.isEmpty)
            .opacity(selectedItemIDs.isEmpty ? 0.4 : 1.0)
            .help("Delete selected items")

            // Paste All Button (Primary Icon button with count)
            Button {
                let items = favorites.filter { selectedItemIDs.contains($0.id) }
                guard !items.isEmpty else { return }
                PasteService.paste(items: items)
                selectedItemIDs.removeAll()
                baseSelectedIDs.removeAll()
                anchorItemID = nil
                isSelectionMode = false
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.doc.on.clipboard")
                        .font(.system(size: 11, weight: .semibold))
                    if !selectedItemIDs.isEmpty {
                        Text("\(selectedItemIDs.count)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selectedItemIDs.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                )
                .cfShadow(CFShadow.card)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(selectedItemIDs.isEmpty)
            .opacity(selectedItemIDs.isEmpty ? 0.4 : 1.0)
            .keyboardShortcut(.defaultAction)
            .help("Paste all selected items (Return)")

            // Done / Exit Selection Button (Icon button)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedItemIDs.removeAll()
                    baseSelectedIDs.removeAll()
                    anchorItemID = nil
                    isSelectionMode = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CFColor.secondaryText)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help("Done / Exit Selection Mode (Esc)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 36))
                .foregroundStyle(CFColor.tabInactive)

            Text("No favorites yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)

            Text("Star items in your clipboard to\nkeep them here permanently.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
