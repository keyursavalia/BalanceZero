import SwiftUI
import SwiftData

struct SavedListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Bindable var list: SavedItemList
    @Binding var isRootPresented: Bool

    @State private var newItemIds: Set<PersistentIdentifier> = []
    @State private var showNameRequiredAlert = false
    @State private var isEditingItems = false
    @State private var isRenamingList = false
    @State private var draftListName = ""

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .dismissKeyboardOnBackgroundTap()

            ScrollView {
                VStack(spacing: 20) {
                    // List header card
                    listHeaderCard
                        .padding(.top, 4)

                    // Items section
                    itemsSection

                    Color.clear.frame(height: 16)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
        .onAppear {
            if !list.items.isEmpty {
                isEditingItems = true
            }
        }
        .onDisappear {
            finalizeNewItems()
            let trimmed = list.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty && !list.items.isEmpty {
                showNameRequiredAlert = true
            } else if trimmed.isEmpty {
                modelContext.delete(list)
            } else {
                list.name = trimmed
            }
            try? modelContext.save()
        }
        .alert("Rename List", isPresented: $isRenamingList) {
            TextField("List name", text: $draftListName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = draftListName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { list.name = trimmed }
            }
        }
        .alert("List Name Required", isPresented: $showNameRequiredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please provide a name for this list.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button {
                draftListName = list.name
                isRenamingList = true
            } label: {
                HStack(spacing: 5) {
                    Text(list.name.isEmpty ? "Untitled List" : list.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.onSurface)
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.outline)
                }
            }
            .buttonStyle(.plain)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Use List") {
                applyToInput()
                isRootPresented = false
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(hasAnyValidItems ? AppTheme.primary : AppTheme.outlineVariant)
            .disabled(!hasAnyValidItems)
        }
    }

    private var hasAnyValidItems: Bool {
        list.items.contains {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.priceInCents > 0
        }
    }

    // MARK: - Header Card

    private var listHeaderCard: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("CATALOGUE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.primary.opacity(0.6))
                Text(list.name.isEmpty ? "Untitled" : list.name)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppTheme.onSurface)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(validItemCount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                Text("ITEMS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.outline)
            }
        }
        .padding(20)
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous))
    }

    private var validItemCount: Int {
        list.items.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.priceInCents > 0
        }.count
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        VStack(spacing: 12) {
            // Section label
            HStack {
                Text("ITEMS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.outline)
                Spacer()
            }
            .padding(.horizontal, 2)

            // Add new item row (always at top when editing)
            addItemRow

            // All items — new ones render with draft styling, existing with saved styling
            if !list.items.isEmpty || isEditingItems {
                LazyVStack(spacing: 8) {
                    ForEach(list.items) { item in
                        if newItemIds.contains(item.id) {
                            DraftItemRow(
                                name: bindingForName(of: item),
                                priceInCents: bindingForPrice(of: item),
                                onDelete: { deleteItem(item); newItemIds.remove(item.id) }
                            )
                        } else {
                            SavedItemRow(
                                name: bindingForName(of: item),
                                priceInCents: bindingForPrice(of: item),
                                onDelete: { deleteItem(item) }
                            )
                        }
                    }
                }
            } else {
                emptyItemsCard
            }
        }
    }

    private var addItemRow: some View {
        Button {
            let newItem = SavedItem(name: "", priceInCents: 0, list: list)
            list.items.append(newItem)
            newItemIds.insert(newItem.id)
            isEditingItems = true
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryFixed)
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                }
                Text("Add item")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                Spacer()
            }
            .padding(14)
            .background(AppTheme.surfaceHigh, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var emptyItemsCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.outlineVariant)
            Text("No items yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.onSurfaceVariant)
            Text("Add items you buy often to this list.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.outline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Data Operations

    // Cleans up new items on navigation: deletes blanks, assigns default names to partial fills.
    private func finalizeNewItems() {
        for item in list.items where newItemIds.contains(item.id) {
            let trimmed = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty && item.priceInCents == 0 {
                list.items.removeAll { $0.id == item.id }
                modelContext.delete(item)
            } else if trimmed.isEmpty {
                item.name = "Unnamed item"
            } else {
                item.name = trimmed
            }
        }
        newItemIds.removeAll()
    }

    private func applyToInput() {
        finalizeNewItems()
        inputVM.items = list.items.map {
            ShoppingItem(name: $0.name, priceInCents: $0.priceInCents)
        }
    }

    private func deleteItem(_ item: SavedItem) {
        list.items.removeAll { $0.id == item.id }
        modelContext.delete(item)
    }

    private func bindingForName(of item: SavedItem) -> Binding<String> {
        Binding(get: { item.name }, set: { item.name = $0 })
    }

    private func bindingForPrice(of item: SavedItem) -> Binding<Int> {
        Binding(get: { item.priceInCents }, set: { item.priceInCents = $0 })
    }
}

// MARK: - Saved Item Row

private struct SavedItemRow: View {
    @Binding var name: String
    @Binding var priceInCents: Int
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.red.opacity(0.75))
            }
            .buttonStyle(.plain)

            TextField("Item name", text: $name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.onSurface)

            CurrencyPriceField(priceInCents: $priceInCents)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Draft Item Row

private struct DraftItemRow: View {
    @Binding var name: String
    @Binding var priceInCents: Int
    var onDelete: (() -> Void)? = nil

    private var hasContent: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || priceInCents > 0
    }

    var body: some View {
        HStack(spacing: 12) {
            if hasContent {
                Button(action: { onDelete?() }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.red.opacity(0.75))
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.outlineVariant)
                    .transition(.opacity)
            }

            TextField("New item name", text: $name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.onSurface)

            CurrencyPriceField(priceInCents: $priceInCents)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.surfaceHigh, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: hasContent)
    }
}
