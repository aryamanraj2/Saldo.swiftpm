import SwiftUI

// MARK: - Subscription Category
enum SubscriptionCategory: String, CaseIterable, Identifiable {
    case music = "Music"
    case streaming = "Streaming"
    case ai = "AI"
    case education = "Education"
    case misc = "Misc"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .music:
            return "music.note"
        case .streaming:
            return "tv"
        case .ai:
            return "sparkles"
        case .education:
            return "graduationcap"
        case .misc:
            return "ellipsis.circle"
        }
    }
}

// MARK: - Subscription Item
struct SubscriptionItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var amount: Double
    var currency: String
    var category: SubscriptionCategory
    
    init(id: UUID = UUID(), name: String, amount: Double, currency: String, category: SubscriptionCategory) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.category = category
    }
    
    // Computed icon name based on category
    var iconName: String {
        if category == .misc && !name.isEmpty {
            // Return first letter of the name for misc category
            return String(name.prefix(1).uppercased())
        }
        return category.iconName
    }
    
    // Determines if we should show a letter icon or SF Symbol
    var usesLetterIcon: Bool {
        category == .misc && !name.isEmpty
    }
}

// MARK: - Currency Options
struct CurrencyOption: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let code: String
    
    static let options: [CurrencyOption] = [
        CurrencyOption(symbol: "₹", code: "INR"),
        CurrencyOption(symbol: "$", code: "USD"),
        CurrencyOption(symbol: "€", code: "EUR"),
        CurrencyOption(symbol: "£", code: "GBP"),
        CurrencyOption(symbol: "¥", code: "JPY")
    ]
}
