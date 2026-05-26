import SwiftUI
import SwiftData

struct CardsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Query(sort: \Card.createdAt, order: .forward) private var cards: [Card]
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showCardCreation = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if cards.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { walletToolbar }
        .sheet(isPresented: Binding(
            get: { showCardCreation && sizeClass != .regular },
            set: { showCardCreation = $0 }
        )) {
            CardCreationView()
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: Binding(
            get: { showCardCreation && sizeClass == .regular },
            set: { showCardCreation = $0 }
        )) {
            CardCreationView()
        }
    }

    // MARK: - Main content (when cards exist)

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Wallet header
            walletHeader
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)

            // Card carousel
            carouselSection

            // Page dots
            pageIndicator
                .padding(.top, 16)

            // Total balance summary
            totalBalanceSummary
                .padding(.horizontal, 20)
                .padding(.top, 24)

            Spacer()
        }
    }

    // MARK: - Wallet header

    private var walletHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MY WALLET")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.outline)
                Text("\(cards.count) Card\(cards.count == 1 ? "" : "s")")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppTheme.primary)
            }
            Spacer()

            // Add card button
            Button {
                showCardCreation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add Card")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                                   startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Carousel

    private var carouselSection: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width - 64, 360.0)
            let sidePadding = (geo.size.width - cardWidth) / 2
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(cards) { card in
                        NavigationLink {
                            CardDetailView(card: card)
                                .environmentObject(inputVM)
                        } label: {
                            CardVisualView(
                                name: card.name,
                                balanceInCents: card.currentBalanceInCents,
                                design: card.design,
                                customColorHex: card.customColorHex,
                                customCompanyName: card.customCompanyName
                            )
                            .frame(width: cardWidth)
                            .scrollTransition(.animated.threshold(.visible(0.5))) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                                    .opacity(phase.isIdentity ? 1.0 : 0.65)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.never)
            .safeAreaPadding(.horizontal, sidePadding)
        }
        .frame(height: cardCarouselHeight(for: UIScreen.main.bounds.width))
    }

    private func cardCarouselHeight(for screenWidth: CGFloat) -> CGFloat {
        let cardWidth = min(screenWidth - 64, 360.0)
        return cardWidth / 1.586 + 24
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        // Uses a scroll position proxy approach — simplified to always show dots
        HStack(spacing: 6) {
            ForEach(0..<cards.count, id: \.self) { _ in
                Circle()
                    .fill(AppTheme.outlineVariant)
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Total balance summary

    private var totalBalanceSummary: some View {
        let totalBalance = cards.reduce(0) { $0 + $1.currentBalanceInCents }
        let totalSpent   = cards.reduce(0) { $0 + $1.totalSpentInCents }

        return HStack(spacing: 12) {
            summaryTile(
                label: "TOTAL BALANCE",
                value: formatCents(totalBalance),
                valueColor: totalBalance < 0 ? Color(hex: "b71c1c") : AppTheme.primary
            )
            summaryTile(
                label: "TOTAL SPENT",
                value: formatCents(totalSpent),
                valueColor: AppTheme.onSurface
            )
        }
    }

    private func summaryTile(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.outline)
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration: stacked empty card outlines
            ZStack {
                Circle()
                    .fill(AppTheme.primaryFixed.opacity(0.5))
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)

                ZStack {
                    // Furthest card
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.outlineVariant.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 200, height: 126)
                        .offset(y: -12)
                    // Middle card
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.outlineVariant.opacity(0.65), lineWidth: 1.5)
                        .frame(width: 200, height: 126)
                        .offset(y: -6)
                    // Front card
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.outlineVariant, lineWidth: 1.5)
                        .background(AppTheme.surfaceLowest.opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .frame(width: 200, height: 126)
                }
            }
            .frame(height: 170)

            VStack(spacing: 10) {
                Text("Your wallet is empty")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(AppTheme.onSurface)

                Text("Add your first card to start tracking your balance and spending with BalanceZero.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                showCardCreation = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Add Your First Card")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                                   startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 16, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var walletToolbar: some ToolbarContent {
        if sizeClass != .regular {
            ToolbarItem(placement: .principal) {
                Text("BalanceZero")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }

    // MARK: - Helpers

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: (Decimal(cents) / 100) as NSDecimalNumber) ?? "$0.00"
    }
}
