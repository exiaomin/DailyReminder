import Foundation

struct ReminderItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), name: String, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}