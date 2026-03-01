import SwiftUI
import FoundationModels

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole: Equatable {
        case user
        case assistant
        case system
    }

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Transaction Analyzer Tool

@available(iOS 26.0, *)
struct TransactionAnalyzerTool: Tool {
    let name = "analyzeTransactions"
    let description = """
        Retrieves and analyzes the user's transaction history, spending patterns, \
        subscriptions, balance, and savings data. Use this tool to understand the \
        user's financial behavior before providing advice.
        """

    @Generable
    struct Arguments {
        @Guide(description: "Analysis type: 'overview', 'high_value', 'recurring', 'categories', 'savings'")
        var analysisType: String
    }

    func call(arguments: Arguments) async throws -> String {
        let store = await TransactionStore.shared
        let manager = await OnboardingManager.shared
        let subscriptions = SubscriptionStore.load()
        let currencySymbol = await CurrencyManager.shared.symbol

        let transactions = await store.transactions

        switch arguments.analysisType {
        case "overview":
            return await buildOverview(
                transactions: transactions,
                manager: manager,
                subscriptions: subscriptions,
                currencySymbol: currencySymbol,
                store: store
            )

        case "high_value":
            return buildHighValueAnalysis(
                transactions: transactions,
                currencySymbol: currencySymbol
            )

        case "recurring":
            return buildRecurringAnalysis(
                transactions: transactions,
                subscriptions: subscriptions,
                currencySymbol: currencySymbol
            )

        case "categories":
            return buildCategoryAnalysis(
                transactions: transactions,
                currencySymbol: currencySymbol
            )

        case "savings":
            return await buildSavingsAnalysis(
                manager: manager,
                currencySymbol: currencySymbol
            )

        default:
            return await buildOverview(
                transactions: transactions,
                manager: manager,
                subscriptions: subscriptions,
                currencySymbol: currencySymbol,
                store: store
            )
        }
    }

    // MARK: - Analysis Builders

    @MainActor
    private func buildOverview(
        transactions: [TransactionRecord],
        manager: OnboardingManager,
        subscriptions: [SubscriptionItem],
        currencySymbol: String,
        store: TransactionStore
    ) -> String {
        let balance = Double(manager.userBalance)
        let allowance = Double(manager.userAllowance)
        let totalSaved = UserDefaults.standard.double(forKey: "totalSaved")

        let expenseTransactions = transactions.filter { $0.type == .expense && $0.source != .savings }
        let thisMonthExpenses = store.expensesThisMonth()
        let thisWeekExpenses = store.expensesThisWeek()
        let todayExpenses = store.expensesToday()

        let spendingRatio = allowance > 0 ? thisMonthExpenses / allowance : 0

        // Category breakdown
        var categoryTotals: [String: Double] = [:]
        for tx in expenseTransactions {
            categoryTotals[tx.category, default: 0] += tx.amountInPrimary
        }
        let topCategories = categoryTotals.sorted { $0.value > $1.value }.prefix(5)

        let subTotal = subscriptions.reduce(0.0) { $0 + $1.amount }

        let summary = """
        === FINANCIAL OVERVIEW ===
        Current Balance: \(currencySymbol)\(String(format: "%.0f", balance))
        Monthly Allowance: \(currencySymbol)\(String(format: "%.0f", allowance))
        Total Saved (Lifetime): \(currencySymbol)\(String(format: "%.0f", totalSaved))

        --- This Period ---
        Spent Today: \(currencySymbol)\(String(format: "%.0f", todayExpenses))
        Spent This Week: \(currencySymbol)\(String(format: "%.0f", thisWeekExpenses))
        Spent This Month: \(currencySymbol)\(String(format: "%.0f", thisMonthExpenses))
        Spending Ratio (Month/Allowance): \(String(format: "%.0f", spendingRatio * 100))%

        --- Top Spending Categories ---
        \(topCategories.map { "• \($0.key): \(currencySymbol)\(String(format: "%.0f", $0.value))" }.joined(separator: "\n"))

        --- Subscriptions ---
        Active Subscriptions: \(subscriptions.count)
        Total Monthly Subscription Cost: \(currencySymbol)\(String(format: "%.0f", subTotal))
        \(subscriptions.map { "• \($0.name): \(currencySymbol)\(String(format: "%.0f", $0.amount))/mo" }.joined(separator: "\n"))

        Total Transactions Recorded: \(transactions.count)
        """

        return summary
    }

