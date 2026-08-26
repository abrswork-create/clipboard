import AppKit
import CoreGraphics

enum DetectedContent {
    case text(String)
    case url(URL, originalText: String)
    case image(NSImage)
}

@MainActor
final class ContentDetectionService {
    
    private let ocrService = OCRService()
    private let urlService = URLDetectionService()
    
    /// Analyzes a CGImage and determines the best clipboard representation.
    func analyze(image cgImage: CGImage) async -> DetectedContent {
        let fallbackImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        // 1. Run OCR
        guard let extractedText = await ocrService.extractText(from: cgImage) else {
            return .image(fallbackImage)
        }
        
        // 2. Check for URL
        if let url = urlService.detectURL(in: extractedText) {
            return .url(url, originalText: extractedText)
        }
        
        // 3. Meaningful Text
        // If the text is just random noise characters or a single letter hallucinated from an image, fallback to image.
        let alphanumericCount = extractedText.filter { $0.isLetter || $0.isNumber }.count
        
        if alphanumericCount >= 2 {
            return .text(extractedText)
        }
        
        // Fallback
        return .image(fallbackImage)
    }
}
