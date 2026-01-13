import SwiftUI

enum SettingsTab: String, CaseIterable {
  case commands = "Commands"
  case recentFiles = "Recent Files"

  var icon: String {
    switch self {
    case .commands: return "terminal"
    case .recentFiles: return "clock.arrow.circlepath"
    }
  }
}

struct SettingsView: View {
  @State private var selectedTab: SettingsTab = .commands

  var body: some View {
    VStack(spacing: 0) {
      // Tab Bar
      HStack(spacing: 4) {
        ForEach(SettingsTab.allCases, id: \.self) { tab in
          TabButton(
            title: tab.rawValue,
            icon: tab.icon,
            isSelected: selectedTab == tab
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              selectedTab = tab
            }
          }
        }
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
      .padding(.bottom, 12)

      Divider()
        .padding(.horizontal, 16)

      // Content
      Group {
        switch selectedTab {
        case .commands:
          CommandsView()
        case .recentFiles:
          RecentFilesView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(20)

      Divider()
        .padding(.horizontal, 16)

      // Footer
      SettingsFooter()
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    .frame(minWidth: 600, minHeight: 500)
    .background(Color(nsColor: .windowBackgroundColor))
  }
}

struct TabButton: View {
  let title: String
  let icon: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.system(size: 12))
        Text(title)
          .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
      )
      .foregroundColor(isSelected ? .accentColor : .secondary)
    }
    .buttonStyle(.plain)
  }
}

struct SettingsFooter: View {
  private let githubURL = "https://github.com/younggglcy/OfficeViewer"

  var body: some View {
    HStack {
      // GitHub Link
      Button(action: openGitHub) {
        HStack(spacing: 6) {
          Image(systemName: "link")
            .font(.system(size: 11))
          Text("GitHub")
            .font(.system(size: 12))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
      }
      .buttonStyle(.plain)
      .help("Open project on GitHub")

      Spacer()

      // Version
      Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0")")
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
  }

  private func openGitHub() {
    if let url = URL(string: githubURL) {
      NSWorkspace.shared.open(url)
    }
  }
}

// MARK: - Commands View

struct CommandsView: View {
  @ObservedObject private var store = ConfigStore.shared
  @State private var editingCommand: OpenCommand?
  @State private var isAddingNew = false
  @State private var hoveredCommandId: UUID?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      VStack(alignment: .leading, spacing: 8) {
        Text("Open Commands")
          .font(.title2)
          .fontWeight(.semibold)

        Text(
          "Configure CLI commands to open decoded Office files. Use ${folder} as placeholder for the folder path."
        )
        .font(.caption)
        .foregroundColor(.secondary)
      }
      .padding(.bottom, 16)

      // Command List
      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(store.commands) { command in
            CommandCard(
              command: command,
              isDefault: store.defaultCommandId == command.id,
              isHovered: hoveredCommandId == command.id,
              onSetDefault: { store.defaultCommandId = command.id },
              onEdit: { editingCommand = command },
              onDelete: {
                if let index = store.commands.firstIndex(where: { $0.id == command.id }) {
                  withAnimation(.easeOut(duration: 0.2)) {
                    store.removeCommand(at: index)
                  }
                }
              }
            )
            .onHover { isHovered in
              hoveredCommandId = isHovered ? command.id : nil
            }
          }
        }
        .padding(.vertical, 4)
      }

      Spacer()

      // Add Button
      HStack {
        Button(action: { isAddingNew = true }) {
          HStack(spacing: 6) {
            Image(systemName: "plus")
              .font(.system(size: 12, weight: .semibold))
            Text("Add Command")
              .font(.system(size: 13, weight: .medium))
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .padding(.top, 16)
    }
    .sheet(item: $editingCommand) { command in
      CommandEditor(
        command: command,
        onSave: { updated in
          store.updateCommand(updated)
          editingCommand = nil
        },
        onCancel: { editingCommand = nil }
      )
    }
    .sheet(isPresented: $isAddingNew) {
      CommandEditor(
        command: OpenCommand(name: "", command: ""),
        onSave: { newCommand in
          store.addCommand(newCommand)
          isAddingNew = false
        },
        onCancel: { isAddingNew = false }
      )
    }
  }
}

