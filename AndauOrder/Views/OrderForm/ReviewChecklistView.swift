import SwiftUI

struct ReviewChecklistView: View {
    @Binding var formData: OrderFormData

    var body: some View {
        Form {
            // Upon Review Checklist
            Section {
                ForEach(Array(formData.reviewChecklist.allItems.enumerated()), id: \.offset) { index, item in
                    Toggle(item.label, isOn: Binding(
                        get: { formData.reviewChecklist[keyPath: item.keyPath] },
                        set: { formData.reviewChecklist[keyPath: item.keyPath] = $0 }
                    ))
                }
            } header: {
                HStack {
                    Text("Upon Review")
                    Spacer()
                    Text("\(formData.reviewChecklist.completedCount)/\(formData.reviewChecklist.totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Referral Source
            Section("How Did You Hear About Us?") {
                ForEach(ReferralSource.allCases) { source in
                    Toggle(source.rawValue, isOn: Binding(
                        get: { formData.referralSources.contains(source) },
                        set: { isOn in
                            if isOn {
                                formData.referralSources.insert(source)
                            } else {
                                formData.referralSources.remove(source)
                            }
                        }
                    ))
                }
            }

            // Payment Status
            Section("Payment") {
                optionalBoolPicker("Paid?", selection: $formData.isPaid)

                Picker("Payment Type", selection: $formData.paymentType) {
                    Text("None").tag(PaymentType?.none)
                    ForEach([PaymentType.paidFull, .paymentPlan], id: \.self) { type in
                        Text(type.rawValue).tag(PaymentType?.some(type))
                    }
                }

                TextField("Name on Card", text: $formData.nameOnCard)
                    .textContentType(.name)

                Label(
                    "Credit card numbers are NOT stored in this app for PCI compliance. Use Square terminal for payment processing.",
                    systemImage: "lock.shield"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func optionalBoolPicker(_ label: String, selection: Binding<Bool?>) -> some View {
        Picker(label, selection: selection) {
            Text("—").tag(Bool?.none)
            Text("Yes").tag(Bool?.some(true))
            Text("No").tag(Bool?.some(false))
        }
    }
}
