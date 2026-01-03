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
                primary: Color.black, // Black
                secondary: Color(red: 0.4, green: 0.4, blue: 0.4), // Medium Grey
                accent: Color(red: 0.3, green: 0.3, blue: 0.3), // Dark Grey
                backgroundBlob1: Color.black.opacity(0.15),
                backgroundBlob2: Color.gray.opacity(0.12),
                backgroundBlob3: Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.1)
            )
        case .moderate:
            return ThemeColors(
                primary: Color.black, // Black
                secondary: Color.black.opacity(0.6),
                accent: Color(red: 0.35, green: 0.35, blue: 0.35), // Medium-Dark Grey
                backgroundBlob1: Color(red: 0.25, green: 0.25, blue: 0.25).opacity(0.2), // Dark Grey
                backgroundBlob2: Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.15), // Medium Grey
                backgroundBlob3: Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.1) // Very Dark Grey
            )
        case .wealthy:
            return ThemeColors(
                primary: Color.black, // Black
                secondary: Color(red: 0.3, green: 0.3, blue: 0.3),
                accent: Color(red: 0.4, green: 0.4, blue: 0.4), // Light-Medium Grey
                backgroundBlob1: Color.gray.opacity(0.18),
                backgroundBlob2: Color(red: 0.6, green: 0.6, blue: 0.6).opacity(0.15),
                backgroundBlob3: Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.12)
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
