import SwiftUI

struct SettingsView: View {
  @ObservedObject private var store = ConfigStore.shared
  @State private var editingCommand: OpenCommand?
  @State private var isAddingNew = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Open Commands")
        .font(.title2)
        .fontWeight(.semibold)

      Text(
        "Configure CLI commands to open decoded Office files. Use ${folder} as placeholder for the folder path."
      )
      .font(.caption)
      .foregroundColor(.secondary)

      List {
        ForEach(store.commands) { command in
          CommandRow(
            command: command,
            isDefault: store.defaultCommandId == command.id,
            onSetDefault: { store.defaultCommandId = command.id },
            onEdit: { editingCommand = command },
            onDelete: {
              if let index = store.commands.firstIndex(where: { $0.id == command.id }) {
                store.removeCommand(at: index)
              }
            }
          )
        }
      }
      .listStyle(.bordered)
      .frame(minHeight: 200)

      HStack {
        Button(action: { isAddingNew = true }) {
          Label("Add Command", systemImage: "plus")
        }

        Spacer()

        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0")")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(20)
    .frame(minWidth: 500, minHeight: 400)
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

struct CommandRow: View {
  let command: OpenCommand
  let isDefault: Bool
  let onSetDefault: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(command.name)
            .fontWeight(.medium)
          if isDefault {
            Text("Default")
              .font(.caption2)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.accentColor.opacity(0.2))
              .foregroundColor(.accentColor)
              .cornerRadius(4)
          }
        }
        Text(command.command)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }

      Spacer()

      HStack(spacing: 8) {
        if !isDefault {
          Button("Set Default") {
            onSetDefault()
          }
          .buttonStyle(.borderless)
          .font(.caption)
        }

        Button(action: onEdit) {
          Image(systemName: "pencil")
        }
        .buttonStyle(.borderless)

        Button(action: onDelete) {
          Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .foregroundColor(.red)
      }
    }
    .padding(.vertical, 4)
  }
}

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
    VStack(alignment: .leading, spacing: 16) {
      Text(originalCommand.name.isEmpty ? "Add Command" : "Edit Command")
        .font(.title2)
        .fontWeight(.semibold)

      VStack(alignment: .leading, spacing: 8) {
        Text("Name")
          .font(.caption)
          .foregroundColor(.secondary)
        TextField("e.g. VSCode", text: $name)
          .textFieldStyle(.roundedBorder)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Command")
          .font(.caption)
          .foregroundColor(.secondary)
        TextField("e.g. code \"${folder}\"", text: $command)
          .textFieldStyle(.roundedBorder)
          .font(.system(.body, design: .monospaced))
        Text("${folder} will be replaced with the decoded folder path")
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      HStack {
        Button("Cancel", action: onCancel)
          .keyboardShortcut(.cancelAction)

        Spacer()

        Button("Save") {
          let updated = OpenCommand(
            id: originalCommand.id,
            name: name.trimmingCharacters(in: .whitespaces),
            command: command.trimmingCharacters(in: .whitespaces)
          )
          onSave(updated)
        }
        .keyboardShortcut(.defaultAction)
        .disabled(!isValid)
      }
      .padding(.top, 8)
    }
    .padding(20)
    .frame(width: 400)
  }
}
