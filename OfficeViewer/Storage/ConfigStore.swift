import Combine
import Foundation

class ConfigStore: ObservableObject {
    static let shared = ConfigStore()

    private let commandsKey = "openCommands"
    private let defaultCommandIdKey = "defaultCommandId"

    @Published var commands: [OpenCommand] {
        didSet { saveCommands() }
    }

    @Published var defaultCommandId: UUID? {
        didSet { saveDefaultCommandId() }
    }

    var defaultCommand: OpenCommand? {
        guard let id = defaultCommandId else {
            return commands.first
        }
        return commands.first { $0.id == id } ?? commands.first
    }

    private init() {
        self.commands = []
        self.defaultCommandId = nil
        loadCommands()
        loadDefaultCommandId()
    }

    private func loadCommands() {
        guard let data = UserDefaults.standard.data(forKey: commandsKey),
              let decoded = try? JSONDecoder().decode([OpenCommand].self, from: data)
        else {
            commands = OpenCommand.defaultCommands
            return
        }
        commands = decoded.isEmpty ? OpenCommand.defaultCommands : decoded
    }

    private func saveCommands() {
        guard let data = try? JSONEncoder().encode(commands) else { return }
        UserDefaults.standard.set(data, forKey: commandsKey)
    }

    private func loadDefaultCommandId() {
        guard let uuidString = UserDefaults.standard.string(forKey: defaultCommandIdKey),
              let uuid = UUID(uuidString: uuidString)
        else {
            defaultCommandId = commands.first?.id
            return
        }
        defaultCommandId = uuid
    }

    private func saveDefaultCommandId() {
        UserDefaults.standard.set(defaultCommandId?.uuidString, forKey: defaultCommandIdKey)
    }

    func addCommand(_ command: OpenCommand) {
        commands.append(command)
        if commands.count == 1 {
            defaultCommandId = command.id
        }
    }

    func removeCommand(at index: Int) {
        let removed = commands.remove(at: index)
        if defaultCommandId == removed.id {
            defaultCommandId = commands.first?.id
        }
    }

    func updateCommand(_ command: OpenCommand) {
        if let index = commands.firstIndex(where: { $0.id == command.id }) {
            commands[index] = command
        }
    }
}
