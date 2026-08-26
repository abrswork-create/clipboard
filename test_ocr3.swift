import Foundation
import Vision
import CoreGraphics
import AppKit

let request = VNRecognizeTextRequest()
if #available(macOS 13.0, *) {
    request.revision = VNRecognizeTextRequestRevision3
}

do {
    request.recognitionLanguages = ["ar-MA", "en-MA"]
    print("Set languages: \(request.recognitionLanguages)")
    
    let nsImage = NSImage(size: NSSize(width: 100, height: 100))
    nsImage.lockFocus()
    NSColor.white.set()
    NSRect(x: 0, y: 0, width: 100, height: 100).fill()
    let text = "Hello World"
    (text as NSString).draw(at: NSPoint(x: 10, y: 40), withAttributes: [.foregroundColor: NSColor.black])
    nsImage.unlockFocus()
    
    var rect = NSRect(x: 0, y: 0, width: 100, height: 100)
    let cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])
    
    if let results = request.results as? [VNRecognizedTextObservation] {
        print("Results: \(results.count)")
    }
} catch {
    print("Error: \(error)")
}
