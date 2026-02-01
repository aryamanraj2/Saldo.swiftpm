import SwiftUI

struct SubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var colors: ThemeColors
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("Add Subscription")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(colors.primary)
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundStyle(Color.saldoSecondary)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SubscriptionSheet(colors: AppTheme.moderate.colors)
}
