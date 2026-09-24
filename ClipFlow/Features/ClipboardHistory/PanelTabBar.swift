import SwiftUI
import AppKit

// MARK: - PanelTab

enum PanelTab: CaseIterable, Identifiable {
    case favorites, emoji, gif, image, kaomoji, symbols, clipboard

    var id: Self { self }

    var icon: String {
        switch self {
        case .favorites:  return "star.fill"
        case .emoji:      return "face.smiling"
        case .gif:        return "play.square"
        case .image:      return "photo"
        case .kaomoji:    return "character.bubble"
        case .symbols:    return "textformat"
        case .clipboard:  return "doc.on.clipboard"
        }
    }

    var label: String {
        switch self {
        case .favorites:  return "Favorites"
        case .emoji:      return "Emoji"
        case .gif:        return "GIF"
        case .image:      return "Images"
        case .kaomoji:    return "Kaomoji"
        case .symbols:    return "Symbols"
        case .clipboard:  return "Clipmory"
        }
    }
}

// MARK: - PanelTabBar

struct PanelTabBar: View {
    @Binding var selectedTab: PanelTab
    let onClose: () -> Void
    
    @State private var itemsAppeared = true
    @State private var hoveredTab: PanelTab? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Tab row in segmented pill bar
            HStack(alignment: .center, spacing: 3) {
                ForEach(PanelTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
            .padding(.horizontal, 10)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .opacity(itemsAppeared ? 1 : 0)
            .offset(y: itemsAppeared ? 0 : 8)

            // Bottom separator
            Divider()
                .foregroundStyle(CFColor.panelBorder)
        }
        .background(Color.clear)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowWindowWillOpen"))) { _ in
            triggerAnimation()
        }
        .onAppear {
            triggerAnimation()
        }
    }
    
    private func triggerAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            itemsAppeared = true
        }
    }

    // MARK: - Subviews

    private func tabButton(_ tab: PanelTab) -> some View {
        let isSelected = selectedTab == tab
        let isHovered = hoveredTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(CFColor.selectedTabBackground)
                        .cfShadow(CFShadow.card)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(CFColor.cardHover)
                }
                
                Image(systemName: tab.icon)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? CFColor.primaryText : (isHovered ? CFColor.primaryText : CFColor.tabInactive))
            }
            .frame(width: 40, height: 30)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { inside in
            withAnimation(.easeInOut(duration: 0.12)) {
                hoveredTab = inside ? tab : (hoveredTab == tab ? nil : hoveredTab)
            }
        }
        .pointingHandCursor()
        .help(tab.label)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CFColor.tabInactive)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.5))
                )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 4)
        .padding(.trailing, 4)
        .help("Close")
    }
}
