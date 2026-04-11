import Foundation

/**
 * A repository pattern protocol abstracting data layer persistence operations.
 * This allows the application to transition between different storage backends
 * (e.g., Local JSON, CoreData, CloudKit) without affecting the UI layer.
 */
public protocol TaskRepository {
    /**
     * Fetches application data from the persistent store.
     * - Returns: An AppData object containing categories and tasks.
     * - Throws: Errors related to file access or decoding.
     */
    func fetchData() throws -> AppData
    
    /**
     * Saves the application state to the persistent store.
     * - Parameter data: The AppData instance to persist.
     * - Throws: Errors related to encoding or file writing.
     */
    func saveData(_ data: AppData) throws
}
