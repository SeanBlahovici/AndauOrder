import SwiftUI

struct ExportView: View {
    let formData: OrderFormData
    @State private var showingSavePanel = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                leadInfoSection
                dealInfoSection
                estimateLineItemsSection
                michelleInfoSection
                workflowChecklistSection
                pdfSection
            }
            .padding()
        }
    }

    // MARK: - Lead Info

    @ViewBuilder
    private var leadInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Lead Info (Zoho CRM)", icon: "person.crop.circle")

            let fields = leadFieldPairs
            CopyButton(title: "Copy All Lead Fields", textToCopy: formatLeadFieldsBlock(fields))

            ForEach(fields, id: \.label) { field in
                CopyableField(label: field.label, value: field.value)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var leadFieldPairs: [(label: String, value: String)] {
        let order = formData
        return [
            ("First Name", order.customer.firstName),
            ("Last Name", order.customer.lastName),
            ("Email", order.customer.email),
            ("Phone", order.customer.phone),
            ("Company", order.customer.clinicName),
            ("Street", order.customer.billingAddress.street),
            ("City", order.customer.billingAddress.city),
            ("Province", order.customer.billingAddress.stateProvince),
            ("Postal Code", order.customer.billingAddress.postalZipCode),
            ("Country", order.customer.billingAddress.country),
        ]
    }

    private func formatLeadFieldsBlock(_ fields: [(label: String, value: String)]) -> String {
        fields
            .filter { !$0.value.isEmpty }
            .map { "\($0.label): \($0.value)" }
            .joined(separator: "\n")
    }

    // MARK: - Deal Info

    @ViewBuilder
    private var dealInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Deal Info (Opportunities)", icon: "briefcase")

            let dealName = FieldMappings.dealName(from: formData)
            let amount = formatCurrency(formData.pricing.total)
            let closingDate = formatDate(formData.date)

            CopyableField(label: "Deal Name", value: dealName)
            CopyableField(label: "Amount", value: amount)
            CopyableField(label: "Closing Date", value: closingDate)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Estimate Line Items

    @ViewBuilder
    private var estimateLineItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Estimate Line Items (Zoho Books)", icon: "list.clipboard")

            let lineItems = FieldMappings.estimateLineItems(from: formData)

            if lineItems.isEmpty {
                Text("No line items — select products first.")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                CopyButton(
                    title: "Copy All Line Items",
                    textToCopy: formatAllLineItems(lineItems)
                )

                ForEach(Array(lineItems.enumerated()), id: \.offset) { _, item in
                    lineItemCard(item)
                }

                HStack {
                    Text("Subtotal")
                        .font(.headline)
                    Spacer()
                    Text(formatCurrency(formData.pricing.subtotal))
                        .font(.headline)
                }
                .padding(.top, 4)

                HStack {
                    Text("Tax (14.975%)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatCurrency(formData.pricing.tax))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Total")
                        .font(.title3.bold())
                    Spacer()
                    Text(formatCurrency(formData.pricing.total))
                        .font(.title3.bold())
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func lineItemCard(_ item: BooksLineItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body.weight(.medium))
                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(formatCurrency(item.rate))
                    .font(.body.weight(.medium))
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                CopyButton(title: "Name", textToCopy: item.name)
                    .controlSize(.small)
                CopyButton(title: "Rate", textToCopy: "\(item.rate)")
                    .controlSize(.small)
            }
        }
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func formatAllLineItems(_ items: [BooksLineItem]) -> String {
        var lines: [String] = []
        for item in items {
            var line = "\(item.name)\t$\(item.rate)"
            if let desc = item.description, !desc.isEmpty {
                line += "\t(\(desc))"
            }
            lines.append(line)
        }
        lines.append("")
        lines.append("Subtotal:\t\(formatCurrency(formData.pricing.subtotal))")
        lines.append("Tax (14.975%):\t\(formatCurrency(formData.pricing.tax))")
        lines.append("Total:\t\(formatCurrency(formData.pricing.total))")
        return lines.joined(separator: "\n")
    }

    // MARK: - Michelle's Info

    @ViewBuilder
    private var michelleInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Estimate Notes (Michelle's Info)", icon: "envelope")

            let notes = FieldMappings.estimateNotes(from: formData)

            Text(notes)
                .font(.body)
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            CopyButton(title: "Copy Notes Block", textToCopy: notes)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Workflow Checklist

    @ViewBuilder
    private var workflowChecklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Zoho Entry Workflow", icon: "list.number")

            let steps = [
                "Create Lead in CRM (use Lead Info above)",
                "Transition Lead: New \u{2192} TM Reached Out \u{2192} Customer Engaged",
                "In Opportunities: Transition to Qualified, set closing date & amount",
                "Demo Booked / Meeting Scheduled \u{2014} set demo date & follow-up",
                "Sync Account with Books",
                "Create Estimate in Books (use Line Items above)",
                "Add Michelle's info to estimate notes (use Notes Block above)",
                "Verify customer info in Customers",
                "Add credit card if available (More \u{2192} Add New Card)",
            ]

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 20, alignment: .trailing)
                    Text(step)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - PDF Export

    @ViewBuilder
    private var pdfSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Export", icon: "square.and.arrow.up")

            Button {
                PDFGenerator.saveOrderPDF(formData: formData)
            } label: {
                Label("Generate PDF", systemImage: "doc.richtext")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.title3.bold())
            .padding(.bottom, 4)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.locale = Locale(identifier: "en_CA")
        return formatter.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
