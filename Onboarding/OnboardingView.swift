import SwiftUI

// MARK: - Onboarding View
/// Main onboarding screen with name input + 3 financial question slides
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @Environment(\.colorScheme) var colorScheme

    // Slide state
    @State private var currentPage = 0
    @State private var minPage = 0

    // User data
    @State private var userName = ""
    @FocusState private var isNameFieldFocused: Bool

    // User financial data
    @State private var allowance = CurrencyManager.shared.selected.defaultAllowance
    @State private var spending = CurrencyManager.shared.selected.defaultSpending

    // Animation
    @Namespace private var namespace

    // Transition State
    @State private var showTransition = false
    @State private var transitionQuote = ""

    // Current theme based on active slide's value
    private var currentTheme: AppTheme {
        switch currentPage {
        case 0:
            // Name input - use a welcoming wealthy green theme
            return .wealthy
        case 1:
            return AppTheme.from(balance: Double(allowance))
        case 2:
            // Invert logic for spending: higher spending = danger, lower = wealthy
            return AppTheme.fromSpending(spending: Double(spending), maxSpending: Double(allowance))
        default:
            return .wealthy
        }
    }

    // Theme for the transition screen (based on final spending status)
    private var transitionTheme: AppTheme {
        AppTheme.fromSpending(spending: Double(spending), maxSpending: Double(allowance))
    }

    private var themeColors: ThemeColors {
        currentTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        ZStack {
            // Dynamic animated background
            CleanBackground(colors: showTransition ? transitionTheme.colors(for: colorScheme) : themeColors)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Page content
                TabView(selection: $currentPage) {
                    // Page 0: Name Input
                    nameInputSlide
                        .tag(0)

                    // Page 1: Allowance
                    slideContent(
                        question: "How much is your allowance?",
                        value: $allowance,
                        icon: "wallet.bifold.fill",
                        subtitle: "Your monthly income or pocket money",
                        showCurrencyHint: true
                    )
                    .tag(1)

                    // Page 2: Spending
                    slideContent(
                        question: "How much do you spend?",
                        value: $spending,
                        icon: "cart.fill",
                        subtitle: "Your typical monthly expenses",
                        maxSliderValue: allowance,
                        themeOverride: AppTheme.fromSpending(spending: Double(spending), maxSpending: Double(allowance))
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, newValue in
                    // Prevent backward navigation past the minimum allowed page
                    if newValue < minPage {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentPage = minPage
                        }
                    }
                }

                
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

    // MARK: - Name Input Slide
    private var nameInputSlide: some View {
        VStack(spacing: 32) {
            Spacer()

            // Greeting icon with glass effect
            if #available(iOS 26.0, *) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(themeColors.accent)
                    .frame(width: 80, height: 80)
                    .glassEffect(.regular.tint(themeColors.accent.opacity(0.2)))
                    .symbolEffect(.wiggle, options: .repeat(2))
            }

            // Question text
            VStack(spacing: 8) {
                Text("Hey,")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(themeColors.primary)

                Text("What's your name?")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(themeColors.primary)
            }

            // Elegant text field with liquid glass
            if #available(iOS 26.0, *) {
                TextField("", text: $userName, prompt: Text("Enter your name")
                    .foregroundStyle(themeColors.secondary.opacity(0.6)))
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(themeColors.primary)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isNameFieldFocused)
                    .submitLabel(.next)
                    .onSubmit {
                        if canProceed {
                            isNameFieldFocused = false
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPage += 1
                            }
                            minPage = currentPage
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 32)
                    .glassEffect(.regular.tint(themeColors.accent.opacity(0.15)), in: .capsule)
                    .padding(.horizontal, 24)
            }

            // Subtle hint
            Text("This is how we'll greet you")
                .font(.subheadline)
                .foregroundStyle(themeColors.secondary)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 16)
        .task {
            // Auto-focus the text field with a slight delay for smooth transition
            try? await Task.sleep(for: .seconds(0.5))
            isNameFieldFocused = true
        }
    }

    // MARK: - Slide Content
    @ViewBuilder
    private func slideContent(
        question: String,
        value: Binding<Int>,
        icon: String,
        subtitle: String,
        maxSliderValue: Int? = nil,
        themeOverride: AppTheme? = nil,
        showCurrencyHint: Bool = false
    ) -> some View {
        let currency = CurrencyManager.shared.selected
        let resolvedMax = maxSliderValue ?? currency.sliderMax

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
                maxValue: resolvedMax,
                step: currency.sliderStep,
                themeOverride: themeOverride,
                showCurrencyHint: showCurrencyHint
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

    // Check if can proceed from current page
    private var canProceed: Bool {
        if currentPage == 0 {
            return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    private var actionButton: some View {
        Button {
            if currentPage < 2 {
                // Dismiss keyboard if on name page
                if currentPage == 0 {
                    isNameFieldFocused = false
                }
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPage += 1
                }
                // Lock out backward navigation to completed pages
                minPage = currentPage
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
                .foregroundStyle(canProceed ? themeColors.primary : themeColors.primary.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .glassEffect(.regular.interactive().tint(themeColors.accent.opacity(canProceed ? 0.3 : 0.1)), in: .capsule)
            } else {
                // Fallback on earlier versions
            }
        }
        .disabled(!canProceed)
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
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmedName, forKey: "userName")
        UserDefaults.standard.set(allowance, forKey: "userAllowance")
        UserDefaults.standard.set(spending, forKey: "userSpending")
        // Default starting balance = allowance (fresh month)
        UserDefaults.standard.set(allowance, forKey: "userBalance")
        
        // Haptic for completion
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
            withAnimation(.easeOut(duration: 0.5)) {
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
