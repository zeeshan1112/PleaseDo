import SwiftUI

/**
 * The main ViewModel for the task application.
 * Manages state for tasks, categories, and handles lazy loading of the task archive.
 * Coordinates between the UI and the dual-file persistence layer.
 */
public class TaskListViewModel: ObservableObject {
    /// Active tasks published to UI observers.
    @Published public var tasks: [TaskItem] = []
    
    /// Archived tasks, loaded lazily only when requested.
    @Published public var archivedTasks: [TaskItem] = []
    
    /// Available categories for task organization.
    @Published public var categories: [String] = []
    
    /// The currently selected category for filtering the active task list.
    @Published public var selectedCategory: String = ""
    
    /// Transient bound text for the new task input field.
    @Published public var newTaskTitle: String = ""
    
    /// Controls visibility of the archive viewer overlay.
    /// Toggling this to true may trigger a lazy load of the archive data.
    @Published public var showingArchive: Bool = false {
        didSet {
            if showingArchive && !isArchiveLoaded {
                loadArchive()
            }
        }
    }
    
    /// Tracks if the archive has been loaded into memory during this session.
    @Published public var isArchiveLoaded: Bool = false
    
    /// Persisted count of archived tasks for display without loading the full archive.
    @Published public var archiveCount: Int = 0
    
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
     * Provisions the ViewModel and performs initial data loading (Active only).
     * - Parameter repository: Backing storage implementation.
     */
    public init(repository: TaskRepository = LocalTaskRepository()) {
        self.repository = repository
        self.showPendingCount = UserDefaults.standard.object(forKey: "showPendingCount") as? Bool ?? true
        loadData()
    }
    
    /**
     * Derived list of tasks filtered by selected category and sorted by manual order index.
     */
    public var filteredTasks: [TaskItem] {
        tasks.filter { $0.category == selectedCategory }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    /**
     * Indicates if the maximum category limit has been reached.
     */
    public var canAddCategory: Bool {
        categories.count < maxCategories
    }
    
    /**
     * Loads active tasks and categories from the primary store.
     * This method ignores archived tasks to keep peak performance.
     */
    public func loadData() {
        do {
            let appData = try repository.fetchData()
            self.categories = appData.categories
            self.tasks = appData.tasks
            self.archiveCount = appData.archivedCount
            
            // Migration: If tasks have no order, assign one based on creation date (descending)
            // This ensures a stable initial state for the new manual ordering system.
            if !tasks.isEmpty && tasks.allSatisfy({ $0.orderIndex == 0 }) {
                reIndexAllTasks()
            }
            
            if !categories.isEmpty && selectedCategory.isEmpty {
                self.selectedCategory = categories[0]
            }
            pendingTaskCount = tasks.filter { !$0.isCompleted }.count
        } catch {
            print("Failed to load active data: \(error)")
        }
    }
    
    /**
     * Serializes categories and active tasks to the primary store.
     */
    private func saveActiveData() {
        let appData = AppData(categories: categories, tasks: tasks, archivedCount: archiveCount)
        do {
            try repository.saveData(appData)
            pendingTaskCount = tasks.filter { !$0.isCompleted }.count
        } catch {
            print("Failed to save active data: \(error)")
        }
    }
    
    /**
     * Lazily loads the archive data into memory.
     */
    public func loadArchive() {
        do {
            self.archivedTasks = try repository.fetchArchive()
            self.isArchiveLoaded = true
            updateArchiveCount()
        } catch {
            print("Failed to load archive: \(error)")
        }
    }
    
    /**
     * Serializes the current archivedTasks list to the archive store.
     */
    private func saveArchiveData() {
        do {
            try repository.saveArchive(archivedTasks)
            updateArchiveCount()
        } catch {
            print("Failed to save archive data: \(error)")
        }
    }
    
    /**
     * Syncs the archiveCount property with the current archivedTasks array size and persists it.
     */
    private func updateArchiveCount() {
        archiveCount = archivedTasks.count
        saveActiveData()
    }
    
    // MARK: - Category Management
    
    public func addCategory(name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, canAddCategory, !categories.contains(trimmedName) else { return false }
        
        categories.append(trimmedName)
        selectedCategory = trimmedName
        saveActiveData()
        return true
    }
    
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
        
        // If archive is loaded, we update it too. 
        // Note: If archive isn't loaded, we'd need to load it or handle it separately.
        // For simplicity and correctness, we ensure archive is updated if loaded.
        if isArchiveLoaded {
            for i in 0..<archivedTasks.count {
                if archivedTasks[i].category == oldName {
                    archivedTasks[i].category = trimmedName
                }
            }
            saveArchiveData()
        } else {
            // Advanced: Update archive without loading it or queue it
            // For now, let's assume renaming categories is rare and we can just load it if we must.
            loadArchive()
            for i in 0..<archivedTasks.count {
                if archivedTasks[i].category == oldName {
                    archivedTasks[i].category = trimmedName
                }
            }
            saveArchiveData()
        }
        
        if selectedCategory == oldName {
            selectedCategory = trimmedName
        }
        
        saveActiveData()
        return true
    }
    
