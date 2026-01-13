import SwiftUI
import AVFoundation
import UIKit

// MARK: - Tick Configuration
struct OnboardingTickConfig {
    var tickWidth: CGFloat = 3
    var tickHeight: CGFloat = 40
    var tickHPadding: CGFloat = 4
    var inActiveHeightProgress: CGFloat = 0.5
    var interactionHeight: CGFloat = 80
    var animation: Animation = .interpolatingSpring(duration: 0.25, bounce: 0, initialVelocity: 0)
}

// MARK: - Onboarding Slider
/// A premium tick-based slider with haptics, sound, Liquid Glass effects, and dynamic theming
struct OnboardingSlider: View {
    let question: String
    @Binding var value: Int  // Value in rupees (0, 500, 1000, etc.)
    let maxValue: Int
    let step: Int
    var themeOverride: AppTheme? = nil  // Optional: use parent's theme instead of calculating
    
    // Configuration
    private let config = OnboardingTickConfig()
    
    // Internal state
    @State private var tickIndex: Int = 0
    @State private var scrollPosition: Int?
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var animationRange: ClosedRange<Int> = 0...0
    @State private var isInitialSetupDone: Bool = false
    @State private var previousTickIndex: Int = 0
    
    // Haptic feedback

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    // Computed properties
    private var tickCount: Int {
        maxValue / step
    }
    
    private var tickWidth: CGFloat {
        config.tickWidth + (config.tickHPadding * 2)
    }
    
    // Theme based on current value (or use override from parent)
    private var currentTheme: AppTheme {
        themeOverride ?? AppTheme.from(balance: Double(value))
    }
    
    private var themeColors: ThemeColors {
        currentTheme.colors
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Question text
            Text(question)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(themeColors.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Value display with Liquid Glass
            valueDisplay
            
            Spacer()
            
            // Tick Picker
            tickPicker
            
            // Range labels
            rangeLabels
        }
        .animation(.easeInOut(duration: 0.4), value: currentTheme)
    }
    
    // MARK: - Value Display
    private var valueDisplay: some View {
        VStack(spacing: 4) {
            Text("₹\(formattedValue)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(themeColors.primary)
                .contentTransition(.numericText(value: Double(value)))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(themeColors.accent.opacity(0.3)), in: .rect(cornerRadius: 24))
        .padding(.horizontal, 40)
    }
    
    private var formattedValue: String {
        if value >= 1000 {
            let thousands = Double(value) / 1000.0
            if thousands.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(thousands))K"
            } else {
                return String(format: "%.1fK", thousands)
            }
        }
        return "\(value)"
    }
    
    // MARK: - Tick Picker
    private var tickPicker: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0...tickCount, id: \.self) { index in
                        tickView(for: index)
                    }
                }
                .frame(height: config.tickHeight)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .safeAreaPadding(.horizontal, (size.width - tickWidth) / 2)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                guard scrollPhase != .idle else { return }
                let index = max(min(Int((newValue / tickWidth).rounded()), tickCount), 0)
                let previousIndex = tickIndex
                tickIndex = index
                
                // Trigger haptic and sound on tick change
                if previousIndex != index && isInitialSetupDone {
                    triggerFeedback()
                }
                
                let isGreater = tickIndex > previousIndex
                let leadingBound = isGreater ? previousIndex : tickIndex
                let trailingBound = !isGreater ? previousIndex : tickIndex
                animationRange = leadingBound...trailingBound
            }
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
                animationRange = tickIndex...tickIndex
                
                if newPhase == .idle && scrollPosition != tickIndex {
                    withAnimation(config.animation) {
                        scrollPosition = tickIndex
                    }
                }
            }
        }
        .frame(height: config.interactionHeight)
        .overlay {
            // Center indicator with Liquid Glass
            centerIndicator
        }
        .task {
            guard !isInitialSetupDone else { return }
            
            // Prepare haptic generators
            feedbackGenerator.prepare()
            
            // Set initial position from value
            let initialTick = value / step
            updateScrollPosition(to: initialTick)
            
            try? await Task.sleep(for: .seconds(0.05))
            isInitialSetupDone = true
        }
        .allowsHitTesting(isInitialSetupDone)
        .onChange(of: tickIndex) { _, newValue in
            withAnimation(.snappy(duration: 0.4, extraBounce: 0.1)) {
                value = newValue * step
            }
        }
        .onChange(of: value) { _, newValue in
            let newTick = newValue / step
            guard tickIndex != newTick else { return }
            updateScrollPosition(to: newTick)
        }
    }
    
    // MARK: - Tick View
    @ViewBuilder
    private func tickView(for index: Int) -> some View {
        let height = config.tickHeight
        let isInside = animationRange.contains(index)
        let isActive = tickIndex == index
        let isMajorTick = index % 10 == 0
        
        let fillColor: Color = {
            if isActive {
                return themeColors.accent
            } else if isInside {
                return themeColors.primary.opacity(0.7)
            } else {
                return themeColors.primary.opacity(0.25)
            }
        }()
        
        RoundedRectangle(cornerRadius: config.tickWidth / 2)
            .fill(fillColor)
            .frame(
                width: isMajorTick ? config.tickWidth * 1.3 : config.tickWidth,
                height: height * (isInside ? 1 : config.inActiveHeightProgress * (isMajorTick ? 1.2 : 1))
            )
            .frame(width: tickWidth, height: height, alignment: .center)
            .animation(isInside || !isInitialSetupDone ? .none : config.animation, value: isInside)
    }
    
    // MARK: - Center Indicator
    private var centerIndicator: some View {
        VStack(spacing: 0) {
            // Top triangle
            Triangle()
                .fill(themeColors.accent)
                .frame(width: 12, height: 8)
            
            Spacer()
            
            // Bottom triangle
            Triangle()
                .fill(themeColors.accent)
                .frame(width: 12, height: 8)
                .rotationEffect(.degrees(180))
        }
        .frame(height: config.interactionHeight)
        .allowsHitTesting(false)
    }
    
    // MARK: - Range Labels
    private var rangeLabels: some View {
        HStack {
            Text("₹0")
                .font(.caption)
                .foregroundStyle(themeColors.secondary)
            
            Spacer()
            
            Text("₹\(maxValue / 1000)K")
                .font(.caption)
                .foregroundStyle(themeColors.secondary)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Methods
    private func updateScrollPosition(to tick: Int) {
        let safeTick = max(min(tick, tickCount), 0)
        scrollPosition = safeTick
        tickIndex = safeTick
        animationRange = safeTick...safeTick
    }
    
    private func triggerFeedback() {
        // Haptic feedback - using selection change for slider feel
        feedbackGenerator.impactOccurred()
        
        // Sound feedback (system tick sound 1157)
        let systemSoundID: SystemSoundID = 1157
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var value = 5000
        
        var body: some View {
            ZStack {
                CleanBackground(colors: AppTheme.from(balance: Double(value)).colors)
                
                OnboardingSlider(
                    question: "How much is your allowance?",
                    value: $value,
                    maxValue: 50000,
                    step: 500
                )
            }
        }
    }
    
    return PreviewWrapper()
}
