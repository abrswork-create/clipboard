import SwiftUI
import AppKit

// MARK: - CustomGifImageView
// AppKit NSImageView subclass that reports no intrinsic content size so SwiftUI
// layout constraints strictly control width and height, preventing layout jumps.

final class CustomGifImageView: NSImageView {
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }
}

// MARK: - GifNSImageView
// Renders and loops multi-frame animated GIFs using AppKit.

struct GifNSImageView: NSViewRepresentable {
    let data: Data
    
    func makeNSView(context: Context) -> CustomGifImageView {
        let iv = CustomGifImageView()
        iv.imageScaling = .scaleProportionallyUpOrDown
        iv.imageAlignment = .alignCenter
        iv.animates = true
        iv.canDrawSubviewsIntoLayer = true
        iv.wantsLayer = true
        iv.layer?.masksToBounds = true
        iv.layer?.cornerRadius = 6
        iv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        iv.setContentHuggingPriority(.defaultLow, for: .vertical)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        iv.image = NSImage(data: data)
        return iv
    }
    
    func updateNSView(_ nsView: CustomGifImageView, context: Context) {
        if nsView.image == nil {
            nsView.image = NSImage(data: data)
            nsView.animates = true
        }
    }
}

// MARK: - GifCardThumbnailView
// Displays GIF data with calculated aspect ratio constrained to maxHeight.

struct GifCardThumbnailView: View {
    let data: Data
    let maxHeight: CGFloat
    
    private var ratio: CGFloat {
        guard let img = NSImage(data: data), img.size.height > 0 else { return 1.33 }
        return img.size.width / img.size.height
    }
    
    var body: some View {
        let targetWidth = min(max(maxHeight * ratio, 30), 220)
        GifNSImageView(data: data)
            .frame(width: targetWidth, height: maxHeight)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - GifURLThumbnailView
// Asynchronously loads a GIF URL and displays with rigid maxHeight constraints.

struct GifURLThumbnailView: View {
    let urlString: String
    let maxHeight: CGFloat
    @State private var gifData: Data? = nil
    @State private var isLoading: Bool = true
    
    var body: some View {
        if let data = gifData {
            GifCardThumbnailView(data: data, maxHeight: maxHeight)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "film")
                        .font(.system(size: 16))
                        .foregroundStyle(CFColor.secondaryText)
                }
            }
            .frame(width: maxHeight * 1.33, height: maxHeight)
            .onAppear {
                load()
            }
        }
    }
    
    private func load() {
        if let cached = GifLoader.shared.cachedData(for: urlString) {
            self.gifData = cached
            self.isLoading = false
            return
        }
        
        GifLoader.shared.loadGif(from: urlString) { data in
            DispatchQueue.main.async {
                self.gifData = data
                self.isLoading = false
            }
        }
    }
}
