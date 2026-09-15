import SwiftUI
import AppKit

// MARK: - GifPickerView
// Dedicated gallery view for copied animated GIFs from clipboard history.
// Uses the exact same card design and grid as ImagesView.

struct GifPickerView: View {
    @ObservedObject var store: ClipboardStore
    @State private var searchQuery: String = ""
    @State private var hoveredItemID: UUID? = nil
    @State private var selectedItemID: UUID? = nil
    
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
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .padding(.horizontal, 12)
                .opacity(0.5)
            
            if gifItems.isEmpty {
                emptyState
            } else if filteredGifs.isEmpty {
                noResultsState
            } else {
                gifGrid
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
    
    // MARK: - Grid
    
    private var gifGrid: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredGifs) { item in
                    gifCard(item)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Card
    
    private func gifCard(_ item: ClipboardItem) -> some View {
        let isHovered = hoveredItemID == item.id
        let isSelected = selectedItemID == item.id
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedItemID = item.id
            }
            PasteService.paste(item)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Image container
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                            .frame(height: 110)
                        
                        if let gifUrl = item.gifURLString {
                            GifThumbnailView(urlString: gifUrl)
                                .frame(height: 100)
                                .cornerRadius(4)
                        } else if let path = item.imagePath {
                            if path.lowercased().hasSuffix(".gif"), let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                                GifNSImageView(data: data)
                                    .frame(height: 100)
                                    .cornerRadius(4)
                            } else if let nsImage = FileStorage.loadImage(at: path) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 100)
                                    .cornerRadius(4)
                            }
                        } else {
                            Image(systemName: "film")
                                .font(.system(size: 24))
                                .foregroundStyle(CFColor.tabInactive)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Top badge / actions on hover
                    if isHovered {
                        HStack(spacing: 4) {
                            Button {
                                store.toggleFavorite(item.id)
                            } label: {
                                Image(systemName: item.isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(item.isFavorite ? Color.yellow : .white)
                                    .frame(width: 22, height: 22)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                withAnimation {
                                    store.delete(item.id)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(6)
                        .transition(.opacity)
                    }
                }
                
                // Card footer with app source & timestamp
                HStack {
                    if let source = item.sourceAppName {
                        Text(source.uppercased())
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(CFColor.secondaryText)
                            .lineLimit(1)
                    } else {
                        Text("GIF")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(CFColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text(item.createdAt, style: .time)
                        .font(.system(size: 9))
                        .foregroundStyle(CFColor.secondaryText)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .fill(isHovered ? CFColor.cardHover : CFColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? CFColor.selectedBorder : Color.primary.opacity(0.06),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cfShadow(isHovered ? CFShadow.cardSelected : CFShadow.card)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            hoveredItemID = hovered ? item.id : nil
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 38))
                .foregroundStyle(CFColor.tabInactive)
            
            Text("No copied GIFs yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CFColor.primaryText)
            
            Text("Animated GIFs copied from\nwebpages or apps will appear here.")
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
        iv.layer?.cornerRadius = 4
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
            RoundedRectangle(cornerRadius: 4, style: .continuous)
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
