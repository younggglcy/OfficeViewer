import AppKit
import SwiftUI

@main
struct OfficeViewerApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Settings {
      SettingsView()
        .environmentObject(appDelegate.viewModel)
    }
  }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
  let viewModel = OfficeViewerViewModel()
  private var statusBarItem: NSStatusItem?

  func applicationDidFinishLaunching(_ notification: Notification) {
    print("✅ Application launched")
    print("📋 Command line arguments: \(CommandLine.arguments)")

    // Hide the dock icon
    NSApplication.shared.setActivationPolicy(.accessory)

    // Setup status bar menu
    setupStatusBar()

    // Handle file passed from Finder "Open With"
    if CommandLine.arguments.count > 1 {
      let filePath = CommandLine.arguments[1]
      print("📂 Received file: \(filePath)")

      DispatchQueue.main.async {
        self.viewModel.handleFileOpened(at: filePath)
      }
    }
  }

  private func setupStatusBar() {
    statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusBarItem?.button {
      button.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "OfficeViewer")
      button.action = #selector(toggleSettings)
      button.target = self
    }

    let menu = NSMenu()
    menu.addItem(
      NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

    statusBarItem?.menu = menu
  }

  @objc private func openSettings() {
    NSApplication.shared.activate(ignoringOtherApps: true)
    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
  }

  @objc private func toggleSettings() {
    openSettings()
  }

  @objc private func quitApp() {
    NSApplication.shared.terminate(nil)
  }
}
