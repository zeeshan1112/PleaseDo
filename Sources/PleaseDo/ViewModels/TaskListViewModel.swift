import SwiftUI

public class TaskListViewModel: ObservableObject {
    @Published public var tasks: [TaskItem] = []
    @Published public var selectedCategory: TaskCategory = .work
    @Published public var newTaskTitle: String = ""
    
    private let repository: TaskRepository
    
    public init(repository: TaskRepository = LocalTaskRepository()) {
        self.repository = repository
        loadTasks()
    }
    
    public var filteredTasks: [TaskItem] {
        tasks.filter { $0.category == selectedCategory }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    public func loadTasks() {
        do {
            tasks = try repository.fetchTasks()
        } catch {
            print("Failed to load tasks: \(error)")
        }
    }
    
    private func saveTasks() {
        do {
            try repository.saveTasks(tasks)
        } catch {
            print("Failed to save tasks: \(error)")
        }
    }
    
    public func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let task = TaskItem(title: trimmed, category: selectedCategory)
        tasks.append(task)
        newTaskTitle = ""
        saveTasks()
    }
    
    public func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    public func clearCompleted() {
        tasks.removeAll { $0.category == selectedCategory && $0.isCompleted }
        saveTasks()
    }
}
