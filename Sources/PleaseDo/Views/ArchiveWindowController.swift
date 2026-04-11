import AppKit
import SwiftUI

/**
 * Manages a dedicated macOS window for browsing the task archive.
 * Uses an NSPanel to provide a floating, non-modal window that
 * coexists with the main popover without blocking interaction.
 */
class ArchiveWindowController {
    /// The floating panel displaying the archive UI.
    private var panel: NSPanel?
    
    /// Reference to the shared ViewModel for data access.
    private let viewModel: TaskListViewModel
    
    /**
     * Initializes the controller with a shared ViewModel.
     * - Parameter viewModel: The application's central state manager.
     */
    init(viewModel: TaskListViewModel) {
        self.viewModel = viewModel
    }
    
    /**
     * Opens the archive window, or brings it to the front if already open.
     * Lazily loads archive data from disk on first display.
     */
    func showWindow() {
        // Load the archive data if it hasn't been loaded yet
        if !viewModel.isArchiveLoaded {
            viewModel.loadArchive()
        }
        
        // If the panel already exists, just bring it to attention
        if let existingPanel = panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        let archiveView = ArchiveView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: archiveView)
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 600),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.contentViewController = hostingController
        panel.title = "PleaseDo — Archive"
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.minSize = NSSize(width: 420, height: 500)
        panel.maxSize = NSSize(width: 900, height: 800)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = false
        panel.backgroundColor = NSColor.windowBackgroundColor
        
        self.panel = panel
        
        panel.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    /**
     * Closes the archive window if it is currently open.
     */
    func closeWindow() {
        panel?.close()
        panel = nil
    }
}
