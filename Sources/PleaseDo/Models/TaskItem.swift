import Foundation

public struct AppData: Codable {
    public var categories: [String]
    public var tasks: [TaskItem]
    
    public init(categories: [String] = ["Work", "Personal"], tasks: [TaskItem] = []) {
        self.categories = categories
        self.tasks = tasks
    }
}

public struct TaskItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var category: String
    public var createdAt: Date
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
        self.createdAt = createdAt
    }
}
