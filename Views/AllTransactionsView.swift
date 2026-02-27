import SwiftUI

struct TransactionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let date: Date
    let amount: Double
    let type: TransactionType
    
    enum TransactionType {
        case expense, income
    }
    
    var subtitle: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var formattedAmount: String {
        let prefix = type == .income ? "+" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        let formattedString = formatter.string(from: NSNumber(value: amount)) ?? "₹\(amount)"
        return "\(prefix)\(formattedString)"
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case amountHighest = "Amount (Highest)"
    case amountLowest = "Amount (Lowest)"
    
    var id: String { rawValue }
}

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case expenses = "Expenses"
    case income = "Income"
    
    var id: String { rawValue }
}

struct AllTransactionsView: View {
    var colors: ThemeColors
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedSort: SortOption = .dateNewest
    
    // Mock data based on the original HomeView with actual Date objects
    @State private var transactions: [TransactionItem] = [
        TransactionItem(icon: "basket.fill", title: "Grocery", date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, amount: 450.00, type: .expense),
        TransactionItem(icon: "music.note", title: "Spotify", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, amount: 119.00, type: .expense),
        TransactionItem(icon: "cup.and.saucer.fill", title: "Starbucks", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, amount: 350.00, type: .expense),
        TransactionItem(icon: "gamecontroller.fill", title: "Steam", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, amount: 899.00, type: .expense),
        TransactionItem(icon: "briefcase.fill", title: "Salary", date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, amount: 125000.00, type: .income),
        TransactionItem(icon: "car.fill", title: "Uber", date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, amount: 250.00, type: .expense),
        TransactionItem(icon: "film.fill", title: "Netflix", date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, amount: 199.00, type: .expense),
        TransactionItem(icon: "fork.knife", title: "Dinner", date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, amount: 1200.00, type: .expense),
        TransactionItem(icon: "dollarsign.arrow.circlepath", title: "Refund", date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, amount: 450.00, type: .income)
    ]
    
    var filteredAndSortedTransactions: [TransactionItem] {
        var result = transactions
        
        // 1. Filter
        switch selectedFilter {
        case .all: break
        case .expenses: result = result.filter { $0.type == .expense }
        case .income: result = result.filter { $0.type == .income }
        }
        
        // 2. Search
        if !searchText.isEmpty {
            result = result.filter { 
                $0.title.localizedStandardContains(searchText) ||
                $0.subtitle.localizedStandardContains(searchText)
            }
        }
        
        // 3. Sort
        switch selectedSort {
        case .dateNewest:
            result.sort { $0.date > $1.date }
        case .dateOldest:
            result.sort { $0.date < $1.date }
        case .amountHighest:
            result.sort { $0.amount > $1.amount }
        case .amountLowest:
            result.sort { $0.amount < $1.amount }
        }
        
        return result
    }
    
    var isFilteredOrSorted: Bool {
        selectedFilter != .all || selectedSort != .dateNewest
    }
    
    var body: some View {
        ZStack {
            CleanBackground(colors: colors)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Header Area
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your")
                                .font(.subheadline)
                                .foregroundStyle(Color.saldoSecondary)
                            Text("Transactions")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(colors.primary)
                                .animation(.easeInOut, value: colors.primary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 110)
                    
                    // Floating Liquid Glass Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(colors.primary.opacity(0.7))
                        
                        TextField("Search transactions", text: $searchText)
                            .font(.body)
                            .foregroundStyle(colors.primary)
                            .submitLabel(.search)
                        
                        if !searchText.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    searchText = ""
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(colors.primary.opacity(0.5))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    // Liquid Glass Styling
                    .background {
                        if #available(iOS 26, *) {
                            Color.clear
                                .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 10, x: 0, y: 4)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.4), lineWidth: 1)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    if filteredAndSortedTransactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.saldoSecondary)
                                .padding(.top, 40)
                            Text("No transactions found")
                                .font(.headline)
                                .foregroundStyle(colors.primary)
                            Text("Try a different search or filter.")
                                .font(.subheadline)
                                .foregroundStyle(Color.saldoSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredAndSortedTransactions) { transaction in
                                TransactionRow(
                                    icon: transaction.icon,
                                    title: transaction.title,
                                    subtitle: transaction.subtitle,
                                    amount: transaction.formattedAmount,
                                    colors: colors
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(edges: .top)
        }
        .appStoreStyleToolbar(
            triggerOffset: 60,
            beforeTrailing: { sortFilterMenu },
            afterTrailing: { sortFilterMenu },
            beforeCenter: { EmptyView() },
            afterCenter: {
                Text("Transactions")
                    .font(.headline)
                    .foregroundStyle(colors.primary)
            }
        )
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var sortFilterMenu: some View {
        Menu {
            Section("Sort By") {
                Picker("Sort By", selection: $selectedSort) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
            
            Section("Filter By Type") {
                Picker("Filter By Type", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
        } label: {
            Image(systemName: isFilteredOrSorted ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.title3)
                .foregroundStyle(isFilteredOrSorted ? colors.accent : colors.primary)
        }
    }
}
