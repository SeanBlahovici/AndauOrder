import Foundation
import Observation
import SwiftData

@Observable
final class OrderListViewModel {
    var searchText: String = ""
    var selectedOrderID: UUID?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createNewOrder() -> OrderRecord {
        let order = OrderRecord(orderData: OrderFormData())
        modelContext.insert(order)
        try? modelContext.save()
        selectedOrderID = order.id
        return order
    }

    func deleteOrder(_ order: OrderRecord) {
        if selectedOrderID == order.id {
            selectedOrderID = nil
        }
        modelContext.delete(order)
        try? modelContext.save()
    }
}
