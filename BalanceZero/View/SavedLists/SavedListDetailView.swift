import SwiftUI
import SwiftData

struct SavedListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Bindable var list: SavedItemList
    @Binding var isRootPresented: Bool

    @State private var draftItems: [DraftItem] = [DraftItem()]
    @State private var showNameRequiredAlert = false
    @State private var isEditingItems = false
    @State private var isRenamingList = false
    @State private var draftListName = ""

    struct DraftItem: Identifiable {
        let id = UUID()
        var name: String = ""
        var priceInCents: Int = 0
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
        .onAppear {
            if draftItems.isEmpty { draftItems.append(DraftItem()) }
            if !list.items.isEmpty { isEditingItems = true }
        }
        .onDisappear {
            saveAllValidDrafts()
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
            .foregroundStyle(list.items.isEmpty ? AppTheme.outlineVariant : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                list.items.isEmpty ? AppTheme.surfaceHigh : AppTheme.primary,
                in: Capsule()
            )
            .disabled(list.items.isEmpty)
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
                Text("\(list.items.count)")
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

            // Existing saved items
            if !list.items.isEmpty || isEditingItems {
                LazyVStack(spacing: 8) {
                    ForEach(list.items) { item in
                        SavedItemRow(
                            name: bindingForName(of: item),
                            priceInCents: bindingForPrice(of: item),
                            onDelete: { deleteItem(item) }
                        )
                    }
                }
            } else {
                emptyItemsCard
            }

            // Draft rows
            if isEditingItems {
                LazyVStack(spacing: 8) {
                    ForEach($draftItems) { $draft in
                        DraftItemRow(draft: $draft)
                    }
                }
            }
        }
    }

    private var addItemRow: some View {
        Button {
            saveAllValidDrafts()
            draftItems.append(DraftItem())
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

    private func saveAllValidDrafts() {
        var idsToRemove: [UUID] = []
        for draft in draftItems {
            let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard draft.priceInCents > 0 || !trimmed.isEmpty else { continue }
            let finalName = trimmed.isEmpty ? "Unnamed item" : trimmed
            if !list.items.contains(where: { $0.name == finalName && $0.priceInCents == draft.priceInCents }) {
                let item = SavedItem(name: finalName, priceInCents: draft.priceInCents, list: list)
                list.items.append(item)
                idsToRemove.append(draft.id)
            }
        }
        draftItems.removeAll { idsToRemove.contains($0.id) }
    }

    private func deleteItem(_ item: SavedItem) {
        list.items.removeAll { $0.id == item.id }
        modelContext.delete(item)
    }

    private func applyToInput() {
        inputVM.items = list.items.map {
            ShoppingItem(name: $0.name, priceInCents: $0.priceInCents)
        }
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
    @Binding var draft: SavedListDetailView.DraftItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.outlineVariant)

            TextField("New item name", text: $draft.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.onSurface)

            CurrencyPriceField(priceInCents: $draft.priceInCents)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.surfaceHigh, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }
}
