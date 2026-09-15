import AppKit
import Foundation

// MARK: - FileStorage
// Manages writing media files (images, files) to disk with in-memory caching.
// Images are stored under:
//   ~/Library/Application Support/ClipFlow/Media/Images/

enum FileStorage {

    // MARK: - Memory Cache
    
    private static let imageCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.totalCostLimit = 150 * 1024 * 1024 // 150 MB memory limit
        return cache
    }()

    // MARK: - Directories

    private static let imagesDirectory: URL = {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let imagesDir = baseDir.appendingPathComponent("ClipFlow/Media/Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        return imagesDir
    }()
    
    private static let filesDirectory: URL = {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let filesDir = baseDir.appendingPathComponent("ClipFlow/Media/Files", isDirectory: true)
        try? FileManager.default.createDirectory(at: filesDir, withIntermediateDirectories: true)
        return filesDir
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
            let path = url.path
            let key = NSString(string: path)
            imageCache.setObject(image, forKey: key, cost: png.count)
            return path
        } catch {
            return nil
        }
    }

    /// Saves raw animated GIF data to disk as .gif and returns the file path, or nil on failure.
    @discardableResult
    static func saveGifData(_ data: Data) -> String? {
        let filename = UUID().uuidString + ".gif"
        let url = imagesDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    /// Loads an NSImage from memory cache or disk. Cached in RAM for 60/120 FPS scrolling.
    static func loadImage(at path: String) -> NSImage? {
        let key = NSString(string: path)
        if let cached = imageCache.object(forKey: key) {
            return cached
        }
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        
        // Estimate cost in bytes (width * height * 4 bytes per pixel)
        let cost = Int(image.size.width * image.size.height * 4)
        imageCache.setObject(image, forKey: key, cost: max(cost, 1024))
        return image
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

    /// Deletes a stored media file and clears its in-memory cache entry.
    static func delete(at path: String) {
        let key = NSString(string: path)
        imageCache.removeObject(forKey: key)
        try? FileManager.default.removeItem(atPath: path)
    }
}
