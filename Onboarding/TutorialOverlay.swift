import SwiftUI

// MARK: - Tutorial Step Definition
enum TutorialStep: Int, CaseIterable, Identifiable {
    case remainingBalance = 1
    case getInsights = 2
    case scanReceipt = 3
    case grills = 4
    
    var id: Int { rawValue }
}

// MARK: - Tutorial Item (Stores captured frame info)
struct TutorialItem: Identifiable {
    var id: TutorialStep
    var frame: CGRect
}

// MARK: - Tutorial Coordinator
@MainActor
@Observable
class TutorialCoordinator {
    var items: [TutorialItem] = []
    var overlayWindow: UIWindow?
    var isTutorialFinished: Bool = false
    
    var orderedItems: [TutorialItem] {
        items.sorted { $0.id.rawValue < $1.id.rawValue }
    }
    
    func frame(for step: TutorialStep) -> CGRect? {
        items.first(where: { $0.id == step })?.frame
    }
}

// MARK: - Tutorial Container View
struct TutorialContainer<Content: View>: View {
    @Binding var isActive: Bool
    var content: Content
    var onFinish: () -> Void
    
    @State private var coordinator = TutorialCoordinator()
    
    init(
        isActive: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content,
        onFinish: @escaping () -> Void
    ) {
        self._isActive = isActive
        self.content = content()
        self.onFinish = onFinish
    }
    
    var body: some View {
        content
            .environment(coordinator)
            .task(id: isActive) {
                // Only trigger when isActive becomes true
                guard isActive else { return }
                // Quick delay to capture geometry frames
                try? await Task.sleep(for: .seconds(0.15))
                await createOverlayWindow()
            }
            .onChange(of: coordinator.isTutorialFinished) { _, newValue in
                if newValue {
                    onFinish()
                    hideWindow()
                    isActive = false
                }
            }
            .onChange(of: isActive) { _, newValue in
                if !newValue {
                    hideWindow()
                }
            }
    }
    
    @MainActor
    private func createOverlayWindow() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              isActive,
              coordinator.overlayWindow == nil else { return }
        
        let window = UIWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.isHidden = false
        window.isUserInteractionEnabled = true
        window.windowLevel = .alert + 1
        
        coordinator.overlayWindow = window
        
        // Wait a bit more for frames to be captured
        try? await Task.sleep(for: .seconds(0.1))
        
        if coordinator.items.isEmpty {
            hideWindow()
            return
        }
        
        guard let snapshot = snapshotScreen() else {
            hideWindow()
            return
        }
        
        let hostController = UIHostingController(
            rootView: TutorialOverlayView(snapshot: snapshot)
                .environment(coordinator)
        )
        
        hostController.view.backgroundColor = .clear
        coordinator.overlayWindow?.rootViewController = hostController
    }
    
    private func hideWindow() {
        coordinator.overlayWindow?.rootViewController = nil
        coordinator.overlayWindow?.isHidden = true
        coordinator.overlayWindow?.isUserInteractionEnabled = false
        coordinator.overlayWindow = nil
    }
    
    private func snapshotScreen() -> UIImage? {
        guard let snapshotView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: snapshotView.bounds.size)
        let image = renderer.image { context in
            snapshotView.drawHierarchy(in: snapshotView.bounds, afterScreenUpdates: true)
        }
        return image
    }
}

// MARK: - View Extension for Tutorial Modifier
extension View {
    func tutorialHighlight(_ step: TutorialStep) -> some View {
        self.modifier(TutorialHighlightModifier(step: step))
    }
    
    func tutorialOverlay(isActive: Binding<Bool>, onFinish: @escaping () -> Void = {}) -> some View {
        TutorialContainer(isActive: isActive, content: { self }, onFinish: onFinish)
    }
}

