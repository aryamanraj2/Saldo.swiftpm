import SwiftUI

// MARK: - Transaction Type
enum TransactionType: String, CaseIterable, Identifiable {
    case expense = "Payment"
    case income = "Received"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .expense: return "arrow.up.right"
        case .income: return "arrow.down.left"
        }
    }
}

// MARK: - Manual Payment Sheet
struct ManualPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    var transactionStore: TransactionStore

    // Form State
    @State private var merchantName: String = ""
    @State private var amount: String = ""
    @State private var selectedCurrency: CurrencyOption = CurrencyOption.options[0]
    @State private var selectedCategory: PaymentCategory = .food
    @State private var transactionType: TransactionType = .expense

    @FocusState private var isNameFocused: Bool
    @FocusState private var isAmountFocused: Bool

    private var canSave: Bool {
        !merchantName.isEmpty && !amount.isEmpty && Double(amount) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            ManualPaymentSheetHeader(colors: colors, transactionType: transactionType, onCancel: { dismiss() })
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // MARK: - Form
            ScrollView {
                VStack(spacing: 28) {
                    // Icon Preview
                    ZStack {
                        Circle()
                            .fill(colors.accent.opacity(0.12))
                            .frame(width: 100, height: 100)

                        Image(systemName: selectedCategory.iconName)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(colors.accent)
                            .contentTransition(.symbolEffect(.replace))
                            .id(selectedCategory.iconName)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedCategory)
                    .padding(.top, 20)

                    // Category Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.saldoPrimary)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(PaymentCategory.allCases) { category in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: category.iconName)
                                                .font(.system(size: 14, weight: .semibold))
                                                .symbolVariant(selectedCategory == category ? .fill : .none)

                                            Text(category.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundStyle(selectedCategory == category ? Color.white : colors.accent)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == category ? colors.accent : colors.accent.opacity(0.12))
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    selectedCategory == category ? Color.clear : colors.accent.opacity(0.3),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Form Fields
                    VStack(spacing: 20) {
                        // Merchant Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text(transactionType == .expense ? "Paid to" : "Received from")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)

                            TextField(transactionType == .expense ? "e.g., Swiggy, Amazon" : "e.g., John, Salary", text: $merchantName)
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
                            Text("Amount")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)

                            HStack(spacing: 12) {
                                // Currency Selector
                                Menu {
                                    ForEach(CurrencyOption.options) { option in
                                        Button {
                                            selectedCurrency = option
                                        } label: {
                                            HStack {
                                                Text("\(option.symbol) \(option.code)")
                                                if selectedCurrency.code == option.code {
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

                        // Transaction Type (Liquid Glass Slider)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Transaction Type")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.saldoPrimary)
                            
                            LiquidGlassTransactionTypePicker(
                                selection: $transactionType,
                                colors: colors
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Save Button
                    Button {
                        guard let value = Double(amount) else { return }

                        // Convert to primary currency
                        let primaryAmount = TransactionStore.convertToPrimary(
                            amount: value,
                            fromSymbol: selectedCurrency.symbol
                        )

                        // Create transaction record
                        let record = TransactionRecord(
                            title: merchantName.trimmingCharacters(in: .whitespacesAndNewlines),
                            icon: selectedCategory.iconName,
                            category: selectedCategory.rawValue,
                            type: transactionType == .expense ? .expense : .income,
                            amountInPrimary: primaryAmount,
                            originalAmount: value,
                            originalCurrency: selectedCurrency.code,
                            source: .manual
                        )

                        transactionStore.add(record)

                        if transactionType == .expense {
                            transactionStore.adjustBalance(by: -primaryAmount)
                        } else {
                            transactionStore.adjustBalance(by: primaryAmount)
                        }

                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(transactionType == .expense ? "Add Payment" : "Add Received")
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
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.62)
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
                }
        }
        .presentationDetents([.fraction(0.85)])
        .presentationDragIndicator(.visible)
        .modifier(ManualPaymentSheetEnhancements(cornerRadius: 32))
    }
}

// MARK: - Liquid Glass Transaction Type Picker
struct LiquidGlassTransactionTypePicker: View {
    @Binding var selection: TransactionType
    var colors: ThemeColors
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases) { type in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selection = type
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: type.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .symbolEffect(.bounce, value: selection == type)
                        
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == type ? Color.white : Color.saldoPrimary.opacity(0.5))
                .background {
                    if selection == type {
                        ZStack {
                            if #available(iOS 26, *) {
                                Color.clear
                                    .glassEffect(.regular.interactive().tint(colors.accent.opacity(0.8)), in: .rect(cornerRadius: 16))
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(colors.accent)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                                    .liquidGlass(cornerRadius: 16, material: .regular, shadowColor: colors.accent)
                            }
                        }
                    }
                }
            }
        }
        .padding(6)
        .background {
            ZStack {
                if #available(iOS 26, *) {
                    Color.clear
                        .glassEffect(.regular, in: .rect(cornerRadius: 22))
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.saldoSecondary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.saldoSecondary.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Payment Categories
enum PaymentCategory: String, CaseIterable, Identifiable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case entertainment = "Fun"
    case health = "Health"
    case other = "Other"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .bills: return "bolt.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Header
private struct ManualPaymentSheetHeader: View {
    var colors: ThemeColors
    var transactionType: TransactionType
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

                    Image(systemName: transactionType == .expense ? "plus.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(colors.accent)
                }

                Text(transactionType == .expense ? "Add Payment" : "Add Received")
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

// MARK: - Sheet Enhancements
private struct ManualPaymentSheetEnhancements: ViewModifier {
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
            ManualPaymentSheet(colors: AppTheme.moderate.colors, transactionStore: TransactionStore.shared)
        }
}
