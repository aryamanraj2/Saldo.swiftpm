import SwiftUI
import VisionKit

struct HomeView: View {
    @State private var balance: Double = 4500.0
    @Environment(\.colorScheme) var colorScheme

    // User name from onboarding
    @AppStorage("userName") private var userName: String = ""

    // Camera and scanning state - owned by HomeView to avoid nested sheet issues
    @State private var showCamera = false
    @State private var scannedImage: UIImage?
    @State private var isProcessing = false
    @State private var scanResult: ReceiptMetadata?
    @State private var scanError: Error?
    @State private var showResultSheet = false
    @State private var showErrorAlert = false
    
    // Sheet States (Separate for Grails, Subscriptions, and Manual Payment)
    @State private var showGrailsSheet = false
    @State private var showAddSubscriptionSheet = false
    @State private var showManualPaymentSheet = false
    @State private var showProfileSheet = false
    @State private var showGrailLimitAlert = false
    
    // Subscription Data
    @State private var subscriptions: [SubscriptionItem] = []
    
    // Grail Data
    @State private var grailStore = GrailStore()
    @State private var hasLoadedGrails = false

    // Sheet Detent State (Controlled by HomeView)
    @State private var sheetDetent: PresentationDetent = .scannerMedium
    
    // Scanner Sheet Visibility (must be dismissed when subscription opens)
    @State private var showScannerSheet = true

    // Computed theme based on balance
    var theme: AppTheme {
        AppTheme.from(balance: balance)
    }

    var colors: ThemeColors {
        theme.colors(for: colorScheme)
    }
    
