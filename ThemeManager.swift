import SwiftUI

// MARK: - App Theme Definitions

enum AppTheme: Equatable {
    case danger   // Low balance (< 1000) - Warm Reds
    case moderate // Medium balance (1000 - 5000) - Yellow-Greens
    case wealthy  // High balance (> 5000) - Deep Greens
    
    var colors: ThemeColors {
        switch self {
        case .danger:
            // Warm reds with rose-cream background
            return ThemeColors(
                background: Color(hex: "F5DED3"),           // Soft rose-cream
                primary: Color(hex: "730C0A"),              // Deep burgundy for text/bold elements
                secondary: Color(hex: "730C0A").opacity(0.6),
                accent: Color(hex: "FF746C"),               // Soft coral accent
                backgroundBlob1: Color(hex: "FF746C").opacity(0.12),
                backgroundBlob2: Color(hex: "F8DAC7").opacity(0.15),
                backgroundBlob3: Color(hex: "730C0A").opacity(0.08)
            )
        case .moderate:
            // Yellow-greens with warm cream background
            return ThemeColors(
                background: Color(hex: "F5F0D7"),           // Warm yellow-cream
                primary: Color(hex: "4A7A2C"),              // Olive green for text/bold elements
                secondary: Color(hex: "4A7A2C").opacity(0.6),
                accent: Color(hex: "7BAF3F"),               // Bright lime accent
                backgroundBlob1: Color(hex: "7BAF3F").opacity(0.12),
                backgroundBlob2: Color(hex: "A8C974").opacity(0.15),
                backgroundBlob3: Color(hex: "4A7A2C").opacity(0.08)
            )
        case .wealthy:
            // Deep greens with warm cream background
            return ThemeColors(
                background: Color(hex: "F1E9CE"),           // Warm cream
                primary: Color(hex: "0B5D1E"),              // Deep forest green for text/bold elements
                secondary: Color(hex: "0B5D1E").opacity(0.6),
                accent: Color(hex: "24873A"),               // Fresh green accent
                backgroundBlob1: Color(hex: "24873A").opacity(0.12),
                backgroundBlob2: Color(hex: "4CAF50").opacity(0.15),
                backgroundBlob3: Color(hex: "0B5D1E").opacity(0.08)
            )
        }
    }
    
    static func from(balance: Double) -> AppTheme {
        if balance < 1000 {
            return .danger
        } else if balance < 5000 {
            return .moderate
        } else {
            return .wealthy
        }
    }
    
    /// Inverted logic for spending: higher spending = danger, lower = wealthy
    static func fromSpending(spending: Double, maxSpending: Double) -> AppTheme {
        guard maxSpending > 0 else { return .moderate }
        let spendingRatio = spending / maxSpending
        
        if spendingRatio >= 0.8 {
            return .danger    // Spending 80%+ of allowance = danger
        } else if spendingRatio >= 0.4 {
            return .moderate  // Spending 40-80% = moderate
        } else {
            return .wealthy   // Spending <40% = good (green)
        }
    }
}

struct ThemeColors: Equatable {
    let background: Color      // Dynamic background color
    let primary: Color         // Bold text, graph lines, main accents
    let secondary: Color       // Subdued text
    let accent: Color          // Icons, highlights, shadow tints
    
    // Background Blobs (subtle theme-stained animated elements)
    let backgroundBlob1: Color
    let backgroundBlob2: Color
    let backgroundBlob3: Color
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
