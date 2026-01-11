Here is the breakdown of the visual effect you want to achieve:

The "Miniature" Effect: The current screen shrinks down slightly (like opening the App Switcher).

The Spotlight: A dark layer covers the app, but a specific button or area is "cut out" (highlighted) so it stays bright.

The External Controls: The "Next" button and explanatory text sit outside the phone screen at the bottom.

Here is the detailed explanation and the complete code to build this exactly as shown in your screenshots.

The Core Concept: "Snapshot & Mask"

Instead of trying to redraw your complex Finance Dashboard twice, we use a trick:

We take a Snapshot (Screenshot) of your view as soon as it appears.

We display that screenshot in a new full-screen overlay.

We apply a Reverse Mask (a hole punch) over the item you want to highlight.

We wrap the screenshot in a simulated "iPhone Bezel" and scale it down.

Step 1: The Data Model & Coordinator

This acts as the "Director" of the tutorial. It remembers which step (1, 2, 3) the user is on and handles the "Next" logic.

Swift
import SwiftUI

// 1. The Data Model for each spotlight item
struct OnBoardingItem: Identifiable, Equatable {
    var id: UUID = .init()
    var position: Int      // The order (1st, 2nd, 3rd)
    var maskLocation: CGRect // The frame (x, y, width, height) of the button to highlight
    var title: String      // Title text for the tutorial step
    var description: String // Body text for the tutorial step
    
    static func == (lhs: OnBoardingItem, rhs: OnBoardingItem) -> Bool {
        lhs.id == rhs.id
    }
}

// 2. The Coordinator (The Brain)
@Observable
class OnBoardingCoordinator {
    var items: [OnBoardingItem] = []
    var overlayWindow: UIWindow?
    var currentStepIndex: Int = 0
    
    var orderedItems: [OnBoardingItem] {
        items.sorted { $0.position < $1.position }
    }
    
    var currentItem: OnBoardingItem? {
        if orderedItems.indices.contains(currentStepIndex) {
            return orderedItems[currentStepIndex]
        }
        return nil
    }
    
    func nextStep() {
        if currentStepIndex < orderedItems.count - 1 {
            withAnimation(.snappy) {
                currentStepIndex += 1
            }
        } else {
            dismiss()
        }
    }
    
    func skip() {
        dismiss()
    }
    
    func dismiss() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
        items.removeAll()
        currentStepIndex = 0
    }
}
Step 2: The Main Overlay View

This is the view that draws the "Mini iPhone" and the holes.

Swift
struct OverlayWindowView: View {
    var snapshot: UIImage
    @State var coordinator: OnBoardingCoordinator
    @State private var animate: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets
            
            ZStack {
                // Dark Background for the whole screen
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // The "Mini App" Area
                    GeometryReader { innerProxy in
                        let size = innerProxy.size
                        
                        ZStack {
                            // The Snapshot of your app
                            Image(uiImage: snapshot)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                                .overlay {
                                    // The Dimming Layer with the "Hole"
                                    Rectangle()
                                        .fill(.black.opacity(0.4))
                                        .reverseMask {
                                            if let currentItem = coordinator.currentItem {
                                                let maskLocation = currentItem.maskLocation
                                                
                                                // We cut the hole exactly where the button is
                                                RoundedRectangle(cornerRadius: 12)
                                                    .frame(width: maskLocation.width, height: maskLocation.height)
                                                    .offset(x: maskLocation.minX, y: maskLocation.minY)
                                            }
                                        }
                                }
                                .overlay {
                                    // Draw the iPhone Border/Bezel
                                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                                        .stroke(.white.opacity(0.2), lineWidth: 2)
                                    
                                    // Draw Dynamic Island
                                    Capsule()
                                        .fill(.black)
                                        .frame(width: 120, height: 37)
                                        .position(x: size.width / 2, y: 19)
                                }
                        }
                        // Scale it down to create the "App Switcher" effect
                        .scaleEffect(animate ? 0.85 : 1, anchor: .center)
                        .animation(.smooth(duration: 0.4), value: animate)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // BOTTOM CONTROLS (Title, Description, Next Button)
                    if let item = coordinator.currentItem {
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text(item.title)
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                
                                Text(item.description)
                                    .font(.body)
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            
                            // Navigation Buttons
                            VStack(spacing: 15) {
                                Button {
                                    coordinator.nextStep()
                                } label: {
                                    Text(coordinator.currentStepIndex == coordinator.items.count - 1 ? "Finish" : "Next")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue, in: Capsule())
                                }
                                
                                Button("Skip Tutorial") {
                                    coordinator.skip()
                                }
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            }
                            .padding(.horizontal, 30)
                        }
                        .padding(.bottom, safeArea.bottom + 10)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.5)) {
                animate = true
            }
        }
    }
}

