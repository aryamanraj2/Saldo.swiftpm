import SwiftUI

// MARK: - Add Subscription Sheet (Interactive Design)
struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    
    // Binding to save the subscription
    var onSave: ((SubscriptionItem) -> Void)? = nil
    
    // Form State
    @State private var subscriptionName: String = ""
    @State private var amount: String = ""
    @State private var selectedCurrency: CurrencyOption = CurrencyOption.options[0]
    @State private var selectedCategory: SubscriptionCategory = .music
    
    @FocusState private var isNameFocused: Bool
    @FocusState private var isAmountFocused: Bool
    
    var canSave: Bool {
        !subscriptionName.isEmpty && !amount.isEmpty && Double(amount) != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header with Cancel Button (Glass Style)
            AddSubscriptionSheetHeader(colors: colors, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // MARK: - Main Content Area
            ScrollView {
                VStack(spacing: 28) {
                    // Icon Preview
                    SubscriptionIconPreview(
                        category: selectedCategory,
                        name: subscriptionName,
                        colors: colors
                    )
                    .padding(.top, 20)
                    
                    // Category Picker (Pill-shaped chips)
                    CategoryPicker(
                        selectedCategory: $selectedCategory,
                        colors: colors
                    )
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What is it?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)
                            
                            TextField("e.g., Spotify", text: $subscriptionName)
                                .font(.body)
                                .foregroundStyle(Color.saldoPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.saldoSecondary.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(
                                                    isNameFocused ? colors.accent.opacity(0.4) : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .focused($isNameFocused)
                        }
                        
                        // Amount & Currency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How much?")
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
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(colors.accent.opacity(0.12))
                                    )
                                }
                                
                                // Amount Input
                                TextField("0.00", text: $amount)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.saldoPrimary)
                                    .keyboardType(.decimalPad)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.saldoSecondary.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(
                                                        isAmountFocused ? colors.accent.opacity(0.4) : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    )
                                    .focused($isAmountFocused)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Save Button
                    Button(action: {
                        guard let amountValue = Double(amount) else { return }
                        let subscription = SubscriptionItem(
                            name: subscriptionName,
                            amount: amountValue,
                            currency: selectedCurrency.symbol,
                            category: selectedCategory
                        )
                        onSave?(subscription)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Save Subscription")
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
                    .padding(.bottom, 20)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheetGlassBackground(cornerRadius: 32)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .modifier(AddSubscriptionSheetEnhancements(cornerRadius: 32))
    }
}

// MARK: - Subscription Icon Preview
struct SubscriptionIconPreview: View {
    var category: SubscriptionCategory
    var name: String
    var colors: ThemeColors
    
    var body: some View {
        ZStack {
            Circle()
                .fill(colors.accent.opacity(0.12))
                .frame(width: 100, height: 100)
            
            if category == .misc && !name.isEmpty {
                // Show first letter for misc
                Text(String(name.prefix(1).uppercased()))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(colors.accent)
            } else {
                // Show SF Symbol
                Image(systemName: category.iconName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }
        }
    }
}

// MARK: - Category Picker (Pill-shaped chips)
struct CategoryPicker: View {
    @Binding var selectedCategory: SubscriptionCategory
    var colors: ThemeColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.saldoPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SubscriptionCategory.allCases) { category in
                        CategoryChip(
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

// MARK: - Category Chip
struct CategoryChip: View {
    var category: SubscriptionCategory
    var isSelected: Bool
    var colors: ThemeColors
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
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

// MARK: - Add Subscription Sheet Header (Matches FloatingScanBar Style)
struct AddSubscriptionSheetHeader: View {
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
                        
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }
                    
                    Text("New Subscription")
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
                        
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }
                    
                    Text("New Subscription")
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

// MARK: - Sheet Presentation Enhancements
private struct AddSubscriptionSheetEnhancements: ViewModifier {
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
            AddSubscriptionSheet(colors: AppTheme.moderate.colors)
        }
}
