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
        
        do {
            let appData = try decoder.decode(AppData.self, from: fileData)
            
            // Migration: If the main file contains archived tasks, move them to the archive file
            if !appData.archivedTasks.isEmpty {
                try? performMigration(appData)
                // Return a cleaned version without the archived tasks
                return AppData(categories: appData.categories, tasks: appData.tasks, archivedTasks: [])
            }
            
            return appData
        } catch {
            // Legacy Migration: handle various older formats
            return try handleLegacyMigration(fileData, decoder: decoder)
        }
    }
    
    /**
     * Persists categories and active tasks to tasks.json.
     * Always saves with empty archivedTasks array to keep this file small.
     */
    public func saveData(_ data: AppData) throws {
        var dataToSave = data
        dataToSave.archivedTasks = [] // Ensure archive data is NOT in the main file
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let fileData = try encoder.encode(dataToSave)
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
     * Moves archived tasks from a unified AppData object to the separate archive file.
     */
    private func performMigration(_ appData: AppData) throws {
        var existingArchive = (try? fetchArchive()) ?? []
        existingArchive.append(contentsOf: appData.archivedTasks)
        try saveArchive(existingArchive)
        
        // Save cleaned main file immidiately to finish migration
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
            let migrated = AppData(categories: v2Data.categories, tasks: v2Data.tasks, archivedTasks: [])
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
