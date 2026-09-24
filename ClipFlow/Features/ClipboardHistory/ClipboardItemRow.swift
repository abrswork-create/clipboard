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
    let onPaste: () -> Void
    let style: InterfaceStyle // New
    var isSelectionMode: Bool = false
    var isInMultiSelect: Bool = false
    var onToggleMultiSelect: (() -> Void)? = nil
    var onShiftSelect: (() -> Void)? = nil
    var onCommandSelect: (() -> Void)? = nil

    @State private var isHovered = false
    @State private var showActions = false
    @State private var isRevealed = false
    @State private var isAuthenticating = false

    var body: some View {
        HStack(spacing: showActions ? 6 : 0) {
            // Main Content Block (Always visible)
            contentBlock
            
            // Action Blocks (Visible when expanded)
            if showActions {
                MacOSActionButton(
                    icon: "doc.on.clipboard",
                    tooltip: "Paste",
                    isDestructive: false,
                    action: onPaste
                )
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .trailing)))
                
                MacOSActionButton(
                    icon: "trash",
                    tooltip: "Delete",
                    isDestructive: true,
                    action: {
                        withAnimation { showActions = false }
                        onDelete()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .trailing)))
            }
        }
        .frame(minHeight: 70)
        // We only show selection border if the item is selected, but on which block?
        // Usually, the whole row or the main content block. Let's put it on the main content block.
        .onHover { isHovered = $0 }
        .onChange(of: isHovered) { hovered in
            if !hovered && showActions {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showActions = false
                }
            }
        }
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
                } else if isSelectionMode {
                    onToggleMultiSelect?()
                } else {
                    onSelect()
                }
                if showActions {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showActions = false
                    }
                }
            }
            
            // RIGHT SIDE: Ellipsis, Star, Pin
            VStack(alignment: .trailing) {
                // Three-dot button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showActions.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CFColor.secondaryText)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .opacity(isHovered || showActions ? 1 : 0)
                
                Spacer()
                
                // Bottom right icons
                HStack(spacing: 12) {
                    if isSensitive && shouldMask {
                        Button {
                            if isRevealed {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    isRevealed = false
                                }
                            } else {
                                guard !isAuthenticating else { return }
                                isAuthenticating = true
                                Task {
                                    let authenticated = await PrivacyManager.shared.authenticateUser()
                                    isAuthenticating = false
                                    if authenticated {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                            isRevealed = true
                                        }
                                    }
                                }
                            }
                        } label: {
                            if isAuthenticating {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: isRevealed ? "eye.slash" : "eye")
                                    .font(.system(size: 12))
                                    .foregroundStyle(CFColor.secondaryText)
                            }
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .help(isRevealed ? "Hide sensitive content" : "Authenticate to reveal sensitive content")
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
                        : (isHovered && !showActions ? CFColor.cardHover : CFColor.cardBackground)
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
                        : (isHovered && !showActions ? Color.primary.opacity(0.12) : Color.clear),
                    lineWidth: (isInMultiSelect || isSelected) ? 1.5 : 1
                )
        )
        .cfShadow(isInMultiSelect ? CFShadow.cardSelected : (isSelected ? CFShadow.cardSelected : CFShadow.card))
    }


    // MARK: - Helpers

    private var isSensitive: Bool {
        guard let text = item.text else { return false }
        let settings = SettingsRepository.shared.load()
        guard settings.sensitiveContentDetection else { return false }
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
        if settings.sensitiveContentDetection && SensitiveDataDetector.containsSensitiveData(text) {
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
        .help(tooltip)
        .onHover { isHovered = $0 }
    }
}
