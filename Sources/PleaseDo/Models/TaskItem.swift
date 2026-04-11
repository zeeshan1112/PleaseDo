import Foundation

public enum TaskCategory: String, Codable, CaseIterable {
    case work = "Work"
    case personal = "Personal"
}

public struct TaskItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var category: TaskCategory
    public var createdAt: Date
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: TaskCategory, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
        self.createdAt = createdAt
    }
}
