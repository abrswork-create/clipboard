import Foundation
import Vision

let request = VNRecognizeTextRequest()
if #available(macOS 13.0, *) {
    request.revision = VNRecognizeTextRequestRevision3
}

do {
    let supported = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: request.revision)
    print("Supported: \(supported)")
} catch {
    print("Error: \(error)")
}
