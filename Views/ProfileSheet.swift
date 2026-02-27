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

    private var daysInCurrentMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date()) ?? 1..<32
        return range.count
    }

    private func daySuffix(for day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
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
            && totalAllocation <= 100
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

    // MARK: - Day Section

    private var daySection: some View {
        ProfileSectionCard(colors: colors) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Allowance Day", icon: "calendar", colors: colors)

                Text("Day your allowance arrives every month")
                    .font(.caption)
                    .foregroundStyle(Color.saldoSecondary)
                    .padding(.bottom, 2)

                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
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

                    Menu {
                        Picker("Select Day", selection: $selectedDay) {
                            ForEach(1...daysInCurrentMonth, id: \.self) { day in
                                Text("\(day)\(daySuffix(for: day))").tag(day)
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(selectedDay)\(daySuffix(for: selectedDay)) of the month")
                                .font(.title3).fontWeight(.semibold).foregroundStyle(Color.saldoPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.subheadline)
                                .foregroundStyle(Color.saldoSecondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background { GlassBackgroundField(isFocused: false, colors: colors) }
                        .contentShape(Rectangle())
                    }
                }
            }
        }
    }

    private var allocationSection: some View {
        Group {
            if grailPreviews.isEmpty {
                EmptyView()
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

        if !grailPreviews.isEmpty {
            var loaded: [String: Double] = [:]
            for grail in grailPreviews {
                loaded[grail.id.uuidString] = Double(manager.grailAllocations[grail.id.uuidString] ?? 0)
            }
            let sum = loaded.values.reduce(0, +)
            if sum == 0 {
                // By default allocate something if empty
                let base = min(100.0 / Double(grailPreviews.count), 50.0).rounded()
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
        if !grailPreviews.isEmpty {
            manager.grailAllocations = intAllocations
        }
        dismiss()
    }
}

// MARK: - Savings Split View

struct SavingsSplitView: View {
    let grails: [GrailPreviewItem]
    @Binding var allocations: [String: Double]
    let accentColor: Color

    private var totalAllocation: Double {
        allocations.values.reduce(0, +)
    }

    private var unallocated: Double {
        max(0, 100.0 - totalAllocation)
    }

    // Chart data model for the dynamic rendering rows
    struct Slice: Identifiable {
        let id: String
        let name: String
        let value: Double
        let color: Color
        let category: GrailCategory?
        let image: UIImage?
        let isGeneral: Bool
    }

    private var slices: [Slice] {
        var items = grails.enumerated().map { i, grail in
            Slice(
                id: grail.id.uuidString,
                name: grail.name,
                value: max(allocations[grail.id.uuidString] ?? 0, 0),
                color: grailPaletteColor(index: i, accent: accentColor),
                category: grail.category,
                image: grail.image,
                isGeneral: false
            )
        }
        
        items.append(
            Slice(
                id: "general_savings",
                name: "General Savings",
                value: unallocated,
                color: Color.saldoSecondary,
                category: nil,
                image: nil,
                isGeneral: true
            )
        )
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header row
            HStack {
                SectionLabel(text: "Savings Split", icon: "arrow.triangle.branch",
                             colors: ThemeColors(background: .clear, primary: Color.saldoPrimary,
                                                secondary: Color.saldoSecondary, accent: accentColor,
                                                backgroundBlob1: .clear, backgroundBlob2: .clear, backgroundBlob3: .clear))
                Spacer()
                Text("100% Total")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(Color.saldoSecondary)
            }

            // Legend + stepper rows
            VStack(spacing: 0) {
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    AllocationLegendRow(
                        slice: slice,
                        accentColor: accentColor,
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
    }

    private func stepAllocation(grailID: String, delta: Int) {
        guard grailID != "general_savings" else { return } // General savings is computed
        let current = allocations[grailID] ?? 0
        let proposed = max(0, min(100, current + Double(delta)))
        
        let available = 100.0 - totalAllocation + current
        let finalized = min(proposed, available)
        
        guard finalized != current else { return }
        allocations[grailID] = finalized

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Allocation Legend Row

private struct AllocationLegendRow: View {
    let slice: SavingsSplitView.Slice
    let accentColor: Color
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
                    .fill(slice.isGeneral ? Color.saldoSecondary.opacity(0.12) : slice.color.opacity(0.12))
                    .frame(width: 32, height: 32)
                if let img = slice.image {
                    Image(uiImage: img).resizable().scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: slice.isGeneral ? "safari.fill" : (slice.category?.iconName ?? "star.fill"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(slice.isGeneral ? Color.saldoSecondary : slice.color)
                }
            }

            // Name
            Text(slice.name)
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(Color.saldoPrimary)
                .lineLimit(1)

            Spacer()

            // Stepper/Lock
            HStack(spacing: 6) {
                if slice.isGeneral {
                    // Lock icon + value for General Savings
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.saldoSecondary.opacity(0.5))
                        .frame(width: 28, height: 28)
                        
                    Text("\(Int(slice.value.rounded()))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.saldoSecondary)
                        .frame(width: 44, alignment: .center)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.25), value: Int(slice.value.rounded()))
                        
                    Spacer().frame(width: 28) // Balancing space
                } else {
                    // Minus
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(slice.value > 0 ? slice.color : Color.saldoSecondary.opacity(0.3))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(slice.value > 0 ? slice.color.opacity(0.12) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(slice.value <= 0)

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
                            .foregroundStyle(slice.value < 100 ? slice.color : Color.saldoSecondary.opacity(0.3))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(slice.value < 100 ? slice.color.opacity(0.12) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(slice.value >= 100)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
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
