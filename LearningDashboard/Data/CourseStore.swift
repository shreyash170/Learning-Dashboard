import Foundation

/// Local persistence abstraction. Swap for SwiftData / Core Data / SQLite without touching callers.
protocol CourseStore: Sendable {
    func load() async throws -> [Course]?
    func save(_ courses: [Course]) async throws
}

/// Simple JSON-file cache (atomic writes) in Application Support.
actor FileCourseStore: CourseStore {
    private let url: URL

    init(url: URL = FileCourseStore.defaultURL) { self.url = url }

    static var defaultURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("courses.json")
    }

    func load() throws -> [Course]? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode([Course].self, from: Data(contentsOf: url))
    }

    func save(_ courses: [Course]) throws {
        try JSONEncoder().encode(courses).write(to: url, options: .atomic)
    }
}
