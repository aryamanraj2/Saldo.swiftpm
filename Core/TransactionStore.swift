import SwiftUI

// MARK: - Transaction Record

struct TransactionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let icon: String
    let category: String
    let type: RecordType
    let amountInPrimary: Double
    let originalAmount: Double
    let originalCurrency: String
    let date: Date
    let source: RecordSource

    enum RecordType: String, Codable {
        case expense
        case income
    }

    enum RecordSource: String, Codable {
        case manual
        case receipt
        case subscription
        case allowance
        case savings
    }

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        category: String,
        type: RecordType,
        amountInPrimary: Double,
        originalAmount: Double,
        originalCurrency: String,
        date: Date = Date(),
        source: RecordSource
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.category = category
        self.type = type
        self.amountInPrimary = amountInPrimary
        self.originalAmount = originalAmount
        self.originalCurrency = originalCurrency
        self.date = date
        self.source = source
    }

    // MARK: - Display Helpers

    var subtitle: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var formattedAmount: String {
        let prefix = type == .income ? "+" : "-"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numStr = formatter.string(from: NSNumber(value: amountInPrimary)) ?? "\(amountInPrimary)"
        return "\(prefix)\(AppCurrency.currentSymbol)\(numStr)"
    }
}

// MARK: - Transaction Store

@MainActor
@Observable
final class TransactionStore {
    static let shared = TransactionStore()

    private(set) var transactions: [TransactionRecord] = []

    // MARK: - Persistence

    private static var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("Saldo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("transactions.json")
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func load() {
        guard FileManager.default.fileExists(atPath: Self.fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: Self.fileURL)
            transactions = try Self.decoder.decode([TransactionRecord].self, from: data)
            transactions.sort { $0.date > $1.date }
        } catch {
            // Silently fail — non-critical
        }
    }

    func add(_ record: TransactionRecord) {
        transactions.insert(record, at: 0)
        save()
    }

    private func save() {
        do {
            let data = try Self.encoder.encode(transactions)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
            // Silently fail — non-critical
        }
    }

    // MARK: - Balance Management

    var currentBalance: Double {
        Double(OnboardingManager.shared.userBalance)
    }

    func adjustBalance(by amount: Double) {
        let newBalance = Double(OnboardingManager.shared.userBalance) + amount
        OnboardingManager.shared.userBalance = Int(newBalance.rounded())
    }

    // MARK: - Currency Conversion

    static func convertToPrimary(amount: Double, fromSymbol: String) -> Double {
        let fromCurrency = AppCurrency.allCases.first(where: { $0.symbol == fromSymbol })
            ?? AppCurrency.allCases.first(where: { $0.rawValue == fromSymbol })
            ?? CurrencyManager.shared.selected
        let target = CurrencyManager.shared.selected
        if fromCurrency == target { return amount }
        return fromCurrency.convert(amount, to: target)
    }

    // MARK: - Expense Queries

    func expensesToday() -> Double {
        let cal = Calendar.current
        let now = Date()
        return transactions
            .filter { $0.type == .expense && cal.isDateInToday($0.date) && $0.source != .savings }
            .reduce(0) { $0 + $1.amountInPrimary }
    }

    func expensesThisWeek() -> Double {
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return transactions
            .filter { $0.type == .expense && $0.date >= weekStart && $0.source != .savings }
            .reduce(0) { $0 + $1.amountInPrimary }
    }

    func expensesThisMonth() -> Double {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        let monthStart = cal.date(from: comps) ?? now
        return transactions
            .filter { $0.type == .expense && $0.date >= monthStart && $0.source != .savings }
            .reduce(0) { $0 + $1.amountInPrimary }
    }

    // MARK: - Data Points for Graph

    func dataPointsForPeriod(_ period: SpendPeriod) -> [SpendDataPoint] {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .day:
            var hourlyTotals = [Double](repeating: 0, count: 24)
            let todayStart = calendar.startOfDay(for: now)
            for tx in transactions where tx.type == .expense && tx.source != .savings {
                guard calendar.isDate(tx.date, inSameDayAs: now) else { continue }
                let hour = calendar.component(.hour, from: tx.date)
                hourlyTotals[hour] += tx.amountInPrimary
            }
            return hourlyTotals.enumerated().map { hour, amount in
                let date = calendar.date(byAdding: .hour, value: hour, to: todayStart) ?? now
                return SpendDataPoint(timestamp: date, amount: amount)
            }

        case .week:
            var dailyTotals = [Double](repeating: 0, count: 7)
            for dayOffset in 0..<7 {
                let targetDate = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: now)!
                for tx in transactions where tx.type == .expense && tx.source != .savings {
                    if calendar.isDate(tx.date, inSameDayAs: targetDate) {
                        dailyTotals[dayOffset] += tx.amountInPrimary
                    }
                }
            }
            return dailyTotals.enumerated().map { offset, amount in
                let date = calendar.date(byAdding: .day, value: -(6 - offset), to: now) ?? now
                return SpendDataPoint(timestamp: date, amount: amount)
            }

