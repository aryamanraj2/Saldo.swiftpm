import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Presentation Detent for Grail Sheet
extension PresentationDetent {
    static let grailLarge = PresentationDetent.fraction(0.85)
}

// MARK: - Grail Sheet
struct GrailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    
    // Binding to save the grail
    var onSave: ((GrailItem, UIImage?) -> Void)? = nil
    
    // Form State
    @State private var grailName: String = ""
    @State private var targetAmount: String = ""
    @State private var selectedCurrency: CurrencyOption = CurrencyOption.options[0]
    @State private var selectedCategory: GrailCategory = .sneakers
    @State private var rawSelectedImage: UIImage?
    @State private var maskedSelectedImage: UIImage?
    @State private var isMaskingImage = false
    @State private var maskingErrorMessage: String?
    @State private var maskingTask: Task<Void, Never>?
    @State private var isImagePickerPresented = false
    
    private let imageMaskingService = GrailImageMaskingService()
    
    @FocusState private var isNameFocused: Bool
    @FocusState private var isAmountFocused: Bool
    
    var canSave: Bool {
        !grailName.isEmpty && !targetAmount.isEmpty && Double(targetAmount) != nil && !isMaskingImage
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GrailSheetHeader(colors: colors, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    GrailIconPicker(
                        selectedImage: maskedSelectedImage,
                        category: selectedCategory,
                        name: grailName,
                        colors: colors,
                        isMaskingImage: isMaskingImage
                    ) {
                        dismissKeyboard()
                        isNameFocused = false
                        isAmountFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isImagePickerPresented = true
                        }
                    }
                    .padding(.top, 20)
                    
                    if let maskingErrorMessage {
                        Text(maskingErrorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.saldoSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    } else if isMaskingImage, rawSelectedImage != nil {
                        Text("Removing background...")
                            .font(.caption)
                            .foregroundStyle(Color.saldoSecondary)
                    }
                    
                    GrailCategoryPicker(
                        selectedCategory: $selectedCategory,
                        colors: colors
                    )
                    
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name your Grail")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)
                            
                            TextField("e.g., Jordan 1 Retro", text: $grailName)
                                .font(.body)
                                .foregroundStyle(Color.saldoPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background {
                                    GlassBackgroundField(isFocused: isNameFocused, colors: colors)
                                }
                                .focused($isNameFocused)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly save target")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)
                            
                            HStack(spacing: 12) {
                                Menu {
                                    ForEach(CurrencyOption.options) { option in
                                        Button(action: {
                                            selectedCurrency = option
                                        }) {
                                            HStack {
                                                Text("\(option.symbol) \(option.code)")
                                                if selectedCurrency == option {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(selectedCurrency.symbol)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(colors.accent)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background {
                                        if #available(iOS 26, *) {
                                            Color.clear
                                                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(colors.accent.opacity(0.12))
                                        }
                                    }
                                }
                                
                                TextField("0.00", text: $targetAmount)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.saldoPrimary)
                                    .keyboardType(.decimalPad)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background {
                                        GlassBackgroundField(isFocused: isAmountFocused, colors: colors)
                                    }
                                    .focused($isAmountFocused)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background {
                        GrailFormCardBackground(colors: colors)
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: saveGrail) {
                        Text("Add Grail")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(canSave ? Color.white : Color.saldoSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(canSave ? colors.accent : Color.saldoSecondary.opacity(0.2))
                            )
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.clear, in: .rect(cornerRadius: 32))
                    .opacity(0.78)
            } else {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.62)
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
                    }
            }
        }
        .presentationDetents([.grailLarge])
        .presentationDragIndicator(.visible)
        .modifier(GrailSheetEnhancements(cornerRadius: 32))
        .fullScreenCover(isPresented: $isImagePickerPresented) {
            GrailImagePicker { image in
                handleImagePicked(image)
            } onLoadFailure: {
                maskingErrorMessage = "Couldn't load that image. Try another one."
            }
        }
        .onDisappear {
            maskingTask?.cancel()
        }
    }
    
    private func saveGrail() {
        guard let amountValue = Double(targetAmount) else { return }
        
        let grail = GrailItem(
            name: grailName,
            targetAmount: amountValue,
            currency: selectedCurrency.symbol,
            category: selectedCategory,
            strictness: .balanced
        )
        
        onSave?(grail, maskedSelectedImage)
        dismiss()
    }
    
    private func handleImagePicked(_ image: UIImage) {
        rawSelectedImage = image
        maskedSelectedImage = nil
        maskingErrorMessage = nil
        isMaskingImage = true
        
        maskingTask?.cancel()
        maskingTask = Task {
            do {
                let maskedImage = try await imageMaskingService.maskLargestForegroundSubject(from: image)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    maskedSelectedImage = maskedImage
                    isMaskingImage = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    maskedSelectedImage = nil
                    isMaskingImage = false
                    if let maskingError = error as? GrailImageMaskingService.Error,
                       maskingError == .unsupportedEnvironment {
                        maskingErrorMessage = "Simulator can't run background masking. Test on a physical iPhone."
                    } else {
                        maskingErrorMessage = "Couldn't isolate subject. We'll use your grail icon."
                    }
                }
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Helper Views
struct GlassBackgroundField: View {
    var isFocused: Bool
    var colors: ThemeColors
    
    var body: some View {
        if #available(iOS 26, *) {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isFocused ? colors.accent.opacity(0.4) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.saldoSecondary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isFocused ? colors.accent.opacity(0.4) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
    }
}

struct GrailFormCardBackground: View {
    var colors: ThemeColors
    
    var body: some View {
        if #available(iOS 26, *) {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(colors.accent.opacity(0.12), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 0.5)
                )
        }
    }
}

struct GrailIconPicker: View {
    var selectedImage: UIImage?
    var category: GrailCategory
    var name: String
    var colors: ThemeColors
    var isMaskingImage: Bool
    var onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Button(action: onTap) {
                ZStack(alignment: .bottomTrailing) {
                    GrailIconPreview(
                        selectedImage: selectedImage,
                        category: category,
                        name: name,
                        colors: colors
                    )
                    .frame(width: 112, height: 112)
                    .overlay {
                        if isMaskingImage {
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.95))
                                .overlay {
                                    ProgressView()
                                        .tint(colors.accent)
                                }
                        }
                    }
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(colors.accent)
                        .frame(width: 30, height: 30)
                        .background {
                            if #available(iOS 26, *) {
                                Color.clear
                                    .glassEffect(.regular.interactive(), in: .circle)
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                                    )
                            }
                        }
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 2) {
                Text("Choose Grail visual")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Text("Tap to open your gallery")
                    .font(.caption2)
                    .foregroundStyle(Color.saldoSecondary)
            }
        }
    }
}