    public func deleteCategory(_ name: String) {
        guard categories.count > 1 else { return }
        
        categories.removeAll { $0 == name }
        tasks.removeAll { $0.category == name }
        
        // Ensure archive items for this category are also removed
        loadArchive()
        archivedTasks.removeAll { $0.category == name }
        saveArchiveData()
        
        if selectedCategory == name {
            selectedCategory = categories.first ?? ""
        }
        saveActiveData()
    }
    
    // MARK: - Task Management
    
    public func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedCategory.isEmpty else { return }
        
        // We insert new tasks at the top (lowest index)
        // To avoid negative indices, we can just shift everything up by 1 and set new to 0
        for i in 0..<tasks.count {
            if tasks[i].category == selectedCategory {
                tasks[i].orderIndex += 1
            }
        }
        
        let task = TaskItem(title: trimmed, category: selectedCategory, orderIndex: 0)
        tasks.append(task)
        newTaskTitle = ""
        saveActiveData()
    }
    
    /**
     * Re-orders tasks based on a drag-and-drop operation within the UI.
     * - Parameters:
     *   - source: The original offsets of the tasks being moved.
     *   - destination: The new target offset.
     */
    public func moveTask(from source: IndexSet, to destination: Int) {
        // 1. Get the tasks associated with the current category in their current sorted order
        var categoryTasks = filteredTasks
        
        // 2. Perform the move in the temporary array
        categoryTasks.move(fromOffsets: source, toOffset: destination)
        
        // 3. Update the orderIndex for these tasks in a local copy to avoid multiple notifications
        var updatedTasks = tasks
        for (index, task) in categoryTasks.enumerated() {
            if let globalIndex = updatedTasks.firstIndex(where: { $0.id == task.id }) {
                updatedTasks[globalIndex].orderIndex = index
            }
        }
        
        self.tasks = updatedTasks
        saveActiveData()
    }
    
    /**
     * Normalizes order indices for all tasks across all categories.
     * Useful for migration or clean-up.
     */
    private func reIndexAllTasks() {
        for category in categories {
            let catTasks = tasks.filter { $0.category == category }
                .sorted { $0.createdAt > $1.createdAt } // Default to Newest First for migration
            
            for (index, task) in catTasks.enumerated() {
                if let globalIndex = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[globalIndex].orderIndex = index
                }
            }
        }
        saveActiveData()
    }
    
    public func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
            saveActiveData()
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveActiveData()
    }
    
    public func clearCompleted() {
        tasks.removeAll { $0.category == selectedCategory && $0.isCompleted }
        saveActiveData()
    }
    
    public func clearAllInSelectedCategory() {
        tasks.removeAll { $0.category == selectedCategory }
        saveActiveData()
    }
    
    // MARK: - Archive Management
    
    public func archiveTask(_ task: TaskItem) {
        guard task.isCompleted else { return }
        
        // Load archive before modification to ensure we don't overwrite it
        if !isArchiveLoaded { loadArchive() }
        
        archivedTasks.append(task)
        tasks.removeAll { $0.id == task.id }
        
        saveActiveData()
        saveArchiveData()
    }
    
    public func archiveCompletedInSelectedCategory() {
        let completed = tasks.filter { $0.category == selectedCategory && $0.isCompleted }
        guard !completed.isEmpty else { return }
        
        if !isArchiveLoaded { loadArchive() }
        
        archivedTasks.append(contentsOf: completed)
        tasks.removeAll { $0.category == selectedCategory && $0.isCompleted }
        
        saveActiveData()
        saveArchiveData()
    }
    
    public func deleteArchivedTask(_ task: TaskItem) {
        if !isArchiveLoaded { loadArchive() }
        archivedTasks.removeAll { $0.id == task.id }
        saveArchiveData()
    }
    
    /**
     * Permanently deletes all archived tasks.
     */
    public func deleteAllArchivedTasks() {
        archivedTasks.removeAll()
        saveArchiveData()
    }
}
