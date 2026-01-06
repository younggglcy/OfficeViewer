# OfficeViewer

A macOS menu bar app for developers to quickly inspect Office file internals.

## What it does

Office files (.docx, .xlsx, .pptx) are actually ZIP archives containing XML files. OfficeViewer extracts these files and opens them with your preferred editor, making it easy to inspect the underlying OOXML structure.

## Installation

```bash
# Clone and build
git clone https://github.com/younggglcy/OfficeViewer.git
cd OfficeViewer
xcodebuild -scheme OfficeViewer -configuration Release build

# Install
cp -r ~/Library/Developer/Xcode/DerivedData/OfficeViewer-*/Build/Products/Release/OfficeViewer.app /Applications/

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f /Applications/OfficeViewer.app
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
