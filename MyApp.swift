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
                        // Show tutorial if onboarding done but tutorial not completed
                        if !hasCompletedTutorial {
                            // Quick delay to let views render
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