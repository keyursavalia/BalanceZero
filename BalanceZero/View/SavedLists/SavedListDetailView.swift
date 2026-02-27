import SwiftUI
import SwiftData

struct SavedListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel

    @Bindable var list: SavedItemList
    @Binding var isRootPresented: Bool

    @State private var draftItems: [DraftItem] = [DraftItem()]
    @State private var showNameRequiredAlert = false

    struct DraftItem: Identifiable {
        let id = UUID()
        var name: String = ""
        var priceInCents: Int = 0
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Form {
                Section(header: Text("List Name").font(.headline)) {
                    TextField("Name", text: $list.name)
                        .font(.system(size: 17, weight: .semibold))
                }

                Section(header: Text("Items").font(.headline)) {
                    ForEach(list.items) { item in
                        HStack {
                            TextField("Item name", text: binding(for: item, keyPath: \.name))
                            CurrencyPriceField(priceInCents: bindingForPriceInCents(of: item))
                            Button {
                                deleteItem(item)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)

                    ForEach($draftItems) { $draft in
                        HStack {
                            TextField("New item name", text: $draft.name)
                            CurrencyPriceField(priceInCents: $draft.priceInCents)
                        }
                    }

                    Button {
                        saveAllValidDrafts()
                        addNewDraftRow()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                            Text("Add Item Row")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(list.name.isEmpty ? "List" : list.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Use List") {
                    applyToInput()
                    isRootPresented = false
                }
                .disabled(list.items.isEmpty)
            }
        }
        .onAppear {
            // Ensure at least one draft row exists when view appears
            if draftItems.isEmpty {
                draftItems.append(DraftItem())
            }
        }
        .onDisappear {
            // Save any remaining valid draft items
            saveAllValidDrafts()

            // Validate that the list has a name
            let trimmedName = list.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty && !list.items.isEmpty {
                // If name is empty but items exist, show alert
                showNameRequiredAlert = true
            } else if trimmedName.isEmpty && list.items.isEmpty {
                // If name is empty and no items, delete the list
                modelContext.delete(list)
            } else {
                list.name = trimmedName
            }

            try? modelContext.save()
        }
        .alert("List Name Required", isPresented: $showNameRequiredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please provide a name for this list before saving.")
        }
    }

    private func saveAllValidDrafts() {
        var savedDraftIds: [UUID] = []

        for draft in draftItems {
            let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { continue }
            guard draft.priceInCents > 0 else { continue }

            // Check if not already in list
            if !list.items.contains(where: { $0.name == trimmedName && $0.priceInCents == draft.priceInCents }) {
                let item = SavedItem(name: trimmedName, priceInCents: draft.priceInCents, list: list)
                list.items.append(item)
                savedDraftIds.append(draft.id)
            }
        }

        // Remove saved drafts
        draftItems.removeAll { savedDraftIds.contains($0.id) }
    }

    private func addNewDraftRow() {
        draftItems.append(DraftItem())
    }

    private func deleteItem(_ item: SavedItem) {
        if let index = list.items.firstIndex(where: { $0.id == item.id }) {
            list.items.remove(at: index)
            modelContext.delete(item)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = list.items[index]
            modelContext.delete(item)
        }
        list.items.remove(atOffsets: offsets)
    }

    private func binding(for item: SavedItem, keyPath: ReferenceWritableKeyPath<SavedItem, String>) -> Binding<String> {
        Binding(
            get: { item[keyPath: keyPath] },
            set: { newValue in
                item[keyPath: keyPath] = newValue
            }
        )
    }

    private func bindingForPriceInCents(of item: SavedItem) -> Binding<Int> {
        Binding(
            get: { item.priceInCents },
            set: { item.priceInCents = $0 }
        )
    }

    private func applyToInput() {
        inputVM.items = list.items.map { saved in
            ShoppingItem(name: saved.name, priceInCents: saved.priceInCents)
        }
    }
}

