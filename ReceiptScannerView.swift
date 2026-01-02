import SwiftUI
import AVFoundation

// MARK: - Scanner Sheet State
enum ScannerSheetState: Equatable {
    case minimized   // Small pill: camera icon + "Scan Receipt"
    case medium      // Medium detent: scan receipt + grills section
}

// MARK: - iOS 26 Floating Sheet View
struct ReceiptScannerView: View {
    @Binding var sheetState: ScannerSheetState
    var colors: ThemeColors
    
    @State private var dragOffset: CGFloat = 0
    @State private var showCamera = false
    @GestureState private var isDragging = false
    
    // Sheet heights
    private let minimizedHeight: CGFloat = 56
    private let mediumDetentFraction: CGFloat = 0.42
    
    var body: some View {
        GeometryReader { geometry in
            let mediumHeight = geometry.size.height * mediumDetentFraction
            let currentHeight = sheetState == .minimized ? minimizedHeight : mediumHeight
            let rawHeight = currentHeight + (dragOffset.isFinite ? dragOffset : 0)
            let safeHeight = max(minimizedHeight, min(rawHeight, mediumHeight))
            
            VStack(spacing: 0) {
                Spacer()
                
                // Floating Sheet Container
                VStack(spacing: 0) {
                    if sheetState == .minimized {
                        // MARK: - Minimized Pill
                        MinimizedSheetPill(colors: colors) {
                            expandToMedium()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        // MARK: - Medium Detent Content
                        MediumDetentContent(
                            colors: colors,
                            onScanTap: { showCamera = true },
                            onCollapse: { collapseToMinimized() }
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(height: safeHeight)
                .frame(maxWidth: .infinity)
                .background(
                    // iOS 26 Liquid Glass Effect
                    GlassBackground(cornerRadius: sheetState == .minimized ? 28 : 24)
                )
                .clipShape(RoundedRectangle(cornerRadius: sheetState == .minimized ? 28 : 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -5)
                .shadow(color: colors.accent.opacity(0.1), radius: 30, x: 0, y: -10)
                .padding(.horizontal, sheetState == .minimized ? 20 : 12)
                .padding(.bottom, sheetState == .minimized ? 16 : 8)
                .gesture(dragGesture(mediumHeight: mediumHeight))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sheetState)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: dragOffset)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ExpandedCameraView(
                colors: colors,
                showContent: .constant(true),
                onClose: { showCamera = false }
            )
        }
    }
    
    // MARK: - Drag Gesture
    private func dragGesture(mediumHeight: CGFloat) -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let translation = value.translation.height
                
                if sheetState == .minimized {
                    // Dragging up from minimized
                    if translation < 0 {
                        dragOffset = max(translation, -(mediumHeight - minimizedHeight))
                    }
                } else {
                    // Dragging down from medium
                    if translation > 0 {
                        dragOffset = min(translation, mediumHeight - minimizedHeight)
                    }
                }
            }
            .onEnded { value in
                let velocity = value.velocity.height
                let translation = value.translation.height
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragOffset = 0
                    
                    if sheetState == .minimized {
                        // Threshold to expand: dragged up enough or fast enough
                        if translation < -50 || velocity < -500 {
                            sheetState = .medium
                        }
                    } else {
                        // Threshold to collapse: dragged down enough or fast enough
                        if translation > 50 || velocity > 500 {
                            sheetState = .minimized
                        }
                    }
                }
            }
    }
    
    private func expandToMedium() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            sheetState = .medium
        }
    }
    
    private func collapseToMinimized() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            sheetState = .minimized
        }
    }
}

// MARK: - Glass Background (iOS 26 Liquid Glass)
struct GlassBackground: View {
    var cornerRadius: CGFloat
    
    var body: some View {
        // Use glassEffect for iOS 26+, fallback to ultraThinMaterial
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                )
                .glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            // Fallback on earlier versions
        }
    }
}

// MARK: - Minimized Sheet Pill
struct MinimizedSheetPill: View {
    var colors: ThemeColors
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Camera icon with accent background
                ZStack {
                    Circle()
                        .fill(colors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colors.accent)
                }
                
                Text("Scan Receipt")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.saldoSecondary.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(FloatingSheetButtonStyle())
    }
}

// MARK: - Medium Detent Content
struct MediumDetentContent: View {
    var colors: ThemeColors
    var onScanTap: () -> Void
    var onCollapse: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            DragHandle()
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Scan Receipt Row
            Button(action: onScanTap) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan Receipt")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.saldoPrimary)
                        
                        Text("Take a photo or choose from gallery")
                            .font(.caption)
                            .foregroundStyle(Color.saldoSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.saldoSecondary.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.saldoSecondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(FloatingSheetButtonStyle())
            .padding(.horizontal, 16)
            
            // Grills Section Header
            HStack {
                Text("Grills")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Spacer()
                
                // TODO badge
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
            .padding(.top, 24)
            .padding(.bottom, 12)
            
            // Grills Placeholder Grid
            GrillsPlaceholder(colors: colors)
                .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}

// MARK: - Drag Handle
struct DragHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.saldoSecondary.opacity(0.35))
            .frame(width: 36, height: 5)
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
        
        ReceiptScannerView(
            sheetState: .constant(.minimized),
            colors: AppTheme.wealthy.colors
        )
    }
}