struct CommandCard: View {
  let command: OpenCommand
  let isDefault: Bool
  let isHovered: Bool
  let onSetDefault: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      // Icon
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.accentColor.opacity(0.15))
          .frame(width: 40, height: 40)
        Image(systemName: "terminal")
          .font(.system(size: 16))
          .foregroundColor(.accentColor)
      }

      // Info
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(command.name)
            .font(.system(size: 14, weight: .medium))

          if isDefault {
            Text("Default")
              .font(.system(size: 10, weight: .medium))
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(Color.accentColor.opacity(0.15))
              .foregroundColor(.accentColor)
              .cornerRadius(4)
          }
        }

        Text(command.command)
          .font(.system(size: 12, design: .monospaced))
          .foregroundColor(.secondary)
          .lineLimit(1)
      }

      Spacer()

      // Actions
      HStack(spacing: 4) {
        if !isDefault {
          Button(action: onSetDefault) {
            Text("Set Default")
              .font(.system(size: 11, weight: .medium))
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(Color.secondary.opacity(0.1))
              .foregroundColor(.secondary)
              .cornerRadius(6)
          }
          .buttonStyle(.plain)
          .opacity(isHovered ? 1 : 0)
        }

        Button(action: onEdit) {
          Image(systemName: "pencil")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(width: 28, height: 28)
            .background(Color.secondary.opacity(isHovered ? 0.1 : 0))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0.5)

        Button(action: onDelete) {
          Image(systemName: "trash")
            .font(.system(size: 12))
            .foregroundColor(.red.opacity(0.8))
            .frame(width: 28, height: 28)
            .background(Color.red.opacity(isHovered ? 0.1 : 0))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0.5)
      }
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(nsColor: .controlBackgroundColor))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
    )
  }
}

// MARK: - Command Editor

struct CommandEditor: View {
  @State private var name: String
  @State private var command: String
  let originalCommand: OpenCommand
  let onSave: (OpenCommand) -> Void
  let onCancel: () -> Void

  init(
    command: OpenCommand, onSave: @escaping (OpenCommand) -> Void, onCancel: @escaping () -> Void
  ) {
    self.originalCommand = command
    self._name = State(initialValue: command.name)
    self._command = State(initialValue: command.command)
    self.onSave = onSave
    self.onCancel = onCancel
  }

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty
      && !command.trimmingCharacters(in: .whitespaces).isEmpty
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Header
      Text(originalCommand.name.isEmpty ? "Add Command" : "Edit Command")
        .font(.title2)
        .fontWeight(.semibold)

      // Form
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Name")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
          TextField("e.g. VSCode", text: $name)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 14))
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Command")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
          TextField("e.g. code \"${folder}\"", text: $command)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 14, design: .monospaced))

          HStack(spacing: 4) {
            Image(systemName: "info.circle")
              .font(.system(size: 10))
            Text("${folder} will be replaced with the decoded folder path")
              .font(.system(size: 11))
          }
          .foregroundColor(.secondary)
        }
      }

      Spacer()

      // Actions
      HStack {
        Button("Cancel", action: onCancel)
          .keyboardShortcut(.cancelAction)

        Spacer()

        Button(action: {
          let updated = OpenCommand(
            id: originalCommand.id,
            name: name.trimmingCharacters(in: .whitespaces),
            command: command.trimmingCharacters(in: .whitespaces)
          )
          onSave(updated)
        }) {
          Text("Save")
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(isValid ? Color.accentColor : Color.secondary.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(!isValid)
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(24)
    .frame(width: 420, height: 280)
  }
}
