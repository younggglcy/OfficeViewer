import Foundation

enum FileDecoderError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String)
    case directoryCreationFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .decodingFailed(let message):
            return "Failed to decode file: \(message)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"
        }
    }
}

enum FileDecoder {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    private static var cacheDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Caches/OfficeViewer")
    }

    static func decode(_ filePath: String) throws -> String {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: filePath) else {
            throw FileDecoderError.fileNotFound(filePath)
        }

        // Create cache directory if needed
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                throw FileDecoderError.directoryCreationFailed(cacheDirectory.path)
            }
        }

        // Generate unique folder name: filename_yyyyMMdd_HHmmss
        let fileName = (filePath as NSString).lastPathComponent.replacingOccurrences(of: ".", with: "_")
        let timestamp = dateFormatter.string(from: Date())
        let folderName = "\(fileName)_\(timestamp)"
        let outputDir = cacheDirectory.appendingPathComponent(folderName)

        // Run unzip
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", filePath, "-d", outputDir.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw FileDecoderError.decodingFailed(error.localizedDescription)
        }

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw FileDecoderError.decodingFailed(errorMessage)
        }

        // Format all XML files for better readability
        formatXMLFiles(in: outputDir)

        return outputDir.path
    }

    private static func formatXMLFiles(in directory: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "xml" else { continue }

            // Use xmllint to format the XML file
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xmllint")
            process.arguments = ["--format", "--output", fileURL.path, fileURL.path]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            try? process.run()
            process.waitUntilExit()
        }
    }
}
