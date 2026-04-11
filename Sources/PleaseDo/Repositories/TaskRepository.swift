import Foundation

public protocol TaskRepository {
    func fetchTasks() throws -> [TaskItem]
    func saveTasks(_ tasks: [TaskItem]) throws
}
