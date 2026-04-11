import SwiftUI

/**
 * The main ViewModel for the task application.
 * Manages state for tasks, categories, archiving, and business logic for task/category CRUD.
 * Coordinates between the UI and the persistence layer.
 */
public class TaskListViewModel: ObservableObject {
    /// Active tasks published to UI observers.
    @Published public var tasks: [TaskItem] = []
    
    /// Archived tasks stored separately from active tasks.
    @Published public var archivedTasks: [TaskItem] = []
    
    /// Available categories for task organization.
    @Published public var categories: [String] = []
    
    /// The currently selected category for filtering the task list.
    @Published public var selectedCategory: String = ""
    
    /// Transient bound text for the new task input field.
    @Published public var newTaskTitle: String = ""
    
    /// Controls visibility of the archive viewer overlay.
    @Published public var showingArchive: Bool = false
    
    /// Number of incomplete tasks, synced to AppStorage for the Menu Bar badge.
    @AppStorage("pendingCount") private var pendingTaskCount: Int = 0
    
    /// User preference for visibility of the pending task count in the menu bar.
    @Published public var showPendingCount: Bool {
        didSet {
            UserDefaults.standard.set(showPendingCount, forKey: "showPendingCount")
        }
    }
    
    /// Concrete backing layer handling IO interactions.
    private let repository: TaskRepository
    
    /// Hardcapped boundary for maximum categories allowed.
    private let maxCategories = 5
    
    /**
     * Provisions the ViewModel and performs initial data loading.
     * - Parameter repository: Backing storage implementation.
     */
    public init(repository: TaskRepository = LocalTaskRepository()) {
        self.repository = repository
        self.showPendingCount = UserDefaults.standard.object(forKey: "showPendingCount") as? Bool ?? true
        loadData()
    }
    
    /**
     * Derived list of tasks filtered by selected category and sorted by creation date.
     */
    public var filteredTasks: [TaskItem] {
        tasks.filter { $0.category == selectedCategory }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    /**
     * Indicates if the maximum category limit has been reached.
     */
    public var canAddCategory: Bool {
        categories.count < maxCategories
    }
    
    /**
     * Loads data from the repository and updates local state.
     * Falls back to default state if no data exists.
     */
    public func loadData() {
        do {
            let appData = try repository.fetchData()
            self.categories = appData.categories
            self.tasks = appData.tasks
            self.archivedTasks = appData.archivedTasks
            if !categories.isEmpty && selectedCategory.isEmpty {
                self.selectedCategory = categories[0]
            }
            pendingTaskCount = tasks.filter { !$0.isCompleted }.count
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    
    /**
     * Serializes the current state and persists it to the repository.
     */
    private func saveData() {
        let dataToSave = AppData(categories: categories, tasks: tasks, archivedTasks: archivedTasks)
        do {
            try repository.saveData(dataToSave)
            pendingTaskCount = tasks.filter { !$0.isCompleted }.count
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    // MARK: - Category Management
    
    /**
     * Adds a new category to the system.
     * - Parameter name: Raw string name for the new category.
     * - Returns: True if added successfully, false if invalid or limit reached.
     */
    public func addCategory(name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, canAddCategory, !categories.contains(trimmedName) else { return false }
        
        categories.append(trimmedName)
        selectedCategory = trimmedName
        saveData()
        return true
    }
    
    /**
     * Renames an existing category and migrates all assigned tasks.
     * - Parameters:
     *   - oldName: The current name of the category.
     *   - newName: The desired new name.
     * - Returns: True if renamed successfully.
     */
    public func renameCategory(oldName: String, newName: String) -> Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName != oldName, !categories.contains(trimmedName) else { return false }
        
        if let index = categories.firstIndex(of: oldName) {
            categories[index] = trimmedName
        }
        
        for i in 0..<tasks.count {
            if tasks[i].category == oldName {
                tasks[i].category = trimmedName
            }
        }
        
        for i in 0..<archivedTasks.count {
            if archivedTasks[i].category == oldName {
                archivedTasks[i].category = trimmedName
            }
        }
        
        if selectedCategory == oldName {
            selectedCategory = trimmedName
        }
        
        saveData()
        return true
    }
    
    /**
     * Removes a category and all associated tasks (active and archived).
     * - Parameter name: Name of the category to delete.
     */
    public func deleteCategory(_ name: String) {
        guard categories.count > 1 else { return }
        
        categories.removeAll { $0 == name }
        tasks.removeAll { $0.category == name }
        archivedTasks.removeAll { $0.category == name }
        
        if selectedCategory == name {
            selectedCategory = categories.first ?? ""
        }
        saveData()
    }
    
    // MARK: - Task Management
    
    /**
     * Creates a new task in the currently selected category.
     */
    public func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedCategory.isEmpty else { return }
        
        let task = TaskItem(title: trimmed, category: selectedCategory)
        tasks.append(task)
        newTaskTitle = ""
        saveData()
    }
    
    /**
     * Toggles the completion state for a specific task.
     * - Parameter task: The task item to update.
     */
    public func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveData()
        }
    }
    
    /**
     * Permanently deletes a task.
     * - Parameter task: The task item to remove.
     */
    public func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    /**
     * Clears all completed tasks within the selected category.
     */
    public func clearCompleted() {
        tasks.removeAll { $0.category == selectedCategory && $0.isCompleted }
        saveData()
    }
    
    /**
     * Permanently removes every task associated with the currently selected category.
     */
    public func clearAllInSelectedCategory() {
        tasks.removeAll { $0.category == selectedCategory }
        saveData()
    }
    
    // MARK: - Archive Management
    
    /**
     * Archives a single completed task by moving it from active tasks to the archive.
     * Stamps the task with the current date as its archivedAt timestamp.
     * - Parameter task: The completed task to archive.
     */
    public func archiveTask(_ task: TaskItem) {
        guard task.isCompleted else { return }
        
        var archivedCopy = task
        archivedCopy.archivedAt = Date()
        archivedTasks.append(archivedCopy)
        tasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    /**
     * Archives all completed tasks in the currently selected category.
     */
    public func archiveCompletedInSelectedCategory() {
        let completed = tasks.filter { $0.category == selectedCategory && $0.isCompleted }
        for var task in completed {
            task.archivedAt = Date()
            archivedTasks.append(task)
        }
        tasks.removeAll { $0.category == selectedCategory && $0.isCompleted }
        saveData()
    }
    
    /**
     * Permanently deletes an archived task.
     * - Parameter task: The archived task to purge.
     */
    public func deleteArchivedTask(_ task: TaskItem) {
        archivedTasks.removeAll { $0.id == task.id }
        saveData()
    }
}
