import SwiftUI
import FoundationModels

// MARK: - Insights View

struct InsightsView: View {
    var colors: ThemeColors
    var transactionStore: TransactionStore

    @State private var aiManager: InsightsAIManager?
    @State private var inputText = ""
    @State private var appearAnimation = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Suggested quick prompts for students
    private let quickPrompts = [
        "Where am I spending the most?",
        "How can I save more?",
        "Show me my recurring expenses",
        "Am I on track this month?"
    ]

    var body: some View {
        ZStack {
            // Background
            CleanBackground(colors: colors)

            if #available(iOS 26.0, *) {
                let model = SystemLanguageModel.default
                switch model.availability {
                case .available:
                    chatInterface
                case .unavailable(let reason):
                    unavailableView(reason: reason)
                }
            } else {
                unavailableFallback
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(colors.primary)
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 14))
                        .foregroundStyle(colors.accent)
                        .symbolEffect(.breathe, isActive: aiManager?.isGenerating == true)
                    Text("Saldo AI")
                        .font(.headline)
                        .foregroundStyle(colors.primary)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                appearAnimation = true
            }
        }
        .onDisappear {
            if #available(iOS 26.0, *) {
                aiManager?.terminate()
            }
        }
    }

    // MARK: - Chat Interface

    @available(iOS 26.0, *)
    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Messages Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Zen header
                        zenHeader
                            .padding(.top, 12)

                        // Health check loading or messages
                        if let manager = aiManager {
                            if manager.messages.isEmpty && manager.isGenerating {
                                healthCheckShimmer
                                    .id("shimmer")
                            }

                            ForEach(manager.messages) { message in
                                chatBubble(for: message)
                                    .id(message.id)
                            }

                            if manager.isGenerating && !manager.messages.isEmpty {
                                typingIndicator
                                    .id("typing")
                            }

                            if let error = manager.errorMessage {
                                errorBubble(error)
                                    .id("error")
                            }
                        }

                        // Quick prompts (show only after health check, before user sends first message)
                        if let manager = aiManager,
                           manager.isHealthCheckComplete,
                           manager.messages.filter({ $0.role == .user }).isEmpty {
                            quickPromptsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .onChange(of: aiManager?.messages.count) {
                    if let lastMessage = aiManager?.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input Bar
            inputBar
        }
        .task {
            guard aiManager == nil else { return }
            let manager = InsightsAIManager()
            aiManager = manager
            manager.initializeSession()
            await manager.performHealthCheck()
        }
    }

    // MARK: - Zen Header

    private var zenHeader: some View {
        VStack(spacing: 8) {
            // Lotus icon
            ZStack {
                Circle()
                    .fill(colors.accent.opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: "apple.intelligence")
                    .font(.system(size: 24))
                    .foregroundStyle(colors.accent)
            }
            .opacity(appearAnimation ? 1 : 0)
            .scaleEffect(appearAnimation ? 1 : 0.7)

            Text("Financial Wellness")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(colors.primary)
                .opacity(appearAnimation ? 1 : 0)

            Text("Your personal AI guide to smarter spending")
                .font(.footnote)
                .foregroundStyle(Color.saldoSecondary)
                .opacity(appearAnimation ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Health Check Shimmer

    @available(iOS 26.0, *)
    private var healthCheckShimmer: some View {
        VStack(alignment: .leading, spacing: 10) {
            shimmerLine(width: 220)
            shimmerLine(width: 180)
            shimmerLine(width: 260)
            shimmerLine(width: 140)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
        )
        .padding(.trailing, 40)
    }

    private func shimmerLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(colors.accent.opacity(0.15))
            .frame(width: width, height: 12)
            .shimmering()
    }

    // MARK: - Chat Bubble

    private func chatBubble(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? Color.white : colors.primary)
                    .textSelection(.enabled)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                if message.role == .user {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [colors.accent, colors.accent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                                    lineWidth: 1
                                )
                        )
                }
            }

            if message.role == .assistant { Spacer(minLength: 48) }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(colors.accent.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .offset(y: typingDotOffset(for: index))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
            )

            Spacer()
        }
    }

    @State private var typingAnimationPhase: CGFloat = 0

    private func typingDotOffset(for index: Int) -> CGFloat {
        let phase = typingAnimationPhase + Double(index) * 0.33
        return sin(phase * .pi * 2) * 4
    }

    // MARK: - Error Bubble

    private func errorBubble(_ text: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.footnote)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(Color.saldoSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer()
        }
    }

    // MARK: - Quick Prompts

    private var quickPromptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask me anything")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(Color.saldoSecondary)

            FlowLayout(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        if #available(iOS 26.0, *) {
                            Task {
                                await aiManager?.sendMessage(prompt)
                            }
                        }
                    } label: {
                        Text(prompt)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(colors.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(colors.accent.opacity(0.25), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about your finances...", text: $inputText, axis: .vertical)
                .font(.subheadline)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            isInputFocused ? colors.accent.opacity(0.4) : Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                            lineWidth: 1
                        )
                )
                .focused($isInputFocused)

            // Send Button
            Button {
                sendCurrentMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.saldoSecondary.opacity(0.3)
                        : colors.accent
                    )
                    .symbolEffect(.bounce, value: inputText.isEmpty)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiManager?.isGenerating == true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Send Message

    private func sendCurrentMessage() {
        let text = inputText
        inputText = ""
        if #available(iOS 26.0, *) {
            Task {
                await aiManager?.sendMessage(text)
            }
        }
    }

    // MARK: - Unavailable Views

    @available(iOS 26.0, *)
    private func unavailableView(reason: SystemLanguageModel.Availability.UnavailableReason) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "apple.intelligence")
                .font(.system(size: 48))
                .foregroundStyle(Color.saldoSecondary.opacity(0.4))

            Text("Apple Intelligence Unavailable")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(colors.primary)

            Text(unavailabilityMessage(for: reason))
                .font(.subheadline)
                .foregroundStyle(Color.saldoSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unavailableFallback: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.saldoSecondary.opacity(0.4))

            Text("Requires iOS 26")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(colors.primary)

            Text("Update your device to iOS 26 or later to use Saldo AI insights.")
                .font(.subheadline)
                .foregroundStyle(Color.saldoSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @available(iOS 26.0, *)
    private func unavailabilityMessage(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This device doesn't support Apple Intelligence. A newer iPhone, iPad, or Mac is required."
        case .appleIntelligenceNotEnabled:
            return "Enable Apple Intelligence in Settings → Apple Intelligence & Siri to use this feature."
        case .modelNotReady:
            return "Apple Intelligence is still setting up. Please try again in a few minutes."
        default:
            return "Apple Intelligence is currently unavailable. Please try again later."
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: max(0, phase - 0.3)),
                            .init(color: .white.opacity(0.3), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.3))
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .blendMode(.overlay)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Flow Layout (for Quick Prompts)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InsightsView(
            colors: AppTheme.moderate.colors,
            transactionStore: TransactionStore.shared
        )
    }
}
