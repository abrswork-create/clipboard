import Foundation
import Vision
import CoreGraphics
import AppKit

func testOCR(languages: [String]) {
    let request = VNRecognizeTextRequest()
    if #available(macOS 13.0, *) {
        request.revision = VNRecognizeTextRequestRevision3
    }
    request.recognitionLanguages = languages
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let nsImage = NSImage(size: NSSize(width: 200, height: 100))
    nsImage.lockFocus()
    NSColor.white.set()
    NSRect(x: 0, y: 0, width: 200, height: 100).fill()
    let text = "مرحبا بالعالم"
    let attr: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.black,
        .font: NSFont.systemFont(ofSize: 24)
    ]
    (text as NSString).draw(at: NSPoint(x: 10, y: 40), withAttributes: attr)
    nsImage.unlockFocus()

    var rect = NSRect(x: 0, y: 0, width: 200, height: 100)
    let cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)!

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
        if let results = request.results as? [VNRecognizedTextObservation] {
            print("Languages: \(languages) -> Results: \(results.count)")
            for obs in results {
                if let top = obs.topCandidates(1).first {
                    print("Text: \(top.string)")
                }
            }
        }
    } catch {
        print("Error: \(error)")
    }
}

testOCR(languages: ["ar-MA"])
testOCR(languages: ["ar-SA"])
