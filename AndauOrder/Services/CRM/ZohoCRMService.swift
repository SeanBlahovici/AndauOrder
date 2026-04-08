import Foundation

// MARK: - Protocol

protocol ZohoCRMServiceProtocol: Sendable {
    func createLead(from order: OrderFormData) async throws -> String
    func getBlueprint(module: String, recordID: String) async throws -> [BlueprintTransition]
    func executeTransition(module: String, recordID: String, transitionID: String, data: [String: Any]?) async throws
    func convertLead(leadID: String, order: OrderFormData) async throws -> (contactID: String, accountID: String, dealID: String)
    func updateDeal(dealID: String, stage: String, closingDate: Date, amount: Decimal) async throws
}

// MARK: - Implementation

final class ZohoCRMService: ZohoCRMServiceProtocol, Sendable {

    private let httpClient: any HTTPClientProtocol
    private let defaults: UserDefaults

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    init(httpClient: any HTTPClientProtocol, defaults: UserDefaults = .standard) {
        self.httpClient = httpClient
        self.defaults = defaults
    }

    // MARK: - Create Lead

    func createLead(from order: OrderFormData) async throws -> String {
        let url = "\(crmBaseURL)/Leads"
        let fields = FieldMappings.leadFields(from: order)
        let body = try Self.rawJSONBody(["data": [fields]])

        let response: CRMResponse<CRMRecordID> = try await httpClient.request(.post, url: url, body: body)

        guard let record = response.data?.first else {
            throw APIError.invalidResponse
        }

        if let code = record.code, code != "SUCCESS" {
            throw APIError.zohoError(code: code, message: record.message ?? "Unknown error")
        }

        guard let leadID = record.details?.id else {
            throw APIError.invalidResponse
        }

        return leadID
    }

    // MARK: - Get Blueprint

    func getBlueprint(module: String, recordID: String) async throws -> [BlueprintTransition] {
        let url = "\(crmBaseURL)/\(module)/\(recordID)/actions/blueprint"
        let response: BlueprintResponse = try await httpClient.request(.get, url: url)
        return response.blueprint.transitions
    }

    // MARK: - Execute Transition

    func executeTransition(module: String, recordID: String, transitionID: String, data: [String: Any]?) async throws {
        let url = "\(crmBaseURL)/\(module)/\(recordID)/actions/blueprint"

        // Build body manually via JSONSerialization since [String: Any] is not Encodable.
        // Use requestRaw and pass the body as a RawJSON wrapper that re-emits pre-serialized bytes.
        var transitionDict: [String: Any] = ["transition_id": transitionID]
        if let data {
            transitionDict["data"] = data
        }
        let bodyDict: [String: Any] = ["blueprint": [transitionDict]]

        let rawBody = try Self.rawJSONBody(bodyDict)

        let (_, response) = try await httpClient.requestRaw(.put, url: url, body: rawBody)

        guard (200...299).contains(response.statusCode) else {
            throw APIError.serverError(statusCode: response.statusCode, message: "Blueprint transition failed")
        }
    }

    // MARK: - Convert Lead

    func convertLead(leadID: String, order: OrderFormData) async throws -> (contactID: String, accountID: String, dealID: String) {
        let url = "\(crmBaseURL)/Leads/\(leadID)/actions/convert"
        let dealName = FieldMappings.dealName(from: order)
        let closingDate = Self.dateFormatter.string(from: order.date)

        let convertRequest = ConvertLeadRequest(
            Deals: ConvertDealData(
                Deal_Name: dealName,
                Closing_Date: closingDate,
                Stage: "Qualification",
                Amount: order.pricing.total
            )
        )
        let body = CRMDataWrapper(data: [convertRequest])

        let response: CRMResponse<ConvertLeadResponse> = try await httpClient.request(.post, url: url, body: body)

        guard let result = response.data?.first?.details else {
            throw APIError.invalidResponse
        }

        return (
            contactID: result.Contacts.id,
            accountID: result.Accounts.id,
            dealID: result.Deals.id
        )
    }

