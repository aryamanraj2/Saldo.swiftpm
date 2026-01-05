import SwiftUI
import VisionKit
import PhotosUI

// MARK: - Document Camera with Gallery Picker
/// Container view that presents the document camera with an option to pick from photo library
struct DocumentCameraWithGallery: View {
    @Binding var scannedImage: UIImage?
    @Binding var isProcessing: Bool
    var onCompletion: (Result<ReceiptMetadata, Error>) -> Void
    var onCancel: () -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Document camera as the main view
            DocumentCameraView(
                scannedImage: $scannedImage,
                isProcessing: $isProcessing,
                onCompletion: onCompletion,
                onCancel: onCancel
            )
            .ignoresSafeArea()
            
            // Floating gallery button overlay
            HStack {
                // Gallery picker button
                if #available(iOS 17.0, *) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Gallery")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        handlePhotoSelection(newItem)
                    }
                } else {
                    // Fallback on earlier versions
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120) // Position above the camera's bottom controls
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Load the image data
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    await MainActor.run {
                        isProcessing = false
                        onCompletion(.failure(ReceiptProcessorError.imageConversionFailed))
                    }
                    return
                }
                
                print("📷 [Gallery] Selected image from photo library: \(Int(uiImage.size.width))x\(Int(uiImage.size.height))")
                
                // Process the image
                let metadata = try await ReceiptProcessor.shared.process(image: uiImage)
                
                await MainActor.run {
                    scannedImage = uiImage
                    isProcessing = false
                    onCompletion(.success(metadata))
                }
            } catch {
                print("❌ [Gallery] Error processing selected image: \(error.localizedDescription)")
                await MainActor.run {
                    isProcessing = false
                    onCompletion(.failure(error))
                }
            }
        }
        
        // Reset selection
        selectedPhotoItem = nil
    }
}

// MARK: - Document Camera View
/// UIViewControllerRepresentable wrapper for VNDocumentCameraViewController
/// Provides high-quality document scanning with auto-shutter and perspective correction
struct DocumentCameraView: UIViewControllerRepresentable {
    
    // MARK: - Bindings
    @Binding var scannedImage: UIImage?
    @Binding var isProcessing: Bool
    
    // MARK: - Callbacks
    var onCompletion: (Result<ReceiptMetadata, Error>) -> Void
    var onCancel: () -> Void
    
    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    @MainActor
    class Coordinator: NSObject, @preconcurrency VNDocumentCameraViewControllerDelegate {
        let parent: DocumentCameraView
        
        init(_ parent: DocumentCameraView) {
            self.parent = parent
        }
        
        // MARK: - VNDocumentCameraViewControllerDelegate
        
        /// Called when user finishes scanning
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // Get the first page (receipts are typically single-page)
            guard scan.pageCount > 0 else {
                controller.dismiss(animated: true) {
                    self.parent.onCompletion(.failure(ReceiptProcessorError.noDocumentFound))
                }
                return
            }
            
            let image = scan.imageOfPage(at: 0)
            parent.scannedImage = image
            parent.isProcessing = true
            
            // Dismiss camera first
            controller.dismiss(animated: true) {
                // Process the image asynchronously
                Task {
                    do {
                        let metadata = try await ReceiptProcessor.shared.process(image: image)
                        await MainActor.run {
                            self.parent.isProcessing = false
                            self.parent.onCompletion(.success(metadata))
                        }
                    } catch {
                        await MainActor.run {
                            self.parent.isProcessing = false
                            self.parent.onCompletion(.failure(error))
                        }
                    }
                }
            }
        }
        
        /// Called when user cancels scanning
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.parent.onCancel()
            }
        }
        
        /// Called when scanning fails
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(animated: true) {
                self.parent.onCompletion(.failure(error))
            }
        }
    }
}

// MARK: - Scan Result Sheet
/// Displays extracted receipt data after scanning
struct ScanResultSheet: View {
    let metadata: ReceiptMetadata
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                
                Text("Receipt Scanned")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Extracted Data
                VStack(spacing: 16) {
                    if let merchant = metadata.merchantName {
                        DataRow(label: "Merchant", value: merchant, icon: "storefront.fill")
                    }
                    
                    if let date = metadata.date {
                        DataRow(label: "Date", value: formatDate(date), icon: "calendar")
                    }
                    
                    if let total = metadata.formattedTotal {
                        DataRow(label: "Total", value: total, icon: "indianrupeesign.circle.fill")
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if !metadata.hasData {
                    Text("No structured data found in receipt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("Add Transaction")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button("Scan Another") {
                        onDismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Data Row Component
struct DataRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Processing Overlay
/// Shows loading indicator while processing receipt
struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processing Receipt...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    ScanResultSheet(metadata: .sample, onDismiss: {})
}
