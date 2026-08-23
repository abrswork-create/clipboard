import SwiftUI

// MARK: - Design System
// Centralised design tokens for ClipFlow's Fluent UI–inspired light panel.

// MARK: CFColor

enum CFColor {
    /// Main panel background — pure white
    static let panelBackground = Color.clear
    /// Card resting state background - translucent to let blur shine through
    static let cardBackground = Color.white.opacity(0.15)
    /// Card hover background
    static let cardHover = Color.white.opacity(0.3)
    /// Selected card border (macOS focus ring style)
    static let selectedBorder = Color.accentColor.opacity(0.8)
    /// Active tab underline — macOS Accent
    static let tabAccent = Color.accentColor
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
    /// Action button background - translucent
    static let actionButton = Color.white.opacity(0.1)
    /// Pinned badge tint
    static let pinActive = Color(nsColor: .systemOrange)
    /// URL / link accent
    static let urlText = Color.accentColor
    /// Drag handle
    static let dragHandle = Color(nsColor: .tertiaryLabelColor)
    /// Clear-all button text
    static let clearAll = Color(nsColor: .systemRed)
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
}
