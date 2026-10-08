import SwiftUI

struct CourseListView: View {
    @State var viewModel: CourseListViewModel
    let repository: CourseRepository
    let onLogout: () -> Void
    @State private var path: [Course] = []

    init(viewModel: CourseListViewModel, repository: CourseRepository, onLogout: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.repository = repository
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
                .navigationTitle("My Courses")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Log Out", action: onLogout)
                    }
                }
                .navigationDestination(for: Course.self) { course in
                    CourseDetailView(course: course, repository: repository) { updated in
                        viewModel.apply(updated)
                    }
                }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading courses…")
        case .failed(let message):
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }
        case .empty:
            ContentUnavailableView("No courses yet", systemImage: "books.vertical",
                                   description: Text("Courses you enroll in will appear here."))
        case .loaded:
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.isShowingCachedData {
                        Label("Offline – showing saved courses", systemImage: "icloud.slash")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    SummaryHeader(progress: viewModel.overallProgress,
                                  courses: viewModel.courses.count,
                                  completed: viewModel.completedLessons,
                                  total: viewModel.totalLessons)
                    ForEach(viewModel.courses) { course in
                        CourseRow(course: course) { path.append(course) }
                    }
                }
                .padding()
            }
            .refreshable { await viewModel.load() }
        }
    }
}

private struct SummaryHeader: View {
    let progress: Int
    let courses: Int
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 16) {
            ProgressRing(value: progress, size: 72, track: .white.opacity(0.25), color: .white)
            VStack(alignment: .leading, spacing: 4) {
                Text("Your progress").font(.headline)
                Text("\(completed) of \(total) lessons done").font(.subheadline)
                Text("\(courses) courses").font(.caption).opacity(0.8)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Theme.accent.gradient, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct CourseRow: View {
    let course: Course
    let onContinue: () -> Void
    private static let icons = ["chevron.left.forwardslash.chevron.right", "sparkles", "laptopcomputer", "book.closed"]

    var body: some View {
        Button(action: onContinue) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: Self.icons[course.id % Self.icons.count])
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 48, height: 48)
                    .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(course.title).font(.headline)
                        Text(course.instructor).font(.subheadline).foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(course.progress), total: 100)
                    HStack {
                        Text("\(course.progress)% • \(course.lessonCount) lessons")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(course.progress == 100 ? "Review" : "Continue")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Theme.accent, in: Capsule())
                    }
                }
            }
            .card()
        }
        .buttonStyle(.plain)
    }
}
