import SwiftUI

/// A currency input field that uses a bare TextField — the only pattern macOS Form doesn't break.
struct CurrencyField: View {
    let label: String
    @Binding var amount: Decimal

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(label, text: $text)
            .multilineTextAlignment(.trailing)
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
            .focused($isFocused)
            .onAppear { syncTextFromAmount() }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    // Show raw number for editing
                    if amount == 0 {
                        text = ""
                    } else {
                        text = plainNumber(from: amount)
                    }
                } else {
                    parseAndSync()
                    syncTextFromAmount()
                }
            }
            .onSubmit {
                parseAndSync()
                syncTextFromAmount()
            }
            .onChange(of: amount) { _, _ in
                if !isFocused {
                    syncTextFromAmount()
                }
            }
    }

    private func parseAndSync() {
        let cleaned = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let value = Decimal(string: cleaned) {
            amount = value
        } else {
            amount = 0
        }
    }

    private func syncTextFromAmount() {
        if amount == 0 {
            text = "$0.00"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "CAD"
            formatter.currencySymbol = "$"
            text = formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
        }
    }

    private func plainNumber(from value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }
}

/// Same as CurrencyField but for Double values (used in PriceCatalogView)
struct CurrencyFieldDouble: View {
    let label: String
    @Binding var amount: Double

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(label, text: $text)
            .multilineTextAlignment(.trailing)
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
            .focused($isFocused)
            .onAppear { syncTextFromAmount() }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    if amount == 0 {
                        text = ""
                    } else {
                        text = String(format: "%.2f", amount)
                    }
                } else {
                    parseAndSync()
                    syncTextFromAmount()
                }
            }
            .onSubmit {
                parseAndSync()
                syncTextFromAmount()
            }
            .onChange(of: amount) { _, _ in
                if !isFocused {
                    syncTextFromAmount()
                }
            }
    }

    private func parseAndSync() {
        let cleaned = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let value = Double(cleaned) {
            amount = value
        } else {
            amount = 0
        }
    }

    private func syncTextFromAmount() {
        if amount == 0 {
            text = "$0.00"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "CAD"
            formatter.currencySymbol = "$"
            text = formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
        }
    }
}
