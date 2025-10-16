import Foundation
import SwiftUI
internal import Combine

class OfficeViewerViewModel: ObservableObject {
  static var shared: OfficeViewerViewModel?

  // MARK: - Published Properties
  @Published var selectedFilePath: String?
  @Published var decodedFolderPath: String?
  @Published var availableApps: [AppInfo] = []
  @Published var selectedApp: AppInfo? {
    didSet {
      // Persist selected app to UserDefaults
      if let selectedApp = selectedApp {
        UserDefaults.standard.set(selectedApp.path, forKey: "selectedAppPath")
      }
    }
  }
  @Published var isProcessing = false
  @Published var errorMessage: String?
  @Published var successMessage: String?

  private let fileService = FileService()

  init() {
    OfficeViewerViewModel.shared = self
    loadAvailableApps()
    loadSavedAppSelection()
  }

  // MARK: - File Handling
  func handleFileOpened(at filePath: String) {
    selectedFilePath = filePath
    decodeFile()
  }

  // MARK: - Decoding
  func decodeFile() {
    guard let filePath = selectedFilePath else {
      errorMessage = "❌ No file selected"
      return
    }

    isProcessing = true
    errorMessage = nil

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      do {
        let decodedPath = try self?.fileService.decodeOfficeFile(at: filePath)

        DispatchQueue.main.async {
          self?.decodedFolderPath = decodedPath
          self?.successMessage = "✅ File decoded: \(decodedPath ?? "")"
          self?.isProcessing = false

          // Auto-open with selected app
          if let decodedPath = decodedPath, let app = self?.selectedApp {
            self?.openFolderWithApp(decodedPath, using: app)
          }
        }
      } catch {
        DispatchQueue.main.async {
          self?.errorMessage = "❌ Decoding failed: \(error.localizedDescription)"
          self?.isProcessing = false
        }
      }
    }
  }

  // MARK: - App Management
  func loadAvailableApps() {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.availableApps = self?.fileService.getAvailableApps() ?? []

      DispatchQueue.main.async {
        if self?.selectedApp == nil {
          self?.selectedApp = self?.availableApps.first { $0.name == "Finder" }
        }
      }
    }
  }

  private func loadSavedAppSelection() {
    if let savedPath = UserDefaults.standard.string(forKey: "selectedAppPath") {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.selectedApp = self.availableApps.first { $0.path == savedPath }
      }
    }
  }

  func openFolderWithApp(_ folderPath: String, using app: AppInfo) {
    do {
      try fileService.openFolderWithApp(at: folderPath, using: app)
      successMessage = "✅ Opened with \(app.name)"
    } catch {
      errorMessage = "❌ Failed to open: \(error.localizedDescription)"
    }
  }
}
