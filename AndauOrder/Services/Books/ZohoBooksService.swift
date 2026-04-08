import Foundation

// MARK: - Protocol

protocol ZohoBooksServiceProtocol: Sendable {
    func searchCustomer(email: String) async throws -> BooksContact?
    func createCustomer(from order: OrderFormData) async throws -> String
    func createEstimate(customerID: String, order: OrderFormData) async throws -> String
}

// MARK: - Implementation

final class ZohoBooksService: ZohoBooksServiceProtocol, @unchecked Sendable {

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

    // MARK: - Search Customer

    func searchCustomer(email: String) async throws -> BooksContact? {
        let url = "\(booksBaseURL)/contacts"
        var params = orgParams
        params["email"] = email

        let response: BooksContactListResponse = try await httpClient.request(.get, url: url, queryParams: params)
        return response.contacts.first
    }

    // MARK: - Create Customer

    func createCustomer(from order: OrderFormData) async throws -> String {
        let url = "\(booksBaseURL)/contacts"

        let body = BooksContactRequest(
            contact_name: "\(order.customer.firstName) \(order.customer.lastName)",
            company_name: order.customer.clinicName.isEmpty ? nil : order.customer.clinicName,
            contact_type: "customer",
            billing_address: Self.booksAddress(from: order.customer.billingAddress),
            shipping_address: Self.booksAddress(from: order.customer.effectiveShippingAddress)
        )

        let response: BooksContactResponse = try await httpClient.request(.post, url: url, body: body, queryParams: orgParams)
        return response.contact.contact_id
    }

    // MARK: - Create Estimate

    func createEstimate(customerID: String, order: OrderFormData) async throws -> String {
        let url = "\(booksBaseURL)/estimates"

        let body = BooksEstimateRequest(
            customer_id: customerID,
            date: Self.dateFormatter.string(from: order.date),
            line_items: FieldMappings.estimateLineItems(from: order),
            notes: FieldMappings.estimateNotes(from: order, defaults: defaults),
            terms: "Total amount does not include tax."
        )

        let response: BooksEstimateResponse = try await httpClient.request(.post, url: url, body: body, queryParams: orgParams)
        return response.estimate.estimate_id
    }

    // MARK: - Private Helpers

    private static func booksAddress(from address: Address) -> BooksAddress {
        BooksAddress(
            attention: nil,
            address: [address.street, address.street2].filter { !$0.isEmpty }.joined(separator: "\n"),
            city: address.city,
            state: address.stateProvince,
            zip: address.postalZipCode,
            country: address.country
        )
    }

    private var booksBaseURL: String {
        let envString = defaults.string(forKey: "zohoEnvironment") ?? "sandbox"
        let environment = ZohoEnvironment(rawValue: envString) ?? .sandbox
        return environment.booksBaseURL
    }

    private var orgParams: [String: String] {
        let orgID = defaults.string(forKey: "zohoOrgID") ?? ""
        return ["organization_id": orgID]
    }
}

// MARK: - Local Response Types

/// Wrapper for the contact search endpoint response.
private struct BooksContactListResponse: Decodable, Sendable {
    let code: Int
    let contacts: [BooksContact]
}