struct GrailIconPreview: View {
    var selectedImage: UIImage?
    var category: GrailCategory
    var name: String
    var colors: ThemeColors
    
    var body: some View {
        ZStack {
            Circle()
                .fill(colors.accent.opacity(0.12))
                .frame(width: 112, height: 112)
            
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                Group {
                    if category == .misc && !name.isEmpty {
                        Text(String(name.prefix(1).uppercased()))
                            .font(.system(size: 38, weight: .bold))
                            .id("text-\(name.prefix(1))")
                    } else {
                        Image(systemName: category.iconName)
                            .font(.system(size: 42, weight: .semibold))
                            .contentTransition(.symbolEffect(.replace))
                            .id(category.iconName)
                    }
                }
                .foregroundStyle(colors.accent)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .overlay(
            Circle()
                .strokeBorder(colors.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.25, dash: [4, 5]))
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: category)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: name)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedImage)
    }
}

struct GrailCategoryPicker: View {
    @Binding var selectedCategory: GrailCategory
    var colors: ThemeColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type of Grail")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GrailCategory.allCases) { category in
                        GrailCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            colors: colors
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct GrailCategoryChip: View {
    var category: GrailCategory
    var isSelected: Bool
    var colors: ThemeColors
    var action: () -> Void
    
    @State private var burstTrigger = 0
    
    var body: some View {
        Button(action: {
            #if !targetEnvironment(simulator)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            #endif
            
            burstTrigger += 1
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .symbolVariant(isSelected ? .fill : .none)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? Color.white : colors.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    Capsule()
                        .fill(isSelected ? colors.accent : colors.accent.opacity(0.12))
                    
                    BurstEffectView(
                        trigger: burstTrigger,
                        color: UIColor(colors.accent)
                    )
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : colors.accent.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct GrailSheetHeader: View {
    var colors: ThemeColors
    var onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if #available(iOS 26, *) {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.saldoPrimary)
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            } else {
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
            }
            
            if #available(iOS 26, *) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "target")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }
                    
                    Text("New Grail")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saldoPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular, in: .capsule)
            } else {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "target")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }
                    
                    Text("New Grail")
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
}

// MARK: - UIKit Image Picker
struct GrailImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void
    var onLoadFailure: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: GrailImagePicker
        
        init(_ parent: GrailImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.dismiss()
                return
            }
            
            parent.dismiss()
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    let imageData = (object as? UIImage)?.pngData()
                    DispatchQueue.main.async {
                        guard let imageData,
                              let image = UIImage(data: imageData) else {
                            self.parent.onLoadFailure?()
                            return
                        }
                        self.parent.onImagePicked(image)
                    }
                }
                return
            }
            
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    let imageData = data
                    DispatchQueue.main.async {
                        guard let imageData,
                              let image = UIImage(data: imageData) else {
                            self.parent.onLoadFailure?()
                            return
                        }
                        self.parent.onImagePicked(image)
                    }
                }
                return
            }
            
            parent.onLoadFailure?()
        }
    }
}

private struct GrailSheetEnhancements: ViewModifier {
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

#Preview {
    GrailSheet(colors: AppTheme.moderate.colors)
}
