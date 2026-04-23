# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-23
**Project:** PleaseDo
**Type:** Swift macOS Menu Bar App

## OVERVIEW
A minimal, distraction-free task manager for macOS. Lives in the menu bar with a glassmorphic SwiftUI interface. Uses hybrid SwiftUI/AppKit architecture for menu bar integration.

## STRUCTURE
```
PleaseDo/
├── Package.swift              # SPM manifest (macOS 13+, executable target)
├── Sources/PleaseDo/
│   ├── PleaseDoApp.swift      # Entry point + AppDelegate (hybrid SwiftUI/AppKit)
│   ├── Models/
│   │   └── TaskItem.swift     # AppData + TaskItem (Codable, JSON persistence)
│   ├── ViewModels/
│   │   └── TaskListViewModel.swift  # Business logic, reactive state
│   ├── Repositories/
│   │   ├── TaskRepository.swift      # Protocol abstraction
│   │   └── LocalTaskRepository.swift # JSON file persistence (~/Library/Application Support/PleaseDo/)
│   └── Views/
│       ├── ContentView.swift           # Main popover UI (320x460)
│       ├── ArchiveView.swift           # Archive browser window
│       └── ArchiveWindowController.swift # AppKit NSPanel manager
└── Tests/PleaseDoTests/
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Entry point | `PleaseDoApp.swift` | `@main` + `AppDelegate` with `NSStatusBar` |
| Data models | `Models/TaskItem.swift` | `AppData`, `TaskItem` (Codable) |
| Business logic | `ViewModels/TaskListViewModel.swift` | `@Published` state, task/category/archive management |
| Persistence | `Repositories/LocalTaskRepository.swift` | Dual JSON files (tasks.json, archive.json) |
| Main UI | `Views/ContentView.swift` | 643 lines - tabs, task list, input, overlays |
| Archive UI | `Views/ArchiveView.swift` | Filterable, paginated archive view |
| Window mgmt | `Views/ArchiveWindowController.swift` | NSPanel for archive window |

## CODE MAP
| Symbol | Type | Location | Role |
|--------|------|----------|------|
| PleaseDoApp | struct | PleaseDoApp.swift | @main entry, Settings scene |
| AppDelegate | class | PleaseDoApp.swift | NSStatusBar, NSPopover, badge updates |
| TaskListViewModel | class | TaskListViewModel.swift | Central state manager |
| TaskItem | struct | TaskItem.swift | Core data model |
| AppData | struct | TaskItem.swift | Top-level persistence container |
| TaskRepository | protocol | TaskRepository.swift | Data layer abstraction |
| LocalTaskRepository | class | LocalTaskRepository.swift | JSON file implementation |
| ContentView | struct | ContentView.swift | Main popover content |
| ArchiveView | struct | ArchiveView.swift | Archive browser |
| ArchiveWindowController | class | ArchiveWindowController.swift | AppKit window manager |

## CONVENTIONS
- **Architecture:** MVVM + Repository pattern
- **Reactive:** SwiftUI `@Published` + Combine for state binding
- **Persistence:** Manual JSON serialization (not CoreData/SwiftData)
- **Comments:** Doc comments for public APIs, `// MARK:` for sections
- **Access Control:** `public` for module exports, `private` for internals
- **SwiftUI Patterns:** `@ObservedObject` for VM injection, `@State` for local UI state
- **Hybrid Bridge:** NotificationCenter for SwiftUI ↔ AppKit communication

## ANTI-PATTERNS (THIS PROJECT)
- **No external dependencies:** Pure Swift/SwiftUI/AppKit - no CocoaPods/SPM deps
- **No CoreData:** Intentionally uses JSON files for simplicity
- **No SwiftData:** Migration path exists in `LocalTaskRepository` but not currently used
- **No CI/CD:** No `.github/workflows` or automation

## UNIQUE STYLES
- **Hybrid Entry:** SwiftUI `@main` + `NSApplicationDelegateAdaptor` for AppKit control
- **Accessory Policy:** `NSApplication.shared.setActivationPolicy(.accessory)` - hides Dock icon
- **Dual File Persistence:** `tasks.json` (hot) + `archive.json` (cold) separation
- **Notification Bridge:** `Notification.Name.openArchiveWindow` decouples view from window controller
- **Badge Updates:** Combine `CombineLatest` on ViewModel publishes for menu bar badge

## COMMANDS
```bash
# Build
swift build

# Run (menu bar tray icon appears)
swift run

# Xcode
open Package.swift

# Test
swift test
```

## NOTES
- Target: macOS 13+ (Ventura)
- Swift Tools: 5.9
- Output: Single executable, no .app bundle in SPM
- Data location: `~/Library/Application Support/PleaseDo/`
- Window sizes: Popover 320x460, Archive 500x700
- Max categories: 5 (hardcoded in `TaskListViewModel`)
