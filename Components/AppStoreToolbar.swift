import SwiftUI

// MARK: - View Extension
extension View {
    /// Adds a dynamic App Store-style toolbar that changes content based on scroll offset.
    /// - Parameters:
    ///   - triggerOffset: The Y-offset point where the toolbar transition happens.
    ///   - beforeTrailing: Content to show in the trailing toolbar slot BEFORE the trigger.
    ///   - afterTrailing: Content to show in the trailing toolbar slot AFTER the trigger.
    ///   - beforeCenter: Content to show in the center (principal) slot BEFORE the trigger.
    ///   - afterCenter: Content to show in the center (principal) slot AFTER the trigger.
    @ViewBuilder
    func appStoreStyleToolbar<T1: View, T2: View, C1: View, C2: View>(
        triggerOffset: CGFloat = 110,
        @ViewBuilder beforeTrailing: @escaping () -> T1,
        @ViewBuilder afterTrailing: @escaping () -> T2,
        @ViewBuilder beforeCenter: @escaping () -> C1,
        @ViewBuilder afterCenter: @escaping () -> C2
    ) -> some View {
        self.modifier(AppStoreToolbarModifier(
            triggerOffset: triggerOffset,
            beforeTrailing: beforeTrailing,
            afterTrailing: afterTrailing,
            beforeCenter: beforeCenter,
            afterCenter: afterCenter
        ))
    }
}

// MARK: - The Modifier Logic
struct AppStoreToolbarModifier<T1: View, T2: View, C1: View, C2: View>: ViewModifier {
    var triggerOffset: CGFloat
    @ViewBuilder var beforeTrailing: () -> T1
    @ViewBuilder var afterTrailing: () -> T2
    @ViewBuilder var beforeCenter: () -> C1
    @ViewBuilder var afterCenter: () -> C2
    
    // State to track if we have scrolled past the trigger point
    @State private var isChanged: Bool = false
    
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
            // 1. Track Scroll Offset (iOS 18+)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldValue, newValue in
                    // 2. Determine if we crossed the threshold
                    let thresholdCrossed = newValue > triggerOffset
                    
                    // Only update state if it actually changed to prevent redraws
                    if isChanged != thresholdCrossed {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isChanged = thresholdCrossed
                        }
                    }
                }
            // 3. Inject Toolbar Items
                .toolbar {
                    // Trailing Items (Top Right)
                    ToolbarItem(placement: .topBarTrailing) {
                        ZStack(alignment: .trailing) {
                            if !isChanged {
                                beforeTrailing()
                            }
                            
                            if isChanged {
                                afterTrailing()
                            }
                        }
                    }
                    
                    // Center Items (Title Area)
                    ToolbarItem(placement: .principal) {
                        ZStack {
                            if !isChanged {
                                beforeCenter()
                            }
                            
                            if isChanged {
                                afterCenter()
                            }
                        }
                    }
                }
        } else {
            // Fallback on earlier versions
        }
    }
}

// MARK: - Helper for Hiding Views
// This ensures buttons don't capture taps when they are invisible
extension View {
    @ViewBuilder
    func visible(_ isVisible: Bool) -> some View {
        if isVisible {
            self
        } else {
            EmptyView()
        }
    }
}
