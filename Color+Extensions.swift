import SwiftUI

extension Color {
    // MARK: - Monochrome Theme (Black, White & Grey)
    
    // Primary accent - Dark grey for actions and highlights
    static let saldoAccent = Color(red: 0.3, green: 0.3, blue: 0.3)
    
    // Primary color - Black for branding and primary elements
    static let saldoGreen = Color.black
    
    // Clean, neutral backgrounds
    static let saldoBackground = Color(red: 0.96, green: 0.96, blue: 0.96) // Light grey
    static let saldoCardBackground = Color.white.opacity(0.8)
    
    // Secondary grey for gradients or lighter elements
    static let saldoLightGreen = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    // Text hierarchy
    static let saldoPrimary = Color.black.opacity(0.85)
    static let saldoSecondary = Color.black.opacity(0.6)
    static let saldoTertiary = Color.black.opacity(0.4)
    
    // Subtle dividers
    static let saldoSeparator = Color.black.opacity(0.08)
}