// MARK: - Tutorial Highlight Modifier
struct TutorialHighlightModifier: ViewModifier {
    var step: TutorialStep
    @Environment(TutorialCoordinator.self) var coordinator: TutorialCoordinator?
    
    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { newFrame in
                guard let coordinator = coordinator else { return }
                
                // Remove existing item for this step
                coordinator.items.removeAll { $0.id == step }
                
                // Add updated item
                let item = TutorialItem(id: step, frame: newFrame)
                coordinator.items.append(item)
            }
            .onDisappear {
                coordinator?.items.removeAll { $0.id == step }
            }
    }
}

// MARK: - Tutorial Overlay View
fileprivate struct TutorialOverlayView: View {
    var snapshot: UIImage

    @Environment(TutorialCoordinator.self) var coordinator
    @Environment(\.colorScheme) var colorScheme
    @State private var animate: Bool = false
    @State private var currentIndex: Int = 0
    @State private var dismissOpacity: Double = 1.0

    // Use moderate theme colors with colorScheme support
    private var themeColors: ThemeColors {
        AppTheme.moderate.colors(for: colorScheme)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let isHomeButtoniPhone = safeArea.bottom == 0
            let cornerRadius: CGFloat = isHomeButtoniPhone ? 15 : 35
            
            ZStack {
                // Background - Moderate theme gradient instead of black
                TutorialBackground(colors: themeColors)
                
                // Scaled iPhone Snapshot
                Image(uiImage: snapshot)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(
                        .rect(
                            cornerRadius: animate ? cornerRadius : 0,
                            style: .circular
                        )
                    )
                    .overlay {
                        // Dark overlay with spotlight cutout
                        Rectangle()
                            .fill(Color.black.opacity(0.35))
                            .reverseMask(alignment: .topLeading) {
                                if !coordinator.orderedItems.isEmpty,
                                   currentIndex < coordinator.orderedItems.count {
                                    let maskLocation = coordinator.orderedItems[currentIndex].frame
                                    
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .frame(
                                            width: maskLocation.width + 12,
                                            height: maskLocation.height + 12
                                        )
                                        .offset(
                                            x: maskLocation.minX - 6,
                                            y: maskLocation.minY - 6
                                        )
                                }
                            }
                    }
                    .overlay {
                        // iPhone frame (no notch - just rounded corners and border)
                        iPhoneFrame(safeArea: safeArea, animate: animate)
                    }
                    .scaleEffect(animate ? 0.68 : 1, anchor: .top)
                    .offset(x: 0, y: animate ? (safeArea.top + 25) : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(alignment: .bottom) {
                        // Bottom navigation
                        TutorialBottomView(
                            safeArea: safeArea,
                            orderedItems: coordinator.orderedItems,
                            currentIndex: $currentIndex,
                            themeColors: themeColors,
                            onFinish: closeTutorial
                        )
                    }
                    .opacity(animate ? 1 : 0)
            }
            .opacity(dismissOpacity)
            .ignoresSafeArea()
        }
        .onAppear {
            guard !animate else { return }
            withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                animate = true
            }
        }
    }
    
    private func closeTutorial() {
        // Animate phone back to full size
        withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
            animate = false
        }
        
        // Fade out overlay
        withAnimation(.easeOut(duration: 0.25).delay(0.15)) {
            dismissOpacity = 0
        }
        
        // Mark as finished after animation completes
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            await MainActor.run {
                coordinator.isTutorialFinished = true
            }
        }
    }
}

