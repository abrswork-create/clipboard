import Foundation
import AppKit

// MARK: - GifLoader
// Asynchronous downloader and disk/memory cache for animated GIFs.

final class GifLoader {
    static let shared = GifLoader()
    
    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var inFlightTasks: [String: [(Data?) -> Void]] = [:]
    private let lock = NSLock()
    
    private init() {
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB memory limit
        
        let baseDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        cacheDirectory = baseDir.appendingPathComponent("com.clipflow.ClipFlow/GifCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Disk Path Helper
    
    private func diskURL(for urlString: String) -> URL {
        let safeName = ContentHasher.hash(string: urlString) + ".gif"
        return cacheDirectory.appendingPathComponent(safeName)
    }
    
    // MARK: - Synchronous Cache Check
    
    func cachedData(for urlString: String) -> Data? {
        let key = NSString(string: urlString)
        if let memData = memoryCache.object(forKey: key) {
            return memData as Data
        }
        let fileUrl = diskURL(for: urlString)
        if fileManager.fileExists(atPath: fileUrl.path), let diskData = try? Data(contentsOf: fileUrl) {
            memoryCache.setObject(diskData as NSData, forKey: key, cost: diskData.count)
            return diskData
        }
        return nil
    }
    
    // MARK: - Load GIF
    
    func loadGif(from urlString: String, completion: @escaping (Data?) -> Void) {
        let key = NSString(string: urlString)
        
        // 1. Check memory cache
        if let memData = memoryCache.object(forKey: key) {
            completion(memData as Data)
            return
        }
        
        // 2. Check disk cache
        let fileUrl = diskURL(for: urlString)
        if fileManager.fileExists(atPath: fileUrl.path), let diskData = try? Data(contentsOf: fileUrl) {
            memoryCache.setObject(diskData as NSData, forKey: key, cost: diskData.count)
            completion(diskData)
            return
        }
        
        // 3. Queue network request (deduplicating concurrent requests for the same URL)
        lock.lock()
        if inFlightTasks[urlString] != nil {
            inFlightTasks[urlString]?.append(completion)
            lock.unlock()
            return
        }
        inFlightTasks[urlString] = [completion]
        lock.unlock()
        
        guard let url = URL(string: urlString) else {
            notifyCompletions(for: urlString, data: nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                self?.notifyCompletions(for: urlString, data: nil)
                return
            }
            
            // Save to memory
            self.memoryCache.setObject(data as NSData, forKey: key, cost: data.count)
            
            // Save to disk
            try? data.write(to: fileUrl)
            
            self.notifyCompletions(for: urlString, data: data)
        }.resume()
    }
    
    private func notifyCompletions(for urlString: String, data: Data?) {
        lock.lock()
        let callbacks = inFlightTasks.removeValue(forKey: urlString) ?? []
        lock.unlock()
        
        DispatchQueue.main.async {
            for callback in callbacks {
                callback(data)
            }
        }
    }
    
    // MARK: - Save Local File for Pasteboard
    
    func getOrSaveLocalGif(urlString: String, data: Data) -> URL {
        let fileUrl = diskURL(for: urlString)
        if !fileManager.fileExists(atPath: fileUrl.path) {
            try? data.write(to: fileUrl)
        }
        return fileUrl
    }
}
