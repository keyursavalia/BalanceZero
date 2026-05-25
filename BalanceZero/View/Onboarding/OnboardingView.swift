import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @Environment(\.horizontalSizeClass) private var sizeClass

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

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(data: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? AppTheme.primary : AppTheme.outlineVariant)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
                    }
                }

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
                        .frame(maxWidth: sizeClass == .regular ? 480 : .infinity)
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
                .padding(.horizontal, sizeClass == .regular ? 80 : 24)
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
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isIPad: Bool { sizeClass == .regular }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()

                illustrationView
                    .frame(height: isIPad ? geo.size.height * 0.38 : 190)
                    .padding(.bottom, isIPad ? 56 : 48)

                VStack(spacing: isIPad ? 20 : 14) {
                    Text(data.title)
                        .font(.system(size: isIPad ? 48 : 36, weight: .heavy))
                        .foregroundStyle(AppTheme.onSurface)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text(data.subtitle)
                        .font(.system(size: isIPad ? 19 : 16, weight: .regular))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: isIPad ? 520 : 310)
                        .lineSpacing(3)
                }

                Spacer()
                // Reserve space for bottom controls
                Spacer()
                    .frame(height: isIPad ? 180 : 160)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, isIPad ? 64 : 32)
        }
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
        GeometryReader { geo in
            let cardW = min(geo.size.width * 0.9, 320.0)
            let cardH = cardW * 0.63
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: cardW * 1.1, height: cardW * 1.1)
                    .blur(radius: 50)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: "546e7a"), Color(hex: "90a4ae")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: cardW, height: cardH)
                    .rotationEffect(.degrees(-8))
                    .offset(y: cardH * 0.08)
                    .opacity(0.6)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: "1b5e20"), Color(hex: "2e7d32")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: cardW, height: cardH)
                    .rotationEffect(.degrees(4))
                    .offset(y: cardH * 0.04)
                    .opacity(0.75)

                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryContainer],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: cardW, height: cardH)

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: cardW * 0.44, height: cardW * 0.44)
                        .blur(radius: 16)
                        .offset(x: cardW * 0.09, y: -cardH * 0.14)

                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()
                        Text("AVAILABLE BALANCE")
                            .font(.system(size: max(7, cardW * 0.032), weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Color.white.opacity(0.6))
                        Text("$200.00")
                            .font(.system(size: max(22, cardW * 0.122), weight: .heavy))
                            .foregroundStyle(.white)
                        Text("My Card")
                            .font(.system(size: max(9, cardW * 0.043), weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    .padding(cardW * 0.08)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "sparkles")
                        .font(.system(size: max(18, cardW * 0.096), weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(cardW * 0.06)
                }
                .frame(width: cardW, height: cardH)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // Page 2: color palette + card preview
    private var walletIllustration: some View {
        GeometryReader { geo in
            let pillW = min(geo.size.width * 0.22, 90.0)
            let pillH = pillW * 0.63
            let dotSize = min(pillW * 0.34, 30.0)
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.08))
                    .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                    .blur(radius: 50)

                VStack(spacing: geo.size.height * 0.1) {
                    HStack(spacing: pillW * 0.15) {
                        ForEach([CardDesign.mastercard, .starbucks, .silver], id: \.rawValue) { design in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(
                                    colors: design.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                .frame(width: pillW, height: pillH)
                                .overlay(
                                    Text(design.typeLabel.isEmpty ? design.displayName : design.typeLabel)
                                        .font(.system(size: design.typeLabel.isEmpty ? max(6, pillW * 0.07) : max(8, pillW * 0.1), weight: .black))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .padding(6),
                                    alignment: .bottomTrailing
                                )
                        }
                    }

                    HStack(spacing: dotSize * 0.37) {
                        ForEach(CardDesign.allCases.prefix(6), id: \.rawValue) { design in
                            Circle()
                                .fill(LinearGradient(
                                    colors: design.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                .frame(width: dotSize, height: dotSize)
                                .shadow(color: design.gradientColors.first?.opacity(0.4) ?? .clear, radius: 6, x: 0, y: 3)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // Page 3: transaction list mockup
    private var transactionsIllustration: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.08))
                    .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                    .blur(radius: 50)

                VStack(spacing: geo.size.height * 0.05) {
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
                .frame(maxWidth: min(geo.size.width * 0.95, 320))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private struct MockRow { let icon: String; let note: String; let date: String; let amount: String }
    private var transactionMockRows: [MockRow] {[
        MockRow(icon: "cart.fill",    note: "Grocery run",      date: "Today",      amount: "-$42.50"),
        MockRow(icon: "fuelpump.fill", note: "Gas station",     date: "Yesterday",  amount: "-$35.00"),
        MockRow(icon: "cup.and.saucer.fill", note: "Coffee",   date: "Mon",        amount: "-$5.75"),
    ]}
}
