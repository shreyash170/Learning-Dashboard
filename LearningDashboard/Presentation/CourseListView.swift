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
            List {
                if viewModel.isShowingCachedData {
                    Label("Offline – showing saved courses", systemImage: "icloud.slash")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                ForEach(viewModel.courses) { course in
                    CourseRow(course: course) { path.append(course) }
                }
            }
            .refreshable { await viewModel.load() }
        }
    }
}

private struct CourseRow: View {
    let course: Course
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title).font(.headline)
            Text(course.instructor).font(.subheadline).foregroundStyle(.secondary)
            ProgressView(value: Double(course.progress), total: 100)
            HStack {
                Text("\(course.progress)% • \(course.lessonCount) lessons")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
