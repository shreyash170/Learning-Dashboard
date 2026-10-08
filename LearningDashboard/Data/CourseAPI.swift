import Foundation

protocol CourseAPI: Sendable {
    func fetchCourses() async throws -> [CourseDTO]
}

/// Mock API backed by a bundled JSON file. It honours the real network state so that
/// turning off Wi-Fi genuinely makes the call fail (needed for the offline demo).
/// Launch with `-forceAPIFailure` to simulate a server error.
struct MockCourseAPI: CourseAPI {
    let monitor: NetworkMonitor
    var latencyNanos: UInt64 = 800_000_000

    func fetchCourses() async throws -> [CourseDTO] {
        try await Task.sleep(nanoseconds: latencyNanos)
        if ProcessInfo.processInfo.arguments.contains("-forceAPIFailure") {
            throw URLError(.badServerResponse)
        }
        guard await monitor.isOnline else { throw URLError(.notConnectedToInternet) }
        guard let url = Bundle.main.url(forResource: "courses", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }
        return try JSONDecoder().decode([CourseDTO].self, from: Data(contentsOf: url))
    }
}
