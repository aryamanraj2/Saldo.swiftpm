import SwiftUI
import VisionKit

struct HomeView: View {
    @State private var balance: Double = 4500.0
    
    // Camera and scanning state - owned by HomeView to avoid nested sheet issues
    @State private var showCamera = false
    @State private var scannedImage: UIImage?
    @State private var isProcessing = false
    @State private var scanResult: ReceiptMetadata?
    @State private var scanError: Error?
    @State private var showResultSheet = false
    @State private var showErrorAlert = false
    
    // Computed theme based on balance
    var theme: AppTheme {
        AppTheme.from(balance: balance)
    }
    
    var colors: ThemeColors {
        theme.colors
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
                                Text("Aryaman")
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
                        
                        // Grid Section
                        HStack(alignment: .top, spacing: 12) {
                            // Left Column: Weekly Spend
                            WeeklySpendCard(colors: colors)
                            
                            // Right Column: Actions
                            VStack(spacing: 12) {
                                ActionButton(
                                    icon: "plus.circle.fill",
                                    title: "Add",
                                    subtitle: "Subscription",
                                    colors: colors,
                                    action: {}
                                )
                                
                                WideActionButton(
                                    icon: "apple.intelligence",
                                    title: "Get Insights",
                                    colors: colors,
                                    action: {}
                                )
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
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Fixed padding for native sheet
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            // Smooth transition for all theme changes
            .animation(.easeInOut(duration: 0.5), value: theme)
                .appStoreStyleToolbar(
                    triggerOffset: 60,
                    beforeTrailing: { 
                        Button(action: {}) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title3)
                                .foregroundStyle(colors.primary)
                        }
                    },
                    afterTrailing: { 
                        Button(action: {}) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title3)
                                .foregroundStyle(colors.primary)
                        }
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
            ScannerSheetContainer(colors: colors, showCamera: $showCamera)
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
        // Processing Overlay
        .overlay {
            if isProcessing {
                ProcessingOverlay()
            }
        }
    }
}

#Preview {
    HomeView()
}

