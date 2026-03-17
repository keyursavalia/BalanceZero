import SwiftUI
import SwiftData

struct SavedListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel

    @Bindable var list: SavedItemList
    @Binding var isRootPresented: Bool

    @State private var draftItems: [DraftItem] = [DraftItem()]
    @State private var showNameRequiredAlert = false
    @State private var isEditingItems = false
    @State private var isRenamingList = false
    @State private var draftListName: String = ""

    struct DraftItem: Identifiable {
        let id = UUID()
        var name: String = ""
        var priceInCents: Int = 0
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Form {
                Section(header: Text("Items").font(.headline)) {
                    if list.items.isEmpty && !isEditingItems {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No items yet")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("Add a few items you often buy so you can quickly reuse this list.")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)

                            Button {
                                isEditingItems = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppTheme.accent)
                                    Text("Add first item")
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .fill(AppTheme.cardBackground)
                        )
                    } else {
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
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(AppTheme.accent)
                                Text("Add Item Row")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Button {
                        draftListName = list.name
                        isRenamingList = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(list.name.isEmpty ? "List" : list.name)
                                .font(.headline)
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
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
            if !list.items.isEmpty {
                isEditingItems = true
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
        .alert("Rename List", isPresented: $isRenamingList, actions: {
            TextField("List name", text: $draftListName)
            Button("Cancel") {}
                .foregroundStyle(.red)
            Button("Save") {
                let trimmed = draftListName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    list.name = trimmed
                }
            }
        })
        .alert("List Name Required", isPresented: $showNameRequiredAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text("Please provide a name for this list before saving.")
        })
    }

    private func saveAllValidDrafts() {
        var savedDraftIds: [UUID] = []

        for draft in draftItems {
            let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard draft.priceInCents > 0 || !trimmedName.isEmpty else { continue }

            let finalName = trimmedName.isEmpty ? "Unnamed item" : trimmedName

            // Check if not already in list
            if !list.items.contains(where: { $0.name == finalName && $0.priceInCents == draft.priceInCents }) {
                let item = SavedItem(name: finalName, priceInCents: draft.priceInCents, list: list)
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

