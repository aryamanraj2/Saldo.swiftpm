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

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            // Apply Liquid Glass as a dedicated background layer so it reads clearly even
            // when the sheet content itself doesn't draw an opaque surface.
            if variant == .extraClear {
                content
                    .background {
                        Color.clear
                            .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
                    }
            } else {
                content
                    .background {
                        Color.clear
                            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                    }
            }
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
}

extension View {
    func sheetGlassBackground(
        cornerRadius: CGFloat,
        variant: SheetGlassVariant = .regular
    ) -> some View {
        modifier(SheetGlassBackgroundModifier(cornerRadius: cornerRadius, variant: variant))
    }
}
