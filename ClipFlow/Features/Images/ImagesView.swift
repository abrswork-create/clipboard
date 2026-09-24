import SwiftUI
import AppKit

// MARK: - ImagesView
// Dedicated gallery view displaying only copied images and screenshots from clipboard history.

struct ImagesView: View {
    @ObservedObject var store: ClipboardStore
    @State private var selectedItemID: UUID? = nil
    @State private var hoveredItemID: UUID? = nil
    @State private var searchQuery: String = ""
    @State private var copiedToastID: UUID? = nil
    
    // Multi-Selection State
    @State private var isSelectionMode: Bool = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var isSelectHovered = false
    @State private var anchorItemID: UUID? = nil
    @State private var baseSelectedIDs: Set<UUID> = []
    
    private var imageItems: [ClipboardItem] {
        store.items.filter { $0.type == .image && $0.imagePath != nil && !$0.isGif }
    }
    
    private var filteredItems: [ClipboardItem] {
        if searchQuery.isEmpty {
            return imageItems
        } else {
            return imageItems.filter { item in
                item.sourceAppName?.localizedCaseInsensitiveContains(searchQuery) == true ||
                item.text?.localizedCaseInsensitiveContains(searchQuery) == true
            }
        }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .padding(.horizontal, 12)
                .opacity(0.5)
            
            if imageItems.isEmpty {
                emptyState
            } else if filteredItems.isEmpty {
                noResultsState
            } else {
                imageGrid
            }
        }
        .overlay(alignment: .bottom) {
            if isSelectionMode || !selectedItemIDs.isEmpty {
                batchActionBar
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
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Text("Images")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CFColor.primaryText)
                    
                    if !imageItems.isEmpty {
                        Text("\(imageItems.count)")
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

                if !imageItems.isEmpty {
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
                    .help(isSelectionMode ? "Exit selection mode" : "Select multiple images to paste or copy")
                    .fixedSize()
                }
            }
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CFColor.secondaryText)
                
                TextField("Search image source...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(CFColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
    
    // MARK: - Grid
    
    private var imageGrid: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredItems) { item in
                    imageCard(item)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .padding(.bottom, (isSelectionMode || !selectedItemIDs.isEmpty) ? 58 : 0)
        }
    }
    
    private func imageCard(_ item: ClipboardItem) -> some View {
        let isHovered = hoveredItemID == item.id
        let isSelected = selectedItemID == item.id
        let isInMultiSelect = selectedItemIDs.contains(item.id)
        
        return Button {
            let modifiers = NSEvent.modifierFlags
            if modifiers.contains(.shift) {
                selectRange(to: item.id)
            } else if modifiers.contains(.command) || isSelectionMode {
                toggleMultiSelect(item.id)
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedItemID = item.id
                    anchorItemID = item.id
                    baseSelectedIDs = [item.id]
                }
                PasteService.paste(item)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    ZStack(alignment: .topTrailing) {
                        // Image container
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: 110)
                            
                            if let gifUrl = item.gifURLString {
                                GifURLThumbnailView(urlString: gifUrl, maxHeight: 100)
                            } else if let path = item.imagePath {
                                if path.lowercased().hasSuffix(".gif"), let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                                    GifCardThumbnailView(data: data, maxHeight: 100)
                                } else if let nsImage = FileStorage.loadImage(at: path) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                        .cornerRadius(4)
                                }
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(CFColor.tabInactive)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Top badge / actions on hover
                        if isHovered && !isSelectionMode && !isInMultiSelect {
                            HStack(spacing: 4) {
                                Button {
                                    store.toggleFavorite(item.id)
                                } label: {
                                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundStyle(item.isFavorite ? Color.yellow : .white)
                                        .frame(width: 22, height: 22)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    withAnimation {
                                        store.delete(item.id)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white)
                                        .frame(width: 22, height: 22)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(6)
                            .transition(.opacity)
                        }
                    }

                    // Selection Checkbox Badge on Top-Left
                    if isSelectionMode || isInMultiSelect {
                        Image(systemName: isInMultiSelect ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isInMultiSelect ? Color(nsColor: .controlAccentColor) : Color.white.opacity(0.85))
                            .padding(6)
                            .shadow(color: Color.black.opacity(0.4), radius: 2)
                    }
                }
                
                // Card footer with app source & timestamp
                HStack {
                    if let source = item.sourceAppName {
                        Text(source.uppercased())
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(CFColor.secondaryText)
                            .lineLimit(1)
                    } else {
                        Text("IMAGE")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(CFColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text(item.createdAt, style: .time)
                        .font(.system(size: 9))
                        .foregroundStyle(CFColor.secondaryText)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .fill(
                        (isInMultiSelect || isSelected)
                            ? CFColor.selectedBackground
                            : (isHovered ? CFColor.cardHover : CFColor.cardBackground)
                    )
                    .overlay(
                        (isInMultiSelect || isSelected)
                            ? RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                                .fill(Color.accentColor.opacity(0.06))
                            : nil
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .strokeBorder(
                        (isInMultiSelect || isSelected)
                            ? CFColor.selectedBorder
                            : (isHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.06)),
                        lineWidth: (isInMultiSelect || isSelected) ? 1.5 : 1
                    )
            )
            .cfShadow(isInMultiSelect ? CFShadow.cardSelected : (isHovered ? CFShadow.cardSelected : CFShadow.card))
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            hoveredItemID = hovered ? item.id : nil
        }
    }
    
    // MARK: - States
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 38))
                .foregroundStyle(CFColor.tabInactive)
            
            Text("No copied images yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)
            
            Text("Screenshots and images copied from\nwebpages or apps will appear here.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(CFColor.tabInactive)
            
            Text("No matching images")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)
            
            Text("Try another search term.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
            
            guard let anchorIndex = filteredItems.firstIndex(where: { $0.id == anchorID }),
                  let targetIndex = filteredItems.firstIndex(where: { $0.id == targetID }) else {
                toggleMultiSelect(targetID)
                return
            }
            
            let startIndex = min(anchorIndex, targetIndex)
            let endIndex = max(anchorIndex, targetIndex)
            let rangeIDs = Set(filteredItems[startIndex...endIndex].map { $0.id })
            
            selectedItemIDs = baseSelectedIDs.union(rangeIDs)
            isSelectionMode = true
        }
    }

    // MARK: - Batch Action Bar

    private var batchActionBar: some View {
        HStack(spacing: 8) {
            // Count badge
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
            .help("\(selectedItemIDs.count) images selected")

            Spacer()

            // Select All / Deselect (Icon button)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if selectedItemIDs.count == filteredItems.count {
                        selectedItemIDs.removeAll()
                        baseSelectedIDs.removeAll()
                        anchorItemID = nil
                    } else {
                        selectedItemIDs = Set(filteredItems.map { $0.id })
                        baseSelectedIDs = selectedItemIDs
                        anchorItemID = filteredItems.first?.id
                    }
                }
            } label: {
                Image(systemName: selectedItemIDs.count == filteredItems.count ? "checklist.checked" : "checklist")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(selectedItemIDs.count == filteredItems.count ? Color.accentColor : CFColor.primaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help(selectedItemIDs.count == filteredItems.count ? "Deselect All" : "Select All")

            // Copy button (Icon button)
            Button {
                let items = filteredItems.filter { selectedItemIDs.contains($0.id) }
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
            .help("Copy selected images to clipboard")

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
            .help("Delete selected images")

            // Paste All Button (Primary Icon button with count)
            Button {
                let items = filteredItems.filter { selectedItemIDs.contains($0.id) }
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
            .help("Paste all selected images (Return)")

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
}
