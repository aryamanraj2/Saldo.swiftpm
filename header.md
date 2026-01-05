Part 1: The Core Modifier (AppStoreToolbar.swift)

This file contains the logic. It is completely reusable and can be applied to any ScrollView. It handles tracking the scroll offset and swapping the toolbar items.
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
                        beforeTrailing()
                            .opacity(isChanged ? 0 : 1)
                            .isHidden(isChanged) // Helper to remove interaction
                        
                        afterTrailing()
                            .opacity(isChanged ? 1 : 0)
                            .isHidden(!isChanged)
                    }
                }
                
                // Center Items (Title Area)
                ToolbarItem(placement: .principal) {
                    ZStack {
                        beforeCenter()
                            .opacity(isChanged ? 0 : 1)
                            .isHidden(isChanged)
                        
                        afterCenter()
                            .opacity(isChanged ? 1 : 0)
                            .isHidden(!isChanged)
                    }
                }
            }
    }
}

// MARK: - Helper for Hiding Views
// This ensures buttons don't capture taps when they are invisible
extension View {
    @ViewBuilder
    func isHidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
}

Part 2: The Custom Button Style (GlassButtonStyle.swift)

The video features a specific "Glass" button style for the "Open" button. Here is a modular implementation of that style

import SwiftUI

struct GlassButtonStyle: ButtonStyle {
    var isActive: Bool = true // Allows toggling the glass effect off if needed
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .padding(.horizontal, 15)
            .padding(.vertical, 7)
            .background {
                if isActive {
                    Capsule()
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring, value: configuration.isPressed)
    }
}
Part 3: Implementation Example (ContentView.swift)

This is how you use the modular code from Part 1 and 2 to recreate the exact view shown in the video.
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            DetailView()
        }
    }
}

struct DetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header Image
                Image("AppIcon") // Replace with your asset
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                
                Text("Mockview")
                    .font(.largeTitle.bold())
                
                Text("Graphics & Design")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                // Dummy Long Content to enable scrolling
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's New")
                        .font(.title2.bold())
                        .padding(.top)
                    
                    Text("Version 4.1.1")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("• Bug fixes and performance improvements.")
                        .padding(.bottom)
                    
                    // Preview Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 250, height: 400)
                                    .overlay {
                                        Text("Preview")
                                            .foregroundStyle(.blue)
                                    }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        
        // MARK: - USE THE MODULAR EXTENSION HERE
        .appStoreStyleToolbar(
            triggerOffset: 100, // Adjust this number based on when you want the switch to happen
            
            // 1. Before Trailing (Initial State)
            beforeTrailing: {
                // Usually empty or share button in App Store
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
            },
            
            // 2. After Trailing (Scrolled State)
            afterTrailing: {
                // The "GET" or "OPEN" button appears here
                Button("Open") {}
                    .buttonStyle(GlassButtonStyle())
            },
            
            // 3. Before Center (Initial State)
            beforeCenter: {
                // Empty, because we want the standard large title or content to show
                EmptyView()
            },
            
            // 4. After Center (Scrolled State)
            afterCenter: {
                // The Mini Icon appears in the center
                Image("AppIcon") // Replace with your asset
                    .resizable()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        )
    }
}

#Preview {
    ContentView()
}
Instructions for Use

Copy Part 1 into a file named AppStoreToolbar.swift. This is your toolset. You never need to touch this file again; you just call the function.

Copy Part 2 into a file named GlassButtonStyle.swift. This handles the aesthetics.

Use Part 3 as a guide. In your main view, apply the .appStoreStyleToolbar(...) modifier to your ScrollView.

Assets: Ensure you have an image named "AppIcon" in your Asset catalog, or change the string in the code to an image you actually possess.