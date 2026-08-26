import Foundation
import Vision
import CoreGraphics

final class OCRService {
    
    /// Extracts text from a CGImage using Apple's Vision framework.
    /// - Parameter image: The image to process.
    /// - Returns: A String containing the recognized text, or nil if nothing meaningful was found.
    func extractText(from image: CGImage) async -> String? {
        let request = VNRecognizeTextRequest()
        
        // We want accuracy over speed
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        if #available(macOS 13.0, *) {
            // Revision 3 has much better support for international languages including Arabic
            request.revision = VNRecognizeTextRequestRevision3
        }
        
        var languages = Locale.preferredLanguages
        if !languages.contains(where: { $0.starts(with: "en") }) {
            languages.append("en-US")
        }
        if !languages.contains(where: { $0.starts(with: "ar") }) {
            languages.append("ar-SA")
        }
        
        // WORKAROUND: Apple's Vision framework (Revision 3) has a bug where if English ("en") 
        // appears before Arabic ("ar") in the recognitionLanguages array, it completely fails 
        // to detect Arabic text (returns 0 results). We must sort Arabic to be first.
        languages.sort { lang1, lang2 in
            if lang1.starts(with: "ar") && !lang2.starts(with: "ar") { return true }
            if !lang1.starts(with: "ar") && lang2.starts(with: "ar") { return false }
            return false // Keep original order for everything else
        }
        
        request.recognitionLanguages = languages
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            
            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                return nil
            }
            
            // Sort observations vertically (top to bottom), then horizontally (left to right)
            let sortedObservations = observations.sorted { obs1, obs2 in
                let yDiff = abs(obs1.boundingBox.minY - obs2.boundingBox.minY)
                if yDiff < (obs1.boundingBox.height * 0.5) {
                    return obs1.boundingBox.minX < obs2.boundingBox.minX
                }
                return obs1.boundingBox.minY > obs2.boundingBox.minY
            }
            
            var lines: [String] = []
            var currentLine: [String] = []
            var currentY: CGFloat? = nil
            
            for obs in sortedObservations {
                guard let topCandidate = obs.topCandidates(1).first else { continue }
                guard topCandidate.confidence > 0.4 else { continue }
                
                if let y = currentY {
                    let yDiff = abs(obs.boundingBox.minY - y)
                    if yDiff < (obs.boundingBox.height * 0.5) {
                        currentLine.append(topCandidate.string)
                    } else {
                        lines.append(currentLine.joined(separator: " "))
                        currentLine = [topCandidate.string]
                        currentY = obs.boundingBox.minY
                    }
                } else {
                    currentLine.append(topCandidate.string)
                    currentY = obs.boundingBox.minY
                }
            }
            
            if !currentLine.isEmpty {
                lines.append(currentLine.joined(separator: " "))
            }
            
            let finalText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return finalText.isEmpty ? nil : finalText
            
        } catch {
            print("OCR Error: \(error)")
            return nil
        }
    }
}
