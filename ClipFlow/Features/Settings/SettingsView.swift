import SwiftUI
import ServiceManagement

// MARK: - SettingsView
struct SettingsView: View {
    @ObservedObject var store: ClipboardStore
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                SidebarItemView(tab: tab, isSelected: selectedTab == tab)
                    .tag(tab)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("ClipFlow Settings")
                        .font(.system(size: 17, weight: .bold))
                        .padding(.bottom, 8)
                        
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView()
                    case .clipboard:
                        ClipboardSettingsView()
                    case .appearance:
                        AppearanceSettingsView()
                    case .shortcuts:
                        ShortcutsSettingsView()
                    case .privacy:
                        PrivacySettingsView(store: store)
                    case .advanced:
                        AdvancedSettingsView()
                    case .about:
                        AboutSettingsView()
                    }
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 32)
                .frame(maxWidth: 700, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // macOS standard content background (white in light mode, dark gray in dark mode)
            .background(Color(NSColor.textBackgroundColor))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Spacer()
                }
            }
        }
        .frame(minWidth: 750, idealWidth: 750, minHeight: 600, idealHeight: 600)
    }
}

// MARK: - GeneralSettingsView
struct GeneralSettingsView: View {
    @State private var settings = SettingsRepository.shared.load()
    @State private var launchAtLogin = SettingsRepository.shared.load().launchAtLogin
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsSection {
                SettingsToggleRow(
                    title: "Clipboard History",
                    subtitle: "Save everything you copy and access it anytime.",
                    showDivider: true,
                    isOn: $settings.enableHistory
                )
                
                SettingsToggleRow(
                    title: "Launch at Login",
                    subtitle: "Start ClipFlow automatically when you log in.",
                    showDivider: true,
                    isOn: $launchAtLogin
                )
                
                SettingsRow(title: "Open ClipFlow", subtitle: "Use a global shortcut to open ClipFlow from anywhere.", showDivider: true) {
                    ShortcutRecorderView(shortcut: $settings.quickClipboardShortcut) {
                        save()
                        GlobalHotkeyManager.shared.rebind()
                    }
                }
                
                SettingsRow(title: "When ClipFlow Opens", subtitle: "Choose what you want to see when ClipFlow opens.", showDivider: false) {
                    Picker("", selection: .constant("Show clipboard history")) {
                        Text("Show clipboard history").tag("Show clipboard history")
                        Text("Show search").tag("Show search")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 180)
                }
            }
            
            SettingsSection {
                SettingsToggleRow(
                    title: "Menu Bar",
                    subtitle: "Show ClipFlow in the menu bar.",
                    showDivider: true,
                    isOn: $settings.showInMenuBar
                )
                
                SettingsRow(title: "Menu Bar Click Action", subtitle: "Choose what happens when you click the menu bar icon.", showDivider: true) {
                    Picker("", selection: .constant("Show recent clips")) {
                        Text("Show recent clips").tag("Show recent clips")
                        Text("Open settings").tag("Open settings")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 180)
                }
                
                SettingsRow(title: "Recent Items", subtitle: "Show recent copied items in the menu bar dropdown.", showDivider: false) {
                    Picker("", selection: .constant(10)) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("20").tag(20)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 80)
                }
            }
        }
        .onChange(of: settings.enableHistory) { _ in save() }
        .onChange(of: launchAtLogin) { newValue in
            LaunchAtLoginManager.shared.setLaunchAtLogin(newValue)
            settings.launchAtLogin = newValue
            save()
        }
        .onChange(of: settings.showInMenuBar) { _ in
            save()
            NotificationCenter.default.post(name: NSNotification.Name("clipFlowShowInMenuBarChanged"), object: nil)
        }
    }
    
    private func save() {
        SettingsRepository.shared.save(settings)
    }
}

