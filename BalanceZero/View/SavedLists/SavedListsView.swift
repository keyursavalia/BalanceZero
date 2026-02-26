import SwiftUI
import SwiftData

struct SavedListsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Query(sort: \SavedItemList.createdAt, order: .reverse) private var lists: [SavedItemList]
    @State private var isPresentingNewListSheet = false
    @State private var newlyCreatedList: SavedItemList?
    @Binding var isPresented: Bool

    var body: some View {
        List {
            Section {
                ForEach(lists) { list in
                    NavigationLink {
                        SavedListDetailView(list: list, isRootPresented: $isPresented)
                            .environmentObject(inputVM)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(list.name)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(list.items.count) items")
                                    .font(AppTheme.bodyFont(size: 14))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteLists)
            } footer: {
                if lists.isEmpty {
                    Text("Create lists of items you buy often so you can quickly load them into a new calculation.")
                        .font(AppTheme.bodyFont(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Saved Lists")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresentingNewListSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $isPresentingNewListSheet) {
            NavigationStack {
                NewSavedListView { name in
                    let list = createList(named: name)
                    newlyCreatedList = list
                }
            }
        }
        .navigationDestination(item: $newlyCreatedList) { list in
            SavedListDetailView(list: list, isRootPresented: $isPresented)
                .environmentObject(inputVM)
        }
    }

    private func createList(named name: String) -> SavedItemList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let list = SavedItemList(name: trimmed)
        modelContext.insert(list)
        try? modelContext.save()
        return list
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(lists[index])
        }
        try? modelContext.save()
    }
}

struct NewSavedListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    let onCreate: (String) -> Void

    var body: some View {
        Form {
            Section(header: Text("List Name")) {
                TextField("e.g. Grocery Staples", text: $name)
            }
        }
        .navigationTitle("New List")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create") {
                    onCreate(name)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

