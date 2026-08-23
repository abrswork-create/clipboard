import Foundation

// MARK: - SearchService
// Provides instant local search over clipboard history.
// Implemented in TASK 12.

enum SearchService {
    
    /// Filters the given array of clipboard items based on the search query.
    /// Returns the original array if the query is empty.
    static func search(items: [ClipboardItem], query: String) -> [ClipboardItem] {
        let normalizedQuery = ClipboardNormalizer.normalize(query)
        if normalizedQuery.isEmpty { return items }
        
        return items.filter { item in
            // Search text content
            if let text = item.text, ClipboardNormalizer.normalize(text).contains(normalizedQuery) {
                return true
            }
            
            // Search source app name
            if let appName = item.sourceAppName, ClipboardNormalizer.normalize(appName).contains(normalizedQuery) {
                return true
            }
            
            // Search file path/name
            if let path = item.filePath, ClipboardNormalizer.normalize(path).contains(normalizedQuery) {
                return true
            }
            
            return false
        }
    }
}
