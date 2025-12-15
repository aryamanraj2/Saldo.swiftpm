import SwiftUI

extension Color {
    // MARK: - Apple-Style Minimal Palette
    
    // Primary accent - Subtle blue like iOS system blue
    static let saldoAccent = Color(red: 0.0, green: 0.478, blue: 1.0)
    
    // Clean backgrounds for light and dark modes
    static let saldoBackground = Color(.systemGroupedBackground)
    static let saldoCardBackground = Color(.secondarySystemGroupedBackground)
    
    // Subtle accent for highlights (minimal green for positive values)
    static let saldoGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    
    // Text hierarchy
    static let saldoPrimary = Color.primary
    static let saldoSecondary = Color.secondary
    static let saldoTertiary = Color(.tertiaryLabel)
    
    // Subtle dividers
    static let saldoSeparator = Color(.separator)
}
