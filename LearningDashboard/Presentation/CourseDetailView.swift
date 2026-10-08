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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress: \(viewModel.course.progress)%").font(.headline)
                    ProgressView(value: Double(viewModel.course.progress), total: 100)
                    Text("\(viewModel.course.completedCount) of \(viewModel.course.lessonCount) lessons completed")
                        .font(.caption).foregroundStyle(.secondary)
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
        HStack {
            Text(lesson.title)
            Spacer()
            if lesson.isCompleted {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(Theme.accent)
            } else {
                Button(action: onComplete) {
                    Label("Mark done", systemImage: "circle").font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy)
            }
        }
        .card()
    }
}
