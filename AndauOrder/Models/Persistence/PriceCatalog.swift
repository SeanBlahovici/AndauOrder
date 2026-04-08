import Foundation
import SwiftData

@Model
final class PriceCatalogEntry {
    @Attribute(.unique) var key: String
    var category: String
    var label: String
    var price: Double
    var updatedAt: Date

    init(key: String, category: String, label: String, price: Double) {
        self.key = key
        self.category = category
        self.label = label
        self.price = price
        self.updatedAt = Date()
    }

    var decimalPrice: Decimal {
        Decimal(price)
    }
}

// MARK: - Catalog Key Helpers

enum PriceCatalogKey {
    // Loupes: keyed by style raw value
    static func loupe(_ style: LoupeStyle) -> String {
        "loupe.\(style.rawValue)"
    }

    // Frames: keyed by frame model
    static func frame(_ frame: FrameModel) -> String {
        "frame.\(frame.rawValue)"
    }

    // Headlights: keyed by type
    static func headlight(_ type: HeadlightType) -> String {
        "headlight.\(type.rawValue)"
    }

    // Fixed-key accessories
    static let extraBattery = "accessory.extraBattery"
    static let orchidCord3_5ft = "accessory.orchidCord3_5ft"
    static let orchidCord5ft = "accessory.orchidCord5ft"
    static let sideShield = "ppe.sideShield"
    static let laserProtection = "ppe.laserProtection"

    // Adapters: keyed by type
    static func adapter(_ type: AdapterType) -> String {
        "adapter.\(type.rawValue)"
    }

    // Corrections
    static let internalRegular = "correction.internal.regular"
    static let internalSpecial = "correction.internal.special"
    static let externalRegular = "correction.external.regular"
    static let externalSpecial = "correction.external.special"
    static let externalMultiFocal = "correction.external.multiFocal"

    // Other
    static let flamingo = "other.flamingo"
    static let laserInserts = "other.laserInserts"
    static let shipping = "other.shipping"
}

// MARK: - Catalog Lookup

enum PriceCatalogLookup {
    /// Look up a price from a list of catalog entries by key
    static func price(for key: String, in catalog: [PriceCatalogEntry]) -> Decimal {
        catalog.first(where: { $0.key == key })?.decimalPrice ?? 0
    }

    /// Build pricing from product selections using the catalog
    static func buildPricing(from formData: OrderFormData, catalog: [PriceCatalogEntry]) -> OrderPricing {
        var pricing = formData.pricing

        // Loupes price = loupe style price (frame is included)
        if let style = formData.loupeSelection.style {
            pricing.loupes = price(for: PriceCatalogKey.loupe(style), in: catalog)
        }

        // Internal correction
        if let internalType = formData.prescription.internalType {
            let key = internalType == .regular
                ? PriceCatalogKey.internalRegular
                : PriceCatalogKey.internalSpecial
            pricing.internalCorrection = price(for: key, in: catalog)
        }

        // External correction
        if let externalType = formData.prescription.externalType {
            let key: String
            switch externalType {
            case .regular: key = PriceCatalogKey.externalRegular
            case .special: key = PriceCatalogKey.externalSpecial
            case .multiFocal: key = PriceCatalogKey.externalMultiFocal
            }
            pricing.externalCorrection = price(for: key, in: catalog)
        }

        // Headlight
        var lightTotal: Decimal = 0
        if let type = formData.headlightSelection.type {
            lightTotal += price(for: PriceCatalogKey.headlight(type), in: catalog)
        }
        if formData.headlightSelection.extraBattery {
            lightTotal += price(for: PriceCatalogKey.extraBattery, in: catalog)
        }
        if formData.headlightSelection.orchidCord3_5ft {
            lightTotal += price(for: PriceCatalogKey.orchidCord3_5ft, in: catalog)
        }
        if formData.headlightSelection.orchidCord5ft {
            lightTotal += price(for: PriceCatalogKey.orchidCord5ft, in: catalog)
        }
        pricing.light = lightTotal

        // Flamingo
        pricing.flamingo = price(for: PriceCatalogKey.flamingo, in: catalog)

        // Laser inserts
        pricing.laserInserts = price(for: PriceCatalogKey.laserInserts, in: catalog)

        // Adapters
        if let adapterType = formData.adapterSelection.type {
            pricing.adapters = price(for: PriceCatalogKey.adapter(adapterType), in: catalog)
        }

        // PPE (added to adapters or its own line — adding to adapters for simplicity)
        // Actually PPE doesn't have its own pricing line in the form, skip for now

        // Shipping
        pricing.shipping = price(for: PriceCatalogKey.shipping, in: catalog)

        // Keep existing promotion (user-entered)
        // Keep existing tax rate

        return pricing
    }

    /// All default catalog entries with $0 prices for initial setup
    static var defaultEntries: [PriceCatalogEntry] {
        var entries: [PriceCatalogEntry] = []

        // Loupes
        for style in LoupeStyle.allCases {
            entries.append(PriceCatalogEntry(
                key: PriceCatalogKey.loupe(style),
                category: "Loupes",
                label: style.rawValue,
                price: 0
            ))
        }

        // Headlights
        for type in HeadlightType.allCases {
            entries.append(PriceCatalogEntry(
                key: PriceCatalogKey.headlight(type),
                category: "Headlights",
                label: type.rawValue,
                price: 0
            ))
        }

        // Accessories
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.extraBattery, category: "Accessories", label: "Extra Battery", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.orchidCord3_5ft, category: "Accessories", label: "3.5 ft Orchid Cord", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.orchidCord5ft, category: "Accessories", label: "5 ft Orchid Cord", price: 0))

        // Adapters
        for type in AdapterType.allCases {
            entries.append(PriceCatalogEntry(
                key: PriceCatalogKey.adapter(type),
                category: "Adapters",
                label: type.rawValue,
                price: 0
            ))
        }

        // Corrections
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.internalRegular, category: "Corrections", label: "Internal - Regular", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.internalSpecial, category: "Corrections", label: "Internal - Special", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.externalRegular, category: "Corrections", label: "External - Regular", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.externalSpecial, category: "Corrections", label: "External - Special", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.externalMultiFocal, category: "Corrections", label: "External - Multi-Focal", price: 0))

        // Other
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.flamingo, category: "Other", label: "Flamingo", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.laserInserts, category: "Other", label: "Laser Inserts", price: 0))
        entries.append(PriceCatalogEntry(key: PriceCatalogKey.shipping, category: "Other", label: "Shipping", price: 0))

        return entries
    }
}
