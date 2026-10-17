import SwiftUI

@main
struct ClipmoryApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true

    var body: some Scene {
        MenuBarExtra("Clipmory", image: "MenuBarIcon", isInserted: $showInMenuBar) {
            Button("Open Clipmory") {
                AppDelegate.shared?.openMainWindow()
            }
            .keyboardShortcut("o")

            Divider()

            Button("Settings...") {
                AppDelegate.shared?.openSettings()
            }
            .keyboardShortcut(",")

#if !APP_STORE
            Button("Check for Updates...") {
                AppDelegate.shared?.checkForUpdates()
            }
            .keyboardShortcut("u")
#endif

            Divider()

            Button("Quit Clipmory") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

