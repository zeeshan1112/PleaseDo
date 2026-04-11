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
    
    public func fetchTasks() throws -> [TaskItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [] // Return empty if no file exists yet
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([TaskItem].self, from: data)
    }
    
    public func saveTasks(_ tasks: [TaskItem]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(tasks)
        try data.write(to: fileURL, options: .atomic)
    }
}
