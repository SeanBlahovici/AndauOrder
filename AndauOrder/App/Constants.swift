import Foundation

enum AppConstants {
    static let appName = "AndauOrder"
    static let defaultTerritoryManager = "Michelle Fontaine"
    static let defaultCountry = "Canada"

    /// Quebec combined GST (5%) + QST (9.975%) = 14.975%
    static let quebecTaxRate: Decimal = 0.14975

    /// Michelle's contact info, pre-filled into estimate notes
    enum MichelleContact {
        static let name = "Michelle Fontaine"
        static let email = "" // To be configured in Settings
        static let phone = "" // To be configured in Settings
    }

    /// Auto-save debounce interval
    static let autoSaveDebounceSeconds: Double = 0.5
}
