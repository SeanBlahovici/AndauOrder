import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - Protocol

protocol HTTPClientProtocol: Sendable {
    func request<T: Decodable>(
        _ method: HTTPMethod,
        url: String,
        body: (any Encodable)?,
        queryParams: [String: String]
    ) async throws -> T

    func requestRaw(
        _ method: HTTPMethod,
        url: String,
        body: (any Encodable)?,
        queryParams: [String: String]
    ) async throws -> (Data, HTTPURLResponse)
}

// MARK: - Default parameter values

extension HTTPClientProtocol {
    func request<T: Decodable>(
        _ method: HTTPMethod,
        url: String,
        body: (any Encodable)? = nil,
        queryParams: [String: String] = [:]
    ) async throws -> T {
        try await request(method, url: url, body: body, queryParams: queryParams)
    }

    func requestRaw(
        _ method: HTTPMethod,
        url: String,
        body: (any Encodable)? = nil,
        queryParams: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        try await requestRaw(method, url: url, body: body, queryParams: queryParams)
    }
}

// MARK: - Implementation

final class HTTPClient: HTTPClientProtocol, Sendable {

    private let authService: any ZohoAuthServiceProtocol
    private let session: URLSession
    private let decoder: JSONDecoder

    init(authService: any ZohoAuthServiceProtocol, session: URLSession = .shared) {
        self.authService = authService
        self.session = session
        self.decoder = JSONDecoder()
    }

    func request<T: Decodable>(
        _ method: HTTPMethod,
        url: String,
        body: (any Encodable)?,
        queryParams: [String: String]
    ) async throws -> T {
        let (data, _) = try await requestRaw(method, url: url, body: body, queryParams: queryParams)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(underlying: error)
        }
    }

    func requestRaw(
        _ method: HTTPMethod,
        url: String,
        body: (any Encodable)?,
        queryParams: [String: String]
    ) async throws -> (Data, HTTPURLResponse) {
        // First attempt
        do {
            return try await performRequest(method, url: url, body: body, queryParams: queryParams)
        } catch APIError.unauthorized {
            // Auto-retry once on 401 — token may have expired mid-request
            return try await performRequest(method, url: url, body: body, queryParams: queryParams, forceRefresh: true)
        }
    }

    // MARK: - Private

    private func performRequest(
        _ method: HTTPMethod,
        url urlString: String,
        body: (any Encodable)?,
        queryParams: [String: String],
        forceRefresh: Bool = false
    ) async throws -> (Data, HTTPURLResponse) {
        guard var components = URLComponents(string: urlString) else {
            throw APIError.invalidResponse
        }

        if !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw APIError.invalidResponse
        }

        let token = try await authService.validAccessToken()

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Zoho-oauthtoken \(token)", forHTTPHeaderField: "Authorization")

        if let body, method == .post || method == .put {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet
            || urlError.code == .networkConnectionLost {
            throw APIError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try Self.validateStatus(httpResponse, data: data)
        return (data, httpResponse)
    }

    private static func validateStatus(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init)
            throw APIError.rateLimited(retryAfter: retryAfter)
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: response.statusCode, message: message)
        }
    }
}
