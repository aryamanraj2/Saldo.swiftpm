import SwiftUI

// MARK: - Profile Sheet
struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    var grailPreviews: [GrailPreviewItem]

    // Form State
    @State private var name: String = ""
    @State private var allowance: String = ""
    @State private var selectedDay: Int = 1
    @State private var allocations: [String: Int] = [:]
    @State private var sliderValues: [String: Double] = [:]

    @FocusState private var isNameFocused: Bool
    @FocusState private var isAmountFocused: Bool

    private var totalAllocation: Int {
        let activeIDs = Set(grailPreviews.map { $0.id.uuidString })
        return allocations.filter { activeIDs.contains($0.key) }.values.reduce(0, +)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !allowance.isEmpty
            && Int(allowance) != nil
            && (grailPreviews.isEmpty || totalAllocation == 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            ProfileSheetHeader(colors: colors, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 28) {
                    nameSection
                    allowanceSection
                    daySection
                    allocationSection
                    saveButton
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(alignment: .center) {
            ProfileSheetBackground()
        }
        .presentationDetents([.fraction(0.92)])
        .presentationDragIndicator(.visible)
        .modifier(ProfileSheetEnhancements(cornerRadius: 32))
        .onAppear {
            loadCurrentValues()
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Name")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)

            TextField("e.g., Aryaman", text: $name)
                .font(.body)
                .foregroundStyle(Color.saldoPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    GlassBackgroundField(isFocused: isNameFocused, colors: colors)
                }
                .focused($isNameFocused)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Allowance Section

    private var allowanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Allowance")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)

            HStack(spacing: 12) {
                ProfileCurrencyBadge(colors: colors)

                TextField("0", text: $allowance)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background {
                        GlassBackgroundField(isFocused: isAmountFocused, colors: colors)
                    }
                    .focused($isAmountFocused)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Day Section

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Allowance Day")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)

                Text("Day of month your allowance arrives")
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)
            }
            .padding(.horizontal, 20)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...31, id: \.self) { day in
                            ProfileDayChip(
                                day: day,
                                isSelected: selectedDay == day,
                                colors: colors
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDay = day
                                }
                            }
                            .id(day)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    proxy.scrollTo(selectedDay, anchor: .center)
                }
            }
        }
    }

    // MARK: - Allocation Section

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Savings Split")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)

                Spacer()

                if !grailPreviews.isEmpty {
                    Text("\(totalAllocation)%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(totalAllocation == 100 ? colors.accent : Color.saldoSecondary)
                }
            }
            .padding(.horizontal, 20)

            Group {
                if grailPreviews.isEmpty {
                    allocationEmptyState
                } else if grailPreviews.count == 1 {
                    allocationSingleGrail
                } else {
                    allocationMultiGrail
                }
            }
        }
    }

    private var allocationEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "target")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.saldoSecondary.opacity(0.4))

            Text("Add a grail first")
                .font(.subheadline)
                .foregroundStyle(Color.saldoSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var allocationSingleGrail: some View {
        let grail = grailPreviews[0]
        return GrailAllocationCard(
            grailName: grail.name,
            grailCategory: grail.category,
            grailImage: grail.image,
            percentage: 100,
            isLocked: true,
            colors: colors,
            sliderValue: .constant(100)
        )
        .padding(.horizontal, 20)
    }

    private var allocationMultiGrail: some View {
        ForEach(grailPreviews) { grail in
            let key = grail.id.uuidString
            let pct = allocations[key] ?? 0
            GrailAllocationCard(
                grailName: grail.name,
                grailCategory: grail.category,
                grailImage: grail.image,
                percentage: pct,
                isLocked: false,
                colors: colors,
                sliderValue: sliderBinding(for: key)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Save Changes")
                    .font(.body)
                    .fontWeight(.semibold)
            }
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

    // MARK: - Data

    private func sliderBinding(for key: String) -> Binding<Double> {
        Binding<Double>(
            get: { sliderValues[key] ?? 0 },
            set: { newVal in
                let newInt = Int(newVal)
                sliderValues[key] = newVal
                redistribute(grailID: key, newValue: newInt)
                // Sync other sliders after redistribution
                for otherKey in sliderValues.keys where otherKey != key {
                    let target = Double(allocations[otherKey] ?? 0)
                    if abs((sliderValues[otherKey] ?? 0) - target) > 0.5 {
                        sliderValues[otherKey] = target
                    }
                }
            }
        )
    }

    private func loadCurrentValues() {
        let manager = OnboardingManager.shared
        name = manager.userName
        allowance = manager.userAllowance > 0 ? "\(manager.userAllowance)" : ""
        selectedDay = manager.allowanceDay

        if grailPreviews.count == 1 {
            allocations = [grailPreviews[0].id.uuidString: 100]
        } else if grailPreviews.count >= 2 {
            var loaded: [String: Int] = [:]
            let activeIDs = grailPreviews.map { $0.id.uuidString }
            for id in activeIDs {
                loaded[id] = manager.grailAllocations[id] ?? 0
            }
            let sum = loaded.values.reduce(0, +)
            if sum != 100 {
                let base = 100 / grailPreviews.count
                for (i, grail) in grailPreviews.enumerated() {
                    let extra = (i == grailPreviews.count - 1) ? (100 - base * grailPreviews.count) : 0
                    loaded[grail.id.uuidString] = base + extra
                }
            }
            allocations = loaded
            for (key, val) in loaded {
                sliderValues[key] = Double(val)
            }
        }
    }

    private func redistribute(grailID: String, newValue: Int) {
        let clamped = max(0, min(100, newValue))
        let oldValue = allocations[grailID] ?? 0

        guard clamped != oldValue else { return }

        allocations[grailID] = clamped

        let otherIDs = grailPreviews.map(\.id.uuidString).filter { $0 != grailID }

        if otherIDs.count == 1 {
            allocations[otherIDs[0]] = 100 - clamped
            return
        }

        let othersTotal = otherIDs.compactMap { allocations[$0] }.reduce(0, +)
        let remaining = 100 - clamped

        if othersTotal > 0 {
            var distributed = 0
            for (i, id) in otherIDs.enumerated() {
                if i == otherIDs.count - 1 {
                    allocations[id] = remaining - distributed
                } else {
                    let ratio = Double(allocations[id] ?? 0) / Double(othersTotal)
                    let share = Int(round(ratio * Double(remaining)))
                    allocations[id] = share
                    distributed += share
                }
            }
        } else {
            let base = remaining / otherIDs.count
            var distributed = 0
            for (i, id) in otherIDs.enumerated() {
                if i == otherIDs.count - 1 {
                    allocations[id] = remaining - distributed
                } else {
                    allocations[id] = base
                    distributed += base
                }
            }
        }
    }

    private func save() {
        let manager = OnboardingManager.shared
        manager.userName = name.trimmingCharacters(in: .whitespaces)
        if let value = Int(allowance) {
            manager.userAllowance = value
        }
        manager.allowanceDay = selectedDay
        if grailPreviews.count >= 2 {
            manager.grailAllocations = allocations
        } else if grailPreviews.count == 1 {
            manager.grailAllocations = [grailPreviews[0].id.uuidString: 100]
        }
        dismiss()
    }
}

// MARK: - Day Chip
private struct ProfileDayChip: View {
    let day: Int
    let isSelected: Bool
    let colors: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(day)")
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? Color.white : Color.saldoPrimary)
                .frame(width: 44, height: 44)
                .background {
                    if isSelected {
                        Circle().fill(colors.accent)
                    } else {
                        Circle().fill(colors.accent.opacity(0.08))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Currency Badge
private struct ProfileCurrencyBadge: View {
    let colors: ThemeColors

    var body: some View {
        Text("₹")
            .font(.title3)
            .fontWeight(.semibold)
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
}

// MARK: - Sheet Background
private struct ProfileSheetBackground: View {
    var body: some View {
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
}

// MARK: - Grail Allocation Card
private struct GrailAllocationCard: View {
    let grailName: String
    let grailCategory: GrailCategory
    let grailImage: UIImage?
    let percentage: Int
    let isLocked: Bool
    let colors: ThemeColors
    @Binding var sliderValue: Double

    var body: some View {
        VStack(spacing: 12) {
            cardHeader
            if !isLocked {
                Slider(value: $sliderValue, in: 0...100, step: 5)
                    .tint(colors.accent)
            }
        }
        .padding(16)
        .background(alignment: .center) {
            GrailFormCardBackground(colors: colors)
        }
    }

    @ViewBuilder
    private var cardHeader: some View {
        HStack(spacing: 12) {
            GrailAllocationThumbnail(
                image: grailImage,
                category: grailCategory,
                colors: colors
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(grailName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saldoPrimary)
                    .lineLimit(1)

                Text(grailCategory.rawValue)
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)
            }

            Spacer()

            Text("\(percentage)%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(colors.accent)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)
            }
        }
    }
}

// MARK: - Grail Thumbnail
private struct GrailAllocationThumbnail: View {
    let image: UIImage?
    let category: GrailCategory
    let colors: ThemeColors

    var body: some View {
        ZStack {
            Circle()
                .fill(colors.accent.opacity(0.12))
                .frame(width: 44, height: 44)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            } else {
                Image(systemName: category.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }
        }
    }
}

// MARK: - Profile Sheet Header
private struct ProfileSheetHeader: View {
    var colors: ThemeColors
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            closeButton
            titlePill
        }
    }

    private var closeButton: some View {
        Group {
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
        }
    }

    private var titlePill: some View {
        Group {
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

                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }

            Text("Profile")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sheet Enhancements
private struct ProfileSheetEnhancements: ViewModifier {
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
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ProfileSheet(colors: AppTheme.moderate.colors, grailPreviews: [])
        }
}
