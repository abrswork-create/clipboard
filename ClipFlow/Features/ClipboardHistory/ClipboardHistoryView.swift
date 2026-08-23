import SwiftUI

// MARK: - ClipboardHistoryView
// Scrollable list of clipboard cards with header controls.

struct ClipboardHistoryView: View {
    @ObservedObject var viewModel: ClipboardHistoryViewModel
    @ObservedObject var store: ClipboardStore

    private var displayItems: [ClipboardItem] {
        SearchService.search(items: store.items, query: viewModel.searchQuery)
    }

    var body: some View {
        VStack(spacing: 0) {
            listHeader
            Divider()
                .padding(.horizontal, 12)
                .opacity(0.5)

            if displayItems.isEmpty {
                if !viewModel.searchQuery.isEmpty {
                    noResultsState
                } else {
                    emptyState
                }
            } else {
                itemList
            }
        }
    }

    // MARK: - Header

    private var listHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Text("Clipboard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CFColor.primaryText)
                
                Spacer()
                
                Button("Clear all") {
                    viewModel.clearAll()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CFColor.clearAll)
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CFColor.secondaryText)
                
                TextField("Search your clipboard...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(CFColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(6)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Item List

    private var itemList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8) {
                // Pinned section
                let pinned = displayItems.filter { $0.isPinned }
                if !pinned.isEmpty {
                    sectionLabel("PINNED")
                    ForEach(pinned) { item in
                        cardRow(item)
                            .id("\(item.id)-pinned:\(item.isPinned)-fav:\(item.isFavorite)")
                    }
                    Divider()
                        .padding(.vertical, 4)
                        .opacity(0.5)
                }

                // Recent section
                let unpinned = displayItems.filter { !$0.isPinned }
                if !unpinned.isEmpty {
                    if !pinned.isEmpty {
                        sectionLabel("RECENT")
                    }
                    ForEach(unpinned) { item in
                        cardRow(item)
                            .id("\(item.id)-pinned:\(item.isPinned)-fav:\(item.isFavorite)")
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.2), value: displayItems)
        }
    }

    // MARK: - Card Row

    private func cardRow(_ item: ClipboardItem) -> some View {
        ClipboardItemRow(
            item: item,
            isSelected: viewModel.selectedItemID == item.id,
            onSelect:      { viewModel.selectItem(item.id) },
            onDelete:      { viewModel.deleteItem(item.id) },
            onPin:         { viewModel.togglePin(item.id) },
            onFavorite:    { viewModel.toggleFavorite(item.id) },
            onPaste:       { viewModel.paste(item.id) }
        )
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(CFColor.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.top, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36))
                .foregroundStyle(CFColor.tabInactive)

            Text("No clipboard history")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)

            Text("Copied text, URLs, and images\nwill appear here.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - No Results State
    
    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(CFColor.tabInactive)

            Text("No results")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)

            Text("Try another search term.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

