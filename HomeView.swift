import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            // Clean Apple-style background
            CleanBackground()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Header Area
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Good Evening")
                                .font(.subheadline)
                                .foregroundStyle(Color.saldoSecondary)
                            Text("Aryaman")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.saldoPrimary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundStyle(Color.saldoAccent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Main Balance
                    BalanceCard()
                        .padding(.horizontal, 20)
                    
                    // Grid Section
                    HStack(alignment: .top, spacing: 12) {
                        // Left Column: Weekly Spend
                        WeeklySpendCard()
                        
                        // Right Column: Actions
                        VStack(spacing: 12) {
                            ActionButton(
                                icon: "plus.circle.fill",
                                title: "Add",
                                subtitle: "Subscription",
                                action: {}
                            )
                            
                            WideActionButton(
                                icon: "chart.bar.fill",
                                title: "Insights",
                                action: {}
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    
                    // Transactions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.saldoPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            TransactionRow(icon: "basket.fill", title: "Grocery", subtitle: "5:30 PM", amount: "₹450.00")
                            TransactionRow(icon: "music.note", title: "Spotify", subtitle: "Yesterday", amount: "₹119.00")
                            TransactionRow(icon: "cup.and.saucer.fill", title: "Starbucks", subtitle: "Yesterday", amount: "₹350.00")
                            TransactionRow(icon: "gamecontroller.fill", title: "Steam", subtitle: "2 days ago", amount: "₹899.00")
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
