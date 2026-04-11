import Foundation

/**
 * Implementation of TaskRepository using local JSON file storage.
 * Data is stored in the user's Application Support directory.
 */
public class LocalTaskRepository: TaskRepository {
    /// The hardcoded filename for the local task database.
    private let fileName = "tasks.json"
    
    /// The URL to the local tasks.json file in Application Support.
    private var fileURL: URL {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupportDir.appendingPathComponent("PleaseDo")
        
        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appDir.appendingPathComponent(fileName)
    }
    
    public init() {}
    
    /**
     * Loads tasks and categories from disk.
     * Includes a migration path for legacy [TaskItem] arrays from older app versions.
     * - Returns: Reconstructed AppData snapshot.
     * - Throws: Decoding errors if the file is corrupted.
     */
    public func fetchData() throws -> AppData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppData()
        }
        
        let fileData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        
        do {
            let appData = try decoder.decode(AppData.self, from: fileData)
            return appData
        } catch {
            // Migration: try decoding without archivedTasks (v2 format)
            struct LegacyAppData: Codable {
                var categories: [String]
                var tasks: [TaskItem]
            }
            if let v2Data = try? decoder.decode(LegacyAppData.self, from: fileData) {
                let migrated = AppData(categories: v2Data.categories, tasks: v2Data.tasks, archivedTasks: [])
                try? saveData(migrated)
                return migrated
            }
            // Migration: try decoding v1 bare array format
            if let legacyData = try? decoder.decode([TaskItem].self, from: fileData) {
                let migrated = AppData(categories: ["Work", "Personal"], tasks: legacyData)
                try? saveData(migrated)
                return migrated
            }
            throw error
        }
    }
    
    /**
     * Persists AppData to a JSON file atomically to prevent data loss.
     * - Parameter data: AppData packet defining exhaustive runtime configurations.
     * - Throws: Filesystem operation constraints.
     */
    public func saveData(_ data: AppData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let fileData = try encoder.encode(data)
        try fileData.write(to: fileURL, options: .atomic)
    }
}