// Helper to create the "Hole"
extension View {
    @inlinable func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}
Step 3: Integration (The Wrapper)

This wrapper goes around your ContentView. It captures the snapshot and launches the window.

Swift
struct OnBoardingWrapper<Content: View>: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    @State private var coordinator = OnBoardingCoordinator()
    
    var body: some View {
        content
            .environment(coordinator)
            .task {
                // If user hasn't seen onboarding, start it after a slight delay
                if !hasSeenOnboarding {
                    try? await Task.sleep(for: .seconds(0.5))
                    await startOnboarding()
                }
            }
    }
    
    @MainActor
    private func startOnboarding() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        // Take Screenshot
        guard let snapshot = window.rootViewController?.view.snapshotView(afterScreenUpdates: true)?.asImage() else { return }
        
        // Create Overlay Window
        let overlayWindow = UIWindow(windowScene: windowScene)
        overlayWindow.rootViewController = UIHostingController(rootView: OverlayWindowView(snapshot: snapshot, coordinator: coordinator))
        overlayWindow.windowLevel = .alert + 1
        overlayWindow.makeKeyAndVisible()
        overlayWindow.backgroundColor = .clear
        
        coordinator.overlayWindow = overlayWindow
    }
}

// Helper to convert UIView to Image
extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
Step 4: Applying it to YOUR App

This is how you attach the tutorial steps to the specific cards in your Finance App.

You need to use a modifier to "tag" the views.

Swift
// The Modifier to tag views
extension View {
    func onBoarding(position: Int, title: String, description: String) -> some View {
        modifier(OnBoardingModifier(position: position, title: title, description: description))
    }
}

struct OnBoardingModifier: ViewModifier {
    var position: Int
    var title: String
    var description: String
    @Environment(OnBoardingCoordinator.self) var coordinator
    
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            let frame = proxy.frame(in: .global)
                            // Add this item to the coordinator
                            let item = OnBoardingItem(position: position, maskLocation: frame, title: title, description: description)
                            coordinator.items.append(item)
                        }
                }
            }
    }
}
Final Usage Example

Here is how your HomeView code would look with the tags added:

Swift
struct AryamanFinanceHome: View {
    var body: some View {
        OnBoardingWrapper { // 1. Wrap your whole app here
            VStack {
                // HEADER
                HStack {
                    VStack(alignment: .leading) {
                        Text("Welcome Back!")
                        Text("Aryaman").font(.largeTitle.bold())
                    }
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        // TAG 1: The Profile
                        .onBoarding(position: 1, title: "Your Profile", description: "Manage your account settings and personal details here.")
                }
                .padding()
                
                // BALANCE CARD
                VStack(alignment: .leading) {
                    Text("Remaining Balance")
                    Text("₹4500.00").font(.system(size: 40, weight: .bold))
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
                // TAG 2: Balance
                .onBoarding(position: 2, title: "Track Balance", description: "See your remaining budget for the month at a glance.")
                
                HStack {
                    // SPENT CARD
                    VStack {
                        Text("Spent this week")
                        Text("₹1,500")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    
                    // ADD SUBSCRIPTION BUTTON
                    Button {
                        // Action
                    } label: {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Subscription")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    // TAG 3: Add Button
                    .onBoarding(position: 3, title: "Add Expenses", description: "Quickly add new subscriptions or one-time expenses.")
                }
                
                Spacer()
            }
        }
    }
}
