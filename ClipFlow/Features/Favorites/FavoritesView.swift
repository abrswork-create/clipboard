import SwiftUI

// MARK: - FavoritesView
// Shows items marked as favorites. Implemented in TASK 14.

struct FavoritesView: View {
    @ObservedObject var store: ClipboardStore
    @State private var selectedItemID: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .padding(.horizontal, 12)
                .opacity(0.5)

            let favorites = store.items.filter { $0.isFavorite }
            if favorites.isEmpty {
                emptyState
            } else {
                itemList(favorites)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Favorites")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(CFColor.primaryText)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private func itemList(_ favorites: [ClipboardItem]) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8) {
                ForEach(favorites) { item in
                    ClipboardItemRow(
                        item: item,
                        isSelected: selectedItemID == item.id,
                        onSelect:      {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedItemID = selectedItemID == item.id ? nil : item.id
                            }
                        },
                        onDelete:      { store.delete(item.id) },
                        onPin:         { store.togglePin(item.id) },
                        onFavorite:    { store.toggleFavorite(item.id) },
                        onPaste:       { PasteService.paste(item) }
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.2), value: favorites)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 36))
                .foregroundStyle(CFColor.tabInactive)

            Text("No favorites yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)

            Text("Star items in your clipboard to\nkeep them here permanently.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
