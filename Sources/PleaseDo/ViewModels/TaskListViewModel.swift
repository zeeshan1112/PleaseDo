import SwiftUI

public class TaskListViewModel: ObservableObject {
    @Published public var tasks: [TaskItem] = []
    @Published public var categories: [String] = []
    @Published public var selectedCategory: String = ""
    @Published public var newTaskTitle: String = ""
    
    private let repository: TaskRepository
    private let maxCategories = 5
    
    public init(repository: TaskRepository = LocalTaskRepository()) {
        self.repository = repository
        loadData()
    }
    
    public var filteredTasks: [TaskItem] {
        tasks.filter { $0.category == selectedCategory }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    public var canAddCategory: Bool {
        categories.count < maxCategories
    }
    
    public func loadData() {
        do {
            let appData = try repository.fetchData()
            self.categories = appData.categories
            self.tasks = appData.tasks
            if !categories.isEmpty && selectedCategory.isEmpty {
                self.selectedCategory = categories[0]
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    
    private func saveData() {
        let dataToSave = AppData(categories: categories, tasks: tasks)
        do {
            try repository.saveData(dataToSave)
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    // Category Actions
    public func addCategory(name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, canAddCategory, !categories.contains(trimmedName) else { return false }
        
        categories.append(trimmedName)
        selectedCategory = trimmedName
        saveData()
        return true
    }
    
    public func deleteCategory(_ name: String) {
        // Prevent deleting if it's the last category
        guard categories.count > 1 else { return }
        
        categories.removeAll { $0 == name }
        // Optional: remove all tasks assigned to that category
        tasks.removeAll { $0.category == name }
        
        if selectedCategory == name {
            selectedCategory = categories.first ?? ""
        }
        saveData()
    }
    
    // Task Actions
    public func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedCategory.isEmpty else { return }
        
        let task = TaskItem(title: trimmed, category: selectedCategory)
        tasks.append(task)
        newTaskTitle = ""
        saveData()
    }
    
    public func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveData()
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    public func clearCompleted() {
        tasks.removeAll { $0.category == selectedCategory && $0.isCompleted }
        saveData()
    }
}
