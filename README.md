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

## ⚙️ Building from Source

PleaseDo is built with Swift and requires macOS 13.0 or later.

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone git@github.com:zeeshan1112/PleaseDo.git
   cd PleaseDo
   ```

2. **Build & Run:**
   ```bash
   swift run
   ```

### Xcode Integration

If you prefer using Xcode:
1. Open common `Package.swift` in Xcode.
2. Press `⌘R` to build and run the target.

## 📂 Project Navigation

- **Sources/PleaseDo/Views**: All SwiftUI interface components.
- **Sources/PleaseDo/ViewModels**: Core task logic and category management.
- **Sources/PleaseDo/Models**: Data structures.
- **Sources/PleaseDo/Repositories**: Local persistence implementation.

---
*Stay focused. Get things done. PleaseDo.*
