import SwiftUI
import AppKit

// MARK: - SymbolsPickerView
// Typographic and mathematical symbols picker with category navigation, search, and click-to-copy.

struct SymbolsPickerView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: SymbolCategory = .arrows
    @State private var hoveredSymbol: String? = nil
    @State private var copiedChar: String? = nil
    
    private let columns = [
        GridItem(.adaptive(minimum: 38, maximum: 46), spacing: 6)
    ]
    
    private var filteredSymbols: [SymbolItem] {
        if searchQuery.isEmpty {
            return SymbolsData.library[selectedCategory] ?? []
        } else {
            let q = searchQuery.lowercased()
            var results: [SymbolItem] = []
            for (_, items) in SymbolsData.library {
                for item in items {
                    if item.char.contains(q) ||
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
                    Text("Symbols")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CFColor.primaryText)
                    
                    Spacer()
                    
                    if let copied = copiedChar {
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
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(CFColor.secondaryText)
                    
                    TextField("Search symbols (e.g. arrow, check, euro, infinity)...", text: $searchQuery)
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
                            ForEach(SymbolCategory.allCases) { cat in
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
            
            // Symbols Grid
            ScrollView(.vertical, showsIndicators: true) {
                if filteredSymbols.isEmpty {
                    noResultsView
                } else {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(filteredSymbols) { item in
                            symbolCell(item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    // MARK: - Category Pill
    
    private func categoryPill(_ category: SymbolCategory) -> some View {
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
    
    // MARK: - Symbol Cell
    
    private func symbolCell(_ item: SymbolItem) -> some View {
        let isHovered = hoveredSymbol == item.char
        
        return Button {
            copySymbol(item.char)
        } label: {
            Text(item.char)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(CFColor.primaryText)
                .frame(width: 40, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? CFColor.cardHover : CFColor.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isHovered ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 1)
                )
                .cfShadow(isHovered ? CFShadow.cardSelected : CFShadow.card)
                .scaleEffect(isHovered ? 1.15 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(item.name)
        .onHover { hovered in
            hoveredSymbol = hovered ? item.char : nil
        }
    }
    
    private func copySymbol(_ char: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(char, forType: .string)
        
        withAnimation {
            copiedChar = char
        }
        
        let dummyItem = ClipboardItem(type: .text, text: char)
        PasteService.paste(dummyItem)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedChar == char {
                    copiedChar = nil
                }
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "textformat")
                .font(.system(size: 32))
                .foregroundStyle(CFColor.tabInactive)
            Text("No symbols found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CFColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
