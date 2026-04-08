import SwiftUI

struct SettingsView: View {
    @AppStorage("zohoEnvironment") private var zohoEnvironment = "sandbox"
    @AppStorage("zohoRefreshToken") private var refreshToken = ""
    @AppStorage("zohoClientID") private var clientID = ""
    @AppStorage("zohoClientSecret") private var clientSecret = ""
    @AppStorage("zohoOrgID") private var orgID = ""
    @AppStorage("michelleEmail") private var michelleEmail = ""
    @AppStorage("michellePhone") private var michellePhone = ""

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
}
