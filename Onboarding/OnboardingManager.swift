import SwiftUI

// MARK: - Onboarding Manager
/// Manages onboarding state and user's initial financial data
@MainActor
@Observable
class OnboardingManager {
    static let shared = OnboardingManager()

    // Persistence keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userName = "userName"
        static let userAllowance = "userAllowance"
        static let userSpending = "userSpending"
        static let userBalance = "userBalance"
    }

    // Properties for SwiftUI observation (no @Published needed with @Observable)
    var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: Keys.userName)
        }
    }

    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    var userAllowance: Int {
        didSet {
            UserDefaults.standard.set(userAllowance, forKey: Keys.userAllowance)
        }
    }
    
    var userSpending: Int {
        didSet {
            UserDefaults.standard.set(userSpending, forKey: Keys.userSpending)
        }
    }
    
    var userBalance: Int {
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
        self.userName = UserDefaults.standard.string(forKey: Keys.userName) ?? ""
        self.userAllowance = UserDefaults.standard.integer(forKey: Keys.userAllowance)
        self.userSpending = UserDefaults.standard.integer(forKey: Keys.userSpending)
        self.userBalance = UserDefaults.standard.integer(forKey: Keys.userBalance)
    }

    // Reset onboarding for testing
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userName = ""
        userAllowance = 0
        userSpending = 0
        userBalance = 0
    }
}
