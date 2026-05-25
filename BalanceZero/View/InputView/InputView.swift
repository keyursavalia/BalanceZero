import SwiftUI
import SwiftData

struct InputView: View {
    /// When opened from a card's detail, this pre-fills the balance field with the card's current balance.
    var initialBalanceInCents: Int? = nil

    @EnvironmentObject private var vm: InputViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingSavedLists = false
    @Query(sort: \SavedItemList.createdAt, order: .reverse) private var savedLists: [SavedItemList]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            backgroundDecoration

            ScrollView {
                VStack(spacing: 20) {
                    BalanceInputCard(
                        balanceText: $vm.balanceText,
                        balanceInCents: vm.balanceInCents
                    )

                    itemsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            calculateBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { navigationToolbar }
        .navigationDestination(isPresented: $showingSavedLists) {
            SavedListsView(isPresented: $showingSavedLists)
                .environmentObject(vm)
        }
        .navigationDestination(item: $vm.result) { result in
            ReportView(vm: ReportViewModel(result: result))
                .environmentObject(vm)
        }
        .onChange(of: vm.result) { _, newValue in
            if let result = newValue {
                let saved = SavedCalculation.from(result)
                modelContext.insert(saved)
                try? modelContext.save()
            }
        }
        .alert("Check Your Input", isPresented: $vm.showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.validationMessage)
        }
        .onAppear {
            // Pre-fill balance from the card whenever this view appears (including after "Start Over")
            if let cents = initialBalanceInCents {
                vm.balanceText = CurrencyInputHelper.formattedFromCents(cents)
            }
        }
    }

    // MARK: - Navigation Toolbar

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Minimizer")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppTheme.primary)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingSavedLists = true
            } label: {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.primaryFixed, in: Circle())
            }
        }
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack(alignment: .center, spacing: 10) {
                Text("Items to Buy")
                    .font(AppTheme.headlineFont(size: 20))
                    .foregroundStyle(AppTheme.onSurface)

                // Load from saved list menu
                Menu {
                    if savedLists.isEmpty {
                        Label("No saved lists yet", systemImage: "tray")
                    } else {
                        ForEach(savedLists) { list in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    vm.items = list.items.map {
                                        ShoppingItem(name: $0.name, priceInCents: $0.priceInCents)
                                    }
                                }
                            } label: {
                                Label(list.name, systemImage: "checkmark.circle")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.primaryFixed)
                        .background(AppTheme.primary, in: Circle())
                }

                Spacer()

                // Item count badge
                let count = vm.items.filter { $0.priceInCents > 0 }.count
                if count > 0 {
                    Text("\(count) item\(count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.primaryFixed, in: Capsule())
                }
            }

            // Item rows
            ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, _ in
                ItemRowView(
                    item: Binding(
                        get: { index < vm.items.count ? vm.items[index] : ShoppingItem(name: "", priceInCents: 0) },
                        set: { if index < vm.items.count { vm.items[index] = $0 } }
                    ),
                    isLastRow: index == vm.items.count - 1,
                    onDelete: {
                        vm.removeItem(at: IndexSet(integer: index))
                    },
                    onPriceBecameNonZero: index == vm.items.count - 1 ? {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            vm.addItem()
                        }
                    } : nil
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95, anchor: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            AddItemButton {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    vm.addItem()
                }
            }
        }
    }

    // MARK: - Calculate CTA Bar

    private var calculateBar: some View {
        VStack(spacing: 0) {
            Button {
                vm.calculate()
            } label: {
                HStack(spacing: 10) {
                    if vm.isCalculating {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "wand.and.sparkles")
                            .font(.system(size: 18, weight: .bold))
                        Text("Find Zero")
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    vm.canCalculate
                        ? LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [AppTheme.outlineVariant, AppTheme.outlineVariant],
                                         startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
                )
                .shadow(
                    color: AppTheme.primary.opacity(vm.canCalculate ? 0.22 : 0),
                    radius: 16, x: 0, y: 6
                )
            }
            .disabled(!vm.canCalculate || vm.isCalculating)
            .animation(.easeInOut(duration: 0.2), value: vm.canCalculate)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            if !vm.canCalculate {
                Text("Enter your balance and at least one item price to minimize.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.outline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Background Decoration

    private var backgroundDecoration: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 120, y: -100)
                .allowsHitTesting(false)

            Circle()
                .fill(AppTheme.primaryContainer.opacity(0.03))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: -100, y: 300)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
