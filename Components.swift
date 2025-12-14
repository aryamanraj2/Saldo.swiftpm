import SwiftUI

// MARK: - Liquid Glass Modifier
struct LiquidGlass: ViewModifier {
    var cornerradius: CGFloat = 30
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerradius, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
            // Specular Highlight (The "Wet" Edge)
            .overlay(
                RoundedRectangle(cornerRadius: cornerradius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.6), location: 0),
                                .init(color: .white.opacity(0.1), location: 0.3),
                                .init(color: .clear, location: 0.5),
                                .init(color: .white.opacity(0.3), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // Subtle inner glow
            .overlay(
                RoundedRectangle(cornerRadius: cornerradius, style: .continuous)
                    .strokeBorder(.white.opacity(0.05), lineWidth: 0.5)
            )
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 30) -> some View {
        self.modifier(LiquidGlass(cornerradius: cornerRadius))
    }
}

// MARK: - Fluid Background
struct FluidBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.saldoBackground.ignoresSafeArea()
            
            // Blob 1: Yellow
            Circle()
                .fill(Color.saldoYellow.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: animate ? -100 : 100, y: animate ? -100 : 100)
            
            // Blob 2: Cyan
            Circle()
                .fill(Color.saldoCyan.opacity(0.3))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: animate ? 150 : -150, y: animate ? 100 : -100)
            
            // Blob 3: Purple (Deep)
            Circle()
                .fill(Color.saldoPurple.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: animate ? -50 : 50, y: animate ? 200 : -200)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Balance Card
struct BalanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Remaining")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Text("₹4,200.00")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                // Use a subtle shadow to lift text off the glass
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            Text("rupees")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass()
    }
}

// MARK: - Spending Card (Weekly)
struct WeeklySpendCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spent this week")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.7))
            
            Text("₹1,500")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
            
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                Text("12% higher")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.black.opacity(0.6))
            
            Spacer()
            
            // Fake Chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.2))
                        .frame(height: CGFloat([20, 40, 30, 60, 45][i]))
                }
            }
        }
        .padding()
        .frame(height: 180)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.saldoYellow) // Solid accent color for this specific card
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.saldoYellow.opacity(0.3), radius: 15, x: 0, y: 10)
        // Add a "Glass" gloss over the solid color
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

// MARK: - Action Buttons
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
                        .fill(Color.saldoYellow)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .liquidGlass(cornerRadius: 30)
        }
    }
}

struct WideActionButton: View {
    var icon: String
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.saldoYellow)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.3))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    var icon: String = "cart.fill"
    var title: String = "Unknown"
    var subtitle: String = "Just now"
    var amount: String = "₹0.00"
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
