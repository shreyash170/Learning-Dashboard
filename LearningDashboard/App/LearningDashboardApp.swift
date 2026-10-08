import SwiftUI

/// Composition root: the only place concrete dependencies are wired together.
@MainActor
final class AppContainer {
    let authService: AuthService = MockAuthService()
    let tokenStore: TokenStore = KeychainTokenStore()
    let monitor = NetworkMonitor()
    let repository: CourseRepository

    init() {
        repository = DefaultCourseRepository(api: MockCourseAPI(monitor: monitor),
                                             store: FileCourseStore())
    }
}

@main
struct LearningDashboardApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup { RootView(container: container) }
    }
}

struct RootView: View {
    let container: AppContainer
    @State private var isAuthenticated: Bool

    init(container: AppContainer) {
        self.container = container
        _isAuthenticated = State(initialValue: container.tokenStore.load() != nil)
    }

    var body: some View {
        if isAuthenticated {
            CourseListView(
                viewModel: CourseListViewModel(repository: container.repository),
                repository: container.repository,
                onLogout: {
                    container.tokenStore.clear()
                    isAuthenticated = false
                })
        } else {
            LoginView(viewModel: LoginViewModel(
                auth: container.authService,
                tokens: container.tokenStore,
                onSuccess: { isAuthenticated = true }))
        }
    }
}
