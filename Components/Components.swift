import SwiftUI
import UIKit

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
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: shadowColor.opacity(colorScheme == .dark ? 0.25 : 0.15),
                radius: colorScheme == .dark ? 20 : 15,
                x: 0,
                y: colorScheme == .dark ? 8 : 10
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.2),
                        lineWidth: 1
                    )
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
    @State private var animate = true
    @State private var hasStartedAnimation = false

    private let blob1Blur: CGFloat = 80
    private let blob2Blur: CGFloat = 100
    private let blob3Blur: CGFloat = 90

    var body: some View {
        ZStack {
            // Base layer - dynamic theme background
            colors.background
                .ignoresSafeArea()

            // Dynamic blobs with subtle glow in dark mode
            GeometryReader { proxy in
                ZStack {
                    // Top Right
                    Circle()
                        .fill(colors.backgroundBlob1)
                        .blur(radius: blob1Blur)
                        .frame(width: 300, height: 300)
                        .position(x: proxy.size.width * 0.9, y: proxy.size.height * 0.1)
                        .offset(x: animate ? -30 : 30, y: animate ? -30 : 30)

                    // Center Left
                    Circle()
                        .fill(colors.backgroundBlob2)
                        .blur(radius: blob2Blur)
                        .frame(width: 400, height: 400)
                        .position(x: 0, y: proxy.size.height * 0.4)
                        .offset(x: animate ? 20 : -20, y: animate ? 40 : -40)

                    // Bottom Right
                    Circle()
                        .fill(colors.backgroundBlob3)
                        .blur(radius: blob3Blur)
                        .frame(width: 350, height: 350)
                        .position(x: proxy.size.width, y: proxy.size.height * 0.85)
                        .offset(x: animate ? -40 : 40, y: animate ? -20 : 20)
                }
            }
            .ignoresSafeArea()
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { _, newSize in
            guard newSize != .zero else { return }
            startBlobAnimationIfNeeded()
        }
    }

    private func startBlobAnimationIfNeeded() {
        guard !hasStartedAnimation else { return }
        hasStartedAnimation = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
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
            
            Text("₹\(balance, format: .number.precision(.fractionLength(2)))")
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

// MARK: - Glass Period Selector (iOS 26+ Optimized)
struct GlassPeriodSelector: View {
    @Binding var selectedPeriod: SpendPeriod
    var colors: ThemeColors
    var onPeriodChange: () -> Void
    
    private let periods = SpendPeriod.allCases
    
    var body: some View {
        GeometryReader { geometry in
            let segmentWidth = geometry.size.width / CGFloat(periods.count)
            let selectedIndex = periods.firstIndex(of: selectedPeriod) ?? 0

            ZStack(alignment: .leading) {
                // Selection indicator background
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.white.opacity(0.5), lineWidth: 0.5)
                    )
                    .frame(width: segmentWidth, height: 34)
                    .offset(x: CGFloat(selectedIndex) * segmentWidth)
                
                // Period labels
                HStack(spacing: 0) {
                    ForEach(periods, id: \.self) { period in
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedPeriod == period ? .bold : .medium)
                            .foregroundStyle(selectedPeriod == period ? colors.primary : Color.saldoSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectPeriod(period)
                            }
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        let index = Int((value.location.x / segmentWidth).rounded(.down))
                        let clampedIndex = max(0, min(periods.count - 1, index))
                        let newPeriod = periods[clampedIndex]
                        if newPeriod != selectedPeriod {
                            selectPeriod(newPeriod)
                        }
                    }
            )
        }
        .frame(height: 42)
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
    }
    
    private func selectPeriod(_ period: SpendPeriod) {
        // Use smooth animation for the selection indicator
        withAnimation(.smooth(duration: 0.25)) {
            selectedPeriod = period
        }
        // Trigger line graph re-draw callback
        onPeriodChange()
    }
}

// MARK: - Weekly Spend Card
struct WeeklySpendCard: View {
    var colors: ThemeColors
    @State private var selectedPeriod: SpendPeriod = .week
    @State private var animationProgress: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Smooth Liquid Glass Period Selector
            GlassPeriodSelector(
                selectedPeriod: $selectedPeriod,
                colors: colors,
                onPeriodChange: {
                    // Animate line graph separately with a slight delay
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                        animationProgress = 1.0
                    }
                }
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
struct GrailPreviewItem: Identifiable {
    let id: UUID
    let visualCacheKey: String
    let name: String
    let category: GrailCategory
    let image: UIImage?
    let targetAmount: Double
    let currentAmount: Double
    let currency: String
    
    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }
}

enum GrailContourRenderer {
    private static let cache = ContourImageCache()

    static func dashedContour(for image: UIImage, color: UIColor) -> UIImage? {
        dashedContour(for: image, cacheID: fallbackCacheID(for: image), color: color)
    }

