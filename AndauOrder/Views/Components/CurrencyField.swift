import SwiftUI

/// A currency input field that works correctly on both macOS and iOS.
/// Avoids the macOS `TextField(value:format:)` double-rendering issue.
struct CurrencyField: View {
    let label: String
    @Binding var amount: Decimal

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 4) {
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $text)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .textFieldStyle(.plain)
                    .onChange(of: text) { _, newValue in
                        // Parse text to Decimal
                        let cleaned = newValue.replacingOccurrences(of: ",", with: "")
                        if let value = Decimal(string: cleaned) {
                            amount = value
                        } else if newValue.isEmpty || newValue == "-" {
                            amount = 0
                        }
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            // Format on blur
                            syncTextFromAmount()
                        }
                    }
            }
            .frame(width: 130)
        }
        .onAppear {
            syncTextFromAmount()
        }
        .onChange(of: amount) { _, _ in
            if !isFocused {
                syncTextFromAmount()
            }
        }
    }

    private func syncTextFromAmount() {
        if amount == 0 {
            text = "0.00"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            text = formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
        }
    }
}

/// Same as CurrencyField but for Double values (used in PriceCatalogView)
struct CurrencyFieldDouble: View {
    let label: String
    @Binding var amount: Double

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 4) {
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $text)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .textFieldStyle(.plain)
                    .onChange(of: text) { _, newValue in
                        let cleaned = newValue.replacingOccurrences(of: ",", with: "")
                        if let value = Double(cleaned) {
                            amount = value
                        } else if newValue.isEmpty || newValue == "-" {
                            amount = 0
                        }
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            syncTextFromAmount()
                        }
                    }
            }
            .frame(width: 130)
        }
        .onAppear {
            syncTextFromAmount()
        }
        .onChange(of: amount) { _, _ in
            if !isFocused {
                syncTextFromAmount()
            }
        }
    }

    private func syncTextFromAmount() {
        if amount == 0 {
            text = "0.00"
        } else {
            text = String(format: "%.2f", amount)
        }
    }
}
