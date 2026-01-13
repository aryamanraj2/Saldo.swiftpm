# SwiftUI Scroll Animation & Cloudy Header Effect Guide

## Overview

This guide explains how to implement the scroll-based header animation effect in the Aqua-Sense iOS app, where the large "Aqua-Sense" title minimizes with a smooth "cloudy" transition when the user scrolls down the dashboard.

---

## Table of Contents

1. [The Basic Effect](#1-the-basic-effect)
2. [Built-in Navigation Bar Collapse](#2-built-in-navigation-bar-collapse)
3. [Adding Cloudy/Blur Effects](#3-adding-cloudyblur-effects)
4. [Advanced: Custom Scroll Header](#4-advanced-custom-scroll-header)
5. [Complete Implementation Example](#5-complete-implementation-example)
6. [Customization Options](#6-customization-options)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. The Basic Effect

### What You See in Aqua-Sense Dashboard

When you scroll the dashboard:
1. **Large Title**: "Aqua-Sense" starts as a large, prominent title
2. **Collapse Animation**: As you scroll down, the title smoothly shrinks
3. **Minimized State**: The title becomes a compact inline navigation bar title
4. **Cloudy Effect**: A subtle blur/fade transition occurs during the collapse

### How It Works

SwiftUI provides built-in navigation bar behavior that automatically handles this transition:

```swift
NavigationView {
    ScrollView {
        // Your scrollable content
        VStack(spacing: 24) {
            // Dashboard content
        }
    }
    .navigationTitle("Aqua-Sense")
    .navigationBarTitleDisplayMode(.large)
}
```

**Key Modifiers:**
- `.navigationTitle("Aqua-Sense")` - Sets the title text
- `.navigationBarTitleDisplayMode(.large)` - Enables the large collapsible title

---

## 2. Built-in Navigation Bar Collapse

### Basic Implementation

```swift
import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Stats Section
                    quickStatsSection

                    // Environmental Conditions
                    environmentalSection

                    // Water Quality Metrics
                    waterQualitySection

                    // Tank List
                    tankListSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100) // Clear bottom tab bar
            }
            .navigationTitle("Aqua-Sense")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.subtleBlueLight,
                        Color.subtleBlueMid
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
}
```

### What Happens Automatically

1. **Large Title (Default)**: The title appears large below the navigation bar
2. **User Scrolls Down**: Navigation bar detects scroll offset
3. **Smooth Transition**: Title smoothly scales down and moves into the navigation bar
4. **Compact State**: Title appears inline with the navigation bar
5. **Scroll Up**: Title expands back to large size

**No additional code required!** SwiftUI handles the animation automatically.

---

## 3. Adding Cloudy/Blur Effects

### Method 1: Blur Behind Navigation Bar

To create a "cloudy" glassmorphism effect behind the navigation bar:

```swift
NavigationView {
    ScrollView {
        // Your content
    }
    .navigationTitle("Aqua-Sense")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(.ultraThinMaterial, for: .navigationBar) // ✨ Blur effect
}
```

**Material Options:**
- `.ultraThinMaterial` - Very subtle blur (recommended)
- `.thinMaterial` - Light blur
- `.regularMaterial` - Medium blur
- `.thickMaterial` - Heavy blur
- `.ultraThickMaterial` - Very heavy blur

### Method 2: Gradient + Blur Combo

For a more custom cloudy effect:

```swift
.toolbarBackground(
    LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.9),
            Color.subtleBlueLight.opacity(0.7)
        ]),
        startPoint: .top,
        endPoint: .bottom
    ),
    for: .navigationBar
)
.toolbarBackground(.visible, for: .navigationBar)
```

### Method 3: Custom Blur Overlay

Add a blur effect that intensifies on scroll:

```swift
struct DashboardView: View {
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Content
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .navigationTitle("Aqua-Sense")
            .navigationBarTitleDisplayMode(.large)
            .overlay(
                // Cloudy overlay that appears on scroll
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(scrollOffset < -50 ? min(abs(scrollOffset + 50) / 100, 0.5) : 0)
                    .frame(height: 100)
                    .ignoresSafeArea()
                    .allowsHitTesting(false),
                alignment: .top
            )
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

---

## 4. Advanced: Custom Scroll Header

For complete control over the header animation, implement a custom sticky header:

```swift
struct DashboardView: View {
    @State private var scrollOffset: CGFloat = 0

    private let minHeaderHeight: CGFloat = 60
    private let maxHeaderHeight: CGFloat = 150

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.subtleBlueLight,
                    Color.subtleBlueMid
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Scrollable Content
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for custom header
                    Color.clear
                        .frame(height: maxHeaderHeight)

                    // Dashboard Content
                    VStack(spacing: 24) {
                        quickStatsSection
                        environmentalSection
                        waterQualitySection
                        tankListSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }

            // Custom Header
            customHeader
                .frame(height: headerHeight)
                .background(
                    ZStack {
                        // Cloudy blur background
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(headerOpacity)

                        // Gradient overlay
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.subtleBlueLight.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .opacity(headerOpacity)
                    }
                )
                .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Computed Properties

    private var headerHeight: CGFloat {
        let height = maxHeaderHeight + scrollOffset
        return max(minHeaderHeight, min(maxHeaderHeight, height))
    }

    private var headerOpacity: Double {
        let progress = (maxHeaderHeight - headerHeight) / (maxHeaderHeight - minHeaderHeight)
        return min(max(progress, 0), 1)
    }

    private var titleScale: CGFloat {
        let progress = (headerHeight - minHeaderHeight) / (maxHeaderHeight - minHeaderHeight)
        return 0.6 + (progress * 0.4) // Scale from 0.6x to 1.0x
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        HStack {
            Text("Aqua-Sense")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.deepOcean)
                .scaleEffect(titleScale, anchor: .leading)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: titleScale)

            Spacer()

            // Toolbar buttons
            HStack(spacing: 16) {
                Button(action: { /* Mic action */ }) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.oceanBlue)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 4)
                }

                Button(action: { /* Add tank action */ }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.oceanBlue))
                        .shadow(radius: 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50) // Adjust for status bar
        .frame(height: headerHeight)
    }
}
```

**What This Does:**
1. **Tracks Scroll Offset**: Uses `GeometryReader` and `PreferenceKey`
2. **Dynamic Height**: Header shrinks from 150pt to 60pt
3. **Title Scaling**: Text scales from 1.0x to 0.6x
4. **Blur Opacity**: Background blur fades in as header shrinks
5. **Smooth Animation**: Spring animation for natural feel

---

## 5. Complete Implementation Example

Here's a full working example combining all techniques:

```swift
import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var showVoiceBot = false
    @State private var showAddTank = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                backgroundGradient

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        quickStatsSection
                        environmentalSection
                        waterQualitySection
                        tankListSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldValue, newValue in
                    scrollOffset = newValue
                }
            }
            .navigationTitle("Aqua-Sense")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Mic Button
                    Button(action: { showVoiceBot = true }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.oceanBlue)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white))
                            .shadow(color: .black.opacity(0.1), radius: 4)
                    }

                    // Add Tank Button
                    Button(action: { showAddTank = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.oceanBlue))
                            .shadow(color: .black.opacity(0.1), radius: 4)
                    }
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
        }
        .sheet(isPresented: $showVoiceBot) {
            VoiceBotView()
        }
        .sheet(isPresented: $showAddTank) {
            AddTankView()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.subtleBlueLight,
                Color.subtleBlueMid
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Sections (Placeholder)

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            QuickStatCard(title: "Active Tanks", value: "3", icon: "drop.fill")
            QuickStatCard(title: "Total Volume", value: "500L", icon: "cylinder.fill")
            QuickStatCard(title: "Avg Temp", value: "26°C", icon: "thermometer")
        }
    }

    private var environmentalSection: some View {
        VStack {
            Text("Environmental Conditions")
                .font(.headline)
            // Add environmental cards
        }
    }

    private var waterQualitySection: some View {
        VStack {
            Text("Water Quality Metrics")
                .font(.headline)
            // Add water quality grid
        }
    }

    private var tankListSection: some View {
        VStack {
            Text("My Tanks")
                .font(.headline)
            // Add tank cards
        }
    }
}

