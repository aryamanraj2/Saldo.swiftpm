import SwiftUI
import AVFoundation

// MARK: - Scanner Sheet State (simplified for native sheet)
enum ScannerSheetState: Equatable {
    case small    // Small detent: ~80pt pill
    case medium   // Medium detent: expanded content
}

// MARK: - Scanner Sheet Container (Apple Maps-style)
// This is the main container that manages the native sheet
struct ScannerSheetContainer: View {
    var colors: ThemeColors
    
    @State private var showSheet: Bool = true
    @State private var selectedDetent: PresentationDetent = .height(80)
    @State private var sheetHeight: CGFloat = 0
    @State private var showCamera = false
    
    // Configuration
    private let smallHeight: CGFloat = 80
    
    var body: some View {
        Color.clear
            .sheet(isPresented: $showSheet) {
                ScannerSheetContent(
                    colors: colors,
                    selectedDetent: $selectedDetent,
                    onScanTap: { showCamera = true }
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
                .presentationDetents([.height(smallHeight), .medium], selection: $selectedDetent)
                .interactiveDismissDisabled() // Prevents closing the sheet fully
                .modifier(
                    PresentationEnhancements(
                        enableBackgroundInteractionUpThrough: .medium,
                        cornerRadius: 32
                    )
                )
            }
            .fullScreenCover(isPresented: $showCamera) {
                ExpandedCameraView(
                    colors: colors,
                    showContent: .constant(true),
                    onClose: { showCamera = false }
                )
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
    var onScanTap: () -> Void
    
    private let smallHeight: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Floating Search Bar (Always Visible - Like Apple Maps)
            FloatingScanBar(colors: colors, onScanTap: onScanTap)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, selectedDetent == .height(smallHeight) ? 12 : 16)
            
            // MARK: - Expanded Content (Only in Medium Detent)
            if selectedDetent != .height(smallHeight) {
                ExpandedSheetContent(colors: colors)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: selectedDetent)
    }
}

// MARK: - Floating Scan Bar (Apple Maps Style Pill)
struct FloatingScanBar: View {
    var colors: ThemeColors
    var onScanTap: () -> Void
    
    var body: some View {
        Button(action: onScanTap) {
            HStack(spacing: 12) {
                // Camera icon with accent background
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(colors.accent.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colors.accent)
                }
                
                Text("Scan Receipt")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Spacer()
                
                // Mic-style icon (matching Apple Maps)
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.saldoSecondary.opacity(0.6))
                
                // Profile circle (matching Apple Maps)
                Circle()
                    .fill(colors.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(colors.accent)
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(FloatingSheetButtonStyle())
    }
}

// MARK: - Expanded Sheet Content (Below the Search Bar)
struct ExpandedSheetContent: View {
    var colors: ThemeColors
    
    var body: some View {
        VStack(spacing: 0) {
            // Grills Section Header
            HStack {
                Text("Grills")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Spacer()
                
                // Coming Soon badge
                Text("Coming Soon")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colors.accent.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Grills Placeholder Grid
            GrillsPlaceholder(colors: colors)
                .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}

// MARK: - Grills Placeholder
struct GrillsPlaceholder: View {
    var colors: ThemeColors
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.saldoSecondary.opacity(0.06))
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: "plus")
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
                            .foregroundStyle(isFlashOn ? Color.yellow : Color.white)
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
            colors: AppTheme.wealthy.colors
        )
    }
}

