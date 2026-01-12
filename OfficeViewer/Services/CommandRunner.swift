import Foundation

enum CommandRunnerError: LocalizedError {
  case executionFailed(String)
  case noPlaceholder

  var errorDescription: String? {
    switch self {
    case .executionFailed(let message):
      return "Command failed: \(message)"
    case .noPlaceholder:
      return "Command must contain ${folder} placeholder"
    }
  }
}

enum CommandRunner {
  static func run(_ commandTemplate: String, folder: String) throws {
    let command = commandTemplate.replacingOccurrences(of: "${folder}", with: folder)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]

    // Set PATH to include common locations for CLI tools
    var environment = ProcessInfo.processInfo.environment
    let additionalPaths = [
      "/usr/local/bin",
      "/opt/homebrew/bin",
      "/usr/bin",
      "/bin",
    ]
    let existingPath = environment["PATH"] ?? ""
    environment["PATH"] = (additionalPaths + [existingPath]).joined(separator: ":")
    process.environment = environment

    let errorPipe = Pipe()
    process.standardError = errorPipe
    process.standardOutput = FileHandle.nullDevice

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      throw CommandRunnerError.executionFailed(error.localizedDescription)
    }

    if process.terminationStatus != 0 {
      let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
      let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
      throw CommandRunnerError.executionFailed(
        errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
    }
  }
}
