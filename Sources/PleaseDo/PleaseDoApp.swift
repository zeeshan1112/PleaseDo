import SwiftUI
import AppKit
import Combine

/**
 * Custom notification name for triggering the archive window from any part of the app.
 */
extension Notification.Name {
    static let openArchiveWindow = Notification.Name("openArchiveWindow")
}

/**
 * The main entry point for the PleaseDo application.
 * Utilizes a background Settings scene to enable a pure Menu Bar experience.
 */
@main
struct PleaseDoApp: App {
    /// Native bridge for macOS application lifecycle events.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

/**
 * Orchestrates the native macOS system tray integration.
 * Manages the status bar icon, the floating popover, and reactive data synchronization.
 */
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    /// The physical button in the macOS menu bar.
    var statusItem: NSStatusItem?
    
    /// The interactive container for the SwiftUI interface.
    var popover: NSPopover?
    
    /// Centralized state manager for the application.
    let viewModel = TaskListViewModel()
    
    /// Manages the standalone archive window lifecycle.
    var archiveWindowController: ArchiveWindowController?
    
    /// Storage for Combine subscriptions to prevent premature deallocation.
    var cancellables = Set<AnyCancellable>()
    
    /**
     * Bootstraps the status item and popover configurations.
     * Sets the app to run as an accessory to hide the Dock icon.
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Setup Popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(viewModel: viewModel))
        popover.delegate = self
        self.popover = popover
        
        // 2. Setup Menu Bar Item with fixed width to prevent popover wiggling during updates
        statusItem = NSStatusBar.system.statusItem(withLength: 48)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "PleaseDo Tasks")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // 3. Reactively Observe ViewModel to Update Badge Count Natively
        Publishers.CombineLatest(viewModel.$tasks, viewModel.$showPendingCount)
            .receive(on: RunLoop.main)
            .sink { [weak self] tasks, showPending in
                guard let self = self else { return }
                
                if showPending {
                    let pendingCount = tasks.filter { !$0.isCompleted }.count
                    self.statusItem?.button?.title = pendingCount > 0 ? " \(pendingCount)" : ""
                } else {
                    self.statusItem?.button?.title = ""
                }
            }
            .store(in: &cancellables)
            
        let initialPending = viewModel.tasks.filter { !$0.isCompleted }.count
        statusItem?.button?.title = initialPending > 0 ? " \(initialPending)" : ""
        
        // 4. Initialize Archive Window Controller and listen for open requests
        archiveWindowController = ArchiveWindowController(viewModel: viewModel)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenArchive),
            name: .openArchiveWindow,
            object: nil
        )
    }
    
    /**
     * Handles the notification to open the archive window.
     */
    @objc func handleOpenArchive() {
        archiveWindowController?.showWindow()
    }
    
    /* Logic removed: No longer deferring updates */
    func popoverDidClose(_ notification: Notification) { }
    
    /**
     * Toggles the popover visibility state.
     * - Parameter sender: The invoking menu bar button.
     */
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
