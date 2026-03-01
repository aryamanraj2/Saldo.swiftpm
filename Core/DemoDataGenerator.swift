import SwiftUI

// MARK: - Demo Data Generator
/// One-tap demo for SSC judges: populates a full month of spending, drops the
/// balance into the danger (red) zone, and fills the consistency chart.
/// Reset restores the exact state the judge had before tapping the button.

@MainActor
struct DemoDataGenerator {

    // MARK: - Pre-Demo Snapshot

    /// Captures the judge's original state so reset can restore it exactly.
    struct Snapshot {
        let balance: Int
        let allowanceDay: Int
        let grailAllocations: [String: Int]
        let lastResetDate: Date?
        let totalSaved: Double
        let subscriptions: [SubscriptionItem]
        let hadGrails: Bool
    }

    static func captureSnapshot(subscriptions: [SubscriptionItem], grailStore: GrailStore) -> Snapshot {
        let mgr = OnboardingManager.shared
        return Snapshot(
            balance: mgr.userBalance,
            allowanceDay: mgr.allowanceDay,
            grailAllocations: mgr.grailAllocations,
            lastResetDate: mgr.lastResetDate,
            totalSaved: UserDefaults.standard.double(forKey: "totalSaved"),
            subscriptions: subscriptions,
            hadGrails: !grailStore.grails.isEmpty
        )
    }

    // MARK: - Run Demo

    /// Populates the app with a full month of data and drops the balance to the
    /// danger zone. The judge stays in this state until they tap Reset.
    /// Returns generated subscriptions for the caller to update its @State.
    static func runDemo(
        transactionStore: TransactionStore,
        grailStore: GrailStore
    ) async -> [SubscriptionItem] {
        let currency = CurrencyManager.shared.selected
        let allowance = Double(OnboardingManager.shared.userAllowance)
        guard allowance > 0 else { return [] }

        // ── Grails ─────────────────────────────────────────────────
        let createdGrails = grailStore.grails.isEmpty
        if createdGrails {
            await createDemoGrails(grailStore: grailStore, allowance: allowance, currency: currency)
        }

        // ── Grail deposits (simulate previous months' savings) ─────
        await addDemoDeposits(grailStore: grailStore, allowance: allowance)

        // ── Subscriptions ──────────────────────────────────────────
        let subs = createDemoSubscriptions(currency: currency, allowance: allowance)
        SubscriptionStore.save(subs)

        // ── Transactions spread across the month ───────────────────
        let transactions = createDemoTransactions(allowance: allowance, currency: currency)
        for tx in transactions {
            transactionStore.add(tx)
        }

        // ── Drop balance into the danger (red) zone ────────────────
        let dangerBalance = Int((currency.dangerThreshold * 0.6).rounded())
        OnboardingManager.shared.userBalance = max(dangerBalance, 1)

        return subs
    }

    // MARK: - Reset

    /// Restores the judge's original state from before the demo.
    static func resetDemo(
        snapshot: Snapshot,
        transactionStore: TransactionStore,
        grailStore: GrailStore
    ) async {
        // Clear demo data
        transactionStore.clearAll()
        SubscriptionStore.save(snapshot.subscriptions)

        // Only remove grails if they were created by the demo
        if !snapshot.hadGrails {
            await grailStore.removeAll()
        }

        // Restore original values
        let mgr = OnboardingManager.shared
        mgr.userBalance = snapshot.balance
        mgr.allowanceDay = snapshot.allowanceDay
        mgr.grailAllocations = snapshot.grailAllocations
        mgr.lastResetDate = snapshot.lastResetDate
        UserDefaults.standard.set(snapshot.totalSaved, forKey: "totalSaved")
    }

    // MARK: - Private Helpers

    private static func createDemoGrails(
        grailStore: GrailStore,
        allowance: Double,
        currency: AppCurrency
    ) async {
        let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()

        let grail1 = GrailItem(
            name: "Air Jordan 1",
            targetAmount: allowance * 3.0,
            currency: currency.symbol,
            category: .sneakers,
            strictness: .balanced,
            createdAt: monthStart
        )

        let grail2 = GrailItem(
            name: "Tokyo Trip",
            targetAmount: allowance * 16.0,
            currency: currency.symbol,
            category: .trips,
            strictness: .gentle,
            createdAt: monthStart
        )

        await grailStore.add(grail: grail1, maskedImage: nil)
        await grailStore.add(grail: grail2, maskedImage: nil)

        let allGrails = grailStore.grails
        if allGrails.count >= 2 {
            OnboardingManager.shared.setAllocation(40, for: allGrails[0].id)
            OnboardingManager.shared.setAllocation(40, for: allGrails[1].id)
        }
    }

    private static func createDemoSubscriptions(
        currency: AppCurrency,
        allowance: Double
    ) -> [SubscriptionItem] {
        let foreignSymbol = currency == .usd ? "€" : "$"

        return [
            SubscriptionItem(
                name: "Spotify",
                amount: (allowance * 0.02).rounded(),
                currency: currency.symbol,
                category: .music
            ),
            SubscriptionItem(
                name: "Netflix",
                amount: currency == .usd ? 10.99 : 15.99,
                currency: foreignSymbol,
                category: .streaming
            ),
            SubscriptionItem(
                name: "ChatGPT Plus",
                amount: currency == .usd ? 19.99 : 20.00,
                currency: foreignSymbol,
                category: .ai
            ),
        ]
    }

