import SwiftUI
import SwiftData

struct SavedListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var inputVM: InputViewModel

    @Bindable var list: SavedItemList

    @State private var newItemName: String = ""
    @State private var newItemPriceText: String = ""

    var body: some View {
        Form {
            Section(header: Text("List Name")) {
                TextField("Name", text: $list.name)
            }

            Section(header: Text("Items")) {
                ForEach(list.items) { item in
                    HStack {
                        TextField("Item name", text: binding(for: item, keyPath: \.name))
                        TextField("Price", text: bindingForPrice(of: item))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .onDelete(perform: deleteItems)

                HStack {
                    TextField("New item name", text: $newItemName)
                    TextField("0.00", text: $newItemPriceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Button {
                        addNewItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(list.name.isEmpty ? "List" : list.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Use List") {
                    applyToInput()
                    dismiss()
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
        guard !trimmedName.isEmpty else { return }

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

