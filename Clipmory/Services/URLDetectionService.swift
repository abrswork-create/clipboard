import Foundation

final class URLDetectionService {
    
    /// Checks if a given string is primarily a URL.
    /// - Parameter text: The text to analyze.
    /// - Returns: A URL if the text is identified as a single link, otherwise nil.
    func detectURL(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fast-path simple schemes
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            if let url = URL(string: trimmed) {
                return url
            }
        }
        
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count))
            
            // We want to ensure that the user selected *just* a URL.
            // If they selected a whole paragraph that contains a URL, we should treat it as Text.
            if let match = matches.first, let url = match.url {
                let matchedString = (trimmed as NSString).substring(with: match.range)
                
                // If the matched URL is essentially the entire string (ignoring minor punctuation/whitespace)
                if matchedString.count >= trimmed.count - 2 {
                    // One more check: if it's just "example.com", NSDataDetector might miss the scheme.
                    // match.url usually prefixes with http:// automatically if it's missing.
                    return url
                }
            }
            
            // Fallback for custom formats or missed domains like "www.apple.com" without scheme
            if trimmed.lowercased().hasPrefix("www.") {
                if let url = URL(string: "https://\(trimmed)") {
                    return url
                }
            }
            
        } catch {
            print("Failed to initialize NSDataDetector: \(error)")
        }
        
        return nil
    }
}
