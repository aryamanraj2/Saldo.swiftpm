import SwiftUI

// MARK: - Edit Subscription Sheet
struct EditSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    var subscription: SubscriptionItem
    var onSave: ((SubscriptionItem) -> Void)? = nil
    var onRemove: ((UUID) -> Void)? = nil

    @State private var amount: String
    @State private var selectedCurrency: CurrencyOption
    @FocusState private var isAmountFocused: Bool

    init(colors: ThemeColors, subscription: SubscriptionItem, onSave: ((SubscriptionItem) -> Void)? = nil, onRemove: ((UUID) -> Void)? = nil) {
        self.colors = colors
        self.subscription = subscription
        self.onSave = onSave
        self.onRemove = onRemove
        self._amount = State(initialValue: String(format: "%.2f", subscription.amount))
        self._selectedCurrency = State(initialValue: CurrencyOption.options.first(where: { $0.symbol == subscription.currency }) ?? CurrencyOption.options[0])
    }

    var canSave: Bool {
        !amount.isEmpty && Double(amount) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            EditSubscriptionSheetHeader(colors: colors, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // MARK: - Main Content
            ScrollView {
                VStack(spacing: 28) {
                    // Icon Preview (read-only)
                    SubscriptionIconPreview(
                        category: subscription.category,
                        name: subscription.name,
                        colors: colors
                    )
                    .padding(.top, 20)

                    // Subscription Name (read-only)
                    VStack(spacing: 4) {
                        Text(subscription.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.saldoPrimary)

                        Text(subscription.category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(Color.saldoSecondary)
                    }

                    // Amount & Currency (editable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
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
                            TextField("0.00", text: $amount)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background {
                                    if #available(iOS 26, *) {
                                        Color.clear
                                            .glassEffect(.regular, in: .rect(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(
                                                        isAmountFocused ? colors.accent.opacity(0.4) : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.saldoSecondary.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(
                                                        isAmountFocused ? colors.accent.opacity(0.4) : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    }
                                }
                                .focused($isAmountFocused)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Save Button
                    Button(action: {
                        guard let amountValue = Double(amount) else { return }
                        var updated = subscription
                        updated.amount = amountValue
                        updated.currency = selectedCurrency.symbol
                        onSave?(updated)
                        dismiss()
                    }) {
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

                    // Divider
                    Rectangle()
                        .fill(Color.saldoSeparator)
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    // Remove Button
                    Button(role: .destructive) {
                        onRemove?(subscription.id)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Remove Subscription")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
        .presentationDetents([.fraction(0.85)])
        .presentationDragIndicator(.visible)
        .modifier(EditSubscriptionSheetEnhancements(cornerRadius: 32))
    }
}

// MARK: - Edit Subscription Sheet Header
struct EditSubscriptionSheetHeader: View {
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

            // Title pill
            if #available(iOS 26, *) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }

                    Text("Edit Subscription")
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

                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colors.accent)
                    }

                    Text("Edit Subscription")
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
private struct EditSubscriptionSheetEnhancements: ViewModifier {
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
            EditSubscriptionSheet(
                colors: AppTheme.moderate.colors,
                subscription: SubscriptionItem(
                    name: "Spotify",
                    amount: 119.0,
                    currency: CurrencyManager.shared.symbol,
                    category: .music
                )
            )
        }
}
