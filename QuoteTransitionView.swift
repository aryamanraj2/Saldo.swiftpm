import SwiftUI

struct QuoteTransitionView: View {
    let quote: String
    let themeColors: ThemeColors
    
    @State private var opacity: Double = 0
    @State private var breathing = false
    
    var body: some View {
        ZStack {
            // Live Gradient Background
            LiveTransitionBackground(colors: themeColors)
                .ignoresSafeArea()
            
            // Content
            VStack {
                Spacer()
                
                Text(quote)
                    .font(.system(size: 27, weight: .medium , design: .rounded)) // SF Pro, Thicker
                    .multilineTextAlignment(.center)
                    .foregroundStyle(themeColors.primary)
                    .padding(.horizontal, 32)
                    .lineSpacing(8)
                    .opacity(opacity)
                    .scaleEffect(opacity > 0 ? 1.0 : 0.95)
                
                Spacer()
                
                // Zen Breathing Ball
                if opacity > 0 {
                    Circle()
                        .fill(themeColors.secondary.opacity(0.8)) // Matching the theme "ball" from the image
                        .frame(width: 80, height: 80)
                        .scaleEffect(breathing ? 1.2 : 0.85)
                        .opacity(breathing ? 0.9 : 0.7)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breathing)
                        .onAppear {
                            breathing = true
                        }
                        .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Live Transition Background
/// A more dynamic version of CleanBackground with independent blob animations
struct LiveTransitionBackground: View {
    var colors: ThemeColors
    
    // Independent animation states for chaos/organic feel
    @State private var animateBlob1 = false
    @State private var animateBlob2 = false
    @State private var animateBlob3 = false
    
    var body: some View {
        ZStack {
            // Base layer
            colors.background
                .ignoresSafeArea()
            
            // Dynamic blobs
            GeometryReader { proxy in
                ZStack {
                    // Blob 1: Top Right - Moves diagonally (More pronounced)
                    Circle()
                        .fill(colors.backgroundBlob1)
                        .blur(radius: 80)
                        .frame(width: 350, height: 350)
                        .position(x: proxy.size.width * 0.9, y: proxy.size.height * 0.1)
                        .offset(x: animateBlob1 ? -120 : 40, y: animateBlob1 ? -40 : 100)
                        .scaleEffect(animateBlob1 ? 1.1 : 0.9) // Breathing blobs
                    
                    // Blob 2: Center Left - Moves horizontally/vertically (More pronounced)
                    Circle()
                        .fill(colors.backgroundBlob2)
                        .blur(radius: 100)
                        .frame(width: 450, height: 450)
                        .position(x: 0, y: proxy.size.height * 0.4)
                        .offset(x: animateBlob2 ? 80 : -60, y: animateBlob2 ? 120 : -80)
                        .scaleEffect(animateBlob2 ? 0.95 : 1.15)
                    
                    // Blob 3: Bottom Right - Moves mainly vertically (More pronounced)
                    Circle()
                        .fill(colors.backgroundBlob3)
                        .blur(radius: 90)
                        .frame(width: 400, height: 400)
                        .position(x: proxy.size.width, y: proxy.size.height * 0.85)
                        .offset(x: animateBlob3 ? -60 : 80, y: animateBlob3 ? -100 : 50)
                        .scaleEffect(animateBlob3 ? 1.1 : 0.9)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            // Animate Blob 1
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                animateBlob1.toggle()
            }
            
            // Animate Blob 2 (Offset start)
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateBlob2.toggle()
            }
            
            // Animate Blob 3 (Different duration)
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                animateBlob3.toggle()
            }
        }
    }
}

#Preview {
    QuoteTransitionView(
        quote: "Look at you, the Master of Coin. Tywin Lannister would be proud.",
        themeColors: AppTheme.wealthy.colors
    )
}