    // MARK: - Update Deal

    func updateDeal(dealID: String, stage: String, closingDate: Date, amount: Decimal) async throws {
        let url = "\(crmBaseURL)/Deals"
        let dateString = Self.dateFormatter.string(from: closingDate)

        let dealUpdate = DealUpdateRecord(
            id: dealID,
            Stage: stage,
            Closing_Date: dateString,
            Amount: amount
        )
        let body = CRMDataWrapper(data: [dealUpdate])

        let response: CRMResponse<CRMRecordID> = try await httpClient.request(.put, url: url, body: body)

        if let record = response.data?.first, let code = record.code, code != "SUCCESS" {
            throw APIError.zohoError(code: code, message: record.message ?? "Unknown error")
        }
    }

    // MARK: - Private Helpers

    /// Converts a `[String: Any]` dictionary into a `RawJSON`-wrapped `Encodable` body.
    private static func rawJSONBody(_ dict: [String: Any]) throws -> RawJSON {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return RawJSON(data: data)
    }

    private var crmBaseURL: String {
        let envString = defaults.string(forKey: "zohoEnvironment") ?? "sandbox"
        let environment = ZohoEnvironment(rawValue: envString) ?? .sandbox
        return environment.crmBaseURL
    }
}

// MARK: - Private DTOs

/// Generic wrapper for CRM request bodies: `{ "data": [...] }`
private struct CRMDataWrapper<T: Encodable>: Encodable {
    let data: [T]
}

/// Wraps pre-serialized JSON `Data` so it passes through `JSONEncoder` unchanged.
///
/// When `HTTPClient` calls `JSONEncoder().encode(body)`, this type's custom
/// `encode(to:)` writes the raw bytes directly, preserving the original JSON structure
/// built via `JSONSerialization`.
private struct RawJSON: Encodable {
    let data: Data

    func encode(to encoder: any Encoder) throws {
        // JSONEncoder uses _JSONEncoder internally; singleValueContainer + encode(Data)
        // would base64-encode the data. Instead, decode the pre-built JSON into a
        // recursively-Encodable JSONValue and encode that.
        let value = try JSONValue.from(data)
        try value.encode(to: encoder)
    }
}

/// A recursively-Encodable representation of arbitrary JSON, used to bridge
/// `JSONSerialization` output into `Encodable` for `JSONEncoder`.
private enum JSONValue: Encodable {
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([(String, JSONValue)])

    static func from(_ data: Data) throws -> JSONValue {
        let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        return wrap(obj)
    }

    private static func wrap(_ value: Any) -> JSONValue {
        switch value {
        case let bool as Bool:
            return .bool(bool)
        case let number as NSNumber:
            return .number(number)
        case let string as String:
            return .string(string)
        case let array as [Any]:
            return .array(array.map { wrap($0) })
        case let dict as [String: Any]:
            // Preserve insertion order from JSONSerialization
            let pairs = dict.map { (key: $0.key, value: wrap($0.value)) }
            return .object(pairs)
        default:
            return .null
        }
    }

    func encode(to encoder: any Encoder) throws {
        switch self {
        case .string(let s):
            var container = encoder.singleValueContainer()
            try container.encode(s)
        case .number(let n):
            var container = encoder.singleValueContainer()
            // Encode as the most appropriate numeric type
            if CFNumberIsFloatType(n) {
                try container.encode(n.doubleValue)
            } else {
                try container.encode(n.int64Value)
            }
        case .bool(let b):
            var container = encoder.singleValueContainer()
            try container.encode(b)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .array(let values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try container.encode(value)
            }
        case .object(let pairs):
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in pairs {
                try container.encode(value, forKey: DynamicCodingKey(key))
            }
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        self.stringValue = string
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

/// Deal update record for PUT /Deals
private struct DealUpdateRecord: Encodable {
    let id: String
    let Stage: String
    let Closing_Date: String
    let Amount: Decimal
}
