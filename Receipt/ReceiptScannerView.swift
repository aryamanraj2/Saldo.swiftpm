import SwiftUI
import AVFoundation
import VisionKit

// MARK: - Scanner Sheet State (simplified for native sheet)
enum ScannerSheetState: Equatable {
    case small    // Small detent: ~80pt pill
    case medium   // Medium detent: expanded content
}

// MARK: - Presentation Detent Extensions
extension PresentationDetent {
    static let scannerSmall = PresentationDetent.height(80)
    static let scannerMedium = PresentationDetent.fraction(0.28)
}

// MARK: - Scanner Sheet Container (Apple Maps-style)
// This is the main container that manages the native sheet
// The camera presentation is handled by the parent view to avoid nested sheet issues
struct ScannerSheetContainer: View {
    var colors: ThemeColors
    
    // Binding to parent's showCamera state - camera will be presented from parent
    @Binding var showCamera: Bool
    
    // Binding to control detent from parent (e.g. collapse on scroll)
    @Binding var selectedDetent: PresentationDetent
    
    // Binding to control sheet visibility from parent
    @Binding var showSheet: Bool
    @State private var sheetHeight: CGFloat = 0
    
    // Subscription data to display
    var subscriptions: [SubscriptionItem] = []
    
    // Callback for manual payment entry
    var onAddPayment: (() -> Void)? = nil

    // Callback for adding subscription from the expanded sheet
    var onAddSubscription: (() -> Void)? = nil
    
    // Check if document scanning is supported
    private var isDocumentScanningSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }
    
    var body: some View {
        // Use a proper container view for the modifiers
        if #available(iOS 17.0, *) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $showSheet) {
                    ScannerSheetContent(
                        colors: colors,
                        selectedDetent: $selectedDetent,
                        subscriptions: subscriptions,
                        onScanTap: {
                            print("[Scanner] Scan button tapped")
                            if isDocumentScanningSupported {
                                // Request camera presentation from parent
                                showCamera = true
                            } else {
                                print("[Scanner] Document scanning not supported on this device")
                            }
                        },
                        onAddPaymentTap: onAddPayment,
                        onAddSubscription: onAddSubscription
                    )
                    // Read the Sheet's Geometry
                    .overlay {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: SheetHeightKey.self, value: proxy.size.height)
                        }
                    }
                    // Update State when size changes
                    .onPreferenceChange(SheetHeightKey.self) { height in
                        self.sheetHeight = height
                    }
                    // Sheet Configuration - 2 detents only
                    .presentationDetents([.scannerSmall, .scannerMedium], selection: $selectedDetent)
                    .interactiveDismissDisabled() // Prevents closing the sheet fully
                    .modifier(
                        PresentationEnhancements(
                            enableBackgroundInteractionUpThrough: .scannerMedium,
                            cornerRadius: 32
                        )
                    )
                }
        } else {
            // Fallback on earlier versions
        }
    }
}


// Applies iOS 16.4+ sheet presentation enhancements when available
private struct PresentationEnhancements: ViewModifier {
    let enableBackgroundInteractionUpThrough: PresentationDetent
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationBackgroundInteraction(.enabled(upThrough: enableBackgroundInteractionUpThrough))
                .presentationCornerRadius(cornerRadius)
        } else {
            content
        }
    }
}

// MARK: - Scanner Sheet Content
struct ScannerSheetContent: View {
    var colors: ThemeColors
    @Binding var selectedDetent: PresentationDetent
    var subscriptions: [SubscriptionItem] = []
    var onScanTap: () -> Void
    var onAddPaymentTap: (() -> Void)? = nil
    var onAddSubscription: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Floating Search Bar (Always Visible - Like Apple Maps)
            FloatingScanBar(colors: colors, onScanTap: onScanTap, onAddPaymentTap: onAddPaymentTap ?? {})
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, selectedDetent == .scannerSmall ? 12 : 16)
                .tutorialHighlight(.scanReceipt)
            
            // MARK: - Expanded Content (Only in Medium Detent)
            if selectedDetent != .scannerSmall {
                ExpandedSheetContent(
                    colors: colors,
                    subscriptions: subscriptions,
                    onAddSubscription: onAddSubscription
                )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: selectedDetent)
    }
}

// MARK: - Floating Scan Bar (Apple Maps Style Pill — Split 70/30)
struct FloatingScanBar: View {
    var colors: ThemeColors
    var onScanTap: () -> Void
    var onAddPaymentTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // MARK: Scan Receipt — 70%
            Button(action: onScanTap) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 34, height: 34)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }

                    Text("Scan Receipt")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saldoPrimary)

                    Spacer(minLength: 0)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.saldoSecondary.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(FloatingSheetButtonStyle())
            .layoutPriority(1)

            // MARK: Add Payment — 30%
            Button(action: onAddPaymentTap) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(colors.accent)

                    Text("Add")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saldoPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(FloatingSheetButtonStyle())
            .frame(width: UIScreen.main.bounds.width * 0.26)
        }
    }
}

