import SwiftUI

struct CourseDetailView: View {
    @State private var viewModel: CourseDetailViewModel

    init(course: Course, repository: CourseRepository, onUpdate: @escaping (Course) -> Void) {
        _viewModel = State(initialValue: CourseDetailViewModel(course: course,
                                                              repository: repository,
                                                              onUpdate: onUpdate))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    ProgressRing(value: viewModel.course.progress, size: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.course.instructor).font(.headline)
                        Text("\(viewModel.course.completedCount) of \(viewModel.course.lessonCount) lessons completed")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .card()

                if let message = viewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(.red)
                }

                ForEach(viewModel.course.lessons) { lesson in
                    LessonRow(lesson: lesson, isBusy: viewModel.inFlightLessonIDs.contains(lesson.id)) {
                        Task { await viewModel.markCompleted(lesson) }
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(viewModel.course.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isBusy: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: lesson.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(lesson.isCompleted ? Theme.accent : .secondary.opacity(0.5))
            Text(lesson.title)
                .foregroundStyle(lesson.isCompleted ? .secondary : .primary)
            Spacer()
            if !lesson.isCompleted {
                Button("Mark done", action: onComplete)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .disabled(isBusy)
            }
        }
        .card()
    }
}
