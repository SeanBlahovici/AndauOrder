import Foundation

enum APIError: Error, LocalizedError, @unchecked Sendable {
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case notFound
    case serverError(statusCode: Int, message: String)
    case networkUnavailable
    case decodingFailed(underlying: Error)
    case invalidResponse
    case zohoError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "Authentication failed. Check your Zoho credentials in Settings."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                "Rate limited by Zoho. Retry after \(Int(seconds)) seconds."
            } else {
                "Rate limited by Zoho. Please wait and try again."
            }
        case .notFound:
            "The requested resource was not found in Zoho."
        case .serverError(let statusCode, let message):
            "Server error (\(statusCode)): \(message)"
        case .networkUnavailable:
            "Network unavailable. Check your internet connection."
        case .decodingFailed(let underlying):
            "Failed to parse Zoho response: \(underlying.localizedDescription)"
        case .invalidResponse:
            "Received an invalid response from Zoho."
        case .zohoError(let code, let message):
            "Zoho error [\(code)]: \(message)"
        }
    }
}
