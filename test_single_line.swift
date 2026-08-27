import Foundation
import Vision
import CoreGraphics
import AppKit

func testOCR(height: Int) {
    let request = VNRecognizeTextRequest()
    if #available(macOS 13.0, *) {
        request.revision = VNRecognizeTextRequestRevision3
    }
    request.recognitionLanguages = ["ar-MA", "en-US"]
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let nsImage = NSImage(size: NSSize(width: 400, height: height))
    nsImage.lockFocus()
    NSColor.white.set()
    NSRect(x: 0, y: 0, width: 400, height: height).fill()
    let text = "This is a single line of text."
    let attr: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.black,
        .font: NSFont.systemFont(ofSize: 18)
    ]
    // Draw text vertically centered
    (text as NSString).draw(at: NSPoint(x: 10, y: (height - 20) / 2), withAttributes: attr)
    nsImage.unlockFocus()

    var rect = NSRect(x: 0, y: 0, width: 400, height: height)
    let cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)!

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
        if let results = request.results as? [VNRecognizedTextObservation] {
            print("Height: \(height) -> Results: \(results.count)")
            for obs in results {
                if let top = obs.topCandidates(1).first {
                    print("Text: '\(top.string)' Confidence: \(top.confidence)")
                }
            }
        }
    } catch {
        print("Error: \(error)")
    }
}

testOCR(height: 100)
testOCR(height: 30)
testOCR(height: 20)