    static func dashedContour(for image: UIImage, cacheID: String, color: UIColor) -> UIImage? {
        let cacheKey = cacheKey(for: cacheID, color: color)
        if let cached = cache.image(forKey: cacheKey) {
            return cached
        }

        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        guard width > 2, height > 2 else {
            return nil
        }
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var sourceBuffer = [UInt8](repeating: 0, count: bytesPerRow * height)
        
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let sourceContext = CGContext(
            data: &sourceBuffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        sourceContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var rawEdges = [UInt8](repeating: 0, count: width * height)
        let alphaThreshold: UInt8 = 6
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let index = y * width + x
                let sourceAlpha = sourceBuffer[(index * bytesPerPixel) + 3]
                guard sourceAlpha > alphaThreshold else { continue }
                
                var hasBackgroundNeighbor = false
                for ny in (y - 1)...(y + 1) {
                    for nx in (x - 1)...(x + 1) where !(nx == x && ny == y) {
                        let neighborIndex = ny * width + nx
                        let neighborAlpha = sourceBuffer[(neighborIndex * bytesPerPixel) + 3]
                        if neighborAlpha <= alphaThreshold {
                            hasBackgroundNeighbor = true
                            break
                        }
                    }
                    if hasBackgroundNeighbor { break }
                }
                
                if hasBackgroundNeighbor {
                    rawEdges[index] = 255
                }
            }
        }
        
        // Thicken the real silhouette edge so it stays visible at card-preview sizes.
        var thickEdges = rawEdges
        let dilationRadius = max(1, Int(round(Double(max(width, height)) * 0.01)))
        if dilationRadius > 0 {
            for y in 1..<(height - 1) {
                for x in 1..<(width - 1) {
                    let index = y * width + x
                    guard rawEdges[index] > 0 else { continue }
                    let minY = max(0, y - dilationRadius)
                    let maxY = min(height - 1, y + dilationRadius)
                    let minX = max(0, x - dilationRadius)
                    let maxX = min(width - 1, x + dilationRadius)
                    for ny in minY...maxY {
                        for nx in minX...maxX {
                            thickEdges[ny * width + nx] = 255
                        }
                    }
                }
            }
        }

        let rgba = color.rgbaComponents
        let dashPeriod = max(8, Int(round(Double(max(width, height)) * 0.06)))
        let dashOnLength = max(4, Int(round(Double(dashPeriod) * 0.58)))

        var output = [UInt8](repeating: 0, count: bytesPerRow * height)
        let solidAlpha = max(160, Int(Double(rgba.a) * 0.92))
        var edgeCounter = 0

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                guard thickEdges[index] > 0 else { continue }
                let phase = edgeCounter % dashPeriod
                edgeCounter += 1
                guard phase < dashOnLength else { continue }

                let pixelOffset = index * bytesPerPixel
                let premultipliedR = (rgba.r * solidAlpha) / 255
                let premultipliedG = (rgba.g * solidAlpha) / 255
                let premultipliedB = (rgba.b * solidAlpha) / 255

                output[pixelOffset] = UInt8(clamping: premultipliedR)
                output[pixelOffset + 1] = UInt8(clamping: premultipliedG)
                output[pixelOffset + 2] = UInt8(clamping: premultipliedB)
                output[pixelOffset + 3] = UInt8(clamping: solidAlpha)
            }
        }
        
        guard let outputContext = CGContext(
            data: &output,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ), let cgOutput = outputContext.makeImage() else {
            return nil
        }
        
        let rendered = UIImage(cgImage: cgOutput, scale: image.scale, orientation: .up)
        cache.setImage(rendered, forKey: cacheKey)
        return rendered
    }

    static func warmCache(for image: UIImage, cacheID: String, colors: [UIColor]) {
        for color in colors {
            _ = dashedContour(for: image, cacheID: cacheID, color: color)
        }
    }

    private static func cacheKey(for cacheID: String, color: UIColor) -> NSString {
        let rgba = color.rgbaComponents
        let key = "\(cacheID)-\(rgba.r)-\(rgba.g)-\(rgba.b)-\(rgba.a)"
        return key as NSString
    }

    private static func fallbackCacheID(for image: UIImage) -> String {
        if let cgImage = image.cgImage {
            return "cg-\(cgImage.width)x\(cgImage.height)-\(Unmanaged.passUnretained(cgImage).toOpaque())"
        }
        return "ui-\(ObjectIdentifier(image))"
    }

    private final class ContourImageCache: @unchecked Sendable {
        private let storage = NSCache<NSString, UIImage>()
        private let lock = NSLock()

        func image(forKey key: NSString) -> UIImage? {
            lock.lock()
            defer { lock.unlock() }
            return storage.object(forKey: key)
        }

        func setImage(_ image: UIImage, forKey key: NSString) {
            lock.lock()
            storage.setObject(image, forKey: key)
            lock.unlock()
        }
    }
}

