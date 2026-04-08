import Foundation

struct OrderPricing: Codable, Sendable, Equatable {
    var loupes: Decimal = 0
    var internalCorrection: Decimal = 0
    var externalCorrection: Decimal = 0
    var light: Decimal = 0
    var flamingo: Decimal = 0
    var laserInserts: Decimal = 0
    var adapters: Decimal = 0
    var shipping: Decimal = 0
    var lessPromotion: Decimal = 0

    /// Tax rate as a decimal (e.g., 0.14975 for Quebec's combined GST+QST)
    var taxRate: Decimal = 0.14975

    var subtotal: Decimal {
        loupes + internalCorrection + externalCorrection + light
            + flamingo + laserInserts + adapters + shipping + lessPromotion
    }

    var tax: Decimal {
        max(subtotal * taxRate, 0)
    }

    var total: Decimal {
        subtotal + tax
    }

    /// All line items with their labels and amounts, for display and estimate creation
    var lineItems: [(label: String, amount: Decimal)] {
        var items: [(String, Decimal)] = []
        if loupes != 0 { items.append(("Loupes", loupes)) }
        if internalCorrection != 0 { items.append(("Internal Correction", internalCorrection)) }
        if externalCorrection != 0 { items.append(("External Correction", externalCorrection)) }
        if light != 0 { items.append(("Light", light)) }
        if flamingo != 0 { items.append(("Flamingo", flamingo)) }
        if laserInserts != 0 { items.append(("Laser Inserts", laserInserts)) }
        if adapters != 0 { items.append(("Adapters", adapters)) }
        if shipping != 0 { items.append(("Shipping", shipping)) }
        if lessPromotion != 0 { items.append(("Promotion Discount", lessPromotion)) }
        return items
    }
}
