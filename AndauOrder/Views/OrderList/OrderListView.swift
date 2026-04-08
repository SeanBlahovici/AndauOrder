import SwiftUI

struct OrderListView: View {
    let orders: [OrderRecord]
    @Binding var selectedOrderID: UUID?
    var onNewOrder: () -> Void
    var onDelete: (OrderRecord) -> Void

    @State private var searchText = ""

    private var filteredOrders: [OrderRecord] {
        if searchText.isEmpty { return orders }
        return orders.filter { order in
            order.customerName.localizedCaseInsensitiveContains(searchText)
                || order.productSummary.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredOrders, id: \.id, selection: $selectedOrderID) { order in
            OrderRowView(order: order)
                .contextMenu {
                    if let formData = order.orderData {
                        Button {
                            PDFGenerator.saveOrderPDF(formData: formData)
                        } label: {
                            Label("Export to PDF", systemImage: "doc.richtext")
                        }
                    }
                    if order.syncStatus == .draft || order.syncStatus == .failed {
                        Button(role: .destructive) {
                            onDelete(order)
                        } label: {
                            Label("Delete Order", systemImage: "trash")
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if order.syncStatus == .draft || order.syncStatus == .failed {
                        Button(role: .destructive) {
                            onDelete(order)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
        }
        .searchable(text: $searchText, prompt: "Search orders")
        .navigationTitle("Orders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onNewOrder) {
                    Label("New Order", systemImage: "plus")
                }
            }
        }
        .overlay {
            if orders.isEmpty {
                ContentUnavailableView {
                    Label("No Orders", systemImage: "doc.text")
                } description: {
                    Text("Tap + to create your first order.")
                }
            }
        }
    }
}
