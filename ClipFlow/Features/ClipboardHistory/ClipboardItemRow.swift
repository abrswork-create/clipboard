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

    @State private var isHovered = false
    @State private var showActions = false

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
            // LEFT SIDE: Text and badges
            VStack(alignment: .leading, spacing: 0) {
                if let appName = item.sourceAppName {
                    Text(appName.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(CFColor.secondaryText)
                        .padding(.bottom, 4)
                }

                if item.type == .image, let imagePath = item.imagePath, let nsImage = FileStorage.loadImage(at: imagePath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: style == .compact ? 50 : (style == .spacious ? 110 : 80), alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.vertical, 4)
                } else {
                    Text(displayText)
                        .font(.system(size: style == .compact ? 11 : (style == .spacious ? 14 : 13), weight: .regular))
                        .foregroundStyle(item.type == .url ? CFColor.urlText : CFColor.primaryText)
                        .lineLimit(style == .compact ? 2 : (style == .spacious ? 6 : 4))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 8)

                typeBadge
            }
            .padding(.horizontal, style == .compact ? 8 : (style == .spacious ? 16 : 12))
            .padding(.vertical, style == .compact ? 6 : (style == .spacious ? 14 : 10))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
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
                
                Spacer()
                
                // Bottom right icons
                HStack(spacing: 12) {
                    Button(action: onFavorite) {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(item.isFavorite ? Color.yellow : CFColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .help(item.isFavorite ? "Unfavorite" : "Favorite")
                    
                    Button(action: onPin) {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 12))
                            .foregroundStyle(item.isPinned ? CFColor.pinActive : CFColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin" : "Pin")
                }
            }
            .padding(.vertical, style == .compact ? 6 : (style == .spacious ? 14 : 10))
            .padding(.trailing, style == .compact ? 8 : (style == .spacious ? 16 : 12))
        }
        .background(
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .fill(isHovered && !isSelected && !showActions ? CFColor.cardHover : CFColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .strokeBorder(
                    isSelected ? CFColor.selectedBorder : Color.clear,
                    lineWidth: 2
                )
        )
        .cfShadow(isSelected ? CFShadow.cardSelected : CFShadow.card)
    }

    // MARK: - Type Badge

    private var typeBadge: some View {
        Group {
            switch item.type {
            case .url:
                badgeLabel("URL", color: CFColor.urlText)
            case .image:
                badgeLabel("Image", color: .purple)
            case .file:
                badgeLabel("File", color: .orange)
            case .richText:
                badgeLabel("Rich Text", color: .green)
            default:
                EmptyView()
            }
        }
    }

    private func badgeLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
    }

    // MARK: - Helpers

    private var displayText: String {
        item.text ?? item.type.rawValue.capitalized
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
