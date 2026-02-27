import SwiftUI

// MARK: - Grail Category
enum GrailCategory: String, CaseIterable, Identifiable, Codable {
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
enum GrailStrictness: String, CaseIterable, Identifiable, Codable {
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

// MARK: - Deposit Record
struct DepositRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var amount: Double
    var date: Date
    var note: String?
    
    init(id: UUID = UUID(), amount: Double, date: Date = Date(), note: String? = nil) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
    }
}

// MARK: - Grail Item
struct GrailItem: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var currency: String
    var category: GrailCategory
    var strictness: GrailStrictness
    var createdAt: Date
    var maskedImageFilename: String?
    var deposits: [DepositRecord]
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }
    
    init(id: UUID = UUID(), 
         name: String, 
         targetAmount: Double, 
         currentAmount: Double = 0, 
         currency: String = "₹",
         category: GrailCategory, 
         strictness: GrailStrictness,
         createdAt: Date = Date(),
         maskedImageFilename: String? = nil,
         deposits: [DepositRecord] = []) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.currency = currency
        self.category = category
        self.strictness = strictness
        self.createdAt = createdAt
        self.maskedImageFilename = maskedImageFilename
        self.deposits = deposits
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case targetAmount
        case currentAmount
        case currency
        case category
        case strictness
        case createdAt
        case maskedImageFilename
        case deposits
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.targetAmount = try container.decode(Double.self, forKey: .targetAmount)
        self.currentAmount = try container.decode(Double.self, forKey: .currentAmount)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.category = try container.decode(GrailCategory.self, forKey: .category)
        self.strictness = try container.decode(GrailStrictness.self, forKey: .strictness)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.maskedImageFilename = try container.decodeIfPresent(String.self, forKey: .maskedImageFilename)
        self.deposits = try container.decodeIfPresent([DepositRecord].self, forKey: .deposits) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(targetAmount, forKey: .targetAmount)
        try container.encode(currentAmount, forKey: .currentAmount)
        try container.encode(currency, forKey: .currency)
        try container.encode(category, forKey: .category)
        try container.encode(strictness, forKey: .strictness)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(maskedImageFilename, forKey: .maskedImageFilename)
        try container.encode(deposits, forKey: .deposits)
    }
}
