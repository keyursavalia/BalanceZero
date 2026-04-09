import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject private var inputVM: InputViewModel

    var body: some View {
        TabView {
            NavigationStack {
                InputView()
            }
            .tabItem {
                Label("Calculate", systemImage: "number.circle.fill")
            }

            CalculationHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .tint(AppTheme.primary)
    }
}
