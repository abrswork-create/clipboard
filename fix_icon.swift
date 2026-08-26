import Cocoa

let imagePath = "ClipFlow/Resources/Assets.xcassets/AppIcon.appiconset/clip board(1).png"
guard let image = NSImage(contentsOfFile: imagePath) else {
    print("Could not load image")
    exit(1)
}

let size = image.size
let newImage = NSImage(size: size)

newImage.lockFocus()

// Fill background with black so the scaled down image blends in
NSColor.black.set()
NSRect(origin: .zero, size: size).fill()

// Scale to 90% to prevent the sides from being cut off
let scale: CGFloat = 0.90
let newWidth = size.width * scale
let newHeight = size.height * scale
let rect = NSRect(x: (size.width - newWidth) / 2.0, 
                  y: (size.height - newHeight) / 2.0, 
                  width: newWidth, 
                  height: newHeight)

image.draw(in: rect, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1.0)

newImage.unlockFocus()

guard let tiffData = newImage.tiffRepresentation,
      let bitmapRep = NSBitmapImageRep(data: tiffData),
      let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG")
    exit(1)
}

let outURL = URL(fileURLWithPath: "fixed_icon.png")
do {
    try pngData.write(to: outURL)
    print("Saved to fixed_icon.png")
} catch {
    print("Error saving: \(error)")
}
