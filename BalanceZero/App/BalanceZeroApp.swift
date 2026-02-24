import SwiftUI
import SwiftData

@main
struct BalanceZeroApp: App {
    @StateObject private var inputVM = InputViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                InputView()
                    .environmentObject(inputVM)
            }
            .tint(AppTheme.accent)
            .modelContainer(for: [SavedItemList.self, SavedItem.self])
        }
    }
}
