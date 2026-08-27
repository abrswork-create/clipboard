import Foundation
import Vision
import CoreGraphics
import AppKit

func testOCR(text: String, languages: [String]) {
    let request = VNRecognizeTextRequest()
    if #available(macOS 13.0, *) {
        request.revision = VNRecognizeTextRequestRevision3
    }
    request.recognitionLanguages = languages
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let nsImage = NSImage(size: NSSize(width: 400, height: 100))
    nsImage.lockFocus()
    NSColor.white.set()
    NSRect(x: 0, y: 0, width: 400, height: 100).fill()
    let attr: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.black,
        .font: NSFont.systemFont(ofSize: 24)
    ]
    (text as NSString).draw(at: NSPoint(x: 10, y: 40), withAttributes: attr)
    nsImage.unlockFocus()

    var rect = NSRect(x: 0, y: 0, width: 400, height: 100)
    let cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)!

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
        if let results = request.results as? [VNRecognizedTextObservation] {
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

testOCR(text: "مرحبا بالعالم", languages: ["ar-SA", "en-US"])
testOCR(text: "Hello World", languages: ["ar-SA", "en-US"])
