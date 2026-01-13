import AppKit
import SwiftUI

struct RecentFilesView: View {
  @ObservedObject private var store = ConfigStore.shared
  @State private var hoveredFileId: UUID?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      HStack {
        Text("Recent Files")
          .font(.title2)
          .fontWeight(.semibold)

        Spacer()

        if !store.recentFiles.isEmpty {
          Button(action: { store.clearRecentFiles() }) {
            Text("Clear All")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .buttonStyle(.plain)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(6)
        }
      }
      .padding(.bottom, 16)

      if store.recentFiles.isEmpty {
        emptyState
      } else {
        fileList
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 12) {
      Spacer()
      Image(systemName: "clock.arrow.circlepath")
        .font(.system(size: 48))
        .foregroundColor(.secondary.opacity(0.5))
      Text("No Recent Files")
        .font(.headline)
        .foregroundColor(.secondary)
      Text("Files you open will appear here")
        .font(.caption)
        .foregroundColor(.secondary.opacity(0.8))
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var fileList: some View {
    ScrollView {
      LazyVStack(spacing: 8) {
        ForEach(store.recentFiles) { file in
          RecentFileRow(
            file: file,
            isHovered: hoveredFileId == file.id,
            onRemove: { store.removeRecentFile(file) }
          )
          .onHover { isHovered in
            hoveredFileId = isHovered ? file.id : nil
          }
        }
      }
      .padding(.vertical, 4)
    }
  }
}

struct RecentFileRow: View {
  let file: RecentFile
  let isHovered: Bool
  let onRemove: () -> Void

  private var fileIcon: String {
    switch file.fileExtension {
    case "docx": return "doc.fill"
    case "xlsx": return "tablecells.fill"
    case "pptx": return "play.rectangle.fill"
    default: return "doc.fill"
    }
  }

  private var fileIconColor: Color {
    switch file.fileExtension {
    case "docx": return .blue
    case "xlsx": return .green
    case "pptx": return .orange
    default: return .gray
    }
  }

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 12) {
        // File Icon
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(fileIconColor.opacity(0.15))
            .frame(width: 40, height: 40)
          Image(systemName: fileIcon)
            .font(.system(size: 18))
            .foregroundColor(fileIconColor)
        }

        // File Info
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(file.fileName)
              .font(.system(size: 13, weight: .medium))
              .lineLimit(1)

            if !file.sourceFileExists {
              StatusBadge(text: "Source Missing", color: .red)
            }
          }

          Text(dateFormatter.string(from: file.openedAt))
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        // Action Buttons
        HStack(spacing: 4) {
          if file.decodedFolderExists {
            Button(action: { openInFinder(path: file.decodedFolderPath) }) {
              Image(systemName: "folder")
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Open decoded folder in Finder")
          } else {
            Image(systemName: "folder.badge.questionmark")
              .font(.system(size: 14))
              .foregroundColor(.secondary.opacity(0.5))
              .frame(width: 28, height: 28)
              .help("Decoded folder no longer exists")
          }

          Button(action: onRemove) {
            Image(systemName: "xmark")
              .font(.system(size: 11, weight: .medium))
              .foregroundColor(.secondary)
              .frame(width: 24, height: 24)
              .background(Color.secondary.opacity(isHovered ? 0.15 : 0))
              .cornerRadius(6)
          }
          .buttonStyle(.plain)
          .opacity(isHovered ? 1 : 0)
        }
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(isHovered ? Color.secondary.opacity(0.08) : Color.clear)
      )

      // Path Details
      VStack(alignment: .leading, spacing: 6) {
        PathRow(
          icon: "doc",
          label: "Source",
          path: file.sourceFilePath,
          exists: file.sourceFileExists
        )
        PathRow(
          icon: "folder",
          label: "Decoded",
          path: file.decodedFolderPath,
          exists: file.decodedFolderExists
        )
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 12)
      .padding(.leading, 52)
    }
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(nsColor: .controlBackgroundColor))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    )
  }

  private func openInFinder(path: String) {
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
  }
}

struct PathRow: View {
  let icon: String
  let label: String
  let path: String
  let exists: Bool

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .font(.system(size: 10))
        .foregroundColor(.secondary)
        .frame(width: 14)

      Text("\(label):")
        .font(.system(size: 10))
        .foregroundColor(.secondary)
        .frame(width: 50, alignment: .leading)

      Text(path)
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(exists ? .secondary : .red.opacity(0.8))
        .lineLimit(1)
        .truncationMode(.middle)

      if !exists {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 9))
          .foregroundColor(.red.opacity(0.8))
      }
    }
  }
}

struct StatusBadge: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.system(size: 9, weight: .medium))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(color.opacity(0.15))
      .foregroundColor(color)
      .cornerRadius(4)
  }
}
