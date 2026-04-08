import Foundation
import SwiftData

@Model
final class CachedZohoItem {
    @Attribute(.unique) var itemID: String
    var name: String
    var sku: String?
    var rate: Double
    var productType: String
    var lastFetched: Date

    init(itemID: String, name: String, sku: String? = nil, rate: Double, productType: String) {
        self.itemID = itemID
        self.name = name
        self.sku = sku
        self.rate = rate
        self.productType = productType
        self.lastFetched = Date()
    }
}
