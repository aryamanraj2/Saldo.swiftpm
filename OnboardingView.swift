import SwiftUI

// MARK: - Onboarding View
/// Main onboarding screen with 3 financial question slides
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    
    // Slide state
    @State private var currentPage = 0
    
    // User financial data
    @State private var allowance = 5000
    @State private var spending = 3000
    @State private var currentBalance = 2000
    
    // Animation
    @Namespace private var namespace
    
    // Transition State
    @State private var showTransition = false
    @State private var transitionQuote = ""
    
    // Current theme based on active slide's value
    private var currentTheme: AppTheme {
        switch currentPage {
        case 0:
            return AppTheme.from(balance: Double(allowance))
        case 1:
            // Invert logic for spending: higher spending = danger, lower = wealthy
            return AppTheme.fromSpending(spending: Double(spending), maxSpending: Double(allowance))
        case 2:
            return AppTheme.from(balance: Double(currentBalance))
        default:
            return AppTheme.from(balance: Double(currentBalance))
        }
    }
    
    // Theme for the transition screen (based on final spending status)
    private var transitionTheme: AppTheme {
        AppTheme.fromSpending(spending: Double(spending), maxSpending: Double(allowance))
    }
    
    private var themeColors: ThemeColors {
        currentTheme.colors
    }
    
    var body: some View {
        ZStack {
            // Dynamic animated background
            CleanBackground(colors: showTransition ? transitionTheme.colors : themeColors)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Page content
                TabView(selection: $currentPage) {
                    slideContent(
                        question: "How much is your allowance?",
                        value: $allowance,
                        icon: "wallet.bifold.fill",
                        subtitle: "Your monthly income or pocket money"
                    )
                    .tag(0)
                    
                    slideContent(
                        question: "How much do you spend?",
                        value: $spending,
                        icon: "cart.fill",
                        subtitle: "Your typical monthly expenses",
                        maxSliderValue: allowance,  // Cap to monthly allowance
                        themeOverride: AppTheme.fromSpending(spending: Double(spending), maxSpending: Double(allowance))
                    )
                    .tag(1)
                    
                    slideContent(
                        question: "What's your current balance?",
                        value: $currentBalance,
                        icon: "indianrupeesign.circle.fill",
                        subtitle: "The amount you have right now"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                
                // Bottom controls
                bottomControls
            }
            .opacity(showTransition ? 0 : 1) // Hide main content during transition
            
            // Transition View
            // if showTransition {
            //     QuoteTransitionView(quote: transitionQuote, themeColors: transitionTheme.colors)
            //         .transition(.opacity)
            //         .zIndex(1)
            // }
        }
        .animation(.easeInOut(duration: 0.5), value: currentTheme)
        .animation(.easeInOut(duration: 0.5), value: showTransition)
    }
    
    // MARK: - Header
    private var header: some View {
        EmptyView()
    }
    
    // MARK: - Slide Content
    @ViewBuilder
    private func slideContent(
        question: String,
        value: Binding<Int>,
        icon: String,
        subtitle: String,
        maxSliderValue: Int = 50000,  // Default max, can be overridden for spending
        themeOverride: AppTheme? = nil  // Optional: pass inverted theme for spending
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with glass effect
            if #available(iOS 26.0, *) {
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(themeColors.accent)
                    .frame(width: 80, height: 80)
                    .glassEffect(.regular.tint(themeColors.accent.opacity(0.2)))
            } else {
                // Fallback on earlier versions
            }
            
            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(themeColors.secondary)
                .padding(.bottom, 8)
            
            Spacer()
            
            // Slider
            OnboardingSlider(
                question: question,
                value: value,
                maxValue: maxSliderValue,
                step: 500,
                themeOverride: themeOverride
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Page indicators
            pageIndicators
            
            // Action button
            actionButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? themeColors.accent : themeColors.primary.opacity(0.2))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
    
    private var actionButton: some View {
        Button {
            if currentPage < 2 {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPage += 1
                }
                // Haptic for page change
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } else {
                completeOnboarding()
            }
        } label: {
            if #available(iOS 26.0, *) {
                HStack(spacing: 8) {
                    Text(currentPage < 2 ? "Continue" : "Get Started")
                        .fontWeight(.semibold)
                    
                    Image(systemName: currentPage < 2 ? "arrow.right" : "checkmark")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(themeColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .glassEffect(.regular.interactive().tint(themeColors.accent.opacity(0.3)), in: .capsule)
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    // MARK: - Quotes Logic
    private func getQuote() -> String {
        let percentage = Double(spending) / Double(max(allowance, 1)) * 100
        
        if percentage < 20 {
            // Low Spending
            let quotes = [
                "Look at you, the Master of Coin. Tywin Lannister would be proud."
            
            ]
            return quotes.randomElement() ?? quotes[0]
            
        } else if percentage <= 60 {
            // Moderate Spending
            let quotes = [
                "\"Perfectly balanced, as all things should be.\"",
                "Not great, not terrible.",
                "Living your best life without the 'Low Balance' notifications. Respect"
            ]
            return quotes.randomElement() ?? quotes[0]
            
        } else {
            // High Spending (> 60%)
            let quotes = [
                "Treat yo' self! (But maybe stop treating yo' self for the rest of the month?)",
                "Houston, we have a problem."
            ]
            return quotes.randomElement() ?? quotes[0]
        }
    }
    
    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        // Generate quote
        transitionQuote = getQuote()
        
        // Save user data
        UserDefaults.standard.set(allowance, forKey: "userAllowance")
        UserDefaults.standard.set(spending, forKey: "userSpending")
        UserDefaults.standard.set(currentBalance, forKey: "userBalance")
        
        // Haptic for completion
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Start Transition
        // withAnimation(.easeInOut(duration: 0.5)) {
        //     showTransition = true
        // }
        
        // Delay before actually completing
        // DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                isOnboardingComplete = true
            }
        // }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var isComplete = false
        
        var body: some View {
            OnboardingView(isOnboardingComplete: $isComplete)
        }
    }
    
    return PreviewWrapper()
}
