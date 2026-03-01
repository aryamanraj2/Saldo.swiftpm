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
                // Let SwiftUI dismiss via onCompletion -> showCamera = false
                parent.onCompletion(.failure(ReceiptProcessorError.noDocumentFound))
                return
            }
            
            let image = scan.imageOfPage(at: 0)
            parent.scannedImage = image
            parent.isProcessing = true
            
            // Process the image asynchronously
            // Do NOT manually dismiss — SwiftUI handles dismissal when onCompletion sets showCamera = false
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
        
        /// Called when user cancels scanning
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            // Let SwiftUI dismiss via onCancel -> showCamera = false
            parent.onCancel()
        }
        
        /// Called when scanning fails
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            // Let SwiftUI dismiss via onCompletion -> showCamera = false
            parent.onCompletion(.failure(error))
        }
    }
}

// MARK: - Scan Result Sheet (Themed & Editable)
/// Displays extracted receipt data after scanning, matching the app's glassmorphic design.
/// Fields are editable so users can correct OCR mistakes.
struct ScanResultSheet: View {
    let metadata: ReceiptMetadata
    var colors: ThemeColors
    var transactionStore: TransactionStore
    var onDismiss: () -> Void

    // Editable state pre-populated from OCR
    @State private var merchantName: String = ""
    @State private var amountString: String = ""
    @State private var selectedDate: Date = Date()

    @FocusState private var focusedField: ScanField?
    @State private var appeared = false

    private enum ScanField: Hashable {
        case merchant, amount
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header (matches ManualPaymentSheetHeader)
            ScanResultHeader(colors: colors, onCancel: onDismiss)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 24) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 88, height: 88)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(colors.accent)
                            .symbolEffect(.bounce, value: appeared)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1.0 : 0)
                    .padding(.top, 8)

                    Text("Receipt Scanned")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.saldoPrimary)

                    // MARK: - Editable Fields
                    VStack(spacing: 16) {
                        // Merchant
                        EditableDataRow(
                            label: "Merchant",
                            icon: "storefront.fill",
                            text: $merchantName,
                            placeholder: "Enter merchant name",
                            colors: colors,
                            isFocused: focusedField == .merchant,
                            onTap: { focusedField = .merchant }
                        )
                        .focused($focusedField, equals: .merchant)

                        // Amount
                        EditableDataRow(
                            label: "Total Amount",
                            icon: "indianrupeesign.circle.fill",
                            text: $amountString,
                            placeholder: "0.00",
                            colors: colors,
                            keyboardType: .decimalPad,
                            isFocused: focusedField == .amount,
                            onTap: { focusedField = .amount }
                        )
                        .focused($focusedField, equals: .amount)

                        // Date (native iOS DatePicker)
                        DatePickerRow(
                            label: "Date",
                            icon: "calendar",
                            date: $selectedDate,
                            colors: colors
                        )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.saldoSecondary.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color.saldoSecondary.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 20)

                    if !metadata.hasData {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(colors.accent)
                            Text("No structured data found — enter details manually")
                                .font(.caption)
                                .foregroundStyle(Color.saldoSecondary)
                        }
                    }

                    // Hint
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                        Text("Tap any field to edit")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.saldoSecondary.opacity(0.6))

                    Spacer(minLength: 20)

                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Parse amount (strip non-numeric chars except decimal)
                            let cleanedAmount = amountString.replacingOccurrences(
                                of: "[^0-9.]", with: "", options: .regularExpression
                            )
                            guard let value = Double(cleanedAmount), value > 0 else {
                                onDismiss()
                                return
                            }

                            // Detect currency from receipt OCR or default to primary
                            let receiptCurrency = AppCurrency.allCases.first {
                                $0.rawValue == (metadata.currencyCode ?? "")
                            } ?? CurrencyManager.shared.selected

                            let primaryAmount = receiptCurrency.convert(value, to: CurrencyManager.shared.selected)

                            let record = TransactionRecord(
                                title: merchantName.isEmpty ? "Receipt" : merchantName.trimmingCharacters(in: .whitespacesAndNewlines),
                                icon: "doc.text.fill",
                                category: "Receipt",
                                type: .expense,
                                amountInPrimary: primaryAmount,
                                originalAmount: value,
                                originalCurrency: receiptCurrency.rawValue,
                                date: selectedDate,
                                source: .receipt
                            )

                            transactionStore.add(record)
                            transactionStore.adjustBalance(by: -primaryAmount)
                            onDismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Add Transaction")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(colors.accent)
                            )
                        }

                        Button(action: onDismiss) {
                            Text("Discard")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.saldoSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.62)
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
                }
        }
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.visible)
        .modifier(ScanResultSheetEnhancements(cornerRadius: 32))
        .onAppear {
            // Pre-populate from OCR
            merchantName = metadata.merchantName ?? ""
            if let total = metadata.formattedTotal {
                amountString = total
            } else if let amount = metadata.totalAmount {
                amountString = "\(amount)"
            }
            if let date = metadata.date {
                selectedDate = date
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Scan Result Header
private struct ScanResultHeader: View {
    var colors: ThemeColors
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.saldoPrimary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                    )
            }

            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colors.accent.opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(colors.accent)
                }

                Text("Scan Result")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)

                Spacer()
            }
            .padding(.horizontal, 14)
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
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Editable Data Row
struct EditableDataRow: View {
    let label: String
    let icon: String
    @Binding var text: String
    var placeholder: String = ""
    var colors: ThemeColors
    var keyboardType: UIKeyboardType = .default
    var isFocused: Bool = false
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(colors.accent.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }

            // Label + TextField
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.saldoSecondary)

                TextField(placeholder, text: $text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.saldoPrimary)
                    .keyboardType(keyboardType)
                    .onTapGesture { onTap() }
            }

            Spacer(minLength: 0)

            // Edit indicator
            Image(systemName: "pencil")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.saldoSecondary.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.saldoSecondary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isFocused ? colors.accent.opacity(0.4) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Date Picker Row (Native iOS Calendar)
struct DatePickerRow: View {
    let label: String
    let icon: String
    @Binding var date: Date
    var colors: ThemeColors

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(colors.accent.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }

            // Label
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.saldoSecondary)

                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(colors.accent)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.saldoSecondary.opacity(0.04))
        )
    }
}

// MARK: - Sheet Enhancements
private struct ScanResultSheetEnhancements: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationCornerRadius(cornerRadius)
                .presentationBackground(.clear)
        } else {
            content
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
    ScanResultSheet(metadata: .sample, colors: AppTheme.wealthy.colors, transactionStore: TransactionStore.shared, onDismiss: {})
}