private extension UIColor {
    var rgbaComponents: (r: Int, g: Int, b: Int, a: Int) {
        let resolved = resolvedColor(with: UITraitCollection.current)
        if let converted = resolved.cgColor.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        ), let components = converted.components {
            if components.count >= 4 {
                return (
                    Int(components[0] * 255),
                    Int(components[1] * 255),
                    Int(components[2] * 255),
                    Int(components[3] * 255)
                )
            } else if components.count == 2 {
                let white = Int(components[0] * 255)
                let alpha = Int(components[1] * 255)
                return (white, white, white, alpha)
            }
        }

        var red: CGFloat = 1
        var green: CGFloat = 1
        var blue: CGFloat = 1
        var alpha: CGFloat = 1
        if resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (Int(red * 255), Int(green * 255), Int(blue * 255), Int(alpha * 255))
        }

        return (255, 255, 255, 255)
    }
}

struct GrailSwipeGalleryView: View {
    var previews: [GrailPreviewItem]
    var colors: ThemeColors
    @Binding var selectedIndex: Int
    var addIcon: String

    var body: some View {
        let slides = Array(previews.prefix(3))
        let showAddSlide = slides.count < 3
        let totalSlides = slides.count + (showAddSlide ? 1 : 0)
        
        VStack(spacing: 6) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, preview in
                    VStack(spacing: 8) {
                        previewVisual(preview)
                            .frame(width: 136, height: 136)
                        
                        Text(preview.name)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.saldoPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        Text(remainingText(for: preview))
                            .font(.caption2)
                            .foregroundStyle(Color.saldoSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                    .padding(.top, 2)
                    .tag(index)
                }
                
                if showAddSlide {
                    VStack(spacing: 8) {
                        Spacer(minLength: 0)
                        Image(systemName: addIcon)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(colors.primary)
                            .padding(.bottom, 4)
                        
                        Text("Add your grails")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(colors.secondary)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 196) // Match the content height
                    .padding(.top, 2)
                    .tag(slides.count)
                }
            }
            .frame(height: 196)
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            if totalSlides > 1 {
                HStack(spacing: 5) {
                    ForEach(0..<totalSlides, id: \.self) { index in
                        Circle()
                            .fill(index == selectedIndex ? colors.accent : Color.saldoSecondary.opacity(0.25))
                            .frame(width: index == selectedIndex ? 7 : 6, height: index == selectedIndex ? 7 : 6)
                    }
                }
            }
        }
    }
    
    private func remainingText(for preview: GrailPreviewItem) -> String {
        if preview.remainingAmount <= 0 {
            return "Ready to buy"
        }
        let amountText = preview.remainingAmount.formatted(
            FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2))
        )
        return "\(preview.currency)\(amountText) left to buy"
    }
    
    @ViewBuilder
    private func previewVisual(_ preview: GrailPreviewItem) -> some View {
        if let image = preview.image {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 126, height: 126)
                    .scaleEffect(1.08)
                
                if let contour = GrailContourRenderer.dashedContour(
                    for: image,
                    cacheID: preview.visualCacheKey,
                    color: UIColor(colors.accent)
                ) {
                    Image(uiImage: contour)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 126, height: 126)
                        .scaleEffect(1.08)
                        .allowsHitTesting(false)
                }
            }
        } else if preview.category == .misc && !preview.name.isEmpty {
            Text(String(preview.name.prefix(1).uppercased()))
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(colors.accent)
        } else {
            Image(systemName: preview.category.iconName)
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(colors.accent)
        }
    }
}

struct ActionButton: View {
    var icon: String
    var title: String
    var subtitle: String
    var colors: ThemeColors
    var grailPreviews: [GrailPreviewItem] = []
    var action: () -> Void
    
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if grailPreviews.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(colors.primary)
                    
                    Text("Add your grails")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(colors.secondary)
                }
                .padding()
            } else {
                GrailSwipeGalleryView(
                    previews: grailPreviews,
                    colors: colors,
                    selectedIndex: $selectedIndex,
                    addIcon: icon
                )
                .padding(.vertical, 16) // Keep some vertical padding to avoid clipping top/bottom
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass(cornerRadius: 20, material: .regular, shadowColor: colors.accent)
        .overlay(alignment: .topLeading) {
            if !grailPreviews.isEmpty {
                let maxSlides = min(grailPreviews.count + (grailPreviews.count < 3 ? 1 : 0), 3)
                if maxSlides > 1 {
                    Text("\(selectedIndex + 1)/\(maxSlides)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.secondary.opacity(0.8))
                        .padding(.top, 14)
                        .padding(.leading, 14)
                }
            }
        }
        .contentShape(.rect(cornerRadius: 20))
        .onTapGesture(perform: action)
        .onChange(of: grailPreviews.count) { _, newCount in
            if newCount == 0 {
                selectedIndex = 0
            } else {
                let totalSlides = min(newCount + (newCount < 3 ? 1 : 0), 3)
                if selectedIndex >= totalSlides {
                    selectedIndex = totalSlides - 1
                }
            }
        }
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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.03),
                        radius: 4,
                        x: 0,
                        y: 2
                    )

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
