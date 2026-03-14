import SwiftUI
import SwiftData

@main
struct BalanceZeroApp: App {
    @StateObject private var inputVM = InputViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(inputVM)
            .tint(AppTheme.accent)
            .modelContainer(for: [SavedItemList.self, SavedItem.self, SavedCalculation.self, SavedResultItem.self])
        }
    }
}
