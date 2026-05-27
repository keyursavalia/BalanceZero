import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @EnvironmentObject private var inputVM: InputViewModel

    let card: Card

    @State private var showAddTransaction = false
    @State private var showEditCard = false
    @State private var showDeleteAlert = false
    @State private var navigateToCalculator = false
    @State private var transactionToDelete: CardTransaction?

    private var sortedTransactions: [CardTransaction] {
        card.transactions.sorted { $0.createdAt > $1.createdAt }
    }

    private var currentBalance: Int { card.currentBalanceInCents }
    private var totalSpent: Int { card.totalSpentInCents }
    private var isOverdrawn: Bool { currentBalance < 0 }

    private var cardGradientColors: [Color] {
        if card.design == .custom, !card.customColorHex.isEmpty {
            let base = Color(hex: card.customColorHex)
            return [base.opacity(0.85), base]
        }
        return card.design.gradientColors
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            backgroundDecoration

            ScrollView {
                VStack(spacing: 24) {
                    cardHeader
                    balanceSection
                    actionButtons
                    transactionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
        .navigationDestination(isPresented: $navigateToCalculator) {
            InputView(
                initialBalanceInCents: currentBalance,
                cardGradientColors: cardGradientColors,
                sourceCardName: card.name,
                sourceCardDesignRawValue: card.design.rawValue,
                sourceCardCustomColorHex: card.customColorHex
            )
            .environmentObject(inputVM)
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(card: card)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppTheme.cornerRadiusLG)
        }
        .sheet(isPresented: Binding(
            get: { showEditCard && sizeClass != .regular },
            set: { showEditCard = $0 }
        )) {
            CardCreationView(existingCard: card)
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: Binding(
            get: { showEditCard && sizeClass == .regular },
            set: { showEditCard = $0 }
        )) {
            CardCreationView(existingCard: card)
        }
        .alert("Delete Card?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteCard() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(card.name)\" and all its transactions. This action cannot be undone.")
        }
        .alert("Delete Transaction?", isPresented: Binding(
            get: { transactionToDelete != nil },
            set: { if !$0 { transactionToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let tx = transactionToDelete { deleteTransaction(tx) }
                transactionToDelete = nil
            }
            Button("Cancel", role: .cancel) { transactionToDelete = nil }
        } message: {
            if let tx = transactionToDelete {
                Text("\"\(tx.note)\" for \(formatCents(tx.amountInCents)) will be removed and your balance will update.")
            }
        }
    }

    // MARK: - Card visual header

    private var cardHeader: some View {
        CardVisualView(
            name: card.name,
            balanceInCents: currentBalance,
            design: card.design,
            customColorHex: card.customColorHex,
            customCompanyName: card.customCompanyName
        )
    }

    // MARK: - Balance stats

    private var balanceSection: some View {
        HStack(spacing: 12) {
            statTile(
                label: "CURRENT BALANCE",
                value: formatCents(currentBalance),
                valueColor: isOverdrawn ? Color(hex: "b71c1c") : AppTheme.primary,
                icon: "creditcard"
            )
            statTile(
                label: "TOTAL SPENT",
                value: formatCents(totalSpent),
                valueColor: AppTheme.onSurface,
                icon: "arrow.down.circle"
            )
        }
    }

    private func statTile(label: String, value: String, valueColor: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.outline)
            }
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

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Log transaction
            Button {
                showAddTransaction = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Log Spend")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.primaryFixed.opacity(0.7), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD, style: .continuous))
            }
            .buttonStyle(.plain)

            // Open minimizer
            Button {
                navigateToCalculator = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Minimizer")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryContainer],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD, style: .continuous)
                )
                .shadow(color: AppTheme.primary.opacity(0.25), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Transaction history section

    @ViewBuilder
    private var transactionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("TRANSACTIONS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.outline)
                Spacer()
                if !sortedTransactions.isEmpty {
                    Text("\(sortedTransactions.count) total")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.outline)
                }
            }

            if sortedTransactions.isEmpty {
                emptyTransactionsCard
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(sortedTransactions) { tx in
                        TransactionRowView(transaction: tx)
                            .contextMenu {
                                Button(role: .destructive) {
                                    transactionToDelete = tx
                                } label: {
                                    Label("Delete Transaction", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private var emptyTransactionsCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryFixed.opacity(0.5))
                    .frame(width: 64, height: 64)
                    .blur(radius: 14)
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(AppTheme.outlineVariant)
            }
            VStack(spacing: 6) {
                Text("No transactions yet")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.onSurface)
                Text("Tap \"Log Spend\" to record your first transaction on this card.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(card.name)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppTheme.primary)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showEditCard = true
                } label: {
                    Label("Edit Card", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Card", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }

    // MARK: - Background decoration

    private var backgroundDecoration: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 120, y: -80)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func deleteCard() {
        modelContext.delete(card)
        try? modelContext.save()
        dismiss()
    }

    private func deleteTransaction(_ tx: CardTransaction) {
        card.transactions.removeAll { $0.id == tx.id }
        modelContext.delete(tx)
        try? modelContext.save()
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: (Decimal(cents) / 100) as NSDecimalNumber) ?? "$0.00"
    }
}
