import AppKit
import Foundation

// MARK: - FileStorage
// Manages writing media files (images, files) to disk.
// Images are stored as PNG under:
//   ~/Library/Application Support/ClipFlow/Media/Images/

enum FileStorage {

    // MARK: - Directories

    private static let imagesDirectory: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipFlow/Media/Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()
    
    private static let filesDirectory: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipFlow/Media/Files", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()

    // MARK: - Image

    /// Saves an NSImage to disk as PNG and returns the file path, or nil on failure.
    @discardableResult
    @MainActor
    static func saveImage(_ image: NSImage) -> String? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else { return nil }

        let filename = UUID().uuidString + ".png"
        let url = imagesDirectory.appendingPathComponent(filename)

        do {
            try png.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    /// Loads an NSImage from a stored path, or nil if the file does not exist.
    static func loadImage(at path: String) -> NSImage? {
        NSImage(contentsOfFile: path)
    }
    
    // MARK: - Generic File
    
    /// Copies an external file into the app's internal storage. Returns the new path.
    static func copyFile(at sourcePath: String) -> String? {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = filesDirectory.appendingPathComponent(UUID().uuidString + "_" + sourceURL.lastPathComponent)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL.path
        } catch {
            return nil
        }
    }

    /// Deletes a stored media file.
    static func delete(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
