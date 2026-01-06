# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build (Debug)
xcodebuild -scheme OfficeViewer -configuration Debug build

# Build (Release)
xcodebuild -scheme OfficeViewer -configuration Release build

# Install to /Applications
cp -r ~/Library/Developer/Xcode/DerivedData/OfficeViewer-*/Build/Products/Release/OfficeViewer.app /Applications/

# Register with macOS Launch Services (required after install)
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f /Applications/OfficeViewer.app

# Format code
swift format -i -r OfficeViewer/

# Clean
xcodebuild clean && rm -rf .build/
```

## Architecture

macOS menu bar app (SwiftUI + AppKit hybrid) that extracts Office files and opens them with configurable CLI commands.

### Flow
1. `AppDelegate` receives file via "Open With" (`application(_:open:)` or `CommandLine.arguments`)
2. `FileDecoder.decode()` extracts ZIP to `~/Library/Caches/OfficeViewer/<name>_<timestamp>/`
3. `CommandRunner.run()` executes user's CLI command with `${folder}` placeholder replaced

### Key Components

| File | Purpose |
|------|---------|
| `OfficeViewerApp.swift` | Entry point, AppDelegate, menu bar setup, file handling orchestration |
| `Models/OpenCommand.swift` | Command configuration model (name + CLI template) |
| `Storage/ConfigStore.swift` | Singleton persisting commands to UserDefaults |
| `Services/FileDecoder.swift` | Extracts Office files using `/usr/bin/unzip` |
| `Services/CommandRunner.swift` | Executes CLI commands via `/bin/zsh -c` |
| `Views/SettingsView.swift` | SwiftUI settings UI for managing commands |

### Configuration Files

- `info.plist` - Document type associations (docx/xlsx/pptx), `LSUIElement=true` for menu bar only
- `OfficeViewer.entitlements` - App sandbox disabled for file system access
- `project.pbxproj` - `GENERATE_INFOPLIST_FILE=NO` to use custom Info.plist
