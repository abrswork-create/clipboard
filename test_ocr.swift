import Foundation
import Vision
import CoreGraphics
import AppKit

let request = VNRecognizeTextRequest()
if #available(macOS 13.0, *) {
    request.revision = VNRecognizeTextRequestRevision3
}

var languages = Locale.preferredLanguages
if !languages.contains(where: { $0.starts(with: "en") }) {
    languages.append("en-US")
}
if !languages.contains(where: { $0.starts(with: "ar") }) {
    languages.append("ar-SA")
}

do {
    request.recognitionLanguages = languages
    print("Set languages: \(languages)")
    
    // Create a dummy image
    let nsImage = NSImage(size: NSSize(width: 100, height: 100))
    nsImage.lockFocus()
    NSColor.white.set()
    NSRect(x: 0, y: 0, width: 100, height: 100).fill()
    let text = "Hello World"
    (text as NSString).draw(at: NSPoint(x: 10, y: 40), withAttributes: [.foregroundColor: NSColor.black])
    nsImage.unlockFocus()
    
    var rect = NSRect(x: 0, y: 0, width: 100, height: 100)
    guard let cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
        print("Failed to get cgimage")
        exit(1)
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])
    
    if let results = request.results as? [VNRecognizedTextObservation] {
        print("Results: \(results.count)")
        for obs in results {
            if let top = obs.topCandidates(1).first {
                print("Text: \(top.string)")
            }
        }
    } else {
        print("No results")
    }
} catch {
    print("Error: \(error)")
}
