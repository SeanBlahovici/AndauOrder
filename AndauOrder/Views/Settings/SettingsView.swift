import SwiftUI

struct SettingsView: View {
    @AppStorage("zohoEnvironment") private var zohoEnvironment = "sandbox"
    @AppStorage("zohoRefreshToken") private var refreshToken = ""
    @AppStorage("zohoClientID") private var clientID = ""
    @AppStorage("zohoClientSecret") private var clientSecret = ""
    @AppStorage("zohoOrgID") private var orgID = ""
    @AppStorage("michelleEmail") private var michelleEmail = ""
    @AppStorage("michellePhone") private var michellePhone = ""

    @State private var connectionTestResult: ConnectionTestResult?
    @State private var isTestingConnection = false

    var body: some View {
        Form {
            Section("Zoho Environment") {
                Picker("Environment", selection: $zohoEnvironment) {
                    Text("Sandbox").tag("sandbox")
                    Text("Production").tag("production")
                }
                .pickerStyle(.segmented)

                if zohoEnvironment == "production" {
                    Label(
                        "Production mode — changes will affect the live CRM.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                    .font(.caption)
                }
            }

            Section("Zoho API Credentials") {
                TextField("Client ID", text: $clientID)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                SecureField("Client Secret", text: $clientSecret)

                SecureField("Refresh Token", text: $refreshToken)

                TextField("Organization ID (Books)", text: $orgID)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif

                Label(
                    "Generate these from api-console.zoho.com → Self Client",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Button {
                    testConnection()
                } label: {
                    HStack {
                        if isTestingConnection {
                            ProgressView()
                                .controlSize(.small)
                            Text("Testing...")
                        } else {
                            Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    }
                }
                .disabled(clientID.isEmpty || clientSecret.isEmpty || refreshToken.isEmpty || isTestingConnection)

                if let result = connectionTestResult {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.results) { service in
                            Label(
                                "\(service.label): \(service.detail)",
                                systemImage: service.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundStyle(service.isSuccess ? .green : .red)
                            .font(.caption)
                        }
                    }
                }
            }

            Section("Michelle's Contact Info") {
                TextField("Email", text: $michelleEmail)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif

                TextField("Phone", text: $michellePhone)
                    .textContentType(.telephoneNumber)
                    #if os(iOS)
                    .keyboardType(.phonePad)
                    #endif

                Label(
                    "Auto-filled into Zoho Books estimate communications.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Sync") {
                NavigationLink {
                    SyncStatusView()
                } label: {
                    Label("Sync Status", systemImage: "arrow.trianglehead.2.clockwise")
                }
            }

            Section("Product Prices") {
                NavigationLink {
                    PriceCatalogView()
                } label: {
                    Label("Price Catalog", systemImage: "dollarsign.circle")
                }

                Label(
                    "Set base prices for products. Prices auto-fill when items are selected in orders.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }

    private var currentEnvironment: ZohoEnvironment {
        ZohoEnvironment(rawValue: zohoEnvironment) ?? .sandbox
    }

    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil

        // Clear cached access token so we force a fresh refresh with current credentials
        let tokenStore = TokenStore()
        tokenStore.accessToken = nil
        tokenStore.accessTokenExpiry = nil

        Task {
            var results: [ServiceTestResult] = []
            let authService = ZohoAuthService()

            // 1. Test OAuth
            do {
                _ = try await authService.validAccessToken()
                results.append(ServiceTestResult(label: "OAuth", isSuccess: true, detail: "Token refresh OK"))
            } catch {
                results.append(ServiceTestResult(label: "OAuth", isSuccess: false, detail: error.localizedDescription))
                connectionTestResult = ConnectionTestResult(results: results)
                isTestingConnection = false
                return
            }

            let httpClient = HTTPClient(authService: authService)

            // 2. Test CRM access
            do {
                let crmURL = "\(currentEnvironment.crmBaseURL)/Leads"
                _ = try await httpClient.requestRaw(.get, url: crmURL, queryParams: ["fields": "id", "per_page": "1"])
                results.append(ServiceTestResult(label: "CRM", isSuccess: true, detail: "Leads module accessible"))
            } catch {
                results.append(ServiceTestResult(label: "CRM", isSuccess: false, detail: error.localizedDescription))
            }

            // 3. Test Books access
            if orgID.isEmpty {
                results.append(ServiceTestResult(label: "Books", isSuccess: false, detail: "Organization ID not set"))
            } else {
                do {
                    let booksURL = "\(currentEnvironment.booksBaseURL)/contacts"
                    _ = try await httpClient.requestRaw(.get, url: booksURL, queryParams: ["organization_id": orgID, "per_page": "1"])
                    results.append(ServiceTestResult(label: "Books", isSuccess: true, detail: "Contacts module accessible"))
                } catch {
                    results.append(ServiceTestResult(label: "Books", isSuccess: false, detail: error.localizedDescription))
                }
            }

            connectionTestResult = ConnectionTestResult(results: results)
            isTestingConnection = false
        }
    }
}

private struct ServiceTestResult: Identifiable {
    let id = UUID()
    let label: String
    let isSuccess: Bool
    let detail: String
}

private struct ConnectionTestResult {
    let results: [ServiceTestResult]

    var isSuccess: Bool {
        results.allSatisfy(\.isSuccess)
    }

    var message: String {
        results.map { "\($0.label): \($0.detail)" }.joined(separator: " · ")
    }
}
