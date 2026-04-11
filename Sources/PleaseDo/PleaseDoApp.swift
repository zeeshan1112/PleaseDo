import SwiftUI
import AppKit

@main
struct PleaseDoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("PleaseDo", systemImage: "checklist") {
            ContentView()
        }
        .menuBarExtraStyle(.window) // Allows for a custom interactive view instead of standard native NSMenu
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hides dock icon, runs as a pure menu bar app
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
