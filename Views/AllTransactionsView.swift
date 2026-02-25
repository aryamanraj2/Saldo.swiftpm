import SwiftUI

struct TransactionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let amount: Double
    let type: TransactionType
    
    enum TransactionType {
        case expense, income
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

struct AllTransactionsView: View {
    var colors: ThemeColors
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case expenses = "Expenses"
        case income = "Income"
    }
    
    // Mock data based on the original HomeView
    @State private var transactions: [TransactionItem] = [
        TransactionItem(icon: "basket.fill", title: "Grocery", subtitle: "Today, 5:30 PM", amount: 450.00, type: .expense),
        TransactionItem(icon: "music.note", title: "Spotify", subtitle: "Yesterday", amount: 119.00, type: .expense),
        TransactionItem(icon: "cup.and.saucer.fill", title: "Starbucks", subtitle: "Yesterday", amount: 350.00, type: .expense),
        TransactionItem(icon: "gamecontroller.fill", title: "Steam", subtitle: "2 days ago", amount: 899.00, type: .expense),
        TransactionItem(icon: "briefcase.fill", title: "Salary", subtitle: "5 days ago", amount: 125000.00, type: .income),
        TransactionItem(icon: "car.fill", title: "Uber", subtitle: "1 week ago", amount: 250.00, type: .expense),
        TransactionItem(icon: "film.fill", title: "Netflix", subtitle: "1 week ago", amount: 199.00, type: .expense),
        TransactionItem(icon: "fork.knife", title: "Dinner", subtitle: "2 weeks ago", amount: 1200.00, type: .expense),
        TransactionItem(icon: "dollarsign.arrow.circlepath", title: "Refund", subtitle: "2 weeks ago", amount: 450.00, type: .income)
    ]
    
    var filteredTransactions: [TransactionItem] {
        var result = transactions
        
        // Apply filter
        switch selectedFilter {
        case .all: break
        case .expenses: result = result.filter { $0.type == .expense }
        case .income: result = result.filter { $0.type == .income }
        }
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter { 
                $0.title.localizedStandardContains(searchText) ||
                $0.subtitle.localizedStandardContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            CleanBackground(colors: colors)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Filters
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(FilterType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Transactions List
                    VStack(spacing: 12) {
                        if filteredTransactions.isEmpty {
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
                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(
                                    icon: transaction.icon,
                                    title: transaction.title,
                                    subtitle: transaction.subtitle,
                                    amount: transaction.formattedAmount,
                                    colors: colors
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search transactions")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}
