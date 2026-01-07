# OfficeViewer

A macOS Finder "Open With" utility that unpacks Office files (.docx/.xlsx/.pptx) and opens the extracted folder in your editor; includes a menu bar for settings.

<video src="docs/show.mov" width="720" autoplay loop muted playsinline></video>

## What it does

Office files (.docx, .xlsx, .pptx) are actually ZIP archives containing XML files. OfficeViewer extracts these files and opens them with your preferred editor, making it easy to inspect the underlying OOXML structure.

## Installation

### Download (Recommended)

1. Download the latest `OfficeViewer-x.x.x.dmg` from [Releases](https://github.com/younggglcy/OfficeViewer/releases)
2. Open the DMG and drag OfficeViewer to Applications folder
3. Launch OfficeViewer from Applications

> **Note**: Since the app is not notarized by Apple, macOS Gatekeeper may block it on first launch. See [Bypassing Gatekeeper](#bypassing-gatekeeper) below.

### Build from Source

```bash
git clone https://github.com/younggglcy/OfficeViewer.git
cd OfficeViewer
xcodebuild -scheme OfficeViewer -configuration Release build
cp -r ~/Library/Developer/Xcode/DerivedData/OfficeViewer-*/Build/Products/Release/OfficeViewer.app /Applications/
```

## Usage

1. Right-click any `.docx`, `.xlsx`, or `.pptx` file in Finder
2. Select **Open With** → **OfficeViewer**
3. The file is extracted and opened with your configured command

## Configuration

Click the menu bar icon → **Settings...** to configure open commands.

### Default Commands

| Name   | Command              |
|--------|----------------------|
| VSCode | `code "${folder}"`   |
| Finder | `open "${folder}"`   |

### Custom Commands

Add your own commands using the `${folder}` placeholder:

```bash
# Sublime Text
subl "${folder}"

# IntelliJ IDEA
idea "${folder}"

# Terminal (cd into folder)
open -a Terminal "${folder}"

# List contents
ls -la "${folder}"
```

## How it works

1. Receives Office file via "Open With" context menu
2. Extracts contents to `~/Library/Caches/OfficeViewer/<filename>_<timestamp>/`
3. Executes the default command with the extracted folder path

## File Structure

Extracted Office files follow the OOXML structure:

```
document_docx_20240106_123456/
├── [Content_Types].xml
├── _rels/
├── docProps/
│   ├── app.xml
│   └── core.xml
└── word/
    ├── document.xml      # Main content
    ├── styles.xml
    ├── settings.xml
    └── ...
```

## Bypassing Gatekeeper

Since the app is not signed with an Apple Developer certificate, macOS will show a warning on first launch. Use one of these methods to open it:

**Method 1: Right-click to Open**
1. Right-click (or Control-click) on OfficeViewer in Applications
2. Select **Open** from the context menu
3. Click **Open** in the dialog that appears

**Method 2: System Settings**
1. Try to open OfficeViewer (it will be blocked)
2. Open **System Settings** → **Privacy & Security**
3. Scroll down to find the message about OfficeViewer being blocked
4. Click **Open Anyway**
5. Enter your password if prompted

**Method 3: Terminal**
```bash
xattr -cr /Applications/OfficeViewer.app
```

## Requirements

- macOS 12+
- Xcode 14+ (for building)

## Why?

As developers working with Office files, we often need to inspect the underlying XML structure. The typical workflow involves:

1. Open folder containing Office file in VSCode
2. Install OOXML Viewer extension
3. Navigate and decode

OfficeViewer simplifies this to a single right-click action.

## License

MIT
