import SwiftUI

/// A currency input field that works correctly on both macOS and iOS.
/// Uses LabeledContent to prevent macOS Form from splitting label/value incorrectly.
struct CurrencyField: View {
    let label: String
    @Binding var amount: Decimal

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        LabeledContent(label) {
            TextField("0.00", text: $text)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .frame(minWidth: 100)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .onChange(of: text) { _, newValue in
                    let cleaned = newValue.replacingOccurrences(of: ",", with: "")
                    if let value = Decimal(string: cleaned) {
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
            text = ""
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            text = formatter.string(from: amount as NSDecimalNumber) ?? ""
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
        LabeledContent(label) {
            TextField("$0.00", text: $text)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .frame(minWidth: 100)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .onChange(of: text) { _, newValue in
                    let cleaned = newValue
                        .replacingOccurrences(of: "$", with: "")
                        .replacingOccurrences(of: ",", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if let value = Double(cleaned) {
                        amount = value
                    } else if cleaned.isEmpty || cleaned == "-" {
                        amount = 0
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        syncTextFromAmount()
                    }
                }
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
            text = ""
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            text = formatter.string(from: NSNumber(value: amount)) ?? ""
        }
    }
}
