import Foundation
import Security

/// Keychain-backed storage for Zoho OAuth tokens.
struct TokenStore: Sendable {

    private static let service = "com.andaumedical.order.zoho"

    // MARK: - Keys

    private enum Key: String {
        case accessToken
        case accessTokenExpiry
        case refreshToken
    }

    // MARK: - Access Token

    var accessToken: String? {
        get { Self.read(key: .accessToken) }
        nonmutating set {
            if let newValue {
                Self.upsert(key: .accessToken, value: newValue)
            } else {
                Self.delete(key: .accessToken)
            }
        }
    }

    var accessTokenExpiry: Date? {
        get {
            guard let raw = Self.read(key: .accessTokenExpiry),
                  let interval = TimeInterval(raw) else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        nonmutating set {
            if let newValue {
                let raw = String(newValue.timeIntervalSince1970)
                Self.upsert(key: .accessTokenExpiry, value: raw)
            } else {
                Self.delete(key: .accessTokenExpiry)
            }
        }
    }

    var refreshToken: String? {
        get { Self.read(key: .refreshToken) }
        nonmutating set {
            if let newValue {
                Self.upsert(key: .refreshToken, value: newValue)
            } else {
                Self.delete(key: .refreshToken)
            }
        }
    }

    // MARK: - Clear All

    func clearAll() {
        Self.delete(key: .accessToken)
        Self.delete(key: .accessTokenExpiry)
        Self.delete(key: .refreshToken)
    }

    // MARK: - Keychain Helpers

    private static func baseQuery(key: Key) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
    }

    private static func read(key: Key) -> String? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private static func upsert(key: Key, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query = baseQuery(key: key)
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private static func delete(key: Key) {
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)
    }
}
