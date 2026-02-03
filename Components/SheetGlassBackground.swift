import SwiftUI

/// Shared sheet background styling that matches the iOS 26 Liquid Glass look
/// while providing a reasonable fallback on older OS versions.
enum SheetGlassVariant {
    case regular
    /// More translucent / more "see-through" than `.regular`.
    case extraClear
}

struct SheetGlassBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat
    let variant: SheetGlassVariant
    let opacity: Double

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            // Apply Liquid Glass as a dedicated background layer so it reads clearly even
            // when the sheet content itself doesn't draw an opaque surface.
            if variant == .extraClear {
                content
                    .background {
                        Color.clear
                            .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
                            .opacity(opacity)
                    }
            } else {
                content
                    .background {
                        Color.clear
                            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                            .opacity(opacity)
                    }
            }
        } else {
            content
                .background(.ultraThinMaterial.opacity(opacity))
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
}

extension View {
    func sheetGlassBackground(
        cornerRadius: CGFloat,
        variant: SheetGlassVariant = .regular,
        opacity: Double = 1.0
    ) -> some View {
        modifier(SheetGlassBackgroundModifier(cornerRadius: cornerRadius, variant: variant, opacity: opacity))
    }
}
