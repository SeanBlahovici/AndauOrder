import SwiftUI
import SwiftData

struct SyncStatusView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OrderRecord.updatedAt, order: .reverse) private var orders: [OrderRecord]
    @Environment(SyncCoordinator.self) private var syncCoordinator

    var body: some View {
        List {
            Section {
                Button("Sync All Now") {
                    Task { @MainActor in await syncCoordinator.syncNow(modelContext: modelContext) }
                }
                .disabled(!syncCoordinator.isConnected)
            }

            ForEach(syncableOrders) { order in
                Section(order.customerName) {
                    HStack {
                        Text("Status")
                        Spacer()
                        SyncStatusBadge(status: order.syncStatus)
                    }

                    SyncStepsView(orderID: order.id)

                    if order.syncStatus == .failed {
                        Button("Retry Failed Steps") {
                            Task { @MainActor in
                                await syncCoordinator.syncEngine.retryFailed(orderID: order.id, modelContext: modelContext)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sync Status")
    }

    private var syncableOrders: [OrderRecord] {
        orders.filter { $0.syncStatus != .draft }
    }
}

// MARK: - Sync Steps View

private struct SyncStepsView: View {
    let orderID: UUID
    @Environment(\.modelContext) private var modelContext
    @State private var entries: [SyncQueueEntry] = []

    var body: some View {
        ForEach(entries, id: \.id) { entry in
            HStack {
                Image(systemName: iconName(for: entry.status))
                    .foregroundStyle(iconColor(for: entry.status))
                Text(entry.stepType.displayLabel)
                Spacer()
                if entry.status == .failed, let error = entry.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
            .font(.caption)
        }
        .onAppear { fetchEntries() }
    }

    private func fetchEntries() {
        let targetOrderID = orderID
        do {
            entries = try modelContext.fetch(
                FetchDescriptor<SyncQueueEntry>(
                    predicate: #Predicate<SyncQueueEntry> { $0.orderID == targetOrderID },
                    sortBy: [SortDescriptor(\.stepOrder)]
                )
            )
        } catch {
            print("Failed to fetch sync entries: \(error)")
        }
    }

    private func iconName(for status: SyncStepStatus) -> String {
        switch status {
        case .pending: "circle"
        case .inProgress: "arrow.trianglehead.2.clockwise"
        case .completed: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        case .skipped: "minus.circle"
        }
    }

    private func iconColor(for status: SyncStepStatus) -> Color {
        switch status {
        case .pending: .secondary
        case .inProgress: .blue
        case .completed: .green
        case .failed: .red
        case .skipped: .secondary
        }
    }
}
