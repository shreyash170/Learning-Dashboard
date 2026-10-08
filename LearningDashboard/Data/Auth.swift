import Foundation
import Security

enum AuthError: LocalizedError {
    case invalidCredentials
    var errorDescription: String? { "Incorrect email or password." }
}

protocol AuthService: Sendable {
    func login(email: String, password: String) async throws -> String
}

/// Mock: any valid email + password "password123" succeeds.
struct MockAuthService: AuthService {
    func login(email: String, password: String) async throws -> String {
        try await Task.sleep(nanoseconds: 900_000_000)
        guard password == "password123" else { throw AuthError.invalidCredentials }
        return "mock-token-\(UUID().uuidString)"
    }
}

protocol TokenStore: Sendable {
    func save(_ token: String) throws
    func load() -> String?
    func clear()
}

/// Tokens live in the Keychain, not UserDefaults.
struct KeychainTokenStore: TokenStore {
    private let service = "com.example.LearningDashboard"
    private let account = "authToken"

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func save(_ token: String) throws {
        SecItemDelete(baseQuery as CFDictionary)
        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clear() { SecItemDelete(baseQuery as CFDictionary) }
}
