import Foundation

struct RecentFile: Codable, Identifiable, Equatable {
  let id: UUID
  let sourceFilePath: String
  let decodedFolderPath: String
  let fileName: String
  let openedAt: Date

  init(
    id: UUID = UUID(),
    sourceFilePath: String,
    decodedFolderPath: String,
    fileName: String,
    openedAt: Date = Date()
  ) {
    self.id = id
    self.sourceFilePath = sourceFilePath
    self.decodedFolderPath = decodedFolderPath
    self.fileName = fileName
    self.openedAt = openedAt
  }

  var sourceFileExists: Bool {
    FileManager.default.fileExists(atPath: sourceFilePath)
  }

  var decodedFolderExists: Bool {
    var isDirectory: ObjCBool = false
    return FileManager.default.fileExists(atPath: decodedFolderPath, isDirectory: &isDirectory)
      && isDirectory.boolValue
  }

  var fileExtension: String {
    (sourceFilePath as NSString).pathExtension.lowercased()
  }
}
