import SwiftUI

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
        }
    }
}
