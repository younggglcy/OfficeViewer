import AppKit
import Sparkle
import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.officeviewer", category: "main")

@main
struct OfficeViewerApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Settings {
      SettingsView()
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarItem: NSStatusItem?
  private var settingsWindow: NSWindow?
  private var updaterController: SPUStandardUpdaterController!

  func applicationDidFinishLaunching(_ notification: Notification) {
    updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
    NSApplication.shared.setActivationPolicy(.accessory)
    setupStatusBar()

    logger.info("App launched, args: \(CommandLine.arguments)")

    // Handle file passed via command line arguments
    if CommandLine.arguments.count > 1 {
      let filePath = CommandLine.arguments[1]
      logger.info("Processing file: \(filePath)")
      handleFile(at: filePath)
    }
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      handleFile(at: url.path)
    }
  }

  private func setupStatusBar() {
    statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusBarItem?.button {
      button.image = NSImage(
        systemSymbolName: "doc.text",
        accessibilityDescription: "OfficeViewer"
      )
    }

    let menu = NSMenu()
    menu.addItem(
      NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
    )
    menu.addItem(
      NSMenuItem(
        title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
    )
    menu.addItem(NSMenuItem.separator())
    menu.addItem(
      NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
    )

    statusBarItem?.menu = menu
  }

  private func handleFile(at path: String) {
    logger.info("handleFile called with: \(path)")
    do {
      let folderPath = try FileDecoder.decode(path)
      logger.info("Decoded to: \(folderPath)")

      guard let command = ConfigStore.shared.defaultCommand else {
        logger.error("No default command configured")
        showAlert(
          title: "No Command Configured", message: "Please configure a command in Settings.")
        return
      }

      logger.info("Running command: \(command.command)")
      try CommandRunner.run(command.command, folder: folderPath)
      logger.info("Command executed successfully")
    } catch {
      logger.error("Error: \(error.localizedDescription)")
      showAlert(title: "Error", message: error.localizedDescription)
    }
  }

  private func showAlert(title: String, message: String) {
    DispatchQueue.main.async {
      let alert = NSAlert()
      alert.messageText = title
      alert.informativeText = message
      alert.alertStyle = .warning
      alert.addButton(withTitle: "OK")
      alert.runModal()
    }
  }

  @objc private func openSettings() {
    if settingsWindow == nil {
      let hostingController = NSHostingController(rootView: SettingsView())
      let window = NSWindow(contentViewController: hostingController)
      window.title = "OfficeViewer Settings"
      window.styleMask = [.titled, .closable, .resizable]
      window.setContentSize(NSSize(width: 600, height: 500))
      window.minSize = NSSize(width: 600, height: 500)
      window.center()
      settingsWindow = window
    }

    settingsWindow?.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  @objc private func checkForUpdates() {
    updaterController.checkForUpdates(nil)
  }

  @objc private func quitApp() {
    NSApplication.shared.terminate(nil)
  }
}
