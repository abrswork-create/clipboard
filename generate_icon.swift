import Cocoa

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)

// Draw background (transparent)
NSColor.clear.set()
rect.fill()

// Background gradient
let gradient = NSGradient(starting: NSColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 1.0), 
                          ending: NSColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0))
let path = NSBezierPath(roundedRect: rect, xRadius: 220, yRadius: 220)
gradient?.draw(in: path, angle: -45.0)

// Draw a white clipboard-like shape in the center
let clipRect = NSRect(x: 312, y: 212, width: 400, height: 550)
let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 40, yRadius: 40)
NSColor.white.set()
clipPath.fill()

// Draw the top clip part
let topClipRect = NSRect(x: 412, y: 720, width: 200, height: 80)
let topClipPath = NSBezierPath(roundedRect: topClipRect, xRadius: 20, yRadius: 20)
NSColor.lightGray.set()
topClipPath.fill()

// Draw some text lines on the clipboard
NSColor.systemGray.withAlphaComponent(0.5).set()
let line1 = NSBezierPath(roundedRect: NSRect(x: 362, y: 600, width: 300, height: 30), xRadius: 15, yRadius: 15)
line1.fill()

let line2 = NSBezierPath(roundedRect: NSRect(x: 362, y: 520, width: 250, height: 30), xRadius: 15, yRadius: 15)
line2.fill()

let line3 = NSBezierPath(roundedRect: NSRect(x: 362, y: 440, width: 280, height: 30), xRadius: 15, yRadius: 15)
line3.fill()


image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmapRep = NSBitmapImageRep(data: tiffData),
      let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("Failed to get PNG data")
    exit(1)
}

let url = URL(fileURLWithPath: "new_icon.png")
do {
    try pngData.write(to: url)
    print("Saved to new_icon.png")
} catch {
    print("Error saving: \(error)")
}
