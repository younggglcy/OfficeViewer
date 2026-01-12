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

### Version Management

Version is managed via Xcode Build Settings (best practice):

| Build Setting | Info.plist Key | Purpose |
|---------------|----------------|---------|
| `MARKETING_VERSION` | `CFBundleShortVersionString` | User-facing version (e.g., `0.1.1`) |
| `CURRENT_PROJECT_VERSION` | `CFBundleVersion` | Build number (e.g., `1`) |

Info.plist uses `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` placeholders.

To update version via CLI:
```bash
# Update MARKETING_VERSION in project.pbxproj
sed -i '' 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = 1.0.0;/g' OfficeViewer.xcodeproj/project.pbxproj
```

## Release Workflow

When releasing a new version, **always ask the user** which type of version bump:
- **major** (X.0.0) - Breaking changes
- **minor** (x.Y.0) - New features
- **patch** (x.y.Z) - Bug fixes

**Important**: Tagged commits must ONLY contain version bump changes. Never include fixes or features in a tagged commit. If there are pending changes, commit them separately first, then create a version bump commit with tag.

Steps:
1. Ask user: major / minor / patch
2. Commit any pending fix/feature changes first (without tag)
3. Update `MARKETING_VERSION` in `OfficeViewer.xcodeproj/project.pbxproj`
4. Commit: `chore: bump version to x.y.z`
5. Create tag: `git tag vX.Y.Z`
6. Push: `git push origin main && git push origin vX.Y.Z`

GitHub Actions will automatically build DMG and create Release.