        case .month:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let monthStart = calendar.date(from: comps)!
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)!.count
            var dailyTotals = [Double](repeating: 0, count: daysInMonth)
            for tx in transactions where tx.type == .expense && tx.source != .savings {
                let txComps = calendar.dateComponents([.year, .month, .day], from: tx.date)
                guard txComps.year == comps.year, txComps.month == comps.month,
                      let day = txComps.day, day >= 1, day <= daysInMonth else { continue }
                dailyTotals[day - 1] += tx.amountInPrimary
            }
            return dailyTotals.enumerated().map { index, amount in
                let date = calendar.date(byAdding: .day, value: index, to: monthStart) ?? now
                return SpendDataPoint(timestamp: date, amount: amount)
            }
        }
    }

    // MARK: - Consistency (Logged Days)

    func loggedDaysThisMonth() -> Set<Int> {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        var days = Set<Int>()
        for tx in transactions {
            let txComps = cal.dateComponents([.year, .month, .day], from: tx.date)
            if txComps.year == comps.year, txComps.month == comps.month,
               let day = txComps.day {
                days.insert(day)
            }
        }
        return days
    }

    // MARK: - Recent Transactions

    func recentTransactions(limit: Int = 3) -> [TransactionRecord] {
        Array(transactions.prefix(limit))
    }

    // MARK: - Subscription Pro-Rating

    func subscriptionCostForPeriod(_ period: SpendPeriod, subscriptions: [SubscriptionItem]) -> Double {
        let target = CurrencyManager.shared.selected
        var totalMonthly: Double = 0

        for sub in subscriptions {
            let fromCurrency = AppCurrency.allCases.first(where: { $0.symbol == sub.currency })
                ?? CurrencyManager.shared.selected
            let convertedAmount = fromCurrency.convert(sub.amount, to: target)
            totalMonthly += convertedAmount
        }

        switch period {
        case .day:   return totalMonthly / 30.0
        case .week:  return totalMonthly / 4.33
        case .month: return totalMonthly
        }
    }

    // MARK: - Allowance Reset

    func checkAllowanceReset(grailStore: GrailStore) {
        let manager = OnboardingManager.shared
        let calendar = Calendar.current
        let now = Date()
        let allowanceDay = manager.allowanceDay

        // Determine last reset
        let lastReset = manager.lastResetDate ?? calendar.date(byAdding: .month, value: -2, to: now)!

        // Find the most recent allowance day
        var comps = calendar.dateComponents([.year, .month], from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 28
        comps.day = min(allowanceDay, daysInMonth)
        guard let resetDate = calendar.date(from: comps) else { return }

        // If resetDate is in the future this month, use last month's
        let effectiveResetDate: Date
        if resetDate > now {
            effectiveResetDate = calendar.date(byAdding: .month, value: -1, to: resetDate) ?? resetDate
        } else {
            effectiveResetDate = resetDate
        }

        // Already reset for this period
        if lastReset >= effectiveResetDate { return }

        // --- PERFORM RESET ---

        // 1. Calculate savings (remaining balance, clamped to 0)
        let currentBal = Double(manager.userBalance)
        let savings = max(currentBal, 0)

        // 2. Update totalSaved
        let currentTotalSaved = UserDefaults.standard.double(forKey: "totalSaved")
        UserDefaults.standard.set(currentTotalSaved + savings, forKey: "totalSaved")

        // 3. Distribute savings to grails
        if savings > 0 {
            let allocations = manager.grailAllocations
            for grail in grailStore.grails {
                let percent = allocations[grail.id.uuidString] ?? 0
                if percent > 0 {
                    let grailDeposit = savings * Double(percent) / 100.0
                    Task {
                        await grailStore.addDeposit(
                            to: grail.id,
                            amount: grailDeposit,
                            note: "Auto-savings"
                        )
                    }
                }
            }

            // Record savings transaction
            let savingsRecord = TransactionRecord(
                title: "Monthly Savings",
                icon: "leaf.fill",
                category: "Savings",
                type: .expense,
                amountInPrimary: savings,
                originalAmount: savings,
                originalCurrency: CurrencyManager.shared.selected.rawValue,
                date: effectiveResetDate,
                source: .savings
            )
            add(savingsRecord)
        }

        // 4. Reset balance to allowance
        manager.userBalance = manager.userAllowance

        // 5. Record allowance credit
        let allowanceRecord = TransactionRecord(
            title: "Monthly Allowance",
            icon: "banknote.fill",
            category: "Allowance",
            type: .income,
            amountInPrimary: Double(manager.userAllowance),
            originalAmount: Double(manager.userAllowance),
            originalCurrency: CurrencyManager.shared.selected.rawValue,
            date: effectiveResetDate,
            source: .allowance
        )
        add(allowanceRecord)

        // 6. Update last reset date
        manager.lastResetDate = effectiveResetDate
    }
}