// MARK: - Quick Stat Card Component

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.oceanBlue)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.deepOcean)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Color Extensions

extension Color {
    static let deepOcean = Color(hex: "#001F3F")
    static let oceanBlue = Color(hex: "#1B6F9A")
    static let mediumBlue = Color(hex: "#0A4D92")
    static let subtleBlueLight = Color(hex: "#E8F4F8")
    static let subtleBlueMid = Color(hex: "#D4E9F2")
    static let subtleBlueAccent = Color(hex: "#B8DAEB")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
```

---

## 6. Customization Options

### Adjust Blur Intensity

```swift
.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
// Change to: .thinMaterial, .regularMaterial, .thickMaterial, .ultraThickMaterial
```

### Change Animation Speed

```swift
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
// response: Duration of animation (lower = faster)
// dampingFraction: Bounciness (lower = more bouncy)
```

### Custom Blur Color

```swift
.toolbarBackground(
    Color.white.opacity(0.8),
    for: .navigationBar
)
.toolbarBackgroundVisibility(.visible, for: .navigationBar)
```

### Add Frosted Glass Effect

```swift
.background {
    ZStack {
        Color.white.opacity(0.7)
        VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
    }
}
```

### Fade In/Out Elements

```swift
.opacity(scrollOffset < -100 ? 0 : 1)
.animation(.easeInOut(duration: 0.3), value: scrollOffset)
```

---

## 7. Troubleshooting

### Issue: Title Doesn't Collapse

**Solution:** Ensure you have:
1. `NavigationView` or `NavigationStack` wrapper
2. `.navigationTitle()` modifier
3. `.navigationBarTitleDisplayMode(.large)` modifier
4. Scrollable content inside (ScrollView or List)

```swift
NavigationView { // ✅ Required
    ScrollView { // ✅ Required
        // Content
    }
    .navigationTitle("Title") // ✅ Required
    .navigationBarTitleDisplayMode(.large) // ✅ Required
}
```

### Issue: Blur Effect Not Visible

**Solution:** Make sure to set visibility:

```swift
.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
.toolbarBackgroundVisibility(.visible, for: .navigationBar) // ✅ Add this
```

### Issue: Jerky Animation

**Solution:** Use `.animation()` modifier with smooth timing:

```swift
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
// Or
.animation(.easeInOut(duration: 0.3), value: scrollOffset)
```

### Issue: Title Overlaps Content

**Solution:** Add top padding to content:

```swift
ScrollView {
    VStack(spacing: 24) {
        // Content
    }
    .padding(.top, 8) // ✅ Add spacing below large title
}
```

### Issue: Scroll Offset Not Tracking

**Solution (iOS 17+):** Use `.onScrollGeometryChange()`:

```swift
ScrollView {
    // Content
}
.onScrollGeometryChange(for: CGFloat.self) { geometry in
    geometry.contentOffset.y
} action: { oldValue, newValue in
    scrollOffset = newValue
}
```

**Solution (iOS 16 and earlier):** Use GeometryReader + PreferenceKey (see Section 4).

---

## Key Takeaways

1. **Built-in Behavior**: SwiftUI's `.navigationBarTitleDisplayMode(.large)` handles most of the animation automatically
2. **Material Effects**: Use `.ultraThinMaterial` for the cloudy glassmorphism look
3. **Smooth Transitions**: Spring animations create natural, fluid motion
4. **Custom Control**: For advanced effects, track scroll offset and animate manually
5. **Combine Techniques**: Mix blur, gradients, and opacity for rich visual effects

---

## Additional Resources

**Apple Documentation:**
- [NavigationView](https://developer.apple.com/documentation/swiftui/navigationview)
- [Scroll Modifiers](https://developer.apple.com/documentation/swiftui/scrollview)
- [Material Effects](https://developer.apple.com/documentation/swiftui/material)

**Aqua-Sense Implementation:**
- See [DashboardView.swift](aqua/Views/DashboardView.swift) for the live implementation
- See [TankView.swift](aqua/Views/TankView.swift) for parallax scroll effect example
- See [Theme.swift](aqua/Views/Theme.swift) for color palette

---

**Last Updated:** January 3, 2026
**iOS Version:** iOS 17.0+
**SwiftUI Version:** SwiftUI 5.0+
