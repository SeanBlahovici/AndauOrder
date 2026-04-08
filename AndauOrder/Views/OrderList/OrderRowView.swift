import SwiftUI

struct OrderRowView: View {
    let order: OrderRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.customerName)
                    .font(.headline)

                if !order.productSummary.isEmpty {
                    Text(order.productSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(order.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            SyncStatusBadge(status: order.syncStatus)
        }
        .padding(.vertical, 2)
    }
}
