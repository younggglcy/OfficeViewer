import AppKit
import Foundation

class FileService {
  // MARK: - File Decoding
  func decodeOfficeFile(at filePath: String) throws -> String {
    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: filePath) else {
      throw FileServiceError.fileNotFound
    }

    let tempDir = NSTemporaryDirectory()
    let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
    let decodedFolderPath = (tempDir as NSString)
      .appendingPathComponent("\(fileName)_decoded_\(UUID().uuidString)")

    try fileManager.createDirectory(
      atPath: decodedFolderPath,
      withIntermediateDirectories: true,
      attributes: nil
    )

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    process.arguments = ["-q", filePath, "-d", decodedFolderPath]

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw FileServiceError.decodingFailed("unzip command execution failed")
    }

    print("✅ File decoded to: \(decodedFolderPath)")
    return decodedFolderPath
  }

  // MARK: - App Discovery
  func getAvailableApps() -> [AppInfo] {
    let fileManager = FileManager.default
    let applicationPaths = [
      "/Applications",
      "/System/Applications",
      NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true)
        .first ?? "",
    ]

    var apps: [AppInfo] = []

    for path in applicationPaths {
      do {
        let appNames = try fileManager.contentsOfDirectory(atPath: path)
        for appName in appNames {
          if appName.hasSuffix(".app") {
            let fullPath = (path as NSString).appendingPathComponent(appName)

            if let bundle = Bundle(path: fullPath),
              let executablePath = bundle.executablePath
            {
              let displayName = appName.replacingOccurrences(of: ".app", with: "")

              if shouldIncludeApp(displayName) {
                apps.append(
                  AppInfo(
                    name: displayName,
                    path: fullPath,
                    executablePath: executablePath
                  ))
              }
            }
          }
        }
      } catch {
        print("⚠️ Failed to read application directory: \(path)")
      }
    }

    let uniqueApps = Array(Set(apps)).sorted { $0.name < $1.name }

    var result = uniqueApps.filter { $0.name == "Finder" }
    result.append(contentsOf: uniqueApps.filter { $0.name != "Finder" })

    return result
  }

  // MARK: - App Launching
  func openFolderWithApp(at folderPath: String, using app: AppInfo) throws {
    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: folderPath) else {
      throw FileServiceError.fileNotFound
    }

    let folderURL = URL(fileURLWithPath: folderPath)
    let workspace = NSWorkspace.shared

    if app.name == "Finder" {
      workspace.selectFile(folderPath, inFileViewerRootedAtPath: "")
    } else {
      let appURL = URL(fileURLWithPath: app.path)
      do {
        try workspace.open(
          [folderURL], withApplicationAt: appURL, options: [],
          configuration: [:])
      } catch {
        throw FileServiceError.openingFailed("Unable to open app: \(app.name)")
      }
    }

    print("✅ Opened with \(app.name): \(folderPath)")
  }

  // MARK: - Helpers
  private func shouldIncludeApp(_ name: String) -> Bool {
    let blacklist = [
      "com.apple",
      "System",
      "Simulator",
      "Assistant",
    ]

    for item in blacklist {
      if name.contains(item) {
        return false
      }
    }

    return true
  }
}

// MARK: - Data Models
struct AppInfo: Identifiable, Hashable {
  let id = UUID()
  let name: String
  let path: String
  let executablePath: String

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(path)
  }

  static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
    lhs.path == rhs.path
  }
}

enum FileServiceError: LocalizedError {
  case fileNotFound
  case decodingFailed(String)
  case openingFailed(String)

  var errorDescription: String? {
    switch self {
    case .fileNotFound:
      return "File not found"
    case .decodingFailed(let message):
      return "Decoding failed: \(message)"
    case .openingFailed(let message):
      return "Opening failed: \(message)"
    }
  }
}
