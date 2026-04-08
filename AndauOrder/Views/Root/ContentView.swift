import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OrderRecord.updatedAt, order: .reverse) private var orders: [OrderRecord]
    @State private var selectedOrderID: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            OrderListView(
                orders: orders,
                selectedOrderID: $selectedOrderID,
                onNewOrder: createNewOrder,
                onDelete: deleteOrder
            )
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        createSampleOrder()
                    } label: {
                        Label("Sample Order", systemImage: "flask")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        } detail: {
            if let selectedOrderID,
               let order = orders.first(where: { $0.id == selectedOrderID }) {
                OrderFormContainerView(orderRecord: order)
            } else {
                ContentUnavailableView(
                    "Select an Order",
                    systemImage: "doc.text",
                    description: Text("Choose an order from the sidebar or create a new one.")
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
    }

    private func createNewOrder() {
        let order = OrderRecord(orderData: OrderFormData())
        modelContext.insert(order)
        try? modelContext.save()
        selectedOrderID = order.id
    }

    private func deleteOrder(_ order: OrderRecord) {
        if selectedOrderID == order.id {
            selectedOrderID = nil
        }
        modelContext.delete(order)
        try? modelContext.save()
    }

    private func createSampleOrder() {
        let formData = SampleOrderFactory.create()
        let order = OrderRecord(orderData: formData)
        modelContext.insert(order)
        try? modelContext.save()
        selectedOrderID = order.id
    }
}
