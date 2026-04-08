import SwiftUI

struct PricingView: View {
    @Binding var formData: OrderFormData
    var onRecalculate: (() -> Void)?

    var body: some View {
        Form {
            Section {
                Button {
                    onRecalculate?()
                } label: {
                    Label("Recalculate from Catalog", systemImage: "arrow.trianglehead.2.clockwise")
                }

                Label(
                    "Prices auto-fill from your catalog when you tap Recalculate. You can override any value manually.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Line Items") {
                CurrencyField(label: "Loupes", amount: $formData.pricing.loupes)
                CurrencyField(label: "Internal Correction", amount: $formData.pricing.internalCorrection)
                CurrencyField(label: "External Correction", amount: $formData.pricing.externalCorrection)
                CurrencyField(label: "Light", amount: $formData.pricing.light)
                CurrencyField(label: "Flamingo", amount: $formData.pricing.flamingo)
                CurrencyField(label: "Laser Inserts", amount: $formData.pricing.laserInserts)
                CurrencyField(label: "Adapters", amount: $formData.pricing.adapters)
                CurrencyField(label: "Shipping", amount: $formData.pricing.shipping)
                CurrencyField(label: "Less Promotion", amount: $formData.pricing.lessPromotion)
            }

            Section("Tax") {
                HStack {
                    Text("Tax Rate")
                    Spacer()
                    TextField("14.975", text: taxRateText)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                        .frame(width: 80)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("%")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Totals") {
                totalRow("Subtotal", amount: formData.pricing.subtotal)
                totalRow("Tax", amount: formData.pricing.tax)
                totalRow("Total", amount: formData.pricing.total, bold: true)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            onRecalculate?()
        }
    }

    private var taxRateText: Binding<String> {
        Binding(
            get: {
                let pct = formData.pricing.taxRate * 100
                let formatter = NumberFormatter()
                formatter.minimumFractionDigits = 1
                formatter.maximumFractionDigits = 3
                return formatter.string(from: pct as NSDecimalNumber) ?? "14.975"
            },
            set: { newValue in
                if let value = Decimal(string: newValue) {
                    formData.pricing.taxRate = value / 100
                }
            }
        )
    }

    @ViewBuilder
    private func totalRow(_ label: String, amount: Decimal, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(amount, format: .currency(code: "CAD"))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(bold ? .primary : .secondary)
        }
    }
}
