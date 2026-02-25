import SwiftUI
import Charts

// MARK: - Profile Sheet
struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    var grailPreviews: [GrailPreviewItem]

    // Form State
    @State private var name: String = ""
    @State private var allowance: String = ""
    @State private var selectedDay: Int = 1
    @State private var allocations: [String: Double] = [:]

    @FocusState private var isNameFocused: Bool
    @FocusState private var isAmountFocused: Bool

    // Compact DatePicker binding — maps Int day ↔ Date
    private var dayBinding: Binding<Date> {
        Binding(
            get: {
                var c = Calendar.current.dateComponents([.year, .month], from: Date())
                c.day = selectedDay
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newDate in
                selectedDay = Calendar.current.component(.day, from: newDate)
            }
        )
    }

    private var totalAllocation: Double {
        let ids = Set(grailPreviews.map { $0.id.uuidString })
        return allocations.filter { ids.contains($0.key) }.values.reduce(0, +)
    }

    private var intAllocations: [String: Int] {
        allocations.mapValues { Int($0.rounded()) }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !allowance.isEmpty
            && Int(allowance) != nil
            && (grailPreviews.isEmpty || abs(totalAllocation - 100) < 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            ProfileSheetHeader(colors: colors, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 20) {
                    nameSection
                    allowanceSection
                    daySection
                    allocationSection
                    saveButton
                }
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(alignment: .center) { ProfileSheetBackground() }
        .presentationDetents([.fraction(0.95)])
        .presentationDragIndicator(.visible)
        .modifier(ProfileSheetEnhancements(cornerRadius: 32))
        .onAppear { loadCurrentValues() }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        ProfileSectionCard(colors: colors) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Your Name", icon: "person.fill", colors: colors)
                TextField("e.g., Aryaman", text: $name)
                    .font(.body)
                    .foregroundStyle(Color.saldoPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background { GlassBackgroundField(isFocused: isNameFocused, colors: colors) }
                    .focused($isNameFocused)
            }
        }
    }

    // MARK: - Allowance Section

    private var allowanceSection: some View {
        ProfileSectionCard(colors: colors) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Monthly Allowance", icon: "indianrupeesign.circle.fill", colors: colors)
                HStack(spacing: 10) {
                    Text("₹")
                        .font(.title3).fontWeight(.semibold).foregroundStyle(colors.accent)
                        .frame(width: 44, height: 44)
                        .background {
                            if #available(iOS 26, *) {
                                Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colors.accent.opacity(0.12))
                            }
                        }
                    TextField("0", text: $allowance)
                        .font(.title3).fontWeight(.semibold).foregroundStyle(Color.saldoPrimary)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background { GlassBackgroundField(isFocused: isAmountFocused, colors: colors) }
                        .focused($isAmountFocused)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Day Section — Compact DatePicker (tap → calendar popover)

    private var daySection: some View {
        ProfileSectionCard(colors: colors) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Allowance Day", icon: "calendar", colors: colors)

                Text("Day your allowance arrives every month")
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)

                // .compact style = small pill label, tap → full calendar overlay pops up
                // On iOS 26 this gets the Liquid Glass treatment automatically
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(colors.accent)
                        .font(.body)

                    DatePicker(
                        "",
                        selection: dayBinding,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(colors.accent.opacity(0.07))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(colors.accent.opacity(0.18), lineWidth: 1)
                        }
                }

                Text("Tap the date to pick a day →")
                    .font(.caption2)
                    .foregroundStyle(Color.saldoSecondary.opacity(0.6))
            }
        }
    }

    // MARK: - Allocation Section

    private var allocationSection: some View {
        Group {
            if grailPreviews.isEmpty {
                EmptyView()
            } else if grailPreviews.count == 1 {
                ProfileSectionCard(colors: colors) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Savings Split", icon: "chart.pie.fill", colors: colors)
                        HStack(spacing: 12) {
                            GrailAllocationThumbnail(
                                image: grailPreviews[0].image,
                                category: grailPreviews[0].category,
                                colors: colors
                            )
                            Text(grailPreviews[0].name)
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.saldoPrimary)
                            Spacer()
                            Text("100%")
                                .font(.title3).fontWeight(.bold).foregroundStyle(colors.accent)
                            Image(systemName: "lock.fill").font(.caption2).foregroundStyle(Color.saldoSecondary)
                        }
                    }
                }
            } else {
                ProfileSectionCard(colors: colors) {
                    SavingsSplitView(
                        grails: grailPreviews,
                        allocations: $allocations,
                        accentColor: colors.accent
                    )
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button { save() } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 18, weight: .semibold))
                Text("Save Changes").font(.body).fontWeight(.semibold)
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
        .animation(.spring(response: 0.3), value: canSave)
    }

    // MARK: - Data

    private func loadCurrentValues() {
        let manager = OnboardingManager.shared
        name = manager.userName
        allowance = manager.userAllowance > 0 ? "\(manager.userAllowance)" : ""
        selectedDay = manager.allowanceDay

        if grailPreviews.count == 1 {
            allocations = [grailPreviews[0].id.uuidString: 100]
        } else if grailPreviews.count >= 2 {
            var loaded: [String: Double] = [:]
            for grail in grailPreviews {
                loaded[grail.id.uuidString] = Double(manager.grailAllocations[grail.id.uuidString] ?? 0)
            }
            let sum = loaded.values.reduce(0, +)
            if sum < 1 {
                let base = 100.0 / Double(grailPreviews.count)
                for grail in grailPreviews { loaded[grail.id.uuidString] = base }
            }
            allocations = loaded
        }
    }

    private func save() {
        let manager = OnboardingManager.shared
        manager.userName = name.trimmingCharacters(in: .whitespaces)
        if let value = Int(allowance) { manager.userAllowance = value }
        manager.allowanceDay = selectedDay
        if grailPreviews.count >= 2 {
            manager.grailAllocations = intAllocations
        } else if grailPreviews.count == 1 {
            manager.grailAllocations = [grailPreviews[0].id.uuidString: 100]
        }
        dismiss()
    }
}

