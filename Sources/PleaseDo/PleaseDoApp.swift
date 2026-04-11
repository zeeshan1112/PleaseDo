import SwiftUI
import AppKit
import Combine

@main
struct PleaseDoApp: App {
    // Inject AppDelegate wrapper
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // App requires at least one Scene return. Settings is a hidden system background scene.
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    let viewModel = TaskListViewModel()
    var cancellables = Set<AnyCancellable>()
    var pendingBadgeTitle: String? = nil
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon, run as a background accessory service
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // 1. Create the Popover embedding our exact SwiftUI ContentView
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient // Closes when clicked outside automatically
        popover.contentViewController = NSHostingController(rootView: ContentView(viewModel: viewModel))
        popover.delegate = self
        self.popover = popover
        
        // 2. Create the Status Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "PleaseDo Tasks")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // 3. Reactively Observe ViewModel to Update Badge Count Natively
        viewModel.$tasks
            .receive(on: RunLoop.main)
            .sink { [weak self] tasks in
                guard let self = self else { return }
                let pendingCount = tasks.filter { !$0.isCompleted }.count
                let newTitle = pendingCount > 0 ? " \(pendingCount)" : ""
                
                // If popover is actively open, updating the title will physically shrink/grow the 
                // menu bar icon, instantly snapping the popover window left or right. 
                // We defer the badge UI update until the window cleanly closes!
                if self.popover?.isShown == true {
                    self.pendingBadgeTitle = newTitle
                } else {
                    self.statusItem?.button?.title = newTitle
                }
            }
            .store(in: &cancellables)
            
        // Setup initial text
        let initialPending = viewModel.tasks.filter { !$0.isCompleted }.count
        statusItem?.button?.title = initialPending > 0 ? " \(initialPending)" : ""
    }
    
    func popoverDidClose(_ notification: Notification) {
        // Apply any pending badge task counts now that the window is safe
        if let pending = pendingBadgeTitle {
            statusItem?.button?.title = pending
            pendingBadgeTitle = nil
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Natively popup below the exact bounds of the menu bar icon
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure popover takes focus allowing transient dismissal
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
