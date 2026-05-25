import SwiftUI
import SwiftData

@main
struct BalanceZeroApp: App {
    @StateObject private var inputVM = InputViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(inputVM)
                .tint(AppTheme.accent)
                .modelContainer(for: [
                    SavedItemList.self,
                    SavedItem.self,
                    SavedCalculation.self,
                    SavedResultItem.self,
                    Card.self,
                    CardTransaction.self,
                ])
                .fullScreenCover(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
        }
    }
}
