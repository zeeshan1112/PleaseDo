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
        
        let targetWidth: CGFloat = 560
        let targetHeight: CGFloat = 700
        
        // Setup or update the panel
        if panel == nil {
            let archiveView = ArchiveView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: archiveView)
            
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
                styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            newPanel.contentViewController = hostingController
            newPanel.title = "PleaseDo — Archive"
            newPanel.isReleasedWhenClosed = false
            newPanel.minSize = NSSize(width: 420, height: 750)
            newPanel.maxSize = NSSize(width: 900, height: 1200)
            newPanel.level = .floating
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.isMovableByWindowBackground = true
            newPanel.titlebarAppearsTransparent = false
            newPanel.backgroundColor = NSColor.windowBackgroundColor
            self.panel = newPanel
        }
        
        guard let activePanel = panel else { return }
        
        // Calculate the center of the main screen manually to override macOS caching
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let newX = screenRect.origin.x + (screenRect.width - targetWidth) / 2
            let newY = screenRect.origin.y + (screenRect.height - targetHeight) / 2
            
            // Force the size and position once and for all
            activePanel.setFrame(NSRect(x: newX, y: newY, width: targetWidth, height: targetHeight), display: true, animate: true)
        } else {
            activePanel.center()
        }
        
        activePanel.makeKeyAndOrderFront(nil)
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
