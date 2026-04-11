import Foundation

/**
 * Represents the top-level container for all application data persisted locally.
 * This acts as the schema wrap for the JSON database, ensuring custom categories,
 * active tasks, and archived tasks stay synchronized across application restarts.
 */
public struct AppData: Codable {
    /// An ordered list of user-defined category names (e.g., "Work", "Personal").
    public var categories: [String]
    /// The array of active (non-archived) user tasks.
    public var tasks: [TaskItem]
    /// The array of tasks that have been archived by the user.
    public var archivedTasks: [TaskItem]
    
    /**
     * Initializes a new application data construct.
     * - Parameters:
     *   - categories: The initial structural categories. Defaults to "Work" and "Personal".
     *   - tasks: The collection of active tasks.
     *   - archivedTasks: The collection of archived tasks. Defaults to empty.
     */
    public init(categories: [String] = ["Work", "Personal"], tasks: [TaskItem] = [], archivedTasks: [TaskItem] = []) {
        self.categories = categories
        self.tasks = tasks
        self.archivedTasks = archivedTasks
    }
}

/**
 * A discrete unit of work defined by the user.
 * Contains all metadata required to render, sort, persist, and archive a single task.
 */
public struct TaskItem: Identifiable, Codable, Hashable {
    /// A unique identifier generated automatically upon task creation.
    public var id: UUID
    /// The content of the task displayed in the UI.
    public var title: String
    /// Tracks if the task has been marked complete by the user.
    public var isCompleted: Bool
    /// The category name this task resides under.
    public var category: String
    /// The timestamp when this task was created, used for sorting.
    public var createdAt: Date
    /// The timestamp when this task was archived. Nil if the task is still active.
    public var archivedAt: Date?
    
    /**
     * Constructs a new TaskItem.
     * - Parameters:
     *   - id: Unique identifier, defaults to a new UUID.
     *   - title: The primary task text.
     *   - isCompleted: Initial completion state. Defaults to false.
     *   - category: The category this task belongs to.
     *   - createdAt: Creation date. Defaults to current time.
     *   - archivedAt: Archive date. Defaults to nil.
     */
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: String, createdAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}
