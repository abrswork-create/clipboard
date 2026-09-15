import SwiftUI
import AppKit

// MARK: - GifItem Model

struct GifSnippet: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: String
    let emoji: String
    let previewText: String
    let urlString: String
}

// MARK: - GifPickerView
// Reaction GIF and meme picker with quick search and copy-to-clipboard functionality.

struct GifPickerView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"
    @State private var hoveredID: UUID? = nil
    @State private var copiedTitle: String? = nil
    
    private let categories = ["All", "Reactions", "Celebration", "Funny", "Work"]
    
    private let sampleGifs: [GifSnippet] = [
        GifSnippet(
            title: "Mind Blown",
            category: "Reactions",
            emoji: "🤯",
            previewText: "Mind Blown Explosion",
            urlString: "https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif"
        ),
        GifSnippet(
            title: "Applause / Bravo",
            category: "Celebration",
            emoji: "👏",
            previewText: "Standing Ovation Clapping",
            urlString: "https://media.giphy.com/media/nbvFVPiEiJH6JOGIok/giphy.gif"
        ),
        GifSnippet(
            title: "Popcorn Watching",
            category: "Reactions",
            emoji: "🍿",
            previewText: "Eating Popcorn Drama",
            urlString: "https://media.giphy.com/media/gl0mkIZOW6Nwc/giphy.gif"
        ),
        GifSnippet(
            title: "Thumbs Up / Approved",
            category: "Reactions",
            emoji: "👍",
            previewText: "Great Job Nodding",
            urlString: "https://media.giphy.com/media/111ebonMs90YLu/giphy.gif"
        ),
        GifSnippet(
            title: "Party / Confetti",
            category: "Celebration",
            emoji: "🎉",
            previewText: "Party Dance Celebration",
            urlString: "https://media.giphy.com/media/artj92V8o75VPL7AeQ/giphy.gif"
        ),
        GifSnippet(
            title: "Facepalm / Sigh",
            category: "Funny",
            emoji: "🤦",
            previewText: "Classic Facepalm Sigh",
            urlString: "https://media.giphy.com/media/3og0INyCmHlNylks9O/giphy.gif"
        ),
        GifSnippet(
            title: "Typing Fast / Hacker",
            category: "Work",
            emoji: "💻",
            previewText: "Intense Fast Keyboard Typing",
            urlString: "https://media.giphy.com/media/ule4akeEDWAYE/giphy.gif"
        ),
        GifSnippet(
            title: "Coffee Needed",
            category: "Work",
            emoji: "☕️",
            previewText: "Need Coffee Energy",
            urlString: "https://media.giphy.com/media/3oKIPnAiaMCws8nOsE/giphy.gif"
        ),
        GifSnippet(
            title: "Dance / Happy",
            category: "Celebration",
            emoji: "🕺",
            previewText: "Happy Groovy Dancing",
            urlString: "https://media.giphy.com/media/blSTtZehjAZ8I/giphy.gif"
        ),
        GifSnippet(
            title: "Shocked / Wide Eyes",
            category: "Reactions",
            emoji: "😱",
            previewText: "Shocked Dropped Jaw",
            urlString: "https://media.giphy.com/media/tfUW8mhiFk8NlRezUS/giphy.gif"
        ),
        GifSnippet(
            title: "This Is Fine",
            category: "Funny",
            emoji: "🔥",
            previewText: "Dog in Fire Room",
            urlString: "https://media.giphy.com/media/9M5jK4GXmD5o1irGrF/giphy.gif"
        ),
        GifSnippet(
            title: "Success Kid",
            category: "Celebration",
            emoji: "✊",
            previewText: "Fist Pump Triumph",
            urlString: "https://media.giphy.com/media/nXxOjZrbnbRxS/giphy.gif"
        )
    ]
    
    private var filteredGifs: [GifSnippet] {
        sampleGifs.filter { gif in
            let matchesCategory = (selectedCategory == "All") || (gif.category == selectedCategory)
            let matchesSearch = searchQuery.isEmpty ||
                gif.title.localizedCaseInsensitiveContains(searchQuery) ||
                gif.previewText.localizedCaseInsensitiveContains(searchQuery)
            return matchesCategory && matchesSearch
        }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 155, maximum: 190), spacing: 10)
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
                            Text("Copied GIF!")
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
                    
                    TextField("Search reaction GIFs (e.g. coffee, dance, popcorn)...", text: $searchQuery)
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
                // Media preview box
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .frame(height: 85)
                    
                    VStack(spacing: 4) {
                        Text(gif.emoji)
                            .font(.system(size: 32))
                        
                        Text(gif.previewText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CFColor.secondaryText)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
                
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
    
    private func copyGif(_ gif: GifSnippet) {
        let pb = NSPasteboard.general
        pb.clearContents()
        // Copy the GIF link and markdown/HTML embed
        pb.setString(gif.urlString, forType: .string)
        
        withAnimation {
            copiedTitle = gif.title
        }
        
        let dummyItem = ClipboardItem(type: .url, text: gif.urlString)
        PasteService.paste(dummyItem)
        
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