// MARK: - Savings Split View (Swift Charts SectorMark)

struct SavingsSplitView: View {
    let grails: [GrailPreviewItem]
    @Binding var allocations: [String: Double]
    let accentColor: Color

    @State private var selectedGrailID: String? = nil
    @State private var selectedAngle: Double? = nil
    @State private var appear: Bool = false

    private var totalAllocation: Double {
        allocations.values.reduce(0, +)
    }

    private var allOk: Bool { abs(totalAllocation - 100) < 1 }

    // Chart data model
    struct Slice: Identifiable {
        let id: String
        let name: String
        let value: Double
        let color: Color
        let category: GrailCategory
        let image: UIImage?
    }

    private var slices: [Slice] {
        grails.enumerated().map { i, grail in
            Slice(
                id: grail.id.uuidString,
                name: grail.name,
                value: max(allocations[grail.id.uuidString] ?? 0, 0),
                color: grailPaletteColor(index: i, accent: accentColor),
                category: grail.category,
                image: grail.image
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header row
            HStack {
                SectionLabel(text: "Savings Split", icon: "chart.pie.fill",
                             colors: ThemeColors(background: .clear, primary: Color.saldoPrimary,
                                                secondary: Color.saldoSecondary, accent: accentColor,
                                                backgroundBlob1: .clear, backgroundBlob2: .clear, backgroundBlob3: .clear))
                Spacer()
                // Animated total badge
                HStack(spacing: 4) {
                    if allOk {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(accentColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text("\(Int(totalAllocation.rounded()))%")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(allOk ? accentColor : .orange)
                        .contentTransition(.numericText())
                }
                .animation(.spring(response: 0.35), value: allOk)
                .animation(.spring(response: 0.35), value: Int(totalAllocation.rounded()))
            }

            // Swift Charts donut
            ZStack {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Pct", slice.value),
                        innerRadius: .ratio(0.55),
                        outerRadius: selectedGrailID == slice.id ? .ratio(0.97) : .ratio(0.88),
                        angularInset: 2.5
                    )
                    .cornerRadius(8)
                    .foregroundStyle(
                        // Gradient fill per slice
                        LinearGradient(
                            colors: [slice.color, slice.color.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(selectedGrailID == nil || selectedGrailID == slice.id ? 1 : 0.45)
                    .shadow(color: slice.color.opacity(selectedGrailID == slice.id ? 0.45 : 0.15),
                            radius: selectedGrailID == slice.id ? 12 : 4, x: 0, y: 4)
                }
                .chartAngleSelection(value: $selectedAngle)
                .onChange(of: selectedAngle) { _, newAngle in
                    if let angle = newAngle {
                        updateSelectedGrail(for: angle)
                    } else {
                        withAnimation(.spring(response: 0.3)) { selectedGrailID = nil }
                    }
                }
                .frame(height: 220)
                .scaleEffect(appear ? 1 : 0.85)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.75), value: appear)

                // Centre content
                VStack(spacing: 4) {
                    if let id = selectedGrailID, let slice = slices.first(where: { $0.id == id }) {
                        // Show selected grail info
                        if let img = slice.image {
                            Image(uiImage: img)
                                .resizable().scaledToFit()
                                .frame(width: 32, height: 32)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: slice.category.iconName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(slice.color)
                                .transition(.scale.combined(with: .opacity))
                        }
                        Text("\(Int(slice.value.rounded()))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(slice.color)
                            .contentTransition(.numericText())
                    } else {
                        // Default centre
                        Image(systemName: allOk ? "checkmark.circle.fill" : "hand.point.up.left.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(allOk ? accentColor : Color.saldoSecondary)
                            .animation(.spring(response: 0.4), value: allOk)
                        Text(allOk ? "Set!" : "Tap\nsegment")
                            .font(.system(size: 11, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(allOk ? accentColor : Color.saldoSecondary)
                            .animation(.spring(response: 0.4), value: allOk)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedGrailID)
            }

            // Instruction hint
            if !allOk {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle").font(.caption2)
                    Text("Adjust values below until total reaches 100%").font(.caption)
                }
                .foregroundStyle(Color.orange)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Legend + stepper rows
            VStack(spacing: 0) {
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    AllocationLegendRow(
                        slice: slice,
                        isSelected: selectedGrailID == slice.id,
                        accentColor: accentColor,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGrailID = selectedGrailID == slice.id ? nil : slice.id
                            }
                        },
                        onDecrement: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                stepAllocation(grailID: slice.id, delta: -5)
                            }
                        },
                        onIncrement: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                stepAllocation(grailID: slice.id, delta: +5)
                            }
                        }
                    )

                    if index < slices.count - 1 {
                        Divider()
                            .overlay(Color.saldoSecondary.opacity(0.08))
                            .padding(.leading, 52)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.saldoSecondary.opacity(0.04))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appear = true
            }
        }
    }

    // Convert chart tap angle → selected grail
    private func updateSelectedGrail(for angle: Double) {
        var cumAngle = 0.0
        let total = totalAllocation
        guard total > 0 else { return }
        for slice in slices {
            let sweep = slice.value / total * 360.0
            cumAngle += sweep
            if angle <= cumAngle {
                withAnimation(.spring(response: 0.3)) {
                    selectedGrailID = slice.id
                }
                return
            }
        }
        withAnimation(.spring(response: 0.3)) { selectedGrailID = nil }
    }

    private func stepAllocation(grailID: String, delta: Int) {
        let current = allocations[grailID] ?? 0
        let proposed = max(5, min(90, current + Double(delta)))
        guard proposed != current else { return }

        allocations[grailID] = proposed

        // Redistribute remainder to others proportionally
        let othersTotal = grails.filter { $0.id.uuidString != grailID }
            .reduce(0.0) { $0 + (allocations[$1.id.uuidString] ?? 0) }
        let remaining = 100.0 - proposed
        let otherIDs = grails.map(\.id.uuidString).filter { $0 != grailID }

        if othersTotal > 0 {
            var distributed = 0.0
            for (i, id) in otherIDs.enumerated() {
                if i == otherIDs.count - 1 {
                    allocations[id] = max(5, remaining - distributed)
                } else {
                    let ratio = (allocations[id] ?? 0) / othersTotal
                    let share = (ratio * remaining).rounded()
                    allocations[id] = max(5, share)
                    distributed += share
                }
            }
        } else {
            let base = remaining / Double(otherIDs.count)
            for id in otherIDs { allocations[id] = max(5, base) }
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Allocation Legend Row

private struct AllocationLegendRow: View {
    let slice: SavingsSplitView.Slice
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Color dot
            Circle()
                .fill(slice.color)
                .frame(width: 10, height: 10)
                .shadow(color: slice.color.opacity(0.5), radius: 4, x: 0, y: 2)

            // Icon
            ZStack {
                Circle()
                    .fill(slice.color.opacity(0.12))
                    .frame(width: 32, height: 32)
                if let img = slice.image {
                    Image(uiImage: img).resizable().scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: slice.category.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(slice.color)
                }
            }

            // Name
            Text(slice.name)
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.saldoPrimary : Color.saldoSecondary)
                .lineLimit(1)
                .animation(.spring(response: 0.25), value: isSelected)

            Spacer()

            // Stepper
            HStack(spacing: 6) {
                // Minus
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(slice.value > 5 ? slice.color : Color.saldoSecondary.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(slice.value > 5 ? slice.color.opacity(0.12) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(slice.value <= 5)

                // Pct badge
                Text("\(Int(slice.value.rounded()))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(slice.color)
                    .frame(width: 44, alignment: .center)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: Int(slice.value.rounded()))

                // Plus
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(slice.value < 90 ? slice.color : Color.saldoSecondary.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(slice.value < 90 ? slice.color.opacity(0.12) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(slice.value >= 90)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? slice.color.opacity(0.06) : .clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture(perform: onTap)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Color Palette

func grailPaletteColor(index: Int, accent: Color) -> Color {
    let uiAccent = UIColor(accent)
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    uiAccent.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    let shifts: [CGFloat] = [0, 0.14, 0.28, 0.42, 0.56]
    let newHue = (h + shifts[index % shifts.count]).truncatingRemainder(dividingBy: 1.0)
    return Color(UIColor(hue: newHue, saturation: max(0.45, s * 0.9), brightness: max(0.55, b), alpha: a))
}

// MARK: - Section Label (available for both ProfileSheet and SavingsSplitView)

struct SectionLabel: View {
    let text: String
    let icon: String
    let colors: ThemeColors

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(colors.accent)
            Text(text)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)
        }
    }
}

// MARK: - Section Card Container

private struct ProfileSectionCard<Content: View>: View {
    let colors: ThemeColors
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                if #available(iOS 26, *) {
                    Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 20))
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                        }
                }
            }
            .padding(.horizontal, 20)
    }
}