// MARK: - ClipboardSettingsView
struct ClipboardSettingsView: View {
    @State private var settings = SettingsRepository.shared.load()
    let limits = [100, 500, 1000, 5000, 0]
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsSection {
                SettingsRow(title: "History Limit", subtitle: "How many items to keep in the database.", showDivider: false) {
                    Picker("", selection: $settings.historyLimit) {
                        ForEach(limits, id: \.self) { limit in
                            Text(limit == 0 ? "Unlimited items" : "\(limit) items").tag(limit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 160)
                }
            }
            
            SettingsSection {
                SettingsToggleRow(title: "Save Text", subtitle: "Record plain text, rich text, and URLs.", showDivider: true, isOn: $settings.saveText)
                SettingsToggleRow(title: "Save Images", subtitle: "Record image data (PNG, JPEG, etc).", showDivider: true, isOn: $settings.saveImages)
                SettingsToggleRow(title: "Save Copied Files", subtitle: "Record file references and Finder paths.", showDivider: settings.saveFiles, isOn: $settings.saveFiles)
                
                if settings.saveFiles {
                    SettingsRow(title: "File Storage Strategy", subtitle: "How files are referenced when copied.", showDivider: false) {
                        Picker("", selection: $settings.fileStorageMode) {
                            ForEach(FileStorageMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }
            }
        }
        .onChange(of: settings.historyLimit) { _ in save() }
        .onChange(of: settings.saveText) { _ in save() }
        .onChange(of: settings.saveImages) { _ in save() }
        .onChange(of: settings.saveFiles) { _ in save() }
        .onChange(of: settings.fileStorageMode) { _ in save() }
    }
    
    private func save() {
        SettingsRepository.shared.save(settings)
    }
}

// MARK: - AppearanceSettingsView
struct AppearanceSettingsView: View {
    @State private var settings = SettingsRepository.shared.load()
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsSection {
                SettingsRow(title: "Theme", subtitle: "Application color scheme.", showDivider: true) {
                    Picker("", selection: $settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 160)
                }
                
                SettingsRow(title: "Interface Style", subtitle: "Density of the clipboard items.", showDivider: false) {
                    Picker("", selection: $settings.interfaceStyle) {
                        ForEach(InterfaceStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 160)
                }
            }
        }
        .onChange(of: settings.theme) { _ in
            save()
            NotificationCenter.default.post(name: NSNotification.Name("clipFlowThemeChanged"), object: nil)
        }
        .onChange(of: settings.interfaceStyle) { _ in
            save()
            NotificationCenter.default.post(name: NSNotification.Name("clipFlowInterfaceStyleChanged"), object: nil)
        }
    }
    
    private func save() {
        SettingsRepository.shared.save(settings)
    }
}

// MARK: - ShortcutsSettingsView
struct ShortcutsSettingsView: View {
    var body: some View {
        SettingsSection {
            SettingsRow(title: "Global Shortcut", subtitle: "To change the global shortcut, go to the General tab.", showDivider: false) {
                EmptyView()
            }
        }
    }
}

// MARK: - PrivacySettingsView
struct PrivacySettingsView: View {
    @ObservedObject var store: ClipboardStore
    @State private var settings = SettingsRepository.shared.load()
    @State private var showConfirmClear = false
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsSection {
                SettingsRow(title: "Delete History", subtitle: "Automatically delete old clipboard items.", showDivider: false) {
                    Picker("", selection: $settings.autoDeleteHistory) {
                        ForEach(AutoDeleteHistory.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 160)
                }
            }
            
            SettingsSection {
                SettingsToggleRow(
                    title: "Sensitive Content Detection",
                    subtitle: "Automatically detect passwords, credit cards, and API keys.",
                    showDivider: settings.sensitiveContentDetection,
                    isOn: $settings.sensitiveContentDetection
                )
                
                if settings.sensitiveContentDetection {
                    SettingsRow(title: "When Detected", subtitle: "Action to take when sensitive data is found.", showDivider: false) {
                        Picker("", selection: $settings.sensitiveContentAction) {
                            ForEach(SensitiveContentAction.allCases, id: \.self) { action in
                                Text(action.rawValue).tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }
            }
            
            SettingsSection {
                SettingsRow(title: "Clear Database", subtitle: "Permanently delete all unpinned clipboard items.", showDivider: false) {
                    Button("Clear History...") {
                        showConfirmClear = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .confirmationDialog("Are you sure? This cannot be undone.", isPresented: $showConfirmClear, titleVisibility: .visible) {
                        Button("Clear History", role: .destructive) {
                            store.clearAll()
                        }
                    }
                }
            }
        }
        .onChange(of: settings.autoDeleteHistory) { _ in save() }
        .onChange(of: settings.sensitiveContentDetection) { _ in save() }
        .onChange(of: settings.sensitiveContentAction) { _ in save() }
    }
    
    private func save() {
        SettingsRepository.shared.save(settings)
    }
}

// MARK: - AdvancedSettingsView
struct AdvancedSettingsView: View {
    var body: some View {
        SettingsSection {
            SettingsRow(title: "Database Location", subtitle: "The local path where SQLite data is stored.", showDivider: false) {
                Button("Reveal in Finder") {
                    let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("ClipFlow", isDirectory: true)
                    NSWorkspace.shared.selectFile(supportDir.path, inFileViewerRootedAtPath: "")
                }
            }
        }
    }
}

// MARK: - AboutSettingsView
struct AboutSettingsView: View {
    private var isAppStoreInstall: Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return false }
        return FileManager.default.fileExists(atPath: receiptUrl.path)
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("ClipFlow")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Version 1.0.0 (Build 102)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text("© 2026 ClipFlow Inc. All rights reserved.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            
            SettingsSection {
                SettingsRow(title: "Website", subtitle: "Visit our homepage for updates and news.", showDivider: true) {
                    Button("Open") {}
                }
                
                SettingsRow(title: "Twitter", subtitle: "Follow us on Twitter.", showDivider: true) {
                    Button("Follow") {}
                }
                
                if isAppStoreInstall {
                    SettingsRow(title: "Rate App", subtitle: "Love ClipFlow? Please rate us on the App Store.", showDivider: false) {
                        Button("Rate") {
                            if let url = URL(string: "macappstore://apps.apple.com/app/id123456789?action=write-review") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                } else {
                    SettingsRow(title: "Share on Reddit", subtitle: "Tell others about ClipFlow on Reddit.", showDivider: true) {
                        Button("Share") {
                            let title = "I found an amazing clipboard manager for Mac called ClipFlow"
                            let text = "I have been using ClipFlow to manage my clipboard history and it has completely transformed my workflow. It is incredibly fast, easy to use, and keeps all my copied text and images perfectly organized. Highly recommend checking it out if you want to boost your productivity!"
                            if let titleEncoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                               let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                               let url = URL(string: "https://reddit.com/submit?url=https://clipflow.app&title=\(titleEncoded)&text=\(textEncoded)") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                    
                    SettingsRow(title: "Share on Facebook", subtitle: "Share ClipFlow with your friends.", showDivider: false) {
                        Button("Share") {
                            let text = "I have been using ClipFlow to manage my clipboard history and it has completely transformed my workflow. It is incredibly fast, easy to use, and keeps all my copied text and images perfectly organized. Highly recommend checking it out if you want to boost your productivity!"
                            if let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                               let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=https://clipflow.app&quote=\(textEncoded)") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 32)
    }
}
import SwiftUI

// MARK: - Sidebar Item Enum

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case clipboard = "Clipboard"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"
    case privacy = "Privacy"
    case advanced = "Advanced"
    case about = "About"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .appearance: return "paintpalette.fill"
        case .shortcuts: return "keyboard.fill"
        case .privacy: return "lock.shield.fill"
        case .advanced: return "slider.horizontal.3"
        case .about: return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .general: return .blue
        case .clipboard: return .pink
        case .appearance: return .orange
        case .shortcuts: return .green
        case .privacy: return .purple
        case .advanced: return .indigo
        case .about: return .gray
        }
    }
}

// MARK: - Sidebar Item View

struct SidebarItemView: View {
    let tab: SettingsTab
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tab.iconColor.gradient)
                    .frame(width: 26, height: 26)
                
                Image(systemName: tab.iconName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
            }
            
            Text(tab.rawValue)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .primary : .primary.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
        .padding(.bottom, 20)
    }
}

// MARK: - Settings Row

struct SettingsRow<Control: View>: View {
    let title: String
    let subtitle: String?
    let showDivider: Bool
    let control: () -> Control
    
    init(title: String, subtitle: String? = nil, showDivider: Bool = true, @ViewBuilder control: @escaping () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.showDivider = showDivider
        self.control = control
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer(minLength: 16)
                
                control()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if showDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Toggle Row Variant

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    let showDivider: Bool
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String? = nil, showDivider: Bool = true, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.showDivider = showDivider
        self._isOn = isOn
    }
    
    var body: some View {
        SettingsRow(title: title, subtitle: subtitle, showDivider: showDivider) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

// MARK: - Shortcut Recorder

