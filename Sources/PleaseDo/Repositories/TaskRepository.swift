import Foundation

public protocol TaskRepository {
    func fetchData() throws -> AppData
    func saveData(_ data: AppData) throws
}
