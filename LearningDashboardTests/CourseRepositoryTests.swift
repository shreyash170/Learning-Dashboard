import XCTest
@testable import LearningDashboard

private struct FakeAPI: CourseAPI {
    let result: Result<[CourseDTO], Error>
    func fetchCourses() async throws -> [CourseDTO] { try result.get() }
}

private actor InMemoryStore: CourseStore {
    private var courses: [Course]?
    func load() -> [Course]? { courses }
    func save(_ courses: [Course]) { self.courses = courses }
}

final class CourseRepositoryTests: XCTestCase {
    private let dto = CourseDTO(id: 1, title: "Python", instructor: "John", progress: 50, lessons: 4)

    func test_progressCalculator() {
        XCTAssertEqual(ProgressCalculator.percent(completed: 0, total: 0), 0)
        XCTAssertEqual(ProgressCalculator.percent(completed: 1, total: 3), 33)
        XCTAssertEqual(ProgressCalculator.percent(completed: 9, total: 4), 100) // clamped
    }

    func test_completingLesson_updatesProgress_andSurvivesRefresh() async throws {
        let store = InMemoryStore()
        let repo = DefaultCourseRepository(api: FakeAPI(result: .success([dto])), store: store)

        let first = try await repo.loadCourses().courses[0]
        XCTAssertEqual(first.progress, 50)                    // 2 of 4 done

        let pending = try XCTUnwrap(first.lessons.first { !$0.isCompleted })
        let updated = try await repo.markLessonCompleted(courseID: 1, lessonID: pending.id)
        XCTAssertEqual(updated.progress, 75)

        // Server refresh must not wipe local progress.
        let refreshed = try await repo.loadCourses().courses[0]
        XCTAssertEqual(refreshed.progress, 75)
    }

    func test_offline_servesCachedCourses_butFailsWithNoCache() async throws {
        let store = InMemoryStore()
        _ = try await DefaultCourseRepository(api: FakeAPI(result: .success([dto])), store: store).loadCourses()

        let offline = DefaultCourseRepository(
            api: FakeAPI(result: .failure(URLError(.notConnectedToInternet))), store: store)
        let result = try await offline.loadCourses()
        XCTAssertTrue(result.isFromCache)
        XCTAssertEqual(result.courses.count, 1)

        let empty = DefaultCourseRepository(
            api: FakeAPI(result: .failure(URLError(.notConnectedToInternet))), store: InMemoryStore())
        do { _ = try await empty.loadCourses(); XCTFail("Expected failure") } catch { }
    }
}
