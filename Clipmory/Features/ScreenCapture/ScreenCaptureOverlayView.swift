import SwiftUI

struct ScreenCaptureOverlayView: View {
    var onSelectionComplete: (CGRect) -> Void
    
    @State private var dragStart: CGPoint? = nil
    @State private var dragCurrent: CGPoint? = nil
    
    var selectionRect: CGRect {
        guard let start = dragStart, let current = dragCurrent else { return .zero }
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(start.x - current.x)
        let height = abs(start.y - current.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background with cutout
                Color.black.opacity(0.4)
                    .mask(
                        CutoutShape(cutoutRect: selectionRect)
                            .fill(style: FillStyle(eoFill: true))
                    )
                
                // Selection border
                if dragStart != nil {
                    Path { path in
                        path.addRect(selectionRect)
                    }
                    .stroke(Color.white, lineWidth: 1)
                    
                    // Dimensions text
                    let rect = selectionRect
                    if rect.width > 10 && rect.height > 10 {
                        Text("\(Int(rect.width)) × \(Int(rect.height))")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .position(x: rect.maxX - 40, y: rect.maxY + 15) // Placed near bottom right
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStart == nil {
                            dragStart = value.startLocation
                        }
                        dragCurrent = value.location
                    }
                    .onEnded { value in
                        let finalRect = selectionRect
                        dragStart = nil
                        dragCurrent = nil
                        
                        // Convert to bottom-left coordinates for the window (Cocoa coordinate system)
                        // SwiftUI uses top-left coordinates.
                        let cocoaY = geometry.size.height - finalRect.maxY
                        let cocoaRect = CGRect(x: finalRect.minX, y: cocoaY, width: finalRect.width, height: finalRect.height)
                        
                        onSelectionComplete(cocoaRect)
                    }
            )
            .onDisappear {
                // Failsafe cleanup if window disappears
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                // Cancel if the app loses focus (e.g. Command-Tab)
                dragStart = nil
                dragCurrent = nil
                onSelectionComplete(.zero)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct CutoutShape: Shape {
    var cutoutRect: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        if !cutoutRect.isEmpty {
            path.addRect(cutoutRect)
        }
        return path
    }
}
