import SwiftUI
import AppKit

// MARK: - ClipboardItemRow
// A large rounded card representing one clipboard entry.
// When selected: black border + action bar slides in below.

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void
    let onFavorite: () -> Void
    var onPaste: (() -> Void)? = nil
    let style: InterfaceStyle // New
    var isSelectionMode: Bool = false
    var isInMultiSelect: Bool = false
    var onToggleMultiSelect: (() -> Void)? = nil
    var onShiftSelect: (() -> Void)? = nil
    var onCommandSelect: (() -> Void)? = nil
    var isActionsExpanded: Bool = false
    var onToggleActions: (() -> Void)? = nil
    var onCloseActions: (() -> Void)? = nil

    @State private var isHovered = false
    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: isActionsExpanded ? 6 : 0) {
            // Main Content Block (Always visible)
            contentBlock
            
            // Action Blocks (Visible when expanded)
            if isActionsExpanded {
                MacOSActionButton(
                    icon: "doc.on.doc",
                    tooltip: "Copy",
                    isDestructive: false,
                    action: {
                        _ = PasteService.copy(items: [item])
                        onCloseActions?()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .trailing)))
                
                MacOSActionButton(
                    icon: "trash",
                    tooltip: "Delete",
                    isDestructive: true,
                    action: {
                        onCloseActions?()
                        onDelete()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .trailing)))
            }
        }
        .frame(minHeight: 70)
        .onHover { isHovered = $0 }
    }

    // MARK: - Content Block

    private var contentBlock: some View {
        HStack(spacing: 0) {
            // Selection Checkbox
            if isSelectionMode || isInMultiSelect {
                Button {
                    let modifiers = NSEvent.modifierFlags
                    if modifiers.contains(.shift), let onShiftSelect = onShiftSelect {
                        onShiftSelect()
                    } else if modifiers.contains(.command), let onCommandSelect = onCommandSelect {
                        onCommandSelect()
                    } else {
                        onToggleMultiSelect?()
                    }
                } label: {
                    Image(systemName: isInMultiSelect ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isInMultiSelect ? Color(nsColor: .controlAccentColor) : CFColor.secondaryText.opacity(0.5))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .padding(.leading, 10)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(isInMultiSelect ? "Selected item checkbox" : "Unselected item checkbox")
                .accessibilityHint(isInMultiSelect ? "Double-tap to deselect" : "Double-tap to select")
                .accessibilityAddTraits(isInMultiSelect ? [.isButton, .isSelected] : .isButton)
            }

            // LEFT SIDE: Text and badges
            VStack(alignment: .leading, spacing: 0) {
                if let appName = item.sourceAppName {
                    HStack(spacing: 4) {
                        Text(appName.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(CFColor.secondaryText)
                        
                        if isSensitive && shouldMask && !isRevealed {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(CFColor.secondaryText)
                        }
                    }
                    .padding(.bottom, 4)
                }

                let mediaHeight: CGFloat = (style == .compact ? 50 : (style == .spacious ? 110 : 80))

                if let gifUrl = item.gifURLString {
                    GifURLThumbnailView(urlString: gifUrl, maxHeight: mediaHeight)
                        .padding(.vertical, 4)
                } else if item.type == .image, let imagePath = item.imagePath {
                    if imagePath.lowercased().hasSuffix(".gif"), let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
                        GifCardThumbnailView(data: data, maxHeight: mediaHeight)
                            .padding(.vertical, 4)
                    } else if let nsImage = FileStorage.loadImage(at: imagePath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: mediaHeight, alignment: .leading)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(.vertical, 4)
                    }
                } else {
                    Text(displayText)
                        .font(.system(size: style == .compact ? 11 : (style == .spacious ? 14 : 13), weight: .regular))
                        .foregroundStyle(item.type == .url ? CFColor.urlText : CFColor.primaryText)
                        .lineLimit(style == .compact ? 2 : (style == .spacious ? 6 : 4))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, style == .compact ? 8 : (style == .spacious ? 16 : 12))
            .padding(.vertical, style == .compact ? 6 : (style == .spacious ? 14 : 10))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                let modifiers = NSEvent.modifierFlags
                if modifiers.contains(.shift), let onShiftSelect = onShiftSelect {
                    onShiftSelect()
                } else if modifiers.contains(.command), let onCommandSelect = onCommandSelect {
                    onCommandSelect()
                } else if isSelectionMode || isInMultiSelect {
                    onToggleMultiSelect?()
                } else {
                    onSelect()
                }
                if isActionsExpanded {
                    onCloseActions?()
                }
            }
            
            // RIGHT SIDE: Ellipsis, Star, Pin
            VStack(alignment: .trailing) {
                // Three-dot button / Close button
                Button {
                    if isActionsExpanded {
                        onCloseActions?()
                    } else {
                        onToggleActions?()
                    }
                } label: {
                    Image(systemName: isActionsExpanded ? "xmark" : "ellipsis")
                        .font(.system(size: isActionsExpanded ? 11 : 14, weight: .medium))
                        .foregroundStyle(CFColor.secondaryText)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .help(isActionsExpanded ? "Close options" : "More options")
                .opacity(isHovered || isActionsExpanded ? 1 : 0)
                
                Spacer()
                
                // Bottom right icons
                HStack(spacing: 12) {
                    if isSensitive && shouldMask {
                        Button(action: handleEyeToggle) {
                            Image(systemName: isRevealed ? "eye.slash" : "eye")
                                .font(.system(size: 12))
                                .foregroundStyle(isRevealed ? Color.accentColor : CFColor.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .help(isRevealed ? "Hide sensitive content" : "Reveal sensitive content")
                    }
                    
                    if isHovered || item.isFavorite {
                        Button(action: onFavorite) {
                            Image(systemName: item.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundStyle(item.isFavorite ? Color.yellow : CFColor.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .help(item.isFavorite ? "Unfavorite" : "Favorite")
                        .transition(.opacity)
                    }
                    
                    if isHovered || item.isPinned {
                        Button(action: onPin) {
                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 12))
                                .foregroundStyle(item.isPinned ? CFColor.pinActive : CFColor.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .help(item.isPinned ? "Unpin" : "Pin")
                        .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .padding(.vertical, style == .compact ? 6 : (style == .spacious ? 14 : 10))
            .padding(.trailing, style == .compact ? 8 : (style == .spacious ? 16 : 12))
        }
        .background(
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .fill(
                    (isInMultiSelect || isSelected)
                        ? CFColor.selectedBackground
                        : (isHovered && !isActionsExpanded ? CFColor.cardHover : CFColor.cardBackground)
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
                        : (isHovered && !isActionsExpanded ? Color.primary.opacity(0.12) : Color.clear),
                    lineWidth: (isInMultiSelect || isSelected) ? 1.5 : 1
                )
        )
        .cfShadow(isInMultiSelect ? CFShadow.cardSelected : (isSelected ? CFShadow.cardSelected : CFShadow.card))
        .contextMenu {
            Button {
                _ = PasteService.copy(items: [item])
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            if let onPaste = onPaste {
                Button {
                    onPaste()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
            }
            
            Divider()
            
            Button {
                onFavorite()
            } label: {
                Label(item.isFavorite ? "Unfavorite" : "Favorite", systemImage: item.isFavorite ? "star.slash" : "star")
            }
            
            Button {
                onPin()
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityHint(rowAccessibilityHint)
        .accessibilityAddTraits(isInMultiSelect ? [.isButton, .isSelected] : .isButton)
    }

    private var rowAccessibilityLabel: String {
        var label = "\(item.sourceAppName ?? "Application"): \(displayText)"
        if isSelectionMode || isInMultiSelect {
            label += isInMultiSelect ? ", Selected" : ", Not selected"
        }
        if item.isPinned {
            label += ", Pinned"
        }
        if item.isFavorite {
            label += ", Favorite"
        }
        return label
    }

    private var rowAccessibilityHint: String {
        if isSelectionMode {
            return isInMultiSelect ? "Double-tap to deselect item" : "Double-tap to select item"
        }
        return "Double-tap to copy or insert clipboard content"
    }


    // MARK: - Helpers

    private func handleEyeToggle() {
        if isRevealed {
            PrivacyManager.shared.unmarkItemAuthenticated(item.id)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isRevealed = false
            }
            return
        }
        
        let settings = SettingsRepository.shared.load()
        if settings.requireAuthForSensitiveContent && !PrivacyManager.shared.isItemAuthenticated(item.id) {
            Task {
                let success = await PrivacyManager.shared.authenticateUser(reason: "reveal sensitive clipboard content")
                if success {
                    PrivacyManager.shared.markItemAuthenticated(item.id)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isRevealed = true
                    }
                }
            }
        } else {
            PrivacyManager.shared.markItemAuthenticated(item.id)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isRevealed = true
            }
        }
    }

    private var isSensitive: Bool {
        let settings = SettingsRepository.shared.load()
        guard settings.sensitiveContentDetection else { return false }
        if item.isSensitive {
            return true
        }
        if ClipboardClassifier.isPasswordManagerBundleId(item.sourceBundleIdentifier) {
            return true
        }
        guard let text = item.text else { return false }
        return SensitiveDataDetector.containsSensitiveData(text)
    }

    private var shouldMask: Bool {
        guard isSensitive else { return false }
        let settings = SettingsRepository.shared.load()
        return settings.sensitiveContentAction == .hide || settings.sensitiveContentAction == .showFirstThree
    }

    private var displayText: String {
        guard let text = item.text else {
            return item.type.rawValue.capitalized
        }
        
        let settings = SettingsRepository.shared.load()
        if isSensitive {
            switch settings.sensitiveContentAction {
            case .hide:
                if !isRevealed {
                    let dotCount = min(max(text.count, 12), 24)
                    return String(repeating: "•", count: dotCount)
                }
            case .showFirstThree:
                if !isRevealed {
                    let prefix = String(text.prefix(3))
                    let dotCount = min(max(text.count - 3, 10), 20)
                    return "\(prefix)\(String(repeating: "•", count: dotCount))"
                }
            case .show, .dontCopy:
                return text
            }
        }
        
        return text
    }
}

// MARK: - MacOS Style Action Button

struct MacOSActionButton: View {
    let icon: String
    let tooltip: String
    let isDestructive: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isHovered ? (isDestructive ? CFColor.destructive : Color.accentColor) : CFColor.actionButton)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isHovered ? .white : CFColor.primaryText)
            }
            .frame(width: 40, height: 40)
            .cfShadow(isHovered ? CFShadow.cardSelected : CFShadow.card)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .help(tooltip)
        .onHover { isHovered = $0 }
    }
}
