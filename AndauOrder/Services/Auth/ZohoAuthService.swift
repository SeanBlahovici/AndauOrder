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

        // Always read refresh token from UserDefaults (set via Settings UI)
        guard let refreshToken = defaults.string(forKey: "zohoRefreshToken"), !refreshToken.isEmpty else {
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

        #if DEBUG
        print("[ZohoAuth] POST \(environment.accountsURL)/oauth/v2/token")
        print("[ZohoAuth] client_id: \(clientID.prefix(10))...")
        print("[ZohoAuth] refresh_token: \(refreshToken.prefix(10))...")
        #endif

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let responseBody = String(data: data, encoding: .utf8) ?? ""

        #if DEBUG
        print("[ZohoAuth] Status: \(httpResponse.statusCode)")
        print("[ZohoAuth] Response: \(responseBody)")
        #endif

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(
                statusCode: httpResponse.statusCode,
                message: responseBody
            )
        }

        // Check for Zoho error response (e.g. {"error": "invalid_code"})
        if let errorObj = try? JSONDecoder().decode(ZohoErrorResponse.self, from: data),
           let error = errorObj.error {
            throw APIError.zohoError(code: error, message: responseBody)
        }

        guard let tokenResponse = try? JSONDecoder().decode(TokenRefreshResponse.self, from: data) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Unexpected response: \(responseBody)")
        }

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

private struct ZohoErrorResponse: Decodable {
    let error: String?
}

private struct TokenRefreshResponse: Decodable {
    let access_token: String
    let expires_in: Int
    let api_domain: String?
}
