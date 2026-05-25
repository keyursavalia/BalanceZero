import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            illustration: .card,
            title: "Your Balance,\nSimplified",
            subtitle: "BalanceZero helps you make the most of every card balance. Never let a penny go to waste."
        ),
        OnboardingPageData(
            illustration: .wallet,
            title: "Design\nYour Card",
            subtitle: "Add any card with a name, starting balance, and a design that matches your style. Your wallet, your way."
        ),
        OnboardingPageData(
            illustration: .transactions,
            title: "Track Every\nSpend",
            subtitle: "Log transactions instantly. Your balance stays accurate so you always know exactly what's left."
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(data: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            .ignoresSafeArea()

            // Bottom controls
            VStack(spacing: 24) {
                // Page indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? AppTheme.primary : AppTheme.outlineVariant)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
                    }
                }

                // CTA Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryContainer],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(
                                cornerRadius: AppTheme.cornerRadiusXL,
                                style: .continuous
                            )
                        )
                        .shadow(color: AppTheme.primary.opacity(0.25), radius: 14, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
            .padding(.bottom, 52)
        }
        .interactiveDismissDisabled(true)
    }
}

// MARK: - Page data model

private struct OnboardingPageData {
    enum Illustration { case card, wallet, transactions }
    let illustration: Illustration
    let title: String
    let subtitle: String
}

// MARK: - Single page view

private struct OnboardingPageView: View {
    let data: OnboardingPageData

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            illustrationView
                .padding(.bottom, 48)

            VStack(spacing: 14) {
                Text(data.title)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(AppTheme.onSurface)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text(data.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 310)
                    .lineSpacing(3)
            }

            Spacer()
            // Reserve space for bottom controls (dots + button)
            Spacer()
                .frame(height: 160)
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var illustrationView: some View {
        switch data.illustration {
        case .card:     cardIllustration
        case .wallet:   walletIllustration
        case .transactions: transactionsIllustration
        }
    }

    // Page 1: stacked card visual mockup
    private var cardIllustration: some View {
        ZStack {
            // Ambient glow
            Circle()
                .fill(AppTheme.primary.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 50)

            // Back card
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "880e4f"), Color(hex: "c2185b")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 230, height: 145)
                .rotationEffect(.degrees(-8))
                .offset(y: 12)
                .opacity(0.6)

            // Middle card
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1b5e20"), Color(hex: "2e7d32")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 230, height: 145)
                .rotationEffect(.degrees(4))
                .offset(y: 6)
                .opacity(0.75)

            // Front card with sparkle
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryContainer],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 230, height: 145)

                // Decorative blob on card
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .blur(radius: 16)
                    .offset(x: 20, y: -20)

                // Balance text on card
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    Text("AVAILABLE BALANCE")
                        .font(.system(size: 7, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.white.opacity(0.6))
                    Text("$200.00")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("My Card")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Sparkle
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(14)
            }
            .frame(width: 230, height: 145)
        }
        .frame(height: 190)
    }

    // Page 2: color palette + card preview
    private var walletIllustration: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 50)

            VStack(spacing: 16) {
                // Mini cards in a row showing different designs
                HStack(spacing: 10) {
                    ForEach([CardDesign.mastercard, .starbucks, .amex], id: \.rawValue) { design in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: design.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 68, height: 43)
                            .overlay(
                                Text(design.typeLabel.isEmpty ? design.displayName : design.typeLabel)
                                    .font(.system(size: design.typeLabel.isEmpty ? 6 : 8, weight: .black))
                                    .foregroundStyle(Color.white.opacity(0.85))
                                    .padding(6),
                                alignment: .bottomTrailing
                            )
                    }
                }

                // Design palette dots
                HStack(spacing: 10) {
                    ForEach(CardDesign.allCases.prefix(6), id: \.rawValue) { design in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: design.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)
                            .shadow(color: design.gradientColors.first?.opacity(0.4) ?? .clear, radius: 6, x: 0, y: 3)
                    }
                }
            }
        }
        .frame(height: 190)
    }

    // Page 3: transaction list mockup
    private var transactionsIllustration: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 50)

            VStack(spacing: 10) {
                ForEach(transactionMockRows, id: \.note) { row in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.surfaceHigh)
                                .frame(width: 36, height: 36)
                            Image(systemName: row.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.outline)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.note)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.onSurface)
                            Text(row.date)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.outline)
                        }
                        Spacer()
                        Text(row.amount)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "b71c1c"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        AppTheme.surfaceLowest,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 4, x: 0, y: 2)
                }
            }
            .frame(maxWidth: 290)
        }
        .frame(height: 190)
    }

    private struct MockRow { let icon: String; let note: String; let date: String; let amount: String }
    private var transactionMockRows: [MockRow] {[
        MockRow(icon: "cart.fill",    note: "Grocery run",      date: "Today",      amount: "-$42.50"),
        MockRow(icon: "fuelpump.fill", note: "Gas station",     date: "Yesterday",  amount: "-$35.00"),
        MockRow(icon: "cup.and.saucer.fill", note: "Coffee",   date: "Mon",        amount: "-$5.75"),
    ]}
}
