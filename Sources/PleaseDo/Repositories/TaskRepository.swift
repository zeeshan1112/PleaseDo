import Foundation

/**
 * A repository pattern protocol abstracting data layer persistence operations.
 * This allows the application to transition between different storage backends
 * (e.g., Local JSON, CoreData, CloudKit) without affecting the UI layer.
 */
public protocol TaskRepository {
    /**
     * Fetches application data (Active tasks and Categories) from the persistent store.
     * - Returns: An AppData object containing categories and active tasks.
     * - Throws: Errors related to file access or decoding.
     */
    func fetchData() throws -> AppData
    
    /**
     * Saves the application state (Active tasks and Categories) to the persistent store.
     * - Parameter data: The AppData instance to persist.
     * - Throws: Errors related to encoding or file writing.
     */
    func saveData(_ data: AppData) throws
    
    /**
     * Fetches all archived tasks from the persistent archive store.
     * - Returns: An array of archived TaskItems.
     * - Throws: Errors related to file access or decoding.
     */
    func fetchArchive() throws -> [TaskItem]
    
    /**
     * Saves the complete list of archived tasks to the persistent archive store.
     * - Parameter archivedTasks: The full array of archived tasks.
     * - Throws: Errors related to file access or decoding.
     */
    func saveArchive(_ archivedTasks: [TaskItem]) throws
}
