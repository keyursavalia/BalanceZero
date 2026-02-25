import SwiftUI
import SwiftData

struct SavedListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel

    @Bindable var list: SavedItemList
    @Binding var isRootPresented: Bool

    @State private var newItemName: String = ""
    @State private var newItemPriceText: String = ""

    private var canAddNewItem: Bool {
        let trimmedName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        let cleanedPrice = newItemPriceText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let value = Decimal(string: cleanedPrice) else { return false }
        let cents = NSDecimalNumber(decimal: value * 100).intValue
        return cents > 0
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
                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundStyle(AppTheme.textSecondary)
                                TextField("0.00", text: bindingForPrice(of: item))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)

                    HStack {
                        TextField("New item name", text: $newItemName)
                        HStack(spacing: 4) {
                            Text("$")
                                .foregroundStyle(canAddNewItem ? AppTheme.textSecondary : AppTheme.textSecondary.opacity(0.5))
                            TextField("0.00", text: $newItemPriceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        Button {
                            addNewItem()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(canAddNewItem ? AppTheme.accent : AppTheme.textSecondary.opacity(0.4))
                        }
                        .disabled(!canAddNewItem)
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
        .onDisappear {
            try? modelContext.save()
        }
    }

    private func addNewItem() {
        let trimmedName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, canAddNewItem else { return }

        let cleanedPrice = newItemPriceText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        let cents: Int
        if let value = Decimal(string: cleanedPrice) {
            cents = max(0, NSDecimalNumber(decimal: value * 100).intValue)
        } else {
            cents = 0
        }

        let item = SavedItem(name: trimmedName, priceInCents: cents, list: list)
        list.items.append(item)
        newItemName = ""
        newItemPriceText = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = list.items[index]
            modelContext.delete(item)
        }
    }

    private func binding(for item: SavedItem, keyPath: ReferenceWritableKeyPath<SavedItem, String>) -> Binding<String> {
        Binding(
            get: { item[keyPath: keyPath] },
            set: { newValue in
                item[keyPath: keyPath] = newValue
            }
        )
    }

    private func bindingForPrice(of item: SavedItem) -> Binding<String> {
        Binding(
            get: {
                let decimal = Decimal(item.priceInCents) / 100
                return NSDecimalNumber(decimal: decimal).stringValue
            },
            set: { newText in
                let cleaned = newText
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if let value = Decimal(string: cleaned) {
                    item.priceInCents = max(0, NSDecimalNumber(decimal: value * 100).intValue)
                } else {
                    item.priceInCents = 0
                }
            }
        )
    }

    private func applyToInput() {
        inputVM.items = list.items.map { saved in
            ShoppingItem(name: saved.name, priceInCents: saved.priceInCents)
        }
    }
}

