import Foundation

enum PricingCalculator {
    /// Calculate subtotal from all line item amounts
    static func subtotal(
        loupes: Decimal,
        internalCorrection: Decimal,
        externalCorrection: Decimal,
        light: Decimal,
        flamingo: Decimal,
        laserInserts: Decimal,
        adapters: Decimal,
        shipping: Decimal,
        lessPromotion: Decimal
    ) -> Decimal {
        loupes + internalCorrection + externalCorrection + light
            + flamingo + laserInserts + adapters + shipping + lessPromotion
    }

    /// Calculate tax from subtotal and rate
    static func tax(subtotal: Decimal, taxRate: Decimal) -> Decimal {
        max(subtotal * taxRate, 0)
    }

    /// Calculate total from subtotal and tax
    static func total(subtotal: Decimal, tax: Decimal) -> Decimal {
        subtotal + tax
    }

    /// Quebec combined GST (5%) + QST (9.975%)
    static let quebecTaxRate: Decimal = 0.14975
}
