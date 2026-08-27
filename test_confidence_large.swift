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

    let nsImage = NSImage(size: NSSize(width: 400, height: 300))
    nsImage.lockFocus()
    NSColor.white.set()
    NSRect(x: 0, y: 0, width: 400, height: 300).fill()
    let attr: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.black,
        .font: NSFont.systemFont(ofSize: 24)
    ]
    (text as NSString).draw(in: NSRect(x: 10, y: 10, width: 380, height: 280), withAttributes: attr)
    nsImage.unlockFocus()

    var rect = NSRect(x: 0, y: 0, width: 400, height: 300)
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

testOCR(text: "Hello World.\nThis is a larger block of text.\nIt has multiple lines.\nLet's see the confidence now.", languages: ["ar-SA", "en-US"])
