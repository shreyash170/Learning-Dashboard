import Foundation
import Observation

@MainActor
@Observable
final class CourseListViewModel {
    enum State: Equatable { case idle, loading, loaded, empty, failed(String) }

    private(set) var state: State = .idle
    private(set) var courses: [Course] = []
    private(set) var isShowingCachedData = false

    @ObservationIgnored private let repository: CourseRepository

    init(repository: CourseRepository) { self.repository = repository }

    func load() async {
        // Only show the full-screen spinner on first load; refreshes keep current content.
        if courses.isEmpty { state = .loading }
        do {
            let result = try await repository.loadCourses()
            courses = result.courses
            isShowingCachedData = result.isFromCache
            state = courses.isEmpty ? .empty : .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Called by the detail screen so the list reflects progress immediately.
    func apply(_ updated: Course) {
        guard let index = courses.firstIndex(where: { $0.id == updated.id }) else { return }
        courses[index] = updated
    }

    private static func message(for error: Error) -> String {
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return "You're offline and no courses are saved yet. Connect once to load them."
        }
        return "Couldn't load courses. Please try again."
    }
}
