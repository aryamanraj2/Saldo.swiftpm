import SwiftUI

// MARK: - Onboarding Manager
/// Manages onboarding state and user's initial financial data
@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    // Persistence keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userAllowance = "userAllowance"
        static let userSpending = "userSpending"
        static let userBalance = "userBalance"
    }
    
    // Published properties for SwiftUI observation
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    @Published var userAllowance: Int {
        didSet {
            UserDefaults.standard.set(userAllowance, forKey: Keys.userAllowance)
        }
    }
    
    @Published var userSpending: Int {
        didSet {
            UserDefaults.standard.set(userSpending, forKey: Keys.userSpending)
        }
    }
    
    @Published var userBalance: Int {
        didSet {
            UserDefaults.standard.set(userBalance, forKey: Keys.userBalance)
        }
    }
    
    // Computed property for initial balance to use in HomeView
    var initialBalance: Double {
        Double(userBalance)
    }
    
    // Computed property for monthly savings potential
    var monthlySavings: Int {
        max(userAllowance - userSpending, 0)
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        self.userAllowance = UserDefaults.standard.integer(forKey: Keys.userAllowance)
        self.userSpending = UserDefaults.standard.integer(forKey: Keys.userSpending)
        self.userBalance = UserDefaults.standard.integer(forKey: Keys.userBalance)
    }
    
    // Reset onboarding for testing
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userAllowance = 0
        userSpending = 0
        userBalance = 0
    }
}
