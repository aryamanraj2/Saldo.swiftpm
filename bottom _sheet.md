This is a sophisticated interaction that replicates the "Apple Maps" feel. The key challenge here is synchronizing a view that lives outside the sheet (the floating search bar) with the dynamic position of the sheet itself.

To make this modular and reusable, I have separated the code into three distinct parts:

The Helper Logic: To capture the sheet's real-time height.

The UI Components: The reusable floating bar and sheet content.

The Main Container: The view that ties the logic together.

1. The Helper Logic

We need a way to pass the height of the sheet up to the parent view so the floating bar knows where to move. We use a PreferenceKey for this.
import SwiftUI
import MapKit

// MARK: - 1. Height Preference Key
// This allows child views (the sheet) to report their size to the parent.
struct SheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// A simple extension to make the glass effect reusable and cleaner
extension View {
    func glassBackground() -> some View {
        self.background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

2. Modular UI Components

Here are the isolated components. You can copy these into their own files or reuse them in other parts of your app.
// MARK: - 2. Floating Search Bar Component
// This is the "pill" shape that floats above the sheet.
struct FloatingSearchBar: View {
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
            Text("Search Maps...")
                .foregroundStyle(.gray)
            Spacer()
            Image(systemName: "mic.fill")
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(height: 50)
        .glassBackground()
        .padding(.horizontal)
    }
}

// MARK: - 3. Bottom Sheet Content
// The actual scrollable content inside the sheet.
struct BottomSheetContent: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Favorites")
                    .font(.title2.bold())
                    .padding(.top)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(1...5, id: \.self) { item in
                            VStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(Image(systemName: "star.fill").foregroundStyle(.blue))
                                Text("Place \(item)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Divider()
                
                Text("Recents")
                    .font(.title2.bold())
                
                ForEach(1...10, id: \.self) { item in
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.gray)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Recent Location \(item)")
                                .font(.headline)
                            Text("10 km away")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
    }
}

3. The Main Implementation (The Logic)

This is where the magic happens. We use GeometryReader inside the sheet to constantly update a state variable sheetHeight. We then use that height to calculate the offset of the floating bar.
// MARK: - 4. Main View
struct AppleMapsCloneView: View {
    // Standard Map State
    @State private var position: MapCameraPosition = .automatic
    
    // Sheet Logic State
    @State private var showSheet: Bool = true
    @State private var selectedDetent: PresentationDetent = .height(80)
    @State private var sheetHeight: CGFloat = 0
    
    // Configuration Constants
    // The height of the smallest detent (the "pill" state)
    let minHeight: CGFloat = 80 
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // A. The Background Map
            Map(position: $position)
                .ignoresSafeArea()
            
            // B. The Floating Search Bar
            // We place this in the ZStack (not the sheet) so it can float freely.
            FloatingSearchBar()
                .offset(y: calculateOffset()) // 1. Dynamic movement
                .opacity(calculateOpacity())  // 2. Dynamic fading
                .padding(.bottom, 10)         // Base padding from bottom
                // 3. IMPORTANT: Animate changes to sync with the sheet's spring animation
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8), value: sheetHeight)
        }
        // C. The Bottom Sheet Setup
        .sheet(isPresented: $showSheet) {
            BottomSheetContent()
                // 4. Read the Sheet's Geometry
                .overlay {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SheetHeightKey.self, value: proxy.size.height)
                    }
                }
                // 5. Update State when size changes
                .onPreferenceChange(SheetHeightKey.self) { height in
                    self.sheetHeight = height
                }
                // 6. Sheet Configuration
                .presentationDetents([.height(minHeight), .medium, .large], selection: $selectedDetent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium)) // Allows map interaction
                .presentationCornerRadius(25)
                .interactiveDismissDisabled() // Prevents closing the sheet fully
        }
    }
    
    // MARK: - Animation Logic
    
    /// Calculates the Y offset for the floating bar.
    /// It moves up as the sheet grows, but stops (locks) when the sheet reaches specific points if desired.
    func calculateOffset() -> CGFloat {
        // Simple logic: The bar sits exactly on top of the sheet
        // Negative value because we are moving UP from the bottom
        return -sheetHeight
    }
    
    /// Fades the search bar out when the sheet gets too large (covering the screen)
    func calculateOpacity() -> Double {
        // If sheet is larger than half the screen, fade out the floating bar
        // because the sheet likely has its own internal search bar now.
        let screenHeight = UIScreen.main.bounds.height
        if sheetHeight > (screenHeight * 0.6) {
            return 0
        }
        return 1
    }
}

#Preview {
    AppleMapsCloneView()
}

Detailed Instructions for Use

Copy-Paste Order: Copy the components in the order provided (Helper -> UI Components -> Main View).

The GeometryReader Trick: The code uses an invisible Color.clear overlay inside the sheet with a GeometryReader. This is the most robust way to get the actual rendered height of a sheet, even while the user is dragging it.

Animation Synchronization: The .animation(.interactiveSpring...) modifier attached to the FloatingSearchBar is critical. It ensures that when the sheet snaps to a new detent (using iOS's built-in spring physics), the floating bar uses the exact same physics to follow it, preventing "lag" or "wobble."

Interaction Modes: I included .presentationBackgroundInteraction(.enabled(upThrough: .medium)). This mimics Apple Maps perfectly—you can pan the map while the sheet is at the bottom or middle, but once it's full screen, the map is locked.

Customization:

To change how high the "minimized" sheet is, change .height(80) in the presentationDetents array.

To change when the floating bar disappears, adjust the logic in calculateOpacity.