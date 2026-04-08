import SwiftUI

struct ReviewSubmitView: View {
    let viewModel: OrderFormViewModel

    private var formData: OrderFormData { viewModel.formData }

    var body: some View {
        Form {
            // Summary
            Section("Customer") {
                summaryRow("Name", value: formData.customer.fullName)
                summaryRow("Email", value: formData.customer.email)
                summaryRow("Phone", value: formData.customer.phone)
                summaryRow("Clinic", value: formData.customer.clinicName)
                summaryRow("Specialty", value: formData.customer.specialty)
                if formData.customer.isStudent {
                    summaryRow("Student", value: "Yes — \(formData.customer.studentInfo?.schoolName ?? "")")
                }
            }

            Section("Products") {
                summaryRow("Loupes", value: formData.loupeSelection.displayDescription)
                summaryRow("Headlight", value: formData.headlightSelection.displayDescription)
                summaryRow("PPE", value: formData.ppeSelection.displayDescription)
                summaryRow("Adapter", value: formData.adapterSelection.displayDescription)
                if !formData.otherNotes.isEmpty {
                    summaryRow("Notes", value: formData.otherNotes)
                }
            }

            Section("Customization") {
                if !formData.customization.customEngraving.isEmpty {
                    summaryRow("Engraving", value: formData.customization.customEngraving)
                }
                if let wd = formData.customization.workingDistanceInches {
                    summaryRow("Working Distance", value: "\(wd) in")
                }
                if formData.prescription.internalType != nil || formData.prescription.externalType != nil {
                    summaryRow("Internal Rx", value: formData.prescription.internalType?.rawValue ?? "None")
                    summaryRow("External Rx", value: formData.prescription.externalType?.rawValue ?? "None")
                }
            }

            Section("Pricing") {
                ForEach(formData.pricing.lineItems, id: \.label) { item in
                    HStack {
                        Text(item.label)
                        Spacer()
                        Text(item.amount, format: .currency(code: "CAD"))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(formData.pricing.total, format: .currency(code: "CAD"))
                        .fontWeight(.bold)
                }
            }

            Section("Review Checklist") {
                HStack {
                    Text("Completed")
                    Spacer()
                    Text("\(formData.reviewChecklist.completedCount)/\(formData.reviewChecklist.totalCount)")
                        .foregroundStyle(
                            formData.reviewChecklist.isComplete ? .green : .orange
                        )
                }
            }

            // Actions
            Section {
                Button {
                    viewModel.save()
                } label: {
                    Label("Save as Draft", systemImage: "doc")
                        .frame(maxWidth: .infinity)
                }

                Button {
                    viewModel.markForSync()
                } label: {
                    Label("Submit to Zoho", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .disabled(!viewModel.isReadyToSubmit)

                if !viewModel.isReadyToSubmit {
                    Label(
                        "Complete required fields (customer name, email, and loupe selection) to submit.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func summaryRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
        }
    }
}
