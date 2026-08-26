import SwiftUI

// MARK: - MainPanelView
// Root view for the standalone ClipFlow window.
// White background, tab navigation at top, content area below.

struct MainPanelView: View {
    @ObservedObject var store: ClipboardStore
    @StateObject private var viewModel: ClipboardHistoryViewModel
    @State private var selectedTab: PanelTab = .clipboard
    
    // Animation States
    @State private var windowScale: CGFloat = 0.92
    @State private var windowOpacity: Double = 0.0
    @State private var windowBlur: CGFloat = 10.0
    
    // Theme State
    @State private var appTheme: AppTheme = SettingsRepository.shared.load().theme
    
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
        .blur(radius: windowBlur)
        .opacity(windowOpacity)
        .scaleEffect(windowScale)
        .preferredColorScheme(colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowThemeChanged"))) { _ in
            appTheme = SettingsRepository.shared.load().theme
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowWindowWillOpen"))) { _ in
            triggerAnimation()
        }
        .onAppear {
            triggerAnimation()
        }
    }
    
    private func triggerAnimation() {
        // Reset state instantly
        windowScale = 0.92
        windowOpacity = 0.0
        windowBlur = 10.0
        
        // 0-180ms: window expands and clears blur
        withAnimation(.easeOut(duration: 0.18)) {
            windowOpacity = 1.0
            windowBlur = 0.0
        }
        
        // End: 2-3% bounce settling at 1.0
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65, blendDuration: 0)) {
            windowScale = 1.0
        }
    }
    
    // MARK: - Computed Properties
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
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
