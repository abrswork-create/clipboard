import SwiftUI
import AppKit

// MARK: - Design System
// Centralised design tokens for Clipmory's Fluent UI–inspired light panel.

// MARK: CFColor

enum CFColor {
    /// Main panel background — pure white
    static let panelBackground = Color.clear
    /// Card resting state background - 70% white opacity
    static let cardBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let match = appearance.bestMatch(from: [.aqua, .darkAqua])
        if match == .darkAqua {
            return NSColor(white: 0.22, alpha: 0.70)
        } else {
            return NSColor.white.withAlphaComponent(0.70)
        }
    }))
    /// Card hover background - 85% white opacity
    static let cardHover = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let match = appearance.bestMatch(from: [.aqua, .darkAqua])
        if match == .darkAqua {
            return NSColor(white: 0.28, alpha: 0.85)
        } else {
            return NSColor.white.withAlphaComponent(0.85)
        }
    }))
    /// Selected card border (subtle macOS accent outline)
    static let selectedBorder = Color.accentColor.opacity(0.40)
    /// Selected card background base - keeps crisp luminous white in light mode
    static let selectedBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let match = appearance.bestMatch(from: [.aqua, .darkAqua])
        if match == .darkAqua {
            return NSColor(white: 0.28, alpha: 0.85)
        } else {
            return NSColor.white.withAlphaComponent(0.92)
        }
    }))
    /// Active tab underline — macOS Accent
    static let tabAccent = Color.accentColor
    /// Selected tab button background - white in light mode
    static let selectedTabBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let match = appearance.bestMatch(from: [.aqua, .darkAqua])
        if match == .darkAqua {
            return NSColor(white: 0.35, alpha: 0.9)
        } else {
            return NSColor.white
        }
    }))
    /// Inactive tab icon
    static let tabInactive = Color(nsColor: .secondaryLabelColor)
    /// Primary text
    static let primaryText = Color(nsColor: .labelColor)
    /// Secondary text
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    /// Panel border
    static let panelBorder = Color(nsColor: .separatorColor)
    /// Destructive action
    static let destructive = Color(nsColor: .systemRed)
    /// Action button background - adaptive subtle translucency
    static let actionButton = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let match = appearance.bestMatch(from: [.aqua, .darkAqua])
        if match == .darkAqua {
            return NSColor.white.withAlphaComponent(0.12)
        } else {
            return NSColor.black.withAlphaComponent(0.06)
        }
    }))
    /// Pinned badge tint
    static let pinActive = Color(nsColor: .systemOrange)
    /// URL / link text color (black-blue)
    static let urlText = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let match = appearance.bestMatch(from: [.aqua, .darkAqua])
        if match == .darkAqua {
            return NSColor(srgbRed: 0.45, green: 0.65, blue: 0.92, alpha: 1.0)
        } else {
            return NSColor(srgbRed: 0.10, green: 0.18, blue: 0.32, alpha: 1.0)
        }
    }))
    /// Drag handle
    static let dragHandle = Color(nsColor: .tertiaryLabelColor)
    /// Clear-all button text
    static let clearAll = Color(nsColor: .labelColor)
    /// Separator lines between cards
    static let separator = Color(nsColor: .separatorColor).opacity(0.3)
}

// MARK: CFRadius

enum CFRadius {
    static let panel: CGFloat = 16
    static let card: CGFloat = 8
    static let button: CGFloat = 6
    static let actionBar: CGFloat = 8
}

// MARK: CFShadow

struct CFShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let panel = CFShadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
    static let card  = CFShadow(color: .black.opacity(0.04), radius: 3,  x: 0, y: 1)
    static let cardSelected = CFShadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
}

// MARK: - View Extension

extension View {
    func cfShadow(_ s: CFShadow) -> some View {
        self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }

    /// Changes the mouse cursor to a pointing hand on hover
    func pointingHandCursor() -> some View {
        self.modifier(PointingHandModifier())
    }
}

// MARK: - Pointing Hand Cursor Modifier

struct PointingHandModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering != isHovered {
                    isHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .onDisappear {
                if isHovered {
                    isHovered = false
                    NSCursor.pop()
                }
            }
    }
}

