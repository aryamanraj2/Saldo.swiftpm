import SwiftUI

// MARK: - Grail Category
enum GrailCategory: String, CaseIterable, Identifiable {
    case sneakers = "Sneakers"
    case perfumes = "Perfumes"
    case watches = "Watches"
    case trips = "Trips"
    case vinyl = "Vinyl"
    case misc = "Misc"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .sneakers: return "shoe.fill"
        case .perfumes: return "drop.fill"
        case .watches: return "watchface.applewatch.case"
        case .trips: return "airplane"
        case .vinyl: return "record.circle.fill"
        case .misc: return "star.fill"
        }
    }
}

// MARK: - Grail Strictness
enum GrailStrictness: String, CaseIterable, Identifiable {
    case gentle = "Gentle"
    case balanced = "Balanced"
    case ruthless = "Ruthless"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .gentle: return "Encouraging nudges"
        case .balanced: return "Firm reminders"
        case .ruthless: return "No mercy on spending"
        }
    }
    
    var iconName: String {
        switch self {
        case .gentle: return "leaf.fill"
        case .balanced: return "scale.3d"
        case .ruthless: return "flame.fill"
        }
    }
}

// MARK: - Grail Item
struct GrailItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var currency: String
    var category: GrailCategory
    var strictness: GrailStrictness
    
    init(id: UUID = UUID(), 
         name: String, 
         targetAmount: Double, 
         currentAmount: Double = 0, 
         currency: String = "₹",
         category: GrailCategory, 
         strictness: GrailStrictness) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.currency = currency
        self.category = category
        self.strictness = strictness
    }
}
