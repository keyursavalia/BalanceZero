import SwiftUI
import SwiftData

struct SavedListsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Query(sort: \SavedItemList.createdAt, order: .reverse) private var lists: [SavedItemList]
    @Binding var isPresented: Bool
    @State private var isPresentingNewListSheet = false
    @State private var newListName = ""
    @State private var newlyCreatedList: SavedItemList?
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if lists.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header summary
                        listHeader
                            .padding(.top, 4)

                        // Cards
                        LazyVStack(spacing: 12) {
                            ForEach(lists) { list in
                                NavigationLink {
                                    SavedListDetailView(list: list, isRootPresented: $isPresented)
                                        .environmentObject(inputVM)
                                } label: {
                                    SavedListCard(list: list) {
                                        loadList(list)
                                    }
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteList(list)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        // Dashed "create new" card
                        Button {
                            newListName = ""
                            isPresentingNewListSheet = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Create New List")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundStyle(AppTheme.outline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                                    .strokeBorder(AppTheme.outlineVariant, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Saved Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newListName = ""
                    isPresentingNewListSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .sheet(isPresented: $isPresentingNewListSheet) {
            newListSheet
        }
        .navigationDestination(item: $newlyCreatedList) { list in
            SavedListDetailView(list: list, isRootPresented: $isPresented)
                .environmentObject(inputVM)
        }
    }

    // MARK: - List Header

    private var listHeader: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("COLLECTION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                Text("Your Lists")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppTheme.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(lists.count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.onSurface)
                Text("LISTS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.outline)
            }
        }
        .padding(20)
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.primaryFixed.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.surfaceLowest)
                    .frame(width: 72, height: 72)
                    .shadow(color: AppTheme.onSurface.opacity(0.06), radius: 10, x: 0, y: 4)
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(AppTheme.outlineVariant)
            }

            VStack(spacing: 8) {
                Text("No saved lists")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.onSurface)
                Text("Create lists of items you buy often to quickly load them into a calculation.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            Button {
                newListName = ""
                isPresentingNewListSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First List")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                                   startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 32)
        .sheet(isPresented: $isPresentingNewListSheet) {
            newListSheet
        }
    }

    // MARK: - New List Sheet

    private var newListSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("New List")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(AppTheme.onSurface)
                    Text("Organize items you buy often for quick reuse.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)

                VStack(alignment: .leading, spacing: 8) {
                    Text("LIST NAME")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.outline)

                    TextField("e.g. Grocery Staples", text: $newListName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.onSurface)
                        .padding(16)
                        .background(AppTheme.surfaceHigh, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                        .autocorrectionDisabled()
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresentingNewListSheet = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.surfaceHigh, in: Capsule())

                    Button("Create") {
                        if let list = createList(named: newListName) {
                            isPresentingNewListSheet = false
                            newlyCreatedList = list
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LinearGradient(colors: [AppTheme.outlineVariant, AppTheme.outlineVariant],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                                             startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppTheme.cornerRadiusLG)
    }

    // MARK: - Helpers

    private func createList(named name: String) -> SavedItemList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let list = SavedItemList(name: trimmed)
        modelContext.insert(list)
        try? modelContext.save()
        return list
    }

    private func deleteList(_ list: SavedItemList) {
        modelContext.delete(list)
        try? modelContext.save()
    }

    private func loadList(_ list: SavedItemList) {
        inputVM.items = list.items.map {
            ShoppingItem(name: $0.name, priceInCents: $0.priceInCents)
        }
        isPresented = false
    }
}

// MARK: - List Card

private struct SavedListCard: View {
    let list: SavedItemList
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.primaryFixed)
                    .frame(width: 46, height: 46)
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(list.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
                    .lineLimit(1)

                Text("\(list.items.count) item\(list.items.count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.outline)
            }

            Spacer()

            // Quick-use button
            Button(action: onUse) {
                Text("Use")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryFixed, in: Capsule())
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.outlineVariant)
        }
        .padding(16)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
