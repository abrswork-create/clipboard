import SwiftUI
import AppKit

// MARK: - GifSnippet Model

struct GifSnippet: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: String
    let tags: String
    let urlString: String
}

// MARK: - GifNSImageView
// Native AppKit image view that plays animated GIFs continuously.

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

// MARK: - GifThumbnailView
// Asynchronously loads and caches the GIF, displaying an animated preview.

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
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundStyle(CFColor.secondaryText)
                }
            }
        }
        .frame(height: 105)
        .clipped()
        .onAppear {
            loadGif()
        }
    }
    
    private func loadGif() {
        GifLoader.shared.loadGif(from: urlString) { data in
            DispatchQueue.main.async {
                self.gifData = data
                self.isLoading = false
            }
        }
    }
}

// MARK: - GifPickerView
// Reaction GIF and meme picker with animated previews and copy/paste support.

struct GifPickerView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"
    @State private var hoveredID: UUID? = nil
    @State private var copiedTitle: String? = nil
    
    private let categories = ["All", "Reactions", "Celebration", "Memes", "Work"]
    
    private let curatedGifs: [GifSnippet] = [
        // Reactions
        GifSnippet(
            title: "Mind Blown",
            category: "Reactions",
            tags: "explosion boom whoa shock wow",
            urlString: "https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif"
        ),
        GifSnippet(
            title: "Popcorn Watching",
            category: "Reactions",
            tags: "eating drama movie drama eating watching",
            urlString: "https://media.giphy.com/media/gl0mkIZOW6Nwc/giphy.gif"
        ),
        GifSnippet(
            title: "Thumbs Up",
            category: "Reactions",
            tags: "yes ok approve good job nodding",
            urlString: "https://media.giphy.com/media/111ebonMs90YLu/giphy.gif"
        ),
        GifSnippet(
            title: "Facepalm",
            category: "Reactions",
            tags: "sigh disbelief forehead stupid mistake",
            urlString: "https://media.giphy.com/media/3og0INyCmHlNylks9O/giphy.gif"
        ),
        GifSnippet(
            title: "OMG Shocked",
            category: "Reactions",
            tags: "excited gasp chris pratt wide eyes surprise",
            urlString: "https://media.giphy.com/media/5VKbvrjxpVJCM/giphy.gif"
        ),
        GifSnippet(
            title: "Blinking Guy",
            category: "Reactions",
            tags: "drew scanlon disbelief what white guy blinking",
            urlString: "https://media.giphy.com/media/l3q2K5jinAlChoCLS/giphy.gif"
        ),
        GifSnippet(
            title: "Laughing Hard",
            category: "Reactions",
            tags: "lol haha hilarious dying laughing",
            urlString: "https://media.giphy.com/media/10JhviFuU2gWD6/giphy.gif"
        ),
        GifSnippet(
            title: "Yes Nodding",
            category: "Reactions",
            tags: "agree smiling jack nicholson exactly correct",
            urlString: "https://media.giphy.com/media/XMBJ0l20sNWEM/giphy.gif"
        ),
        GifSnippet(
            title: "Excited Dog",
            category: "Reactions",
            tags: "cute happy dog doggo wow jump",
            urlString: "https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif"
        ),
        GifSnippet(
            title: "Heart Love",
            category: "Reactions",
            tags: "heart love affection adore cute kiss",
            urlString: "https://media.giphy.com/media/M90mJvfWfd5mbUuULX/giphy.gif"
        ),
        GifSnippet(
            title: "Crying Tears",
            category: "Reactions",
            tags: "sad cry tears emotional weep",
            urlString: "https://media.giphy.com/media/OPU6wzx8JrHna/giphy.gif"
        ),
        GifSnippet(
            title: "Rolling Eyes",
            category: "Reactions",
            tags: "annoyed ironical eye roll whatever please",
            urlString: "https://media.giphy.com/media/3o7btUg31RTyA3L6CO/giphy.gif"
        ),
        
        // Celebration
        GifSnippet(
            title: "Applause Bravo",
            category: "Celebration",
            tags: "clapping standing ovation congrats cheer",
            urlString: "https://media.giphy.com/media/nbvFVPiEiJH6JOGIok/giphy.gif"
        ),
        GifSnippet(
            title: "Party Confetti",
            category: "Celebration",
            tags: "celebrate dance celebration party woohoo",
            urlString: "https://media.giphy.com/media/artj92V8o75VPL7AeQ/giphy.gif"
        ),
        GifSnippet(
            title: "Happy Dance",
            category: "Celebration",
            tags: "dance dancing Carlton groovy victory win",
            urlString: "https://media.giphy.com/media/blSTtZehjAZ8I/giphy.gif"
        ),
        GifSnippet(
            title: "Success Kid",
            category: "Celebration",
            tags: "fist pump triumph baby win yes",
            urlString: "https://media.giphy.com/media/nXxOjZrbnbRxS/giphy.gif"
        ),
        GifSnippet(
            title: "Cheers Leonardo",
            category: "Celebration",
            tags: "toast great gatsby drink glass wine celebrate",
            urlString: "https://media.giphy.com/media/GCLlQnV7wNXcA/giphy.gif"
        ),
        GifSnippet(
            title: "Mic Drop",
            category: "Celebration",
            tags: "boom done finished victory obama",
            urlString: "https://media.giphy.com/media/3o7qDSOv7N9IOghNre/giphy.gif"
        ),
        GifSnippet(
            title: "Slow Clap",
            category: "Celebration",
            tags: "clapping citizen kane well done clap",
            urlString: "https://media.giphy.com/media/gLWT587QJ12VO/giphy.gif"
        ),
        
        // Memes
        GifSnippet(
            title: "This Is Fine",
            category: "Memes",
            tags: "fire dog cup coffee chaos ok problem",
            urlString: "https://media.giphy.com/media/9M5jK4GXmD5o1irGrF/giphy.gif"
        ),
        GifSnippet(
            title: "Confused Travolta",
            category: "Memes",
            tags: "pulp fiction looking where lost what",
            urlString: "https://media.giphy.com/media/g01ZnwAUvutuK8GIQn/giphy.gif"
        ),
        GifSnippet(
            title: "Deal With It",
            category: "Memes",
            tags: "sunglasses cool dog swagger savage",
            urlString: "https://media.giphy.com/media/L3ERvA6jWCd0qO4NdX/giphy.gif"
        ),
        
        // Work
        GifSnippet(
            title: "Cat Typing Fast",
            category: "Work",
            tags: "typing keyboard fast work hustle code coder",
            urlString: "https://media.giphy.com/media/JIX9t2j0ZTN98BsM97/giphy.gif"
        ),
        GifSnippet(
            title: "Need Coffee",
            category: "Work",
            tags: "coffee morning tired awake energy caffeine",
            urlString: "https://media.giphy.com/media/3oKIPnAiaMCws8nOsE/giphy.gif"
        ),
        GifSnippet(
            title: "Waiting Skeleton",
            category: "Work",
            tags: "waiting patience loading forever still waiting",
            urlString: "https://media.giphy.com/media/Emg9qPKR5hquI/giphy.gif"
        )
    ]
    
    private var filteredGifs: [GifSnippet] {
        curatedGifs.filter { gif in
            let matchesCategory = (selectedCategory == "All") || (gif.category == selectedCategory)
            let matchesSearch = searchQuery.isEmpty ||
                gif.title.localizedCaseInsensitiveContains(searchQuery) ||
                gif.tags.localizedCaseInsensitiveContains(searchQuery) ||
                gif.category.localizedCaseInsensitiveContains(searchQuery)
            return matchesCategory && matchesSearch
        }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 155, maximum: 195), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("GIFs")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CFColor.primaryText)
                    
                    Spacer()
                    
                    if let copied = copiedTitle {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Copied \(copied)!")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .transition(.opacity)
                    }
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(CFColor.secondaryText)
                    
                    TextField("Search animated reaction GIFs (e.g. mind blown, cat typing, party)...", text: $searchQuery)
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
                
                // Category Pills
                if searchQuery.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(categories, id: \.self) { cat in
                                categoryPill(cat)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 12)
                .opacity(0.5)
            
            // GIF Grid
            ScrollView(.vertical, showsIndicators: true) {
                if filteredGifs.isEmpty {
                    noResultsView
                } else {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(filteredGifs) { gif in
                            gifCard(gif)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    // MARK: - Category Pill
    
    private func categoryPill(_ category: String) -> some View {
        let isSelected = selectedCategory == category
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        } label: {
            Text(category)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? CFColor.selectedTabBackground : Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? CFColor.primaryText : CFColor.secondaryText)
                .cfShadow(isSelected ? CFShadow.card : CFShadow(color: .clear, radius: 0, x: 0, y: 0))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - GIF Card
    
    private func gifCard(_ gif: GifSnippet) -> some View {
        let isHovered = hoveredID == gif.id
        
        return Button {
            copyGif(gif)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Real Animated GIF Preview
                GifThumbnailView(urlString: gif.urlString)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                
                // Title and tag
                HStack {
                    Text(gif.title)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(CFColor.primaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("GIF")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(3)
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
                    .strokeBorder(isHovered ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 1)
            )
            .cfShadow(isHovered ? CFShadow.cardSelected : CFShadow.card)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            hoveredID = hovered ? gif.id : nil
        }
    }
    
    // MARK: - Copy & Paste Action
    
    private func copyGif(_ gif: GifSnippet) {
        withAnimation {
            copiedTitle = gif.title
        }
        
        GifLoader.shared.loadGif(from: gif.urlString) { data in
            guard let data = data else {
                // Fallback: copy link
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(gif.urlString, forType: .string)
                let item = ClipboardItem(type: .url, text: gif.urlString)
                PasteService.paste(item)
                return
            }
            
            // 1. Save locally to cache so fileURL is available
            let localUrl = GifLoader.shared.getOrSaveLocalGif(urlString: gif.urlString, data: data)
            
            // 2. Put animated GIF data, TIFF fallback, file URL, and web URL on pasteboard
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setData(data, forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
            if let image = NSImage(data: data), let tiff = image.tiffRepresentation {
                pb.setData(tiff, forType: .tiff)
            }
            pb.writeObjects([localUrl as NSURL])
            pb.setString(gif.urlString, forType: .string)
            
            // 3. Trigger auto-paste into active app
            let item = ClipboardItem(type: .image, imagePath: localUrl.path)
            PasteService.paste(item)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedTitle == gif.title {
                    copiedTitle = nil
                }
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "play.slash")
                .font(.system(size: 32))
                .foregroundStyle(CFColor.tabInactive)
            Text("No GIFs found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CFColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
