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
            // Base layer - dynamic theme background
            colors.background
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
        .animation(.easeInOut(duration: 0.8), value: colors.background)
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

// MARK: - Spend Data Point (Backend-Ready Model)
struct SpendDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let amount: Double
    
    // Factory method for creating sample data (will be replaced by backend)
    static func sampleData(for period: SpendPeriod) -> [SpendDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .day:
            // 24 hourly data points
            return (0..<24).map { hour in
                let date = calendar.date(byAdding: .hour, value: -23 + hour, to: now) ?? now
                let amounts: [Double] = [15, 45, 25, 60, 40, 30, 70, 55, 45, 35, 80, 50, 40, 55, 65, 85, 50, 75, 45, 60, 70, 65, 90, 70]
                return SpendDataPoint(timestamp: date, amount: amounts[hour])
            }
        case .week:
            // 7 daily data points
            return (0..<7).map { day in
                let date = calendar.date(byAdding: .day, value: -6 + day, to: now) ?? now
                let amounts: [Double] = [250, 450, 320, 580, 420, 380, 520]
                return SpendDataPoint(timestamp: date, amount: amounts[day])
            }
        case .month:
            // 30 daily data points for more curves
            return (0..<30).map { day in
                let date = calendar.date(byAdding: .day, value: -29 + day, to: now) ?? now
                let amounts: [Double] = [180, 220, 160, 280, 350, 200, 240, 180, 320, 260, 
                                          190, 280, 340, 220, 260, 190, 300, 250, 210, 280,
                                          320, 240, 200, 260, 290, 220, 250, 200, 270, 300]
                return SpendDataPoint(timestamp: date, amount: amounts[day])
            }
        }
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
    
    var dataPoints: [SpendDataPoint] {
        SpendDataPoint.sampleData(for: self)
    }
}

// MARK: - Spend Line Graph
struct SpendLineGraph: View {
    var dataPoints: [SpendDataPoint]
    var accentColor: Color
    var lineColor: Color
    var animationProgress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let points = normalizedPoints(in: CGSize(width: width, height: height))
            
            ZStack {
                // Smooth curved line
                SpendLinePath(points: points, progress: animationProgress)
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 3.7, lineCap: .round, lineJoin: .round))
            }
        }
    }
    
    // Normalize data points to fit within the view bounds
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !dataPoints.isEmpty else { return [] }
        
        let amounts = dataPoints.map { $0.amount }
        let minAmount = amounts.min() ?? 0
        let maxAmount = amounts.max() ?? 1
        let range = maxAmount - minAmount
        let safeRange = range > 0 ? range : 1
        
        // Horizontal padding 0 to stretch to edges, vertical padding 10 to avoid clipping
        let horizontalPadding: CGFloat = -12
        let verticalPadding: CGFloat = 8
        
        let usableWidth = size.width - (horizontalPadding * 2)
        let usableHeight = size.height - (verticalPadding * 2)
        
        return dataPoints.enumerated().map { index, point in
            let x = horizontalPadding + (CGFloat(index) / CGFloat(max(dataPoints.count - 1, 1))) * usableWidth
            let normalizedY = (point.amount - minAmount) / safeRange
            let y = verticalPadding + (1 - normalizedY) * usableHeight // Invert Y axis
            return CGPoint(x: x, y: y)
        }
    }
    
    // Get position on the curved line at a given percentage
    private func positionOnCurve(at percentage: CGFloat, points: [CGPoint]) -> CGPoint? {
        guard points.count >= 2 else { return points.first }
        
        let totalSegments = points.count - 1
        let targetSegment = percentage * CGFloat(totalSegments)
        let segmentIndex = min(Int(targetSegment), totalSegments - 1)
        let segmentProgress = targetSegment - CGFloat(segmentIndex)
        
        // Get the 4 control points for Catmull-Rom
        let p0 = points[max(segmentIndex - 1, 0)]
        let p1 = points[segmentIndex]
        let p2 = points[min(segmentIndex + 1, points.count - 1)]
        let p3 = points[min(segmentIndex + 2, points.count - 1)]
        
        return catmullRomPoint(p0: p0, p1: p1, p2: p2, p3: p3, t: segmentProgress)
    }
    
    // Catmull-Rom spline interpolation
    private func catmullRomPoint(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t
        
        let x = 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t +
                (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
                (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
        
        let y = 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t +
                (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Animatable Line Path Shape
struct SpendLinePath: Shape {
    var points: [CGPoint]
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        guard points.count >= 2 else { return Path() }
        
        var path = Path()
        path.move(to: points[0])
        
        // Draw smooth curves using Catmull-Rom spline
        for i in 0..<(points.count - 1) {
            let p0 = points[max(i - 1, 0)]
            let p1 = points[i]
            let p2 = points[min(i + 1, points.count - 1)]
            let p3 = points[min(i + 2, points.count - 1)]
            
            // Generate curve points between p1 and p2
            let segments = 10
            for j in 1...segments {
                let t = CGFloat(j) / CGFloat(segments)
                let point = catmullRomPoint(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
                path.addLine(to: point)
            }
        }
        
        return path.trimmedPath(from: 0, to: progress)
    }
    
    private func catmullRomPoint(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t
        
        let x = 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t +
                (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
                (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
        
        let y = 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t +
                (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Weekly Spend Card
struct WeeklySpendCard: View {
    var colors: ThemeColors
    @State private var selectedPeriod: SpendPeriod = .week
    @State private var animationProgress: CGFloat = 1.0
    @Namespace private var animation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Liquid Glass Switcher
            HStack(spacing: 0) {
                ForEach(SpendPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        // Reset and animate the line drawing
                        animationProgress = 0
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedPeriod = period
                        }
                        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                            animationProgress = 1.0
                        }
                    }) {
                        ZStack {
                            if selectedPeriod == period {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(.white.opacity(0.4), lineWidth: 0.5)
                                    )
                                    .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                            }
                            
                            Text(period.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedPeriod == period ? .bold : .medium)
                                .foregroundStyle(selectedPeriod == period ? colors.primary : Color.saldoSecondary)
                        }
                        .frame(height: 38)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                Color.saldoSecondary.opacity(0.06)
                    .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                 RoundedRectangle(cornerRadius: 14, style: .continuous)
                     .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            
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
                    .foregroundStyle(selectedPeriod.isHigher ? Color.black.opacity(0.7) : Color.gray)
                Text(selectedPeriod.comparison)
                    .font(.caption)
            }
            .foregroundStyle(Color.saldoSecondary)
            
            Spacer()
            
            // Smooth Curved Line Graph
            SpendLineGraph(
                dataPoints: selectedPeriod.dataPoints,
                accentColor: colors.accent,
                lineColor: colors.primary,
                animationProgress: animationProgress
            )
            .frame(height: 70)
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
            .liquidGlass(cornerRadius: 20, material: .regular, shadowColor: colors.accent)
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
            .liquidGlass(cornerRadius: 20, material: .regular, shadowColor: colors.accent)
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
        .liquidGlass(cornerRadius: 20, material: .regular, shadowColor: colors.accent)
    }
}
