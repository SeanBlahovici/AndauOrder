import Foundation

// MARK: - Protocol

protocol ZohoAuthServiceProtocol: Sendable {
    func validAccessToken() async throws -> String
    var isAuthenticated: Bool { get }
}

// MARK: - Implementation

final class ZohoAuthService: ZohoAuthServiceProtocol, @unchecked Sendable {

    private let tokenStore = TokenStore()
    private let session: URLSession
    private let lock = NSLock()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public

    var isAuthenticated: Bool {
        lock.lock()
        defer { lock.unlock() }
        return tokenStore.accessToken != nil && tokenStore.refreshToken != nil
    }

    func validAccessToken() async throws -> String {
        // Check for a valid cached token (with 5-minute buffer)
        if let token = cachedTokenIfValid() {
            return token
        }
        return try await refreshAccessToken()
    }

    // MARK: - Private

    private func cachedTokenIfValid() -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let token = tokenStore.accessToken,
              let expiry = tokenStore.accessTokenExpiry else {
            return nil
        }
        let bufferSeconds: TimeInterval = 5 * 60
        guard Date.now.addingTimeInterval(bufferSeconds) < expiry else {
            return nil
        }
        return token
    }

    private func refreshAccessToken() async throws -> String {
        let defaults = UserDefaults.standard
        guard let clientID = defaults.string(forKey: "zohoClientID"), !clientID.isEmpty,
              let clientSecret = defaults.string(forKey: "zohoClientSecret"), !clientSecret.isEmpty else {
            throw APIError.unauthorized
        }

        // Prefer refresh token from Keychain; fall back to UserDefaults for initial setup
        let refreshToken: String
        if let keychainRT = tokenStore.refreshToken, !keychainRT.isEmpty {
            refreshToken = keychainRT
        } else if let defaultsRT = defaults.string(forKey: "zohoRefreshToken"), !defaultsRT.isEmpty {
            refreshToken = defaultsRT
            // Persist into Keychain for future use
            tokenStore.refreshToken = refreshToken
        } else {
            throw APIError.unauthorized
        }

        let envString = defaults.string(forKey: "zohoEnvironment") ?? "sandbox"
        let environment = ZohoEnvironment(rawValue: envString) ?? .sandbox

        let url = URL(string: "\(environment.accountsURL)/oauth/v2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "refresh_token": refreshToken,
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": "refresh_token",
        ]
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8) ?? "Token refresh failed"
            )
        }

        let tokenResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)

        let newToken = tokenResponse.access_token
        let newExpiry = Date.now.addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        storeToken(newToken, expiry: newExpiry)

        return newToken
    }

    private func storeToken(_ accessToken: String, expiry: Date) {
        lock.lock()
        defer { lock.unlock() }
        tokenStore.accessToken = accessToken
        tokenStore.accessTokenExpiry = expiry
    }
}

// MARK: - Token Refresh DTO

private struct TokenRefreshResponse: Decodable {
    let access_token: String
    let expires_in: Int
    let api_domain: String?
}
