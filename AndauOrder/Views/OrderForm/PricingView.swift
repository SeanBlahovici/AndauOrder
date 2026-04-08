import SwiftUI

struct PricingView: View {
    @Binding var formData: OrderFormData

    var body: some View {
        Form {
            Section("Line Items") {
                currencyField("Loupes", value: $formData.pricing.loupes)
                currencyField("Internal Correction", value: $formData.pricing.internalCorrection)
                currencyField("External Correction", value: $formData.pricing.externalCorrection)
                currencyField("Light", value: $formData.pricing.light)
                currencyField("Flamingo", value: $formData.pricing.flamingo)
                currencyField("Laser Inserts", value: $formData.pricing.laserInserts)
                currencyField("Adapters", value: $formData.pricing.adapters)
                currencyField("Shipping", value: $formData.pricing.shipping)
                currencyField("Less Promotion", value: $formData.pricing.lessPromotion)
            }

            Section("Tax") {
                HStack {
                    Text("Tax Rate")
                    Spacer()
                    TextField(
                        "Rate",
                        value: $formData.pricing.taxRate,
                        format: .percent
                    )
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                }
            }

            Section("Totals") {
                totalRow("Subtotal", amount: formData.pricing.subtotal)
                totalRow("Tax", amount: formData.pricing.tax)
                totalRow("Total", amount: formData.pricing.total, bold: true)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func currencyField(_ label: String, value: Binding<Decimal>) -> some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 2) {
                Text("$").foregroundStyle(.secondary)
                TextField("0", value: value, format: .number.precision(.fractionLength(2)))
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
            .frame(width: 120)
        }
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
