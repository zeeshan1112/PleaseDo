# PleaseDo 📝

**PleaseDo** is a minimal, distraction-free productivity tool for macOS. It lives entirely in your menu bar, ensuring your tasks are always accessible without cluttering your workspace.

Designed for those who value speed and privacy, PleaseDo provides a high-quality native experience that combines absolute simplicity with a premium macOS aesthetic.

![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2013%2B-lightgrey?style=for-the-badge)

## 🎯 Why PleaseDo?

Most task managers are too heavy, requiring multiple clicks just to see what's next. **PleaseDo** was built to solve "input friction." By residing in the menu bar, it becomes a natural extension of your workflow—as easy to check as the system clock.

## ✨ Core Experience

- 💎 **Glassmorphic Design**: A sleek, translucent interface that adapts to your desktop wallpaper.
- 🚀 **Immediate Entry**: Type your task and hit Enter. No complex forms or nested menus.
- 🏷️ **Smart Categorization**: Organize into focused workstreams (Work, Personal, Side Projects).
- 🔢 **Glanceable Status**: Your pending task count is always visible in the menu tray.
- 🔒 **Absolute Privacy**: No cloud, no tracking, no account required. Your data is stored locally in standard JSON format.

## ⚙️ Building & Running

PleaseDo is built with Swift and requires macOS 13.0 or later.

### Command Line

1. **Clone the repository:**
   ```bash
   git clone git@github.com:zeeshan1112/PleaseDo.git
   cd PleaseDo
   ```

2. **Build the project:**
   ```bash
   swift build
   ```

3. **Run the application:**
   ```bash
   swift run
   ```
   *The app will appear as a checklist icon in your menu bar tray.*

### Xcode Integration

1. Open the project folder in Xcode:
   ```bash
   open Package.swift
   ```
2. Press `⌘R` to build and run the `PleaseDo` target.

## 📂 Project Navigation

The project follows a modular architecture for clarity and maintainability:

- **Sources/PleaseDo/Views**: All SwiftUI interface components, including the custom glassmorphic header, task rows, and input area.
- **Sources/PleaseDo/ViewModels**: The `TaskListViewModel`, which manages all reactive application state and business logic.
- **Sources/PleaseDo/Models**: The `TaskItem` and `AppData` models defining our core data structures.
- **Sources/PleaseDo/Repositories**: The `TaskRepository` protocol and its `LocalTaskRepository` implementation, handling all JSON-based file persistence in `~/Library/Application Support/PleaseDo/`.
- **Sources/PleaseDo/PleaseDoApp.swift**: The main entry point and `AppDelegate`, which handles the native AppKit bridge for the Menu Bar popover and badge updates.

---
*Stay focused. Get things done. PleaseDo.*
