import Foundation

public class LocalTaskRepository: TaskRepository {
    private let fileName = "tasks.json"
    private var fileURL: URL {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupportDir.appendingPathComponent("PleaseDo")
        
        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appDir.appendingPathComponent(fileName)
    }
    
    public init() {}
    
    public func fetchData() throws -> AppData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppData() // Default "Work", "Personal"
        }
        
        let fileData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        
        // Attempt to decode as AppData
        do {
            return try decoder.decode(AppData.self, from: fileData)
        } catch {
            // Migration: if the user previously had only [TaskItem]
            if let legacyData = try? decoder.decode([TaskItem].self, from: fileData) {
                let migrated = AppData(categories: ["Work", "Personal"], tasks: legacyData)
                try? saveData(migrated)
                return migrated
            }
            throw error
        }
    }
    
    public func saveData(_ data: AppData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let fileData = try encoder.encode(data)
        try fileData.write(to: fileURL, options: .atomic)
    }
}
