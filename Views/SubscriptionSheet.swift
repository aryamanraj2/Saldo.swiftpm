import SwiftUI

// MARK: - Presentation Detent for Subscription Sheet
extension PresentationDetent {
    static let subscriptionLarge = PresentationDetent.fraction(0.85)
}

// MARK: - Subscription Sheet
struct SubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header with Cancel Button (Glass Style)
            SubscriptionSheetHeader(colors: colors, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // MARK: - Main Content Area
            ScrollView {
                VStack(spacing: 20) {
                    // Placeholder content
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(colors.accent)
                        
                        Text("Add Grails")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.saldoPrimary)
                        
                        Text("Set your spending goals")
                            .font(.subheadline)
                            .foregroundStyle(Color.saldoSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Coming Soon Badge
                    Text("Coming Soon")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(colors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colors.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.subscriptionLarge])
        .presentationDragIndicator(.visible)
        .modifier(SubscriptionSheetEnhancements(cornerRadius: 32))
    }
}

// MARK: - Subscription Sheet Header (Matches FloatingScanBar Style)
struct SubscriptionSheetHeader: View {
    var colors: ThemeColors
    var onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Cancel button with glass effect
            if #available(iOS 26, *) {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.saldoPrimary)
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            } else {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.saldoPrimary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            
            // Title pill (matches scan receipt bar style)
            if #available(iOS 26, *) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }
                    
                    Text("New Grail")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saldoPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular, in: .capsule)
            } else {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }
                    
                    Text("New Grail")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saldoPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
}

// MARK: - Sheet Presentation Enhancements
private struct SubscriptionSheetEnhancements: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationCornerRadius(cornerRadius)
                .presentationBackground(.clear)
        } else {
            content
        }
    }
}

#Preview {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SubscriptionSheet(colors: AppTheme.moderate.colors)
        }
}
