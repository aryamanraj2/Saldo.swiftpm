import SwiftUI

extension Color {
    // MARK: - Wealthy Green & Yellow Theme
    
    // Primary accent - Vibrant Yellow/Lime for actions and highlights
    // A nice energetic lime: HSB(70, 80, 95) -> RGB approx (0.85, 0.95, 0.2)
    static let saldoAccent = Color(red: 0.85, green: 0.93, blue: 0.18)
    
    // Wealthy Green - Deep, rich emerald for branding and primary elements
    // Deep Emerald: RGB(3, 75, 50)
    static let saldoGreen = Color(red: 0.05, green: 0.35, blue: 0.25)
    
    // Clean, slightly tinted backgrounds
    static let saldoBackground = Color(red: 0.98, green: 0.99, blue: 0.98) // Very subtle green tint
    static let saldoCardBackground = Color.white.opacity(0.8)
    
    // Secondary Green for gradients or lighter elements
    static let saldoLightGreen = Color(red: 0.1, green: 0.6, blue: 0.4)
    
    // Text hierarchy
    static let saldoPrimary = Color.black.opacity(0.85)
    static let saldoSecondary = Color.black.opacity(0.6)
    static let saldoTertiary = Color.black.opacity(0.4)
    
    // Subtle dividers
    static let saldoSeparator = Color.black.opacity(0.08)
}
