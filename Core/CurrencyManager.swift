import SwiftUI

// MARK: - App Currency

/// The five supported currencies, with slider parameters scaled to real-world value.
enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case inr = "INR"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"

    var id: String { rawValue }

    /// The currency symbol displayed in the UI.
    var symbol: String {
        switch self {
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        }
    }

    /// Friendly display name.
    var displayName: String {
        switch self {
        case .inr: return "Indian Rupee"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        }
    }

    /// Flag emoji for picker presentation.
    var flag: String {
        switch self {
        case .inr: return "🇮🇳"
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .gbp: return "🇬🇧"
        case .jpy: return "🇯🇵"
        }
    }

    // MARK: - Slider Parameters

    /// Maximum value for the onboarding allowance slider.
    var sliderMax: Int {
        switch self {
        case .inr, .jpy: return 50_000
        case .usd, .eur, .gbp: return 5_000
        }
    }

    /// Step size for the onboarding slider ticks.
    var sliderStep: Int {
        switch self {
        case .inr, .jpy: return 500
        case .usd, .eur, .gbp: return 50
        }
    }

    /// Default initial allowance for a fresh onboarding.
    var defaultAllowance: Int {
        switch self {
        case .inr: return 5000
        case .jpy: return 5000
        case .usd: return 500
        case .eur: return 500
        case .gbp: return 400
        }
    }

    /// Default initial spending for a fresh onboarding.
    var defaultSpending: Int {
        switch self {
        case .inr: return 3000
        case .jpy: return 3000
        case .usd: return 300
        case .eur: return 300
        case .gbp: return 250
        }
    }

    // MARK: - Conversion rates (to INR)

    /// How many INR one unit of this currency buys.
    var toINR: Double {
        switch self {
        case .inr: return 1.0
        case .usd: return 91.0755
        case .gbp: return 122.838
        case .eur: return 107.628
        case .jpy: return 1.0 / 1.7139   // 1 JPY ≈ 0.5835 INR
        }
    }

    /// Convert a value expressed in this currency to another currency.
    func convert(_ amount: Double, to target: AppCurrency) -> Double {
        let inINR = amount * self.toINR
        return inINR / target.toINR
    }

    // MARK: - Theme Thresholds

    /// Danger threshold — balances below this show the danger theme.
    /// Scaled so that the UX "feels" equivalent across currencies.
    var dangerThreshold: Double {
        switch self {
        case .inr: return 1000
        case .jpy: return 1000
        case .usd: return 50
        case .eur: return 50
        case .gbp: return 40
        }
    }

    /// Moderate threshold — balances below this but above danger show moderate theme.
    var moderateThreshold: Double {
        switch self {
        case .inr: return 5000
        case .jpy: return 5000
        case .usd: return 250
        case .eur: return 250
        case .gbp: return 200
        }
    }

    // MARK: - Nonisolated Accessors

    /// Thread-safe accessor for the current currency symbol.
    /// Reads directly from UserDefaults so it can be used from any isolation context.
    static var currentSymbol: String {
        current.symbol
    }

    /// Thread-safe accessor for the current AppCurrency.
    /// Reads directly from UserDefaults so it can be used from any isolation context.
    static var current: AppCurrency {
        if let raw = UserDefaults.standard.string(forKey: "selectedCurrency"),
           let currency = AppCurrency(rawValue: raw) {
            return currency
        }
        return .inr
    }
}

// MARK: - Currency Manager

/// Singleton that persists and provides the user's selected currency.
@MainActor
@Observable
class CurrencyManager {
    static let shared = CurrencyManager()

    private static let storageKey = "selectedCurrency"

    var selected: AppCurrency {
        didSet {
            UserDefaults.standard.set(selected.rawValue, forKey: Self.storageKey)
        }
    }

    /// Convenience accessor for the symbol of the active currency.
    var symbol: String { selected.symbol }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let currency = AppCurrency(rawValue: raw) {
            self.selected = currency
        } else {
            self.selected = .inr
        }
    }

    /// Formats an amount with the current currency symbol.
    /// Examples: "₹4,500.00", "$55.00", "¥8,500"
    func formatted(_ amount: Double, fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        let numStr = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "\(symbol)\(numStr)"
    }

    /// Short format: "₹4.5K", "$550", "¥8.5K"
    func shortFormatted(_ value: Int) -> String {
        if value >= 1000 {
            let thousands = Double(value) / 1000.0
            if thousands.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(symbol)\(Int(thousands))K"
            } else {
                return "\(symbol)\(String(format: "%.1f", thousands))K"
            }
        }
        return "\(symbol)\(value)"
    }
}
