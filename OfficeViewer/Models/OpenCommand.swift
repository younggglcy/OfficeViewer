import Foundation

struct OpenCommand: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var command: String

    init(id: UUID = UUID(), name: String, command: String) {
        self.id = id
        self.name = name
        self.command = command
    }

    static let defaultCommands: [OpenCommand] = [
        OpenCommand(name: "VSCode", command: "code \"${folder}\""),
        OpenCommand(name: "Finder", command: "open \"${folder}\""),
    ]
}
