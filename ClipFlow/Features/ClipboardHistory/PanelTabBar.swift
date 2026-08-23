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
        case .clipboard:  return "Clipboard"
        }
    }
}

// MARK: - PanelTabBar

struct PanelTabBar: View {
    @Binding var selectedTab: PanelTab
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Tab row
            HStack(alignment: .center, spacing: 2) {
                ForEach(PanelTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 0)

            // Bottom separator
            Divider()
                .foregroundStyle(CFColor.panelBorder)
        }
        .background(Color.clear)
    }

    // MARK: - Subviews

    private func tabButton(_ tab: PanelTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .separatorColor))
                }
                
                Image(systemName: tab.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? CFColor.primaryText : CFColor.tabInactive)
            }
            .frame(width: 36, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
