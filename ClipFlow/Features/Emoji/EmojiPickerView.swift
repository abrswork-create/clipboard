import SwiftUI
import AppKit

// MARK: - EmojiPickerView
// Interactive emoji browser with real-time search, category filters, and quick copy-to-pasteboard.

struct EmojiPickerView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: EmojiCategory = .smileys
    @State private var hoveredEmoji: String? = nil
    @State private var copiedEmoji: String? = nil
    
    private let columns = [
        GridItem(.adaptive(minimum: 36, maximum: 44), spacing: 6)
    ]
    
    private var filteredEmojis: [EmojiItem] {
        if searchQuery.isEmpty {
            return EmojiData.library[selectedCategory] ?? []
        } else {
            let q = searchQuery.lowercased()
            var results: [EmojiItem] = []
            for (_, items) in EmojiData.library {
                for item in items {
                    if item.name.lowercased().contains(q) ||
                       item.keywords.contains(where: { $0.contains(q) }) ||
                       item.char == q {
                        results.append(item)
                    }
                }
            }
            return results
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 8) {
                HStack {
                    Text("Emoji")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CFColor.primaryText)
                    
                    Spacer()
                    
                    if let copied = copiedEmoji {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Copied \(copied)")
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
                    
                    TextField("Search emoji (e.g. fire, laugh, coffee)...", text: $searchQuery)
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
                
                // Category Pills (only when not actively searching)
                if searchQuery.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(EmojiCategory.allCases) { cat in
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
            
            // Emoji Grid
            ScrollView(.vertical, showsIndicators: true) {
                if filteredEmojis.isEmpty {
                    noResultsView
                } else {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(filteredEmojis) { item in
                            emojiCell(item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    // MARK: - Category Pill
    
    private func categoryPill(_ category: EmojiCategory) -> some View {
        let isSelected = selectedCategory == category
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 10))
                Text(category.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 8)
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
    
    // MARK: - Emoji Cell
    
    private func emojiCell(_ item: EmojiItem) -> some View {
        let isHovered = hoveredEmoji == item.char
        
        return Button {
            copyEmoji(item.char)
        } label: {
            Text(item.char)
                .font(.system(size: 24))
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? CFColor.cardHover : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isHovered ? Color.primary.opacity(0.1) : Color.clear, lineWidth: 1)
                )
                .scaleEffect(isHovered ? 1.2 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(item.name)
        .onHover { hovered in
            hoveredEmoji = hovered ? item.char : nil
        }
    }
    
    private func copyEmoji(_ char: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(char, forType: .string)
        
        withAnimation {
            copiedEmoji = char
        }
        
        // Auto-paste if accessibility permission granted, otherwise just copy
        let dummyItem = ClipboardItem(type: .text, text: char)
        PasteService.paste(dummyItem)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedEmoji == char {
                    copiedEmoji = nil
                }
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "face.dashed")
                .font(.system(size: 32))
                .foregroundStyle(CFColor.tabInactive)
            Text("No emojis found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CFColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