// MARK: - Tutorial Background (Moderate Theme Gradient)
fileprivate struct TutorialBackground: View {
    var colors: ThemeColors
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base background
            colors.background
            
            // Animated blobs
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(colors.backgroundBlob1)
                        .blur(radius: 80)
                        .frame(width: 300, height: 300)
                        .position(x: proxy.size.width * 0.9, y: proxy.size.height * 0.1)
                        .offset(x: animate ? -30 : 30, y: animate ? -30 : 30)
                    
                    Circle()
                        .fill(colors.backgroundBlob2)
                        .blur(radius: 100)
                        .frame(width: 400, height: 400)
                        .position(x: 0, y: proxy.size.height * 0.4)
                        .offset(x: animate ? 20 : -20, y: animate ? 40 : -40)
                    
                    Circle()
                        .fill(colors.backgroundBlob3)
                        .blur(radius: 90)
                        .frame(width: 350, height: 350)
                        .position(x: proxy.size.width, y: proxy.size.height * 0.85)
                        .offset(x: animate ? -40 : 40, y: animate ? -20 : 20)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - iPhone Frame (No Notch)
@ViewBuilder
fileprivate func iPhoneFrame(safeArea: EdgeInsets, animate: Bool) -> some View {
    let isHomeButtoniPhone = safeArea.bottom == 0
    let cornerRadius: CGFloat = isHomeButtoniPhone ? 20 : 45
    
    ZStack(alignment: .top) {
        // Border frame
        RoundedRectangle(
            cornerRadius: animate ? cornerRadius : 0,
            style: .continuous
        )
        .stroke(Color.white, lineWidth: animate ? 15 : 0)
        .padding(-6)
        
        // NO notch/dynamic island - just clean frame
    }
}

// MARK: - Tutorial Bottom View (Navigation)
fileprivate struct TutorialBottomView: View {
    var safeArea: EdgeInsets
    var orderedItems: [TutorialItem]
    @Binding var currentIndex: Int
    var themeColors: ThemeColors
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Placeholder for explanation text (can be added later)
            Spacer()
                .frame(height: 50)
            
            // Navigation Buttons - Liquid Glass Style
            VStack(spacing: 12) {
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        // Back Button - only visible when not on first item
                        if currentIndex > 0 {
                            Button {
                                withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                                    currentIndex = max(currentIndex - 1, 0)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(themeColors.primary)
                                    .frame(width: 50, height: 50)
                            }
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .scale(scale: 0.5).combined(with: .opacity)
                            ))
                        }
                        
                        // Next/Finish Button
                        Button {
                            if currentIndex == orderedItems.count - 1 {
                                onFinish()
                            } else {
                                withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                                    currentIndex += 1
                                }
                            }
                        } label: {
                            Text(currentIndex == orderedItems.count - 1 ? "Finish" : "Next")
                                .fontWeight(.semibold)
                                .foregroundStyle(themeColors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .contentTransition(.numericText())
                        }
                        .glassEffect(.regular.interactive().tint(themeColors.accent.opacity(0.3)), in: .capsule)
                        .frame(maxWidth: currentIndex > 0 ? 200 : 250)
                    }
                }
                .frame(maxWidth: 280)
                .animation(.smooth(duration: 0.35, extraBounce: 0), value: currentIndex)
                
                // Skip Tutorial Button
                Button(action: onFinish) {
                    Text("Skip Tutorial")
                        .font(.callout)
                        .underline()
                }
                .foregroundStyle(themeColors.secondary)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, safeArea.bottom + 10)
        }
    }
}

// MARK: - Reverse Mask Extension
extension View {
    @ViewBuilder
    fileprivate func reverseMask<Content: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    content()
                        .blendMode(.destinationOut)
                }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showTutorial = true
        
        var body: some View {
            ZStack {
                VStack(spacing: 20) {
                    Text("Balance: ₹4,500")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 12))
                        .tutorialHighlight(.remainingBalance)
                    
                    Button("Get Insights") {}
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 12))
                        .tutorialHighlight(.getInsights)
                    
                    Button("Scan Receipt") {}
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 12))
                        .tutorialHighlight(.scanReceipt)
                    
                    Text("Grills Section")
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 12))
                        .tutorialHighlight(.grills)
                }
            }
            .tutorialOverlay(isActive: $showTutorial) {
                print("Tutorial finished!")
            }
        }
    }
    
    return PreviewWrapper()
}
