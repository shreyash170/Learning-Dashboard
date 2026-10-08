import Foundation

/// Wire format of the course-list endpoint (lesson *count* only).
struct CourseDTO: Decodable, Equatable {
    let id: Int
    let title: String
    let instructor: String
    let progress: Int
    let lessons: Int
}

extension CourseDTO {
    private static let seedTitles = ["Introduction", "Variables & Data Types", "Functions", "OOP"]

    /// The list endpoint only returns a count, so lessons are derived: the first
    /// `progress%` of them are marked completed. A real API would return lessons.
    func toDomain() -> Course {
        let total = max(lessons, 0)
        let pct = Swift.min(Swift.max(progress, 0), 100)
        let done = Int((Double(pct) / 100 * Double(total)).rounded())
        let items = (0..<total).map { i in
            Lesson(id: i + 1,
                   title: i < Self.seedTitles.count ? Self.seedTitles[i] : "Lesson \(i + 1)",
                   isCompleted: i < done)
        }
        return Course(id: id, title: title, instructor: instructor, lessons: items)
    }
}
