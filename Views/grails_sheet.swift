import SwiftUI

// MARK: - Presentation Detent for Grail Sheet
extension PresentationDetent {
    static let grailLarge = PresentationDetent.fraction(0.85)
}

// MARK: - Grail Sheet
struct GrailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    
    // Binding to save the grail
    var onSave: ((GrailItem) -> Void)? = nil
    
    // Form State
    @State private var grailName: String = ""
    @State private var targetAmount: String = ""
    @State private var selectedCurrency: CurrencyOption = CurrencyOption.options[0]
    @State private var selectedCategory: GrailCategory = .sneakers
    @State private var selectedStrictness: GrailStrictness = .balanced
    
    @FocusState private var isNameFocused: Bool
    @FocusState private var isAmountFocused: Bool
    
    var canSave: Bool {
        !grailName.isEmpty && !targetAmount.isEmpty && Double(targetAmount) != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header with Cancel Button (Glass Style)
            GrailSheetHeader(colors: colors, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // MARK: - Main Content Area
            ScrollView {
                VStack(spacing: 28) {
                    // Icon Preview
                    GrailIconPreview(
                        category: selectedCategory,
                        name: grailName,
                        colors: colors
                    )
                    .padding(.top, 20)
                    
                    // Category Picker (Pill-shaped chips)
                    GrailCategoryPicker(
                        selectedCategory: $selectedCategory,
                        colors: colors
                    )
                    
                    // Form Fields
                    VStack(spacing: 24) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's the name of your Grail?")
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
                        
                        // Amount & Currency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How much do you want to save?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)
                            
                            HStack(spacing: 12) {
                                // Currency Selector
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
                                
                                // Amount Input
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
                        
                        // Strictness Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How strict should your Grail be?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)
                            
                            HStack(spacing: 10) {
                                ForEach(GrailStrictness.allCases) { strictness in
                                    StrictnessOption(
                                        strictness: strictness,
                                        isSelected: selectedStrictness == strictness,
                                        colors: colors
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedStrictness = strictness
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Save Button
                    Button(action: {
                        guard let amountValue = Double(targetAmount) else { return }
                        let grail = GrailItem(
                            name: grailName,
                            targetAmount: amountValue,
                            currency: selectedCurrency.symbol,
                            category: selectedCategory,
                            strictness: selectedStrictness
                        )
                        onSave?(grail)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Add Grail")
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
                    .padding(.bottom, 40)
                }
            }
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

struct StrictnessOption: View {
    var strictness: GrailStrictness
    var isSelected: Bool
    var colors: ThemeColors
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: strictness.iconName)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(strictness.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? Color.white : colors.accent)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colors.accent)
                } else {
                    if #available(iOS 26, *) {
                        Color.clear
                            .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(colors.accent.opacity(0.1))
                    }
                }
            }
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(colors.accent.opacity(0.2), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct GrailIconPreview: View {
    var category: GrailCategory
    var name: String
    var colors: ThemeColors
    
    var body: some View {
        ZStack {
            Circle()
                .fill(colors.accent.opacity(0.12))
                .frame(width: 100, height: 100)
            
            Group {
                if category == .misc && !name.isEmpty {
                    // Show first letter for misc
                    Text(String(name.prefix(1).uppercased()))
                        .font(.system(size: 36, weight: .bold))
                        .id("text-\(name.prefix(1))")
                } else {
                    // Show SF Symbol
                    Image(systemName: category.iconName)
                        .font(.system(size: 40, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .id(category.iconName)
                }
            }
            .foregroundStyle(colors.accent)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: category)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: name)
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
                            colors: colors,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            }
                        )
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
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? Color.white : colors.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? colors.accent : colors.accent.opacity(0.12))
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
            // Cancel button with glass effect
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
            
            // Title pill (matches scan receipt bar style)
            if #available(iOS 26, *) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "crown.fill")
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
                        
                        Image(systemName: "crown.fill")
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