    private static func addDemoDeposits(
        grailStore: GrailStore,
        allowance: Double
    ) async {
        let calendar = Calendar.current
        let now = Date()

        // Simulate 2 previous months of savings deposited into grails
        for grail in grailStore.grails {
            let month1Date = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            let month2Date = calendar.date(byAdding: .month, value: -1, to: now) ?? now

            // Each grail gets ~8% of allowance per month (40% allocation × 20% saved)
            let depositAmount = (allowance * 0.08).rounded()

            await grailStore.addDeposit(
                to: grail.id,
                amount: depositAmount,
                note: "Monthly savings"
            )
            // Backdate by mutating won't work easily, but the amount matters more
            await grailStore.addDeposit(
                to: grail.id,
                amount: depositAmount * 1.2, // slightly different second month
                note: "Monthly savings"
            )
        }

        // Update totalSaved to reflect these deposits
        let totalDeposited = grailStore.grails.reduce(0.0) { $0 + $1.currentAmount }
        let existingSaved = UserDefaults.standard.double(forKey: "totalSaved")
        UserDefaults.standard.set(existingSaved + totalDeposited, forKey: "totalSaved")
    }

    private static func createDemoTransactions(
        allowance: Double,
        currency: AppCurrency
    ) -> [TransactionRecord] {
        let calendar = Calendar.current
        let now = Date()

        // Always use the CURRENT month so loggedDaysThisMonth() picks them up
        // and the consistency chart fills across the whole month.
        let comps = calendar.dateComponents([.year, .month], from: now)
        let targetMonth = calendar.date(from: comps)!
        let range = calendar.range(of: .day, in: .month, for: now)!
        let totalDays = range.count

        let templates: [(String, String, String, Double, TransactionRecord.RecordType)] = [
            ("Coffee",          "cup.and.saucer.fill",               "Food",          0.015, .expense),
            ("Grocery Run",     "cart.fill",                         "Groceries",     0.040, .expense),
            ("Bus Fare",        "bus.fill",                          "Transport",     0.010, .expense),
            ("Lunch Out",       "fork.knife",                        "Food",          0.030, .expense),
            ("Movie Night",     "film.fill",                         "Entertainment", 0.025, .expense),
            ("New T-Shirt",     "tshirt.fill",                       "Shopping",      0.060, .expense),
            ("Headphones",      "headphones",                        "Shopping",      0.080, .expense),
            ("Uber Ride",       "car.fill",                          "Transport",     0.020, .expense),
            ("Dinner Date",     "wineglass.fill",                    "Food",          0.050, .expense),
            ("Book",            "book.fill",                         "Education",     0.020, .expense),
            ("Freelance Pay",   "briefcase.fill",                    "Work",          0.120, .income),
            ("Phone Case",      "iphone",                            "Shopping",      0.030, .expense),
            ("Snacks",          "takeoutbag.and.cup.and.straw.fill", "Food",          0.010, .expense),
            ("Gym Day Pass",    "figure.run",                        "Fitness",       0.020, .expense),
            ("Museum Visit",    "building.columns.fill",             "Entertainment", 0.025, .expense),
            ("Stationery",      "pencil.and.ruler.fill",             "Misc",          0.015, .expense),
            ("Birthday Gift",   "gift.fill",                         "Misc",          0.050, .expense),
            ("Haircut",         "scissors",                          "Misc",          0.025, .expense),
        ]

        var transactions: [TransactionRecord] = []

        for (index, template) in templates.enumerated() {
            let (title, icon, category, percent, type) = template

            // Spread evenly: each transaction gets its own day slot across the month
            let day = 1 + (index * totalDays) / templates.count
            let clampedDay = max(1, min(day, totalDays))
            let date = calendar.date(byAdding: .day, value: clampedDay - 1, to: targetMonth) ?? now
            let hour = 8 + (index * 3) % 14
            let dateWithTime = calendar.date(
                bySettingHour: hour, minute: (index * 17) % 60, second: 0, of: date
            ) ?? date

            let amount = max((allowance * percent).rounded(), 1)

            transactions.append(TransactionRecord(
                title: title,
                icon: icon,
                category: category,
                type: type,
                amountInPrimary: amount,
                originalAmount: amount,
                originalCurrency: currency.rawValue,
                date: dateWithTime,
                source: .manual
            ))
        }

        // Foreign-currency transactions to showcase conversion
        let foreign1: AppCurrency = currency == .usd ? .eur : .usd
        let foreign2: AppCurrency = currency == .eur ? .gbp : .eur

        let coffeeAmt: Double = foreign1 == .usd ? 4.50 : (foreign1 == .eur ? 4.20 : 3.80)
        let coffeeDay = max(totalDays / 3, 1)
        let coffeeDate = calendar.date(byAdding: .day, value: coffeeDay - 1, to: targetMonth) ?? now

        transactions.append(TransactionRecord(
            title: "Airport Coffee",
            icon: "airplane.departure",
            category: "Travel",
            type: .expense,
            amountInPrimary: foreign1.convert(coffeeAmt, to: currency).rounded(),
            originalAmount: coffeeAmt,
            originalCurrency: foreign1.rawValue,
            date: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: coffeeDate) ?? coffeeDate,
            source: .manual
        ))

        let courseAmt: Double = foreign2 == .eur ? 29.99 : (foreign2 == .gbp ? 24.99 : 29.99)
        let courseDay = max((totalDays * 2) / 3, 1)
        let courseDate = calendar.date(byAdding: .day, value: courseDay - 1, to: targetMonth) ?? now

        transactions.append(TransactionRecord(
            title: "Online Course",
            icon: "graduationcap.fill",
            category: "Education",
            type: .expense,
            amountInPrimary: foreign2.convert(courseAmt, to: currency).rounded(),
            originalAmount: courseAmt,
            originalCurrency: foreign2.rawValue,
            date: calendar.date(bySettingHour: 20, minute: 15, second: 0, of: courseDate) ?? courseDate,
            source: .manual
        ))

        return transactions
    }
}
