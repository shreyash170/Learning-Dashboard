import Foundation

struct CourseListResult: Equatable {
    let courses: [Course]
    /// True when the network failed and the local cache was served instead.
    let isFromCache: Bool
}

enum RepositoryError: LocalizedError {
    case notFound
    var errorDescription: String? { "That course or lesson could not be found." }
}

protocol CourseRepository: Sendable {
    func loadCourses() async throws -> CourseListResult
    func markLessonCompleted(courseID: Int, lessonID: Int) async throws -> Course
}

/// Single source of truth. Strategy: network-first, cache-fallback.
/// Local lesson completion is preserved when the server list is refreshed.
actor DefaultCourseRepository: CourseRepository {
    private let api: CourseAPI
    private let store: CourseStore

    init(api: CourseAPI, store: CourseStore) {
        self.api = api
        self.store = store
    }

    func loadCourses() async throws -> CourseListResult {
        let cached = (try? await store.load()) ?? nil
        do {
            let remote = try await api.fetchCourses().map { $0.toDomain() }
            let merged = Self.merge(remote: remote, local: cached ?? [])
            try? await store.save(merged)
            return CourseListResult(courses: merged, isFromCache: false)
        } catch {
            if let cached, !cached.isEmpty {
                return CourseListResult(courses: cached, isFromCache: true)
            }
            throw error
        }
    }

    func markLessonCompleted(courseID: Int, lessonID: Int) async throws -> Course {
        var courses = (try await store.load()) ?? []
        guard let index = courses.firstIndex(where: { $0.id == courseID }),
              courses[index].lessons.contains(where: { $0.id == lessonID })
        else { throw RepositoryError.notFound }
        courses[index].markLessonCompleted(id: lessonID)
        try await store.save(courses)
        return courses[index]
    }

    /// Server defines the course set; local progress wins when the lesson structure matches.
    static func merge(remote: [Course], local: [Course]) -> [Course] {
        let localByID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return remote.map { course in
            guard var existing = localByID[course.id], existing.lessonCount == course.lessonCount else {
                return course
            }
            existing.title = course.title
            existing.instructor = course.instructor
            return existing
        }
    }
}