// MARK: - Expanded Sheet Content (Below the Search Bar)
struct ExpandedSheetContent: View {
    var colors: ThemeColors
    var subscriptions: [SubscriptionItem] = []
    var onAddSubscription: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Subscription Section Header
            HStack {
                Text("Subscription")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Spacer()
                
                // Plus button to add subscription
                Button(action: {
                    onAddSubscription?()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(colors.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Subscription Grid (shows actual subscriptions or placeholders)
            SubscriptionGrid(subscriptions: subscriptions, colors: colors)
                .padding(.horizontal, 16)
                .tutorialHighlight(.grills)
            
            Spacer()
        }
    }
}

// MARK: - Subscription Grid
struct SubscriptionGrid: View {
    var subscriptions: [SubscriptionItem]
    var colors: ThemeColors
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            if subscriptions.isEmpty {
                // Show placeholders when empty
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.saldoSecondary.opacity(0.06))
                        .frame(height: 60)
                        .overlay(
                            Image(systemName: "creditcard")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.saldoSecondary.opacity(0.25))
                        )
                }
            } else {
                // Show actual subscriptions
                ForEach(subscriptions) { subscription in
                    SubscriptionGridItem(subscription: subscription, colors: colors)
                }
            }
        }
    }
}

// MARK: - Subscription Grid Item
struct SubscriptionGridItem: View {
    var subscription: SubscriptionItem
    var colors: ThemeColors
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(colors.accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                if subscription.usesLetterIcon {
                    // Show first letter for misc category
                    Text(subscription.iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(colors.accent)
                } else {
                    // Show SF Symbol
                    Image(systemName: subscription.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(colors.accent)
                }
            }
            
            // Name
            Text(subscription.name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.saldoPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.saldoSecondary.opacity(0.06))
        )
    }
}

// MARK: - Subscription Placeholder (Legacy - keeping for backwards compatibility)
struct SubscriptionPlaceholder: View {
    var colors: ThemeColors
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.saldoSecondary.opacity(0.06))
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: "creditcard")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.saldoSecondary.opacity(0.25))
                    )
            }
        }
    }
}

// MARK: - Button Style for Floating Sheet
struct FloatingSheetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Expanded Camera View
struct ExpandedCameraView: View {
    var colors: ThemeColors
    @Binding var showContent: Bool
    var onClose: () -> Void
    
    @State private var isFlashOn = false
    
    var body: some View {
        ZStack {
            // Camera Background (full screen)
            CameraPreviewView()
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top Bar
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    // Title pill
                    VStack(spacing: 2) {
                        Text("Scan Receipt")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Point at your receipt")
                            .font(.caption2)
                            .opacity(0.8)
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // Placeholder
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 40) {
                    // Gallery Button
                    Button(action: {}) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white)
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Capture Button
                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 72, height: 72)
                            
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 4)
                                .frame(width: 82, height: 82)
                        }
                    }
                    .buttonStyle(SnappyButtonStyle())
                    
                    // Flash Button
                    Button(action: { isFlashOn.toggle() }) {
                        Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white)
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Snappy Button Style
struct SnappyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Camera Preview (UIViewRepresentable)
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
    
    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: ()) {
        uiView.stopSession()
    }
}

class CameraPreviewUIView: UIView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var isSessionRunning = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        setupCamera()
    }
    
    private func setupCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { [weak self] in
                self?.configureSession()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.sessionQueue.async {
                        self?.configureSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showPlaceholder()
                    }
                }
            }
        default:
            showPlaceholder()
        }
    }
    
    private func configureSession() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async { [weak self] in
                self?.showPlaceholder()
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.showPlaceholder()
            }
            return
        }
        
        session.commitConfiguration()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = self.bounds
            self.layer.addSublayer(previewLayer)
            
            self.captureSession = session
            self.previewLayer = previewLayer
            
            self.sessionQueue.async {
                session.startRunning()
                self.isSessionRunning = true
            }
        }
    }
    
    private func showPlaceholder() {
        backgroundColor = UIColor.darkGray
        
        let label = UILabel()
        label.text = "Camera Preview"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.isSessionRunning else { return }
            self.captureSession?.stopRunning()
            self.isSessionRunning = false
            DispatchQueue.main.async {
                self.captureSession = nil
                self.previewLayer?.removeFromSuperlayer()
                self.previewLayer = nil
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        
        ScannerSheetContainer(
            colors: AppTheme.wealthy.colors,
            showCamera: .constant(false),
            selectedDetent: .constant(.scannerMedium),
            showSheet: .constant(true)
        )
    }
}