// MARK: - Grail Thumbnail

private struct GrailAllocationThumbnail: View {
    let image: UIImage?
    let category: GrailCategory
    let colors: ThemeColors

    var body: some View {
        ZStack {
            Circle().fill(colors.accent.opacity(0.12)).frame(width: 44, height: 44)
            if let image {
                Image(uiImage: image).resizable().scaledToFit().frame(width: 36, height: 36)
            } else {
                Image(systemName: category.iconName)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(colors.accent)
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
                .fill(.ultraThinMaterial).opacity(0.62)
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - Profile Sheet Header

private struct ProfileSheetHeader: View {
    var colors: ThemeColors
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) { closeButton; titlePill }
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
                        .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
                }
            }
        }
    }

    private var titlePill: some View {
        Group {
            if #available(iOS 26, *) {
                headerContent.glassEffect(.regular, in: .capsule)
            } else {
                headerContent.background(
                    Capsule().fill(.ultraThinMaterial)
                        .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
            }
        }
    }

    private var headerContent: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(colors.accent.opacity(0.12)).frame(width: 32, height: 32)
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(colors.accent)
            }
            Text("Profile").font(.body).fontWeight(.semibold).foregroundStyle(Color.saldoPrimary)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(height: 56).frame(maxWidth: .infinity)
    }
}

// MARK: - Sheet Enhancements

private struct ProfileSheetEnhancements: ViewModifier {
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(cornerRadius).presentationBackground(.clear)
        } else {
            content
        }
    }
}

#Preview {
    Color.gray.opacity(0.3).ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ProfileSheet(colors: AppTheme.moderate.colors, grailPreviews: [])
        }
}
