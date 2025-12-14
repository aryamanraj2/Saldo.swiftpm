import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            // Layer 1: The Liquid Fluid Background
            FluidBackground()
            
            // Layer 2: Content
            ScrollView {
                VStack(spacing: 24) {
                    // Header Area
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Main Balance
                    BalanceCard()
                        .padding(.horizontal)
                    
                    // Grid Section
                    HStack(alignment: .top, spacing: 16) {
                        // Left Column: Weekly Spend (Tall/Large)
                        WeeklySpendCard()
                            .frame(minHeight: 180)
                        
                        // Right Column: Actions
                        VStack(spacing: 16) {
                            ActionButton(
                                icon: "plus",
                                title: "Subscription",
                                subtitle: "Tap to add",
                                action: {}
                            )
                            .frame(height: 180) // Match height of Spend Card roughly? Or let it be flexible.
                            
                            WideActionButton(
                                icon: "sparkles",
                                title: "Get Insights",
                                action: {}
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Transactions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Transactions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TransactionRow(icon: "basket.fill", title: "Grocery", subtitle: "5:30 PM", amount: "₹450.00")
                            TransactionRow(icon: "music.note", title: "Spotify", subtitle: "Yesterday", amount: "₹119.00")
                            TransactionRow(icon: "cup.and.saucer.fill", title: "Starbucks", subtitle: "Yesterday", amount: "₹350.00")
                            TransactionRow(icon: "gamecontroller.fill", title: "Steam", subtitle: "2 days ago", amount: "₹899.00")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    HomeView()
}
