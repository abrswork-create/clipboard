import SwiftUI

// MARK: - ClipboardHistoryView
// Scrollable list of clipboard cards with header controls.

struct ClipboardHistoryView: View {
    @ObservedObject var viewModel: ClipboardHistoryViewModel
    @ObservedObject var store: ClipboardStore
    @ObservedObject var proManager = ProManager.shared
    
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
    
    @State private var interfaceStyle: InterfaceStyle = SettingsRepository.shared.load().interfaceStyle
    @State private var isClearHovered = false

    private var displayItems: [ClipboardItem] {
        SearchService.search(items: store.items, query: viewModel.searchQuery)
    }

    var body: some View {
        VStack(spacing: 0) {
            listHeader
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 8)
                
            Divider()
                .padding(.horizontal, 12)
                .opacity(headerAppeared ? 0.5 : 0)

            if displayItems.isEmpty {
                if !viewModel.searchQuery.isEmpty {
                    noResultsState
                } else {
                    emptyState
                }
            } else {
                itemList
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 12)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowWindowWillOpen"))) { _ in
            triggerAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowInterfaceStyleChanged"))) { _ in
            interfaceStyle = SettingsRepository.shared.load().interfaceStyle
        }
        .onAppear {
            triggerAnimation()
        }
        .alert("You seem to be enjoying Clipmory!", isPresented: $viewModel.showEngagementPrompt) {
            Button("Share on Reddit") {
                let title = "I found an amazing clipboard manager for Mac called Clipmory"
                let text = "I have been using Clipmory to manage my clipboard history and it has completely transformed my workflow. It is incredibly fast, easy to use, and keeps all my copied text and images perfectly organized. Highly recommend checking it out if you want to boost your productivity!"
                if let titleEncoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "https://reddit.com/submit?url=https://clipmory.app&title=\(titleEncoded)&text=\(textEncoded)") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Share on Facebook") {
                let text = "I have been using Clipmory to manage my clipboard history and it has completely transformed my workflow. It is incredibly fast, easy to use, and keeps all my copied text and images perfectly organized. Highly recommend checking it out if you want to boost your productivity!"
                if let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=https://clipmory.app&quote=\(textEncoded)") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Maybe Later", role: .cancel) { }
        } message: {
            Text("Would you mind sharing it with your friends?")
        }
    }
    
    private func triggerAnimation() {
        headerAppeared = false
        cardsAppeared = false
        
        // 250-450ms: Title and search appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.2)) {
                headerAppeared = true
            }
        }
        
        // 300-500ms: Cards appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeOut(duration: 0.2)) {
                cardsAppeared = true
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
                
                Button {
                    viewModel.clearAll()
                } label: {
                    Text("Clear all")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isClearHovered ? CFColor.cardHover : CFColor.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .cfShadow(CFShadow.card)
                }
                .buttonStyle(.plain)
                .onHover { isClearHovered = $0 }
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
                    
                    let visibleUnpinned: [ClipboardItem] = {
                        if proManager.isPro {
                            return unpinned
                        } else {
                            return Array(unpinned.prefix(proManager.freeHistoryLimit))
                        }
                    }()
                    
                    ForEach(visibleUnpinned) { item in
                        cardRow(item)
                            .id("\(item.id)-pinned:\(item.isPinned)-fav:\(item.isFavorite)")
                    }
                    
                    if !proManager.isPro && unpinned.count > proManager.freeHistoryLimit {
                        UpgradeBannerCard(
                            hiddenCount: unpinned.count - proManager.freeHistoryLimit,
                            onUpgrade: {
                                proManager.triggerPaywall(reason: "You have \(unpinned.count - proManager.freeHistoryLimit) hidden items. Upgrade to Pro to unlock unlimited clipboard history.")
                            }
                        )
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
            onPaste:       { viewModel.paste(item.id) },
            style:         interfaceStyle
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