    private func buildHighValueAnalysis(
        transactions: [TransactionRecord],
        currencySymbol: String
    ) -> String {
        let expenses = transactions
            .filter { $0.type == .expense && $0.source != .savings }
            .sorted { $0.amountInPrimary > $1.amountInPrimary }

        let top10 = expenses.prefix(10)
        let avgExpense = expenses.isEmpty ? 0 : expenses.reduce(0) { $0 + $1.amountInPrimary } / Double(expenses.count)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let summary = """
        === HIGH VALUE TRANSACTIONS ===
        Average Expense: \(currencySymbol)\(String(format: "%.0f", avgExpense))

        Top 10 Highest Expenses:
        \(top10.enumerated().map { i, tx in
            "\(i + 1). \(tx.title) — \(currencySymbol)\(String(format: "%.0f", tx.amountInPrimary)) [\(tx.category)] on \(formatter.string(from: tx.date))"
        }.joined(separator: "\n"))
        """

        return summary
    }

    private func buildRecurringAnalysis(
        transactions: [TransactionRecord],
        subscriptions: [SubscriptionItem],
        currencySymbol: String
    ) -> String {
        // Find transactions with the same title appearing multiple times
        var titleCounts: [String: (count: Int, total: Double)] = [:]
        for tx in transactions where tx.type == .expense && tx.source != .savings {
            let existing = titleCounts[tx.title] ?? (count: 0, total: 0)
            titleCounts[tx.title] = (count: existing.count + 1, total: existing.total + tx.amountInPrimary)
        }

        let recurring = titleCounts
            .filter { $0.value.count >= 2 }
            .sorted { $0.value.total > $1.value.total }
            .prefix(10)

        let summary = """
        === RECURRING/REPETITIVE TRANSACTIONS ===

        Subscriptions (\(subscriptions.count) active):
        \(subscriptions.map { "• \($0.name): \(currencySymbol)\(String(format: "%.0f", $0.amount))/mo [\($0.category.rawValue)]" }.joined(separator: "\n"))

        Repetitive Purchases (appeared 2+ times):
        \(recurring.map { "• \($0.key): \($0.value.count) times, total \(currencySymbol)\(String(format: "%.0f", $0.value.total))" }.joined(separator: "\n"))

        These could be opportunities to reduce spending or find cheaper alternatives.
        """

        return summary
    }

    private func buildCategoryAnalysis(
        transactions: [TransactionRecord],
        currencySymbol: String
    ) -> String {
        var categoryTotals: [String: Double] = [:]
        var categoryCounts: [String: Int] = [:]

        for tx in transactions where tx.type == .expense && tx.source != .savings {
            categoryTotals[tx.category, default: 0] += tx.amountInPrimary
            categoryCounts[tx.category, default: 0] += 1
        }

        let totalSpent = categoryTotals.values.reduce(0, +)
        let sorted = categoryTotals.sorted { $0.value > $1.value }

        let summary = """
        === CATEGORY BREAKDOWN ===
        Total Spent: \(currencySymbol)\(String(format: "%.0f", totalSpent))

        \(sorted.map { cat in
            let pct = totalSpent > 0 ? (cat.value / totalSpent * 100) : 0
            let count = categoryCounts[cat.key] ?? 0
            return "• \(cat.key): \(currencySymbol)\(String(format: "%.0f", cat.value)) (\(String(format: "%.0f", pct))%) — \(count) transactions"
        }.joined(separator: "\n"))
        """

        return summary
    }

