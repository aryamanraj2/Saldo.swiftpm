import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false
    @State private var showTutorial = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
                    .tutorialOverlay(isActive: $showTutorial) {
                        hasCompletedTutorial = true
                    }
                    .onAppear {
                        if !hasCompletedTutorial {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showTutorial = true
                            }
                        }
                    }
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
            }
        }
    }
}
//aryaman
