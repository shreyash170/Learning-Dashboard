import Foundation
import Observation

@MainActor
@Observable
final class CourseDetailViewModel {
    private(set) var course: Course
    private(set) var errorMessage: String?
    private(set) var inFlightLessonIDs: Set<Int> = []

    @ObservationIgnored private let repository: CourseRepository
    @ObservationIgnored private let onUpdate: (Course) -> Void

    init(course: Course, repository: CourseRepository, onUpdate: @escaping (Course) -> Void) {
        self.course = course
        self.repository = repository
        self.onUpdate = onUpdate
    }

    func markCompleted(_ lesson: Lesson) async {
        guard !lesson.isCompleted, !inFlightLessonIDs.contains(lesson.id) else { return }
        inFlightLessonIDs.insert(lesson.id)
        defer { inFlightLessonIDs.remove(lesson.id) }
        do {
            // Persist first, then update UI, so what's shown is what's saved.
            let updated = try await repository.markLessonCompleted(courseID: course.id, lessonID: lesson.id)
            course = updated
            errorMessage = nil
            onUpdate(updated)
        } catch {
            errorMessage = "Couldn't save your progress. Please try again."
        }
    }
}
