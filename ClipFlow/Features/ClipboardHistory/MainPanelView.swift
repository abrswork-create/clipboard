import SwiftUI

// MARK: - MainPanelView
// Root view for the standalone ClipFlow window.
// White background, tab navigation at top, content area below.

struct MainPanelView: View {
    @ObservedObject var store: ClipboardStore
    @StateObject private var viewModel: ClipboardHistoryViewModel
    @State private var selectedTab: PanelTab = .clipboard
    let onClose: () -> Void

    init(store: ClipboardStore, onClose: @escaping () -> Void) {
        self.store = store
        _viewModel = StateObject(wrappedValue: ClipboardHistoryViewModel(store: store))
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            PanelTabBar(selectedTab: $selectedTab, onClose: onClose)

            // Content area
            ZStack {
                Group {
                    switch selectedTab {
                    case .clipboard:
                        ClipboardHistoryView(viewModel: viewModel, store: store)
                    case .favorites:
                        FavoritesView(store: store)
                    default:
                        comingSoonView(for: selectedTab)
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            }
        }
        .background(.regularMaterial)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensure the blur material inherits the user's system theme or force light if preferred.
        // For standard "fluent" design, it usually follows system setting, but we'll stick to forced light to preserve our exact design tokens for now.
        .preferredColorScheme(.light)
    }

    // MARK: - Coming Soon Stub

    private func comingSoonView(for tab: PanelTab) -> some View {
        VStack(spacing: 12) {
            Image(systemName: tab.icon)
                .font(.system(size: 32))
                .foregroundStyle(CFColor.tabAccent)

            Text(tab.label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CFColor.primaryText)

            Text("Coming soon")
                .font(.system(size: 13))
                .foregroundStyle(CFColor.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
