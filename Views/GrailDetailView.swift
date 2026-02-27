import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Grail Detail View
struct GrailDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var colors: ThemeColors
    var grailPreview: GrailPreviewItem
    var grailStore: GrailStore
    
    @State private var showDepositSheet = false
    @State private var depositAmount: String = ""
    @State private var depositNote: String = ""
    @State private var animateProgress = false
    @State private var animateTimeline = false
    
    // Image upload states
    @State private var isImagePickerPresented = false
    @State private var isMaskingImage = false
    @State private var maskingErrorMessage: String?
    @State private var maskingTask: Task<Void, Never>?
    
    private let imageMaskingService = GrailImageMaskingService()
    
    // Computed grail data from store (live)
    private var grail: GrailItem? {
        grailStore.grails.first(where: { $0.id == grailPreview.id })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            detailHeader
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: 28) {
                    // Hero Section: Image/Icon
                    heroSection
                        .padding(.top, 12)
                    
                    // Journey Map Timeline
                    if let grail {
                        journeyMapTimeline(grail: grail)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 80)
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottomTrailing) {
            addDepositFAB
                .padding(.trailing, 20)
                .padding(.bottom, 24)
        }
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
        .modifier(GrailDetailSheetEnhancements(cornerRadius: 32))
        .sheet(isPresented: $showDepositSheet) {
            depositInputSheet
        }
        .fullScreenCover(isPresented: $isImagePickerPresented) {
            GrailImagePicker { image in
                handleImagePicked(image)
            } onLoadFailure: {
                maskingErrorMessage = "Couldn't load that image. Try another one."
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateProgress = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                animateTimeline = true
            }
        }
        .onDisappear {
            maskingTask?.cancel()
        }
    }
    
    // MARK: - Header
    private var detailHeader: some View {
        HStack(spacing: 12) {
            // Close button
            if #available(iOS 26, *) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.saldoPrimary)
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            } else {
                Button(action: { dismiss() }) {
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
            
            // Title pill
            if #available(iOS 26, *) {
                headerContent
                    .glassEffect(.regular, in: .capsule)
            } else {
                headerContent
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
    
    private var headerContent: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(colors.accent.opacity(0.12))
                    .frame(width: 32, height: 32)
                
                Image(systemName: grailPreview.category.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }
            
            Text(grailPreview.name)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                // Grail visual
                grailVisual
                    .frame(width: 140, height: 140)
                
                // Add Photo badge (only if no masked image)
                if grailPreview.image == nil {
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Add Photo")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            if #available(iOS 26, *) {
                                Color.clear
                                    .glassEffect(.regular.interactive(), in: .capsule)
                            } else {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(colors.accent.opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .offset(x: 8, y: 8)
                }
            }
            
            if isMaskingImage {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(colors.accent)
                    Text("Removing background...")
                        .font(.caption)
                        .foregroundStyle(Color.saldoSecondary)
                }
            } else if let error = maskingErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
    }
    
    @ViewBuilder
    private var grailVisual: some View {
        let currentImage: UIImage? = {
            // Use live image from store if available
            if let g = grail, let filename = g.maskedImageFilename {
                let preview = grailStore.cachedPreviewItems.first(where: { $0.id == g.id })
                return preview?.image ?? grailPreview.image
            }
            return grailPreview.image
        }()
        
        ZStack {
            Circle()
                .fill(colors.accent.opacity(0.08))
                .frame(width: 140, height: 140)
            
            if let image = currentImage {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .scaleEffect(1.06)
                    
                    if let contour = GrailContourRenderer.dashedContour(
                        for: image,
                        cacheID: grailPreview.visualCacheKey,
                        color: UIColor(colors.accent)
                    ) {
                        Image(uiImage: contour)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                            .scaleEffect(1.06)
                            .allowsHitTesting(false)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if grailPreview.category == .misc && !grailPreview.name.isEmpty {
                Text(String(grailPreview.name.prefix(1).uppercased()))
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(colors.accent)
            } else {
                Image(systemName: grailPreview.category.iconName)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }
        }
        .overlay {
            if currentImage == nil {
                Circle()
                    .strokeBorder(colors.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.25, dash: [4, 5]))
            }
        }
    }
    
    // MARK: - Progress Arc
    private var progressArc: some View {
        let progress = grail?.progress ?? 0
        let remaining = grail?.remainingAmount ?? grailPreview.remainingAmount
        let currency = grailPreview.currency
        
        return VStack(spacing: 6) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.saldoSecondary.opacity(0.12), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 120, height: 120)
                
                // Progress track
                Circle()
                    .trim(from: 0, to: animateProgress ? progress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [colors.accent.opacity(0.6), colors.accent],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // Center text
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .contentTransition(.numericText())
                    
                    Text("saved")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.saldoSecondary)
                }
            }
            .shadow(color: colors.accent.opacity(0.2), radius: 12, x: 0, y: 4)
            
            if remaining > 0 {
                Text("\(currency)\(remaining.formatted(.number.precision(.fractionLength(0...2)))) remaining")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.saldoSecondary)
                    .padding(.top, 4)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                    Text("Goal reached!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(colors.accent)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Journey Map Timeline
    private func journeyMapTimeline(grail: GrailItem) -> some View {
        let deposits = grail.deposits.sorted(by: { $0.date > $1.date }) // Newest first (top)
        let currency = grailPreview.currency
        let progress = grail.progress
        
        return VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("Deposit Journey")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(colors.primary)
                
                Spacer()
                
                if !deposits.isEmpty {
                    Text("\(deposits.count) deposit\(deposits.count == 1 ? "" : "s")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.saldoSecondary)
                }
            }
            .padding(.bottom, 20)
            
            // Timeline
            VStack(spacing: 0) {
                // Goal node at top
                goalNode(grail: grail, currency: currency)
                
                // Remaining track (dashed)
                if progress < 1.0 {
                    DashedTrackLine(color: Color.saldoSecondary.opacity(0.25))
                        .frame(width: 3, height: 40)
                        .padding(.leading, 20)
                }
                
                // Deposit nodes
                if deposits.isEmpty {
                    emptyDepositState
                } else {
                    ForEach(Array(deposits.enumerated()), id: \.element.id) { index, deposit in
                        depositNode(
                            deposit: deposit,
                            currency: currency,
                            isLast: index == deposits.count - 1,
                            index: index
                        )
                    }
                }
                
                // Starting node
                startNode(grail: grail, currency: currency)
            }
        }
        .padding(20)
        .background {
            GrailFormCardBackground(colors: colors)
        }
    }
    
    // MARK: - Timeline Nodes
    private func goalNode(grail: GrailItem, currency: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Goal circle
            ZStack {
                Circle()
                    .fill(grail.progress >= 1.0 ? colors.accent : Color.saldoSecondary.opacity(0.15))
                    .frame(width: 42, height: 42)
                    .shadow(color: colors.accent.opacity(grail.progress >= 1.0 ? 0.3 : 0), radius: 8, x: 0, y: 2)
                
                if let image = grailPreview.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(grail.progress >= 1.0 ? .white : Color.saldoSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Goal")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(colors.primary)
                
                Text("\(currency)\(grail.targetAmount.formatted(.number.precision(.fractionLength(0...2))))")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(colors.accent)
                
                if grail.remainingAmount > 0 {
                    Text("\(currency)\(grail.remainingAmount.formatted(.number.precision(.fractionLength(0...2)))) to go")
                        .font(.caption2)
                        .foregroundStyle(Color.saldoSecondary)
                }
            }
            .padding(.top, 4)
            
            Spacer()
        }
    }
    
    private func depositNode(deposit: DepositRecord, currency: String, isLast: Bool, index: Int) -> some View {
        VStack(spacing: 0) {
            // Solid track line above
            Rectangle()
                .fill(colors.accent)
                .frame(width: 3, height: 24)
                .padding(.leading, 20)
                .opacity(animateTimeline ? 1 : 0)
            
            HStack(alignment: .top, spacing: 14) {
                // Deposit circle
                ZStack {
                    Circle()
                        .fill(colors.accent)
                        .frame(width: 32, height: 32)
                        .shadow(color: colors.accent.opacity(0.25), radius: 6, x: 0, y: 2)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 5) // Center on the 42px goal node
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("+\(currency)\(deposit.amount.formatted(.number.precision(.fractionLength(0...2))))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(colors.accent)
                    
                    Text(deposit.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(Color.saldoSecondary)
                    
                    if let note = deposit.note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(Color.saldoSecondary.opacity(0.8))
                            .italic()
                            .lineLimit(1)
                    }
                }
                .padding(.top, 2)
                
                Spacer()
            }
            .opacity(animateTimeline ? 1 : 0)
            .offset(x: animateTimeline ? 0 : -20)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1 + 0.3), value: animateTimeline)
            
            // Solid track line below (if not last)
            if !isLast {
                Rectangle()
                    .fill(colors.accent)
                    .frame(width: 3, height: 8)
                    .padding(.leading, 20)
                    .opacity(animateTimeline ? 1 : 0)
            }
        }
    }
    
    private func startNode(grail: GrailItem, currency: String) -> some View {
        VStack(spacing: 0) {
            // Track line
            Rectangle()
                .fill(grail.deposits.isEmpty ? Color.saldoSecondary.opacity(0.15) : colors.accent)
                .frame(width: 3, height: 24)
                .padding(.leading, 20)
            
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(colors.accent.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Circle()
                        .fill(colors.accent)
                        .frame(width: 12, height: 12)
                }
                .padding(.leading, 7)
                
                Text("Started \(grail.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.saldoSecondary)
                
                Spacer()
            }
        }
    }
    
    private var emptyDepositState: some View {
        VStack(spacing: 0) {
            DashedTrackLine(color: Color.saldoSecondary.opacity(0.25))
                .frame(width: 3, height: 60)
                .padding(.leading, 20)
            
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(colors.accent.opacity(0.6))
                
                Text("Make your first deposit to start the journey!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.saldoSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                if #available(iOS 26, *) {
                    Color.clear
                        .glassEffect(.regular, in: .rect(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.saldoSecondary.opacity(0.06))
                }
            }
            .padding(.leading, 8)
        }
    }
    
    // MARK: - Add Deposit FAB
    private var addDepositFAB: some View {
        Button(action: {
            showDepositSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Deposit")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(colors.accent)
                    .shadow(color: colors.accent.opacity(0.35), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Deposit Input Sheet
    private var depositInputSheet: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Add Deposit")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.saldoPrimary)
                
                Spacer()
                
                Button(action: { showDepositSheet = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.saldoSecondary)
                }
            }
            .padding(.top, 8)
            
            // Amount field
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                
                HStack(spacing: 8) {
                    Text(grailPreview.currency)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(colors.accent)
                    
                    TextField("0.00", text: $depositAmount)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.saldoPrimary)
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.saldoSecondary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(colors.accent.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            // Note field
            VStack(alignment: .leading, spacing: 8) {
                Text("Note (optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                
                TextField("e.g., Birthday money", text: $depositNote)
                    .font(.body)
                    .foregroundStyle(Color.saldoPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.saldoSecondary.opacity(0.06))
                    }
            }
            
            // Save button
            Button(action: saveDeposit) {
                Text("Save Deposit")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(depositAmount.isEmpty || Double(depositAmount) == nil ? Color.saldoSecondary : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(depositAmount.isEmpty || Double(depositAmount) == nil ? Color.saldoSecondary.opacity(0.2) : colors.accent)
                    )
            }
            .disabled(depositAmount.isEmpty || Double(depositAmount) == nil)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Actions
    private func saveDeposit() {
        guard let amount = Double(depositAmount), amount > 0 else { return }
        let note = depositNote.isEmpty ? nil : depositNote
        
        Task {
            await grailStore.addDeposit(to: grailPreview.id, amount: amount, note: note)
        }
        
        depositAmount = ""
        depositNote = ""
        showDepositSheet = false
        
        // Re-trigger animation
        animateTimeline = false
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            animateTimeline = true
        }
        withAnimation(.easeOut(duration: 0.8)) {
            animateProgress = true
        }
    }
    
    private func handleImagePicked(_ image: UIImage) {
        maskingErrorMessage = nil
        isMaskingImage = true
        
        maskingTask?.cancel()
        maskingTask = Task {
            do {
                let maskedImage = try await imageMaskingService.maskLargestForegroundSubject(from: image)
                guard !Task.isCancelled else { return }
                await grailStore.updateImage(for: grailPreview.id, maskedImage: maskedImage)
                await MainActor.run {
                    isMaskingImage = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isMaskingImage = false
                    if let maskingError = error as? GrailImageMaskingService.Error,
                       maskingError == .unsupportedEnvironment {
                        maskingErrorMessage = "Simulator can't run background masking. Test on a physical iPhone."
                    } else {
                        maskingErrorMessage = "Couldn't isolate subject. Try another photo."
                    }
                }
            }
        }
    }
}

// MARK: - Dashed Track Line
struct DashedTrackLine: View {
    var color: Color
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 1.5, y: 0))
                    path.addLine(to: CGPoint(x: 1.5, y: 1000))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [4, 6]))
            }
            .clipped()
    }
}

// MARK: - Sheet Enhancements
private struct GrailDetailSheetEnhancements: ViewModifier {
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
    GrailDetailView(
        colors: AppTheme.moderate.colors,
        grailPreview: GrailPreviewItem(
            id: UUID(),
            visualCacheKey: "preview",
            name: "Air Jordan 1",
            category: .sneakers,
            image: nil,
            targetAmount: 15000,
            currentAmount: 5000,
            currency: "₹"
        ),
        grailStore: GrailStore()
    )
}