    var body: some View {
        ZStack {
            // Main Content Layer
            NavigationStack {
                ZStack {
                // Dynamic Background based on theme
                CleanBackground(colors: colors)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Area
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Welcome Back!")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.saldoSecondary)
                                Text(userName.isEmpty ? "Friend" : userName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(colors.primary)
                                    .animation(.easeInOut, value: colors.primary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60) // Add padding to avoid collision
                        
                        // Main Balance
                        BalanceCard(balance: balance, colors: colors)
                            .padding(.horizontal, 20)
                            .tutorialHighlight(.remainingBalance)
                        
                        // Grid Section
                        HStack(alignment: .top, spacing: 12) {
                            // Left Column: Weekly Spend
                            WeeklySpendCard(colors: colors)
                            
                            // Right Column: Actions
                            VStack(spacing: 12) {
                                ActionButton(
                                    icon: "plus.circle.fill",
                                    title: "Add",
                                    subtitle: "Grails",
                                    colors: colors,
                                    grailPreviews: grailStore.cachedPreviewItems,
                                    action: {
                                        if grailStore.cachedPreviewItems.count >= 3 {
                                            showGrailLimitAlert = true
                                        } else {
                                            // Dismiss scanner sheet with animation, then show grails sheet
                                            withAnimation(.easeOut(duration: 0.25)) {
                                                showScannerSheet = false
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                showGrailsSheet = true
                                            }
                                        }
                                    }
                                )
                                
                                WideActionButton(
                                    icon: "apple.intelligence",
                                    title: "Get Insights",
                                    colors: colors,
                                    action: {}
                                )
                                .tutorialHighlight(.getInsights)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        
                        // Transactions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Transactions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                TransactionRow(icon: "basket.fill", title: "Grocery", subtitle: "5:30 PM", amount: "₹450.00", colors: colors)
                                TransactionRow(icon: "music.note", title: "Spotify", subtitle: "Yesterday", amount: "₹119.00", colors: colors)
                                TransactionRow(icon: "cup.and.saucer.fill", title: "Starbucks", subtitle: "Yesterday", amount: "₹350.00", colors: colors)
                                TransactionRow(icon: "gamecontroller.fill", title: "Steam", subtitle: "2 days ago", amount: "₹899.00", colors: colors)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 10)
                        
                        // DEBUG CONTROLS
                        VStack(spacing: 10) {
                            Text("Debug Balance: ₹\(Int(balance))")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            
                            Slider(value: $balance, in: 0...10000)
                                .tint(colors.accent)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 15))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Fixed padding for native sheet
                    }
                }
                // Auto-collapse sheet on scroll
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        if sheetDetent != .scannerSmall {
                            sheetDetent = .scannerSmall
                        }
                    }
                )
                .ignoresSafeArea(edges: .top)
            }
            // Smooth transition for all theme changes
            .animation(.easeInOut(duration: 0.5), value: theme)
                .appStoreStyleToolbar(
                    triggerOffset: 60,
                    beforeTrailing: {
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) { showScannerSheet = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showProfileSheet = true }
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title3)
                                .foregroundStyle(colors.primary)
                        }
                        .accessibilityLabel("Profile")
                    },
                    afterTrailing: {
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) { showScannerSheet = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showProfileSheet = true }
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title3)
                                .foregroundStyle(colors.primary)
                        }
                        .accessibilityLabel("Profile")
                    },
                    beforeCenter: { EmptyView() },
                    afterCenter: { 
                        Text("Saldo")
                            .font(.headline)
                            .foregroundStyle(colors.primary)
                    }
                )
                .toolbarBackground(.hidden, for: .navigationBar)
                // Document Camera (VisionKit) - presented from NavigationStack to avoid being blocked by scanner sheet
                .fullScreenCover(isPresented: $showCamera) {
                    DocumentCameraWithGallery(
                        scannedImage: $scannedImage,
                        isProcessing: $isProcessing,
                        onCompletion: { result in
                            showCamera = false
                            switch result {
                            case .success(let metadata):
                                scanResult = metadata
                                showResultSheet = true
                            case .failure(let error):
                                scanError = error
                                showErrorAlert = true
                            }
                        },
                        onCancel: {
                            showCamera = false
                        }
                    )
                    .ignoresSafeArea()
                }
            }
            
            // Receipt Scanner Sheet (Apple Maps-style) - passes binding for camera control
            ScannerSheetContainer(
                colors: colors,
                showCamera: $showCamera,
                selectedDetent: $sheetDetent,
                showSheet: $showScannerSheet,
                subscriptions: subscriptions,
                onAddPayment: {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showScannerSheet = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showManualPaymentSheet = true
                    }
                },
                onAddSubscription: {
                    // Dismiss scanner sheet with animation, then show add subscription sheet
                    withAnimation(.easeOut(duration: 0.25)) {
                        showScannerSheet = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAddSubscriptionSheet = true
                    }
                }
            )
        }
        // Scan Result Sheet
        .sheet(isPresented: $showResultSheet) {
            if let result = scanResult {
                ScanResultSheet(metadata: result) {
                    showResultSheet = false
                    scanResult = nil
                }
            }
        }
        // Error Alert
        .alert("Scan Failed", isPresented: $showErrorAlert) {
            Button("OK") {
                scanError = nil
            }
        } message: {
            Text(scanError?.localizedDescription ?? "Unknown error occurred")
        }
        // Grail Limit Alert
        .alert("Grail Limit Reached", isPresented: $showGrailLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only track up to 3 grails at a time.")
        }
        // Grails Sheet (for Add Grails button)
        .sheet(isPresented: $showGrailsSheet, onDismiss: {
            // Restore scanner sheet smoothly when grails sheet closes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showScannerSheet = true
                }
            }
        }) {
            GrailSheet(colors: colors) { newGrail, maskedImage in
                Task {
                    await grailStore.add(grail: newGrail, maskedImage: maskedImage)
                }
            }
        }
        // Add Subscription Sheet (for subscription plus button in scanner sheet)
        .sheet(isPresented: $showAddSubscriptionSheet, onDismiss: {
            // Restore scanner sheet smoothly when add subscription sheet closes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showScannerSheet = true
                }
            }
        }) {
            AddSubscriptionSheet(colors: colors) { newSubscription in
                subscriptions.append(newSubscription)
            }
        }
        // Manual Payment Sheet
        .sheet(isPresented: $showManualPaymentSheet, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showScannerSheet = true
                }
            }
        }) {
            ManualPaymentSheet(colors: colors, balance: $balance)
        }
        // Profile Sheet
        .sheet(isPresented: $showProfileSheet, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showScannerSheet = true
                }
            }
        }) {
            ProfileSheet(colors: colors, grailPreviews: grailStore.cachedPreviewItems)
        }
        // Processing Overlay
        .overlay {
            if isProcessing {
                ProcessingOverlay()
            }
        }
        .task {
            guard !hasLoadedGrails else { return }
            hasLoadedGrails = true
            await grailStore.load()
        }
    }
}

#Preview {
    HomeView()
}
