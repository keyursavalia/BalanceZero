import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject private var inputVM: InputViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                InputView()
            }
            .tabItem {
                Label("Calculate", systemImage: "percent")
            }
            .tag(0)

            CalculationHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
        }
        .tint(AppTheme.accent)
    }
}
