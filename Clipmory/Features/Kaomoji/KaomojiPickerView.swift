import SwiftUI
import AppKit

// MARK: - KaomojiPickerView
// Interactive Japanese emoticon picker with category filtering, search, and click-to-copy.

struct KaomojiPickerView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: KaomojiCategory = .happy
    @State private var hoveredKaomoji: String? = nil
    @State private var copiedText: String? = nil
    
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 180), spacing: 8)
    ]
    
    private var filteredKaomojis: [KaomojiItem] {
        if searchQuery.isEmpty {
            return KaomojiData.library[selectedCategory] ?? []
        } else {
            let q = searchQuery.lowercased()
            var results: [KaomojiItem] = []
            for (_, items) in KaomojiData.library {
                for item in items {
                    if item.text.contains(q) ||
                       item.name.lowercased().contains(q) ||
                       item.keywords.contains(where: { $0.contains(q) }) {
                        results.append(item)
                    }
                }
            }
            return results
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("Kaomoji")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CFColor.primaryText)
                    
                    Spacer()
                    
                    if copiedText != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Copied!")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .transition(.opacity)
                    }
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(CFColor.secondaryText)
                    
                    TextField("Search kaomoji (e.g. shrug, flip, bear, love)...", text: $searchQuery)
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
                            ForEach(KaomojiCategory.allCases) { cat in
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
            
            // Kaomoji Grid
            ScrollView(.vertical, showsIndicators: true) {
                if filteredKaomojis.isEmpty {
                    noResultsView
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredKaomojis) { item in
                            kaomojiCard(item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    // MARK: - Category Pill
    
    private func categoryPill(_ category: KaomojiCategory) -> some View {
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
    
    // MARK: - Kaomoji Card
    
    private func kaomojiCard(_ item: KaomojiItem) -> some View {
        let isHovered = hoveredKaomoji == item.text
        
        return Button {
            copyKaomoji(item.text)
        } label: {
            VStack(spacing: 4) {
                Text(item.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CFColor.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Text(item.name)
                    .font(.system(size: 9.5))
                    .foregroundStyle(CFColor.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .fill(isHovered ? CFColor.cardHover : CFColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .strokeBorder(isHovered ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 1)
            )
            .cfShadow(isHovered ? CFShadow.cardSelected : CFShadow.card)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            hoveredKaomoji = hovered ? item.text : nil
        }
    }
    
    private func copyKaomoji(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        
        withAnimation {
            copiedText = text
        }
        
        let dummyItem = ClipboardItem(type: .text, text: text)
        PasteService.paste(dummyItem)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedText == text {
                    copiedText = nil
                }
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "character.bubble")
                .font(.system(size: 32))
                .foregroundStyle(CFColor.tabInactive)
            Text("No kaomoji found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CFColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
