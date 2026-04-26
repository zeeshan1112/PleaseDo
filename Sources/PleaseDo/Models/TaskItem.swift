import Foundation

public struct AppData: Codable {
    public var categories: [String]
    public var tasks: [TaskItem]
    public var archivedCount: Int
    
    public init(categories: [String] = ["Work", "Personal"], tasks: [TaskItem] = [], archivedCount: Int = 0) {
        self.categories = categories
        self.tasks = tasks
        self.archivedCount = archivedCount
    }
}

public struct TaskItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var category: String
    public var orderIndex: Int
    public var createdAt: Date
    public var completedAt: Date?
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: String, orderIndex: Int = 0, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, category, orderIndex, createdAt, completedAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        category = try container.decode(String.self, forKey: .category)
        orderIndex = try container.decodeIfPresent(Int.self, forKey: .orderIndex) ?? 0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}