import SwiftUI
import SwiftData

@main
struct BalanceZeroApp: App {
    @StateObject private var inputVM = InputViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true

    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")

    private var isUITesting: Bool { Self.isUITesting }

    private static let modelContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
        return try! ModelContainer(
            for: SavedItemList.self, SavedItem.self, SavedCalculation.self,
                 SavedResultItem.self, Card.self, CardTransaction.self,
            configurations: config
        )
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(inputVM)
                    .tint(AppTheme.accent)
                    .modelContainer(Self.modelContainer)
                    .fullScreenCover(isPresented: Binding(
                        get: { !hasSeenOnboarding && !isUITesting },
                        set: { _ in }
                    )) {
                        OnboardingView {
                            hasSeenOnboarding = true
                        }
                    }

                if showSplash && !isUITesting {
                    SplashScreenView {
                        withAnimation(.easeIn(duration: 0.35)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
        }
    }
}
