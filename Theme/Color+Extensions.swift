import SwiftUI
import UIKit

extension Color {
    // MARK: - Adaptive Colors (Light/Dark Mode)

    // Primary accent - Dark grey in light mode, lighter grey in dark mode
    static var saldoAccent: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                : UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        })
    }

    // Primary color - Black for branding in light, white in dark
    static var saldoGreen: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor.black
        })
    }

    // Clean, neutral backgrounds
    static var saldoBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)
                : UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        })
    }

    static var saldoCardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.white.withAlphaComponent(0.8)
        })
    }

    // Secondary grey for gradients or lighter elements
    static var saldoLightGreen: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
                : UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        })
    }

    // Text hierarchy - Adaptive for light/dark mode
    static var saldoPrimary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.92)
                : UIColor.black.withAlphaComponent(0.85)
        })
    }

    static var saldoSecondary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.6)
                : UIColor.black.withAlphaComponent(0.6)
        })
    }

    static var saldoTertiary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.35)
                : UIColor.black.withAlphaComponent(0.4)
        })
    }

    // Subtle dividers
    static var saldoSeparator: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.08)
        })
    }
}
