import SwiftUI
import AppKit

// MARK: - GifPickerView
// Premium dedicated gallery for copied animated GIFs from clipboard history.

struct GifPickerView: View {
    @ObservedObject var store: ClipboardStore
    @State private var searchQuery: String = ""
    @State private var hoveredItemID: UUID? = nil
    @State private var selectedItemID: UUID? = nil
    @State private var copiedToastID: UUID? = nil
    
    private var gifItems: [ClipboardItem] {
        store.items.filter { $0.isGif }
    }
    
    private var filteredGifs: [ClipboardItem] {
        if searchQuery.isEmpty {
            return gifItems
        } else {
            return gifItems.filter { item in
                (item.sourceAppName?.localizedCaseInsensitiveContains(searchQuery) == true) ||
                (item.text?.localizedCaseInsensitiveContains(searchQuery) == true)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .padding(.horizontal, 14)
                .opacity(0.4)
            
            if gifItems.isEmpty {
                emptyState
            } else if filteredGifs.isEmpty {
                noResultsState
            } else {
                gifList
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Text("GIFs")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CFColor.primaryText)
                    
                    if !gifItems.isEmpty {
                        Text("\(gifItems.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CFColor.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                }
                
                Spacer()
                
                if copiedToastID != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Copied GIF!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    }
                    .transition(.opacity)
                }
            }
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CFColor.secondaryText)
                
                TextField("Search copied GIFs...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(CFColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(6)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
    
    // MARK: - List
    
    private var gifList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                ForEach(filteredGifs) { item in
                    gifCard(item)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Premium Card
    
    private func gifCard(_ item: ClipboardItem) -> some View {
        let isHovered = hoveredItemID == item.id
        let isSelected = selectedItemID == item.id
        
        return VStack(alignment: .leading, spacing: 0) {
            // Top Bar: App Source, Badge, Time, and Actions
            HStack(alignment: .center) {
                // Source App Pill
                if let source = item.sourceAppName {
                    HStack(spacing: 4) {
                        Text(source.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(CFColor.secondaryText)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.05))
                    )
                }
                
                // GIF Tag
                Text("GIF")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(4)
                
                Spacer()
                
                // Timestamp
                Text(item.createdAt, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(CFColor.secondaryText)
                
                // Star Button
                Button {
                    store.toggleFavorite(item.id)
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(item.isFavorite ? Color.yellow : CFColor.secondaryText)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help(item.isFavorite ? "Unfavorite" : "Favorite")
                
                // Trash Button
                Button {
                    withAnimation {
                        store.delete(item.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(CFColor.secondaryText)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Delete from clipboard")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)
            
            // Media Container (Click to Copy & Paste)
            Button {
                pasteItem(item)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.03))
                    
                    if let gifUrl = item.gifURLString {
                        GifThumbnailView(urlString: gifUrl)
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if let path = item.imagePath, path.lowercased().hasSuffix(".gif"),
                              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                        GifNSImageView(data: data)
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if let path = item.imagePath, let nsImage = FileStorage.loadImage(at: path) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "film")
                            .font(.system(size: 32))
                            .foregroundStyle(CFColor.tabInactive)
                            .frame(height: 120)
                    }
                    
                    // Hover Action Overlay
                    if isHovered {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                            
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.clipboard.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Click to Paste")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .fill(isHovered ? CFColor.cardHover : CFColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .strokeBorder(
                    isSelected ? CFColor.selectedBorder : (isHovered ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06)),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .cfShadow(isHovered ? CFShadow.cardSelected : CFShadow.card)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        .onHover { hovered in
            hoveredItemID = hovered ? item.id : nil
        }
    }
    
    private func pasteItem(_ item: ClipboardItem) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedItemID = item.id
            copiedToastID = item.id
        }
        PasteService.paste(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedToastID == item.id {
                    copiedToastID = nil
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(CFColor.tabInactive)
            
            Text("No copied GIFs yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CFColor.primaryText)
            
            Text("Animated GIFs copied from browsers, Slack,\nDiscord, or Messages will appear here.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(CFColor.tabInactive)
            
            Text("No matching GIFs")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)
            
            Text("Try another search term.")
                .font(.system(size: 12))
                .foregroundStyle(CFColor.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Shared Components

struct GifNSImageView: NSViewRepresentable {
    let data: Data
    
    func makeNSView(context: Context) -> NSImageView {
        let iv = NSImageView()
        iv.imageScaling = .scaleProportionallyUpOrDown
        iv.animates = true
        iv.canDrawSubviewsIntoLayer = true
        iv.wantsLayer = true
        iv.layer?.masksToBounds = true
        iv.layer?.cornerRadius = 6
        iv.image = NSImage(data: data)
        return iv
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        if nsView.image == nil {
            nsView.image = NSImage(data: data)
            nsView.animates = true
        }
    }
}

struct GifThumbnailView: View {
    let urlString: String
    @State private var gifData: Data? = nil
    @State private var isLoading: Bool = true
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.04))
            
            if let data = gifData {
                GifNSImageView(data: data)
                    .transition(.opacity)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "film")
                    .font(.system(size: 20))
                    .foregroundStyle(CFColor.secondaryText)
            }
        }
        .clipped()
        .onAppear {
            loadGif()
        }
    }
    
    private func loadGif() {
        if let cached = GifLoader.shared.cachedData(for: urlString) {
            self.gifData = cached
            self.isLoading = false
            return
        }
        
        GifLoader.shared.loadGif(from: urlString) { data in
            DispatchQueue.main.async {
                self.gifData = data
                self.isLoading = false
            }
        }
    }
}
