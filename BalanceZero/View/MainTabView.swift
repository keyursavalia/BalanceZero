import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject private var inputVM: InputViewModel

    var body: some View {
        TabView {
            NavigationStack {
                CardsView()
                    .environmentObject(inputVM)
            }
            .tabItem {
                Label("Wallet", systemImage: "wallet.pass.fill")
            }

            CalculationHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .tint(AppTheme.primary)
    }
}
