import SwiftUI

// MARK: - Liquid Glass Modifier (Apple-Style Minimal)
struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 20
    var material: Material = .ultraThinMaterial
    
    func body(content: Content) -> some View {
        content
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            // Subtle border for definition
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.06), lineWidth: 0.5)
            )
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, material: Material = .ultraThinMaterial) -> some View {
        self.modifier(LiquidGlass(cornerRadius: cornerRadius, material: material))
    }
}

// MARK: - Clean Background (Apple-Style)
struct CleanBackground: View {
    var body: some View {
        Color.saldoBackground
            .ignoresSafeArea()
    }
}

// MARK: - Balance Card
struct BalanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remaining Balance")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.saldoSecondary)
            
            Text("₹4,200.00")
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.saldoPrimary)
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.saldoGreen)
                Text("On track this month")
                    .font(.footnote)
                    .foregroundStyle(Color.saldoSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .liquidGlass(cornerRadius: 24, material: .regular)
    }
}

// MARK: - Weekly Spend Card
struct WeeklySpendCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spent this week")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.saldoSecondary)
            
            Text("₹1,500")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.saldoPrimary)
            
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                Text("12% higher")
                    .font(.caption)
            }
            .foregroundStyle(Color.saldoSecondary)
            
            Spacer()
            
            // Minimal Chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<7) { i in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(i == 6 ? Color.saldoAccent : Color.saldoAccent.opacity(0.3))
                        .frame(height: CGFloat([25, 45, 35, 60, 50, 40, 70][i]))
                }
            }
            .frame(height: 70)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 24, material: .regular)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    var icon: String
    var title: String
    var subtitle: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.saldoAccent.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.saldoAccent)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saldoPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.saldoSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .liquidGlass(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}

struct WideActionButton: View {
    var icon: String
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.saldoAccent)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .liquidGlass(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    var icon: String = "cart.fill"
    var title: String = "Unknown"
    var subtitle: String = "Just now"
    var amount: String = "₹0.00"
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.saldoCardBackground)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.saldoAccent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.saldoPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.saldoCardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
