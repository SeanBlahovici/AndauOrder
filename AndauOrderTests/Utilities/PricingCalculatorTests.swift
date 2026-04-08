import Foundation
import Testing
@testable import AndauOrder

@Suite("PricingCalculator")
struct PricingCalculatorTests {

    @Test("Subtotal sums all line items")
    func subtotalSumsAllItems() {
        let result = PricingCalculator.subtotal(
            loupes: 1000,
            internalCorrection: 200,
            externalCorrection: 173,
            light: 1160,
            flamingo: 0,
            laserInserts: 0,
            adapters: 0,
            shipping: 0,
            lessPromotion: -1000
        )
        #expect(result == 1533)
    }

    @Test("Tax is calculated correctly with Quebec rate")
    func taxCalculation() {
        let sub: Decimal = 1533
        let tax = PricingCalculator.tax(subtotal: sub, taxRate: PricingCalculator.quebecTaxRate)
        // 1533 * 0.14975 = 229.56675
        #expect(tax > 229 && tax < 230)
    }

    @Test("Tax is zero when subtotal is negative")
    func taxNeverNegative() {
        let tax = PricingCalculator.tax(subtotal: -500, taxRate: PricingCalculator.quebecTaxRate)
        #expect(tax == 0)
    }

    @Test("Total is subtotal plus tax")
    func totalCalculation() {
        let sub: Decimal = 1000
        let tax = PricingCalculator.tax(subtotal: sub, taxRate: PricingCalculator.quebecTaxRate)
        let total = PricingCalculator.total(subtotal: sub, tax: tax)
        #expect(total == sub + tax)
    }

    @Test("Promotion discount reduces subtotal")
    func promotionDiscount() {
        let result = PricingCalculator.subtotal(
            loupes: 2000,
            internalCorrection: 0,
            externalCorrection: 0,
            light: 0,
            flamingo: 0,
            laserInserts: 0,
            adapters: 0,
            shipping: 0,
            lessPromotion: -500
        )
        #expect(result == 1500)
    }
}
