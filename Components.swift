import SwiftUI

// MARK: - Sheet Height Preference Key (Apple Maps-style)
// Allows child views (the sheet) to report their size to the parent.
struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Liquid Glass Modifier (Refined)
struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 20
    var material: Material = .ultraThinMaterial
    var shadowColor: Color
    
    func body(content: Content) -> some View {
        content
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: shadowColor.opacity(0.15), radius: 15, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, material: Material = .ultraThinMaterial, shadowColor: Color = .black) -> some View {
        self.modifier(LiquidGlass(cornerRadius: cornerRadius, material: material, shadowColor: shadowColor))
    }
}

// MARK: - Dynamic Background
struct CleanBackground: View {
    var colors: ThemeColors
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base layer
            Color.saldoBackground
                .ignoresSafeArea()
            
            // Dynamic blobs
            GeometryReader { proxy in
                ZStack {
                    // Top Right
                    Circle()
                        .fill(colors.backgroundBlob1)
                        .blur(radius: 80)
                        .frame(width: 300, height: 300)
                        .position(x: proxy.size.width * 0.9, y: proxy.size.height * 0.1)
                        .offset(x: animate ? -30 : 30, y: animate ? -30 : 30)
                    
                    // Center Left
                    Circle()
                        .fill(colors.backgroundBlob2)
                        .blur(radius: 100)
                        .frame(width: 400, height: 400)
                        .position(x: 0, y: proxy.size.height * 0.4)
                        .offset(x: animate ? 20 : -20, y: animate ? 40 : -40)
                    
                    // Bottom Right
                    Circle()
                        .fill(colors.backgroundBlob3)
                        .blur(radius: 90)
                        .frame(width: 350, height: 350)
                        .position(x: proxy.size.width, y: proxy.size.height * 0.85)
                        .offset(x: animate ? -40 : 40, y: animate ? -20 : 20)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        // Animate color changes smoothly
        .animation(.easeInOut(duration: 1.0), value: colors.backgroundBlob1)
    }
}

// MARK: - Balance Card
struct BalanceCard: View {
    var balance: Double
    var colors: ThemeColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remaining Balance")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.saldoSecondary)
            
            Text("₹\(String(format: "%.2f", balance))")
                .contentTransition(.numericText()) // Smooth number transition
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
            
            HStack(spacing: 4) {
                Image(systemName: balance < 1000 ? "exclamationmark.circle.fill" : "arrow.up.right.circle.fill")
                    .foregroundStyle(colors.accent)
                Text(balance < 1000 ? "Low balance warning" : "On track this month")
                    .font(.footnote)
                    .foregroundStyle(Color.saldoSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .liquidGlass(cornerRadius: 24, material: .regular, shadowColor: colors.accent)
    }
}

// MARK: - Spend Period Enum
enum SpendPeriod: String, CaseIterable {
    case day = "D"
    case week = "W"
    case month = "M"
    
    var title: String {
        switch self {
        case .day: return "Spent today"
        case .week: return "Spent this week"
        case .month: return "Spent this month"
        }
    }
    
    var amount: String {
        switch self {
        case .day: return "₹450"
        case .week: return "₹1,500"
        case .month: return "₹6,200"
        }
    }
    
    var comparison: String {
        switch self {
        case .day: return "8% higher"
        case .week: return "12% higher"
        case .month: return "5% lower"
        }
    }
    
    var isHigher: Bool {
        switch self {
        case .day, .week: return true
        case .month: return false
        }
    }
    
    var chartData: [CGFloat] {
        switch self {
        case .day: return [25, 45, 35, 60, 50, 40, 70, 55, 65, 45, 80, 60, 50, 40, 70, 85, 60, 75, 55, 65, 70, 80, 90, 70]
        case .week: return [25, 45, 35, 60, 50, 40, 70]
        case .month: return [60, 55, 70, 65]
        }
    }
}

// MARK: - Weekly Spend Card
struct WeeklySpendCard: View {
    var colors: ThemeColors
    @State private var selectedPeriod: SpendPeriod = .week
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Period Toggle
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    ForEach(SpendPeriod.allCases, id: \.self) { period in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPeriod = period
                            }
                        }) {
                            Text(period.rawValue)
                                .font(.caption)
                                .fontWeight(selectedPeriod == period ? .semibold : .medium)
                                .foregroundStyle(selectedPeriod == period ? colors.accent : Color.saldoSecondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(selectedPeriod == period ? Color.saldoSecondary.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color.saldoSecondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
            }

            
            Text(selectedPeriod.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.saldoSecondary)
                .animation(.none, value: selectedPeriod)
            
            Text(selectedPeriod.amount)
                .contentTransition(.numericText())
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
            
            HStack(spacing: 4) {
                Image(systemName: selectedPeriod.isHigher ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(selectedPeriod.isHigher ? Color.orange : Color.green)
                Text(selectedPeriod.comparison)
                    .font(.caption)
            }
            .foregroundStyle(Color.saldoSecondary)
            
            Spacer()
            
            // Minimal Chart
            HStack(alignment: .bottom, spacing: selectedPeriod == .day ? 2 : 6) {
                ForEach(Array(selectedPeriod.chartData.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(index == selectedPeriod.chartData.count - 1 ? colors.accent : colors.primary.opacity(0.15))
                        .frame(height: height)
                }
            }
            .frame(height: 60)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPeriod)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 24, material: .regular, shadowColor: colors.accent)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    var icon: String
    var title: String
    var subtitle: String
    var colors: ThemeColors
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.05))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(colors.primary)
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
            .liquidGlass(cornerRadius: 20, shadowColor: colors.primary)
        }
        .buttonStyle(.plain)
    }
}

struct WideActionButton: View {
    var icon: String
    var title: String
    var colors: ThemeColors
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon) 
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(colors.primary)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .liquidGlass(cornerRadius: 100, shadowColor: colors.accent)
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
    var colors: ThemeColors
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(colors.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.saldoCardBackground.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
