import Foundation

/**
 * Implementation of TaskRepository using dual local JSON file storage.
 * - tasks.json: Stores categories and active tasks (Hot data).
 * - archive.json: Stores archived tasks (Cold data).
 */
public class LocalTaskRepository: TaskRepository {
    private let tasksFileName = "tasks.json"
    private let archiveFileName = "archive.json"
    
    /// The URL to the main application data directory.
    private var appDirectoryURL: URL {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupportDir.appendingPathComponent("PleaseDo")
        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        }
        return appDir
    }
    
    /// The URL to the tasks.json file.
    private var tasksFileURL: URL {
        appDirectoryURL.appendingPathComponent(tasksFileName)
    }
    
    /// The URL to the archive.json file.
    private var archiveFileURL: URL {
        appDirectoryURL.appendingPathComponent(archiveFileName)
    }
    
    public init() {}
    
    /**
     * Loads categories and active tasks from disk.
     * Performs automatic migration if archived tasks are found in the main file.
     */
    public func fetchData() throws -> AppData {
        guard FileManager.default.fileExists(atPath: tasksFileURL.path) else {
            return AppData()
        }
        
        let fileData = try Data(contentsOf: tasksFileURL)
        let decoder = JSONDecoder()
        
        // Use a local struct for migration detection that includes the legacy archivedTasks field
        struct MigrationData: Codable {
            var categories: [String]
            var tasks: [TaskItem]
            var archivedTasks: [TaskItem]?
            var archivedCount: Int?
        }
        
        do {
            let migData = try decoder.decode(MigrationData.self, from: fileData)
            
            // Migration: If the main file contains archived tasks, move them to the archive file
            if let archived = migData.archivedTasks, !archived.isEmpty {
                // Construct AppData manually for the migration helper
                let legacyAppData = AppData(categories: migData.categories, tasks: migData.tasks, archivedCount: archived.count)
                try? performMigration(legacyAppData, legacyArchivedTasks: archived)
                return legacyAppData
            }
            
            // If the main file doesn't have cached count, bootstrap it once
            let countToReturn = migData.archivedCount ?? fetchArchiveCount()
            return AppData(categories: migData.categories, tasks: migData.tasks, archivedCount: countToReturn)
        } catch {
            // Legacy Migration: handle various older formats
            return try handleLegacyMigration(fileData, decoder: decoder)
        }
    }
    
    /**
     * Persists categories and active tasks to tasks.json.
     * The archivedTasks field is now omitted entirely as it's no longer part of the AppData model.
     */
    public func saveData(_ data: AppData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let fileData = try encoder.encode(data)
        try fileData.write(to: tasksFileURL, options: .atomic)
    }
    
    /**
     * Loads the complete list of archived tasks from archive.json.
     */
    public func fetchArchive() throws -> [TaskItem] {
        guard FileManager.default.fileExists(atPath: archiveFileURL.path) else {
            return []
        }
        
        let fileData = try Data(contentsOf: archiveFileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([TaskItem].self, from: fileData)
    }
    
    /**
     * Efficiently fetches the count of archived tasks.
     * Since archiving uses a separate JSON array, we still have to read it,
     * but we don't need to keep it in memory.
     */
    public func fetchArchiveCount() -> Int {
        guard FileManager.default.fileExists(atPath: archiveFileURL.path) else {
            return 0
        }
        
        do {
            let fileData = try Data(contentsOf: archiveFileURL)
            let decoder = JSONDecoder()
            let archive = try decoder.decode([TaskItem].self, from: fileData)
            return archive.count
        } catch {
            return 0
        }
    }
    
    /**
     * Persists the archived tasks list to archive.json.
     */
    public func saveArchive(_ archivedTasks: [TaskItem]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let fileData = try encoder.encode(archivedTasks)
        try fileData.write(to: archiveFileURL, options: .atomic)
    }
    
    // MARK: - Private Migration Helpers
    
    /**
     * Moves archived tasks from a unified legacy store to the separate archive file.
     */
    private func performMigration(_ appData: AppData, legacyArchivedTasks: [TaskItem]) throws {
        var existingArchive = (try? fetchArchive()) ?? []
        existingArchive.append(contentsOf: legacyArchivedTasks)
        try saveArchive(existingArchive)
        
        // Save cleaned main file immediately to finish migration
        try saveData(appData)
    }
    
    /**
     * Handles decoding of older version formats (bare arrays or missing keys).
     */
    private func handleLegacyMigration(_ fileData: Data, decoder: JSONDecoder) throws -> AppData {
        // Try decoding without archivedTasks (v2 format)
        struct LegacyAppData: Codable {
            var categories: [String]
            var tasks: [TaskItem]
        }
        
        if let v2Data = try? decoder.decode(LegacyAppData.self, from: fileData) {
            let migrated = AppData(categories: v2Data.categories, tasks: v2Data.tasks)
            try? saveData(migrated)
            return migrated
        }
        
        // Try decoding v1 bare array format
        if let legacyData = try? decoder.decode([TaskItem].self, from: fileData) {
            let migrated = AppData(categories: ["Work", "Personal"], tasks: legacyData)
            try? saveData(migrated)
            return migrated
        }
        
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown file format"))
    }
}
