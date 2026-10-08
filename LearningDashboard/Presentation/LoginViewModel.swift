import Foundation
import Observation

enum LoginValidator {
    static func emailError(_ email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Email is required." }
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) == nil ? "Enter a valid email." : nil
    }

    static func passwordError(_ password: String) -> String? {
        if password.isEmpty { return "Password is required." }
        return password.count < 8 ? "Password must be at least 8 characters." : nil
    }
}

@MainActor
@Observable
final class LoginViewModel {
    enum State: Equatable { case idle, loading, failed(String) }

    var email = ""
    var password = ""
    private(set) var state: State = .idle
    private(set) var showValidation = false

    var emailError: String? { showValidation ? LoginValidator.emailError(email) : nil }
    var passwordError: String? { showValidation ? LoginValidator.passwordError(password) : nil }
    var isLoading: Bool { state == .loading }

    @ObservationIgnored private let auth: AuthService
    @ObservationIgnored private let tokens: TokenStore
    @ObservationIgnored private let onSuccess: () -> Void

    init(auth: AuthService, tokens: TokenStore, onSuccess: @escaping () -> Void) {
        self.auth = auth
        self.tokens = tokens
        self.onSuccess = onSuccess
    }

    func login() async {
        showValidation = true
        guard LoginValidator.emailError(email) == nil,
              LoginValidator.passwordError(password) == nil, !isLoading else { return }
        state = .loading
        do {
            let token = try await auth.login(email: email.trimmingCharacters(in: .whitespaces),
                                             password: password)
            try tokens.save(token)
            state = .idle
            onSuccess()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
