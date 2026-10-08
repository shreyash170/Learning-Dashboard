import Foundation

struct Lesson: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var isCompleted: Bool
}

struct Course: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var instructor: String
    var lessons: [Lesson]

    var lessonCount: Int { lessons.count }
    var completedCount: Int { lessons.filter(\.isCompleted).count }

    /// Progress is always derived from lesson state, so it can never drift out of sync.
    var progress: Int {
        ProgressCalculator.percent(completed: completedCount, total: lessonCount)
    }

    /// Returns false if the lesson doesn't exist or is already completed.
    @discardableResult
    mutating func markLessonCompleted(id lessonID: Int) -> Bool {
        guard let index = lessons.firstIndex(where: { $0.id == lessonID }),
              !lessons[index].isCompleted else { return false }
        lessons[index].isCompleted = true
        return true
    }
}

enum ProgressCalculator {
    static func percent(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let clamped = min(max(completed, 0), total)
        return Int((Double(clamped) / Double(total) * 100).rounded())
    }
}