    @MainActor
    private func buildSavingsAnalysis(
        manager: OnboardingManager,
        currencySymbol: String
    ) -> String {
        let totalSaved = UserDefaults.standard.double(forKey: "totalSaved")
        let allowance = Double(manager.userAllowance)
        let balance = Double(manager.userBalance)
        let potentialSavings = max(balance, 0)

        let summary = """
        === SAVINGS ANALYSIS ===
        Total Saved (Lifetime): \(currencySymbol)\(String(format: "%.0f", totalSaved))
        Current Balance (Potential Savings): \(currencySymbol)\(String(format: "%.0f", potentialSavings))
        Monthly Allowance: \(currencySymbol)\(String(format: "%.0f", allowance))
        Savings Rate: \(allowance > 0 ? String(format: "%.0f", (potentialSavings / allowance) * 100) : "N/A")%
        """

        return summary
    }
}

// MARK: - Insights AI Manager

@available(iOS 26.0, *)
@MainActor
@Observable
final class InsightsAIManager {
    var messages: [ChatMessage] = []
    var isGenerating = false
    var isHealthCheckComplete = false
    var errorMessage: String?

    private var session: LanguageModelSession?

    // MARK: - Session Init

    func initializeSession() {
        session = LanguageModelSession(
            tools: [TransactionAnalyzerTool()]
        ) {
            """
            You are Saldo AI — a calm, wise, and supportive financial advisor for students.

            Your personality:
            - Zen-like calm: never alarming, always measured and encouraging
            - Student-focused: practical advice for young people on tight budgets
            - Concise: keep responses focused and actionable, not lengthy
            - Empathetic: acknowledge their situation without judgment
            - Use light emoji sparingly for warmth (🌱, ✨, 💰, 📊)

            Your capabilities:
            - Analyze spending patterns using the analyzeTransactions tool
            - Identify recurring and high expenses
            - Suggest ways to save money
            - Help students build healthy financial habits

            Rules:
            - NEVER perform financial calculations yourself — use the tool data
            - Keep responses under 200 words unless the user asks for more detail
            - Be specific with suggestions (e.g. "Your food spending is 40% of your budget — try meal prepping on Sundays")
            - When greeting, briefly summarize their financial health before giving tips
            - Format responses with clear sections using line breaks
            - Do not mention tool names or technical details to the user
            """
        }

        session?.prewarm()
    }

    // MARK: - Initial Health Check

    func performHealthCheck() async {
        guard !isHealthCheckComplete else { return }
        isGenerating = true

        let healthCheckPrompt = """
        The user just opened their financial insights page. Please:
        1. Use the analyzeTransactions tool with 'overview' to get their current financial status
        2. Provide a brief, friendly greeting with their financial health summary
        3. Highlight 2-3 specific areas where they can improve
        4. End with one encouraging tip

        Keep it concise and student-friendly. Format it nicely with clear sections.
        """

        do {
            guard let session else {
                errorMessage = "AI session not initialized"
                isGenerating = false
                return
            }

            let response = try await session.respond(to: healthCheckPrompt)
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: response.content
            )
            messages.append(assistantMessage)
            isHealthCheckComplete = true
        } catch {
            errorMessage = "Unable to generate insights right now. Please try again."
        }

        isGenerating = false
    }

    // MARK: - Send Message

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        isGenerating = true
        errorMessage = nil

        do {
            guard let session else {
                errorMessage = "AI session not initialized"
                isGenerating = false
                return
            }

            let response = try await session.respond(to: trimmed)
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: response.content
            )
            messages.append(assistantMessage)
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isGenerating = false
    }

    // MARK: - Cleanup

    func terminate() {
        session = nil
        messages = []
        isHealthCheckComplete = false
    }
}
