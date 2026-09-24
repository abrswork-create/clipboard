import SwiftUI

// MARK: - ClipboardHistoryView
// Scrollable list of clipboard cards with header controls.

struct ClipboardHistoryView: View {
    @ObservedObject var viewModel: ClipboardHistoryViewModel
    @ObservedObject var store: ClipboardStore
    @ObservedObject var proManager = ProManager.shared
    
    @State private var headerAppeared = true
    @State private var cardsAppeared = true
    
    @State private var interfaceStyle: InterfaceStyle = SettingsRepository.shared.load().interfaceStyle
    @State private var isClearHovered = false
    @State private var isSelectHovered = false
    @State private var isFreeBadgeHovered = false

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
        .overlay(alignment: .bottom) {
            if viewModel.isSelectionMode || !viewModel.selectedItemIDs.isEmpty {
                batchActionBar
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isSelectionMode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.selectedItemIDs.count)
        .onExitCommand {
            if viewModel.isSelectionMode || !viewModel.selectedItemIDs.isEmpty {
                viewModel.clearSelection()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowWindowWillOpen"))) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                interfaceStyle = SettingsRepository.shared.load().interfaceStyle
            }
            triggerAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("clipFlowInterfaceStyleChanged"))) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                interfaceStyle = SettingsRepository.shared.load().interfaceStyle
            }
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
        withAnimation(.easeOut(duration: 0.15)) {
            headerAppeared = true
            cardsAppeared = true
        }
    }

    // MARK: - Header

    private var listHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Text("Clipmory")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(CFColor.primaryText)
                    .lineLimit(1)
                    .fixedSize()
                
                // Licensing / Trial Badge
                if proManager.isPro {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                        
                        Text("PRO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(CFColor.primaryText)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(CFColor.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                    )
                    .cfShadow(CFShadow.card)
                } else if proManager.isTrialActive {
                    Button {
                        proManager.triggerPaywall(reason: "You are on day \(8 - proManager.trialDaysRemaining) of your 7-day free trial. Upgrade anytime for lifetime updates.")
                    } label: {
                        HStack(spacing: 3) {
                            Text("TRIAL (\(proManager.trialDaysRemaining)d)")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                                .lineLimit(1)
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 7.5, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isFreeBadgeHovered ? CFColor.cardHover : CFColor.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(isFreeBadgeHovered ? 0.5 : 0.3), lineWidth: 1)
                        )
                        .cfShadow(CFShadow.card)
                    }
                    .buttonStyle(.plain)
                    .onHover { isFreeBadgeHovered = $0 }
                    .pointingHandCursor()
                    .help("7-Day Free Trial Active — Click to Upgrade to Pro")
                    .fixedSize()
                } else {
                    Button {
                        proManager.triggerPaywall(reason: "Your 7-day free trial has expired. Upgrade to Clipmory Pro to continue using Clipmory.")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.red)
                            
                            Text("TRIAL EXPIRED")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(Color.red)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.red.opacity(isFreeBadgeHovered ? 0.14 : 0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.red.opacity(isFreeBadgeHovered ? 0.5 : 0.3), lineWidth: 1)
                        )
                        .cfShadow(CFShadow.card)
                    }
                    .buttonStyle(.plain)
                    .onHover { isFreeBadgeHovered = $0 }
                    .pointingHandCursor()
                    .help("Free Trial Expired — Upgrade to Continue")
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    // Multi-select toggle button
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if viewModel.isSelectionMode {
                                viewModel.clearSelection()
                            } else {
                                viewModel.isSelectionMode = true
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(viewModel.isSelectionMode ? Color.accentColor : CFColor.secondaryText)
                            Text(viewModel.isSelectionMode ? "Done" : "Select")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CFColor.primaryText)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(viewModel.isSelectionMode ? CFColor.cardHover : (isSelectHovered ? CFColor.cardHover : CFColor.cardBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(viewModel.isSelectionMode ? Color.accentColor.opacity(0.35) : (isSelectHovered ? Color.primary.opacity(0.18) : Color.primary.opacity(0.08)), lineWidth: 1)
                        )
                        .cfShadow(CFShadow.card)
                    }
                    .buttonStyle(.plain)
                    .onHover { isSelectHovered = $0 }
                    .pointingHandCursor()
                    .help(viewModel.isSelectionMode ? "Exit selection mode" : "Select multiple items to paste or copy")
                    .fixedSize()

                    Button {
                        viewModel.clearAll()
                    } label: {
                        Text("Clear all")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(isClearHovered ? Color.red : CFColor.clearAll)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isClearHovered ? Color.red.opacity(0.08) : CFColor.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(isClearHovered ? Color.red.opacity(0.25) : Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            .cfShadow(CFShadow.card)
                    }
                    .buttonStyle(.plain)
                    .onHover { isClearHovered = $0 }
                    .pointingHandCursor()
                    .help("Clear clipboard history")
                    .fixedSize()
                }
                .fixedSize(horizontal: true, vertical: false)
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
                    .pointingHandCursor()
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
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
                    
                    let visibleUnpinned: [ClipboardItem] = unpinned
                    
                    ForEach(visibleUnpinned) { item in
                        cardRow(item)
                            .id("\(item.id)-pinned:\(item.isPinned)-fav:\(item.isFavorite)")
                    }
                    
                    if !proManager.isPro {
                        UpgradeBannerCard(
                            isExpired: proManager.isTrialExpired,
                            daysRemaining: proManager.trialDaysRemaining,
                            onUpgrade: {
                                proManager.triggerPaywall(
                                    reason: proManager.isTrialExpired
                                        ? "Your 7-day free trial has expired. Upgrade to Clipmory Pro to continue using Clipmory."
                                        : "You have \(proManager.trialDaysRemaining) days remaining in your free trial. Upgrade to Pro for lifetime updates."
                                )
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .padding(.bottom, (viewModel.isSelectionMode || !viewModel.selectedItemIDs.isEmpty) ? 58 : 0)
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
            style:         interfaceStyle,
            isSelectionMode: viewModel.isSelectionMode,
            isInMultiSelect: viewModel.selectedItemIDs.contains(item.id),
            onToggleMultiSelect: { viewModel.toggleSelection(for: item.id) },
            onShiftSelect: { viewModel.selectRange(to: item.id, in: displayItems) },
            onCommandSelect: { viewModel.toggleSelection(for: item.id) }
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

    // MARK: - Batch Action Bar

    private var batchActionBar: some View {
        HStack(spacing: 8) {
            // Count badge
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text("\(viewModel.selectedItemIDs.count)")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(CFColor.primaryText)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.06))
            )
            .help("\(viewModel.selectedItemIDs.count) items selected")

            Spacer()

            // Select All / Deselect (Icon button)
            Button {
                viewModel.selectAll(items: displayItems)
            } label: {
                Image(systemName: viewModel.selectedItemIDs.count == displayItems.count ? "checklist.checked" : "checklist")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(viewModel.selectedItemIDs.count == displayItems.count ? Color.accentColor : CFColor.primaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help(viewModel.selectedItemIDs.count == displayItems.count ? "Deselect All" : "Select All")

            // Copy button (Icon button)
            Button {
                viewModel.copySelected(orderedItems: displayItems)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CFColor.primaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(viewModel.selectedItemIDs.isEmpty)
            .opacity(viewModel.selectedItemIDs.isEmpty ? 0.4 : 1.0)
            .help("Copy selected items to clipboard")

            // Delete button (Icon button)
            Button {
                viewModel.deleteSelected()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CFColor.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(viewModel.selectedItemIDs.isEmpty)
            .opacity(viewModel.selectedItemIDs.isEmpty ? 0.4 : 1.0)
            .help("Delete selected items")

            // Paste All Button (Primary Icon button with count)
            Button {
                viewModel.pasteSelected(orderedItems: displayItems)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.doc.on.clipboard")
                        .font(.system(size: 11, weight: .semibold))
                    if !viewModel.selectedItemIDs.isEmpty {
                        Text("\(viewModel.selectedItemIDs.count)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(viewModel.selectedItemIDs.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                )
                .cfShadow(CFShadow.card)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(viewModel.selectedItemIDs.isEmpty)
            .opacity(viewModel.selectedItemIDs.isEmpty ? 0.4 : 1.0)
            .keyboardShortcut(.defaultAction)
            .help("Paste all selected items (Return)")

            // Done / Exit Selection Button (Icon button)
            Button {
                viewModel.clearSelection()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CFColor.secondaryText)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help("Done / Exit Selection Mode (Esc)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
    }
}

