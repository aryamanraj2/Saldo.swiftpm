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
    
    // Current theme based on active slide's value
    private var currentTheme: AppTheme {
        let value: Double
        switch currentPage {
        case 0: value = Double(allowance)
        case 1: value = Double(spending)
        case 2: value = Double(currentBalance)
        default: value = Double(currentBalance)
        }
        return AppTheme.from(balance: value)
    }
    
    private var themeColors: ThemeColors {
        currentTheme.colors
    }
    
    var body: some View {
        ZStack {
            // Dynamic animated background
            CleanBackground(colors: themeColors)
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
                        subtitle: "Your typical monthly expenses"
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
                .animation(.easeInOut(duration: 0.4), value: currentPage)
                
                // Bottom controls
                bottomControls
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentTheme)
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
        subtitle: String
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
            
            // Slider
            OnboardingSlider(
                question: question,
                value: value,
                maxValue: 50000,
                step: 500
            )
            
            Spacer()
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
    
    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        // Save user data
        UserDefaults.standard.set(allowance, forKey: "userAllowance")
        UserDefaults.standard.set(spending, forKey: "userSpending")
        UserDefaults.standard.set(currentBalance, forKey: "userBalance")
        
        // Haptic for completion
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Complete onboarding
        withAnimation(.easeInOut(duration: 0.5)) {
            isOnboardingComplete = true
        }
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
