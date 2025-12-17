import SwiftUI

// MARK: - App Theme Definitions

enum AppTheme {
    case danger   // Low balance (< 1000)
    case moderate // Medium balance (1000 - 5000)
    case wealthy  // High balance (> 5000)
    
    var colors: ThemeColors {
        switch self {
        case .danger:
            return ThemeColors(
                primary: Color(red: 0.85, green: 0.2, blue: 0.2), // Bright Red
                secondary: Color(red: 0.6, green: 0.1, blue: 0.1), // Dark Red
                accent: Color(red: 1.0, green: 0.4, blue: 0.4), // Salmon/Pinkish pop
                backgroundBlob1: Color.red.opacity(0.35),
                backgroundBlob2: Color.orange.opacity(0.3),
                backgroundBlob3: Color(red: 0.5, green: 0.0, blue: 0.0).opacity(0.2)
            )
        case .moderate:
            return ThemeColors(
                primary: Color(red: 0.05, green: 0.35, blue: 0.25), // Wealthy Green (Keep readable base)
                secondary: Color.black.opacity(0.6),
                accent: Color(red: 0.85, green: 0.93, blue: 0.18), // Yellow/Lime
                backgroundBlob1: Color(red: 0.85, green: 0.93, blue: 0.18).opacity(0.4), // Yellow
                backgroundBlob2: Color(red: 0.1, green: 0.6, blue: 0.4).opacity(0.2), // Green
                backgroundBlob3: Color(red: 0.05, green: 0.35, blue: 0.25).opacity(0.15) // Deep Green
            )
        case .wealthy:
            return ThemeColors(
                primary: Color(red: 0.0, green: 0.5, blue: 0.2), // Pure Emerald
                secondary: Color(red: 0.0, green: 0.3, blue: 0.1),
                accent: Color(red: 0.2, green: 0.85, blue: 0.55), // Mint Green
                backgroundBlob1: Color.green.opacity(0.3),
                backgroundBlob2: Color.mint.opacity(0.25),
                backgroundBlob3: Color.teal.opacity(0.2)
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
}

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    
    // Background Blobs
    let backgroundBlob1: Color
    let backgroundBlob2: Color
    let backgroundBlob3: Color
}
