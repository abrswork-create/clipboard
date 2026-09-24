import SwiftUI

// MARK: - OnboardingView
// Custom animated monochrome first-launch experience.

struct OnboardingView: View {
    @StateObject var viewModel = OnboardingViewModel()
    
    let pageWidth: CGFloat = 900
    let pageHeight: CGFloat = 900
    let lightBackground = Color(white: 0.98)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Paging Content
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    OnboardingFirstSlide(viewModel: viewModel)
                        .frame(width: geometry.size.width)
                    
                    OnboardingSecondSlide(viewModel: viewModel)
                        .frame(width: geometry.size.width)
                    
                    OnboardingThirdSlide(viewModel: viewModel)
                        .frame(width: geometry.size.width)
                        
                    OnboardingPermissionsSlide(viewModel: viewModel)
                        .frame(width: geometry.size.width)
                        
                    OnboardingFinalSlide(viewModel: viewModel)
                        .frame(width: geometry.size.width)
                }
                .frame(width: geometry.size.width * CGFloat(viewModel.totalPages), alignment: .leading)
                .offset(x: -CGFloat(viewModel.currentPage) * geometry.size.width)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.currentPage)
            }
            
            // Bottom progress indicator
            HorizontalProgressIndicator(total: viewModel.totalPages, current: viewModel.currentPage)
                .padding(.bottom, 32)
        }
        .frame(width: pageWidth, height: pageHeight)
        // No scaleEffect so it fits naturally on screen.
        .background(lightBackground)
        .colorScheme(.light)
    }
}

// MARK: - Progress Indicator

struct HorizontalProgressIndicator: View {
    let total: Int
    let current: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.black : Color.black.opacity(0.15))
                    .frame(width: index == current ? 8 : 8, height: index == current ? 8 : 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Clipboard Icon

struct ClipboardIconView: View {
    let faceOpacity: Double
    let lightBackground = Color(white: 0.98)
    
    var body: some View {
        Image("NewMascot")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 120)
            .opacity(faceOpacity == 0 ? 0 : 1)
    }
}

// MARK: - Floating Card View

struct FloatingCardView: View {
    let title: String
    let subtitle: String
    let iconName: String
    let isSystemIcon: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if isSystemIcon {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Text(iconName)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.black)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
            }
            
            if subtitle.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Capsule().fill(Color.black.opacity(0.15)).frame(width: 32, height: 2)
                    Capsule().fill(Color.black.opacity(0.15)).frame(width: 20, height: 2)
                    Capsule().fill(Color.black.opacity(0.15)).frame(width: 28, height: 2)
                }
            } else {
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.4))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Hero Graphic for First Slide

struct FirstSlideHeroGraphic: View {
    let iconScale: CGFloat
    let iconOpacity: Double
    let faceOpacity: Double
    let cardsOpacity: Double
    let cardsOffset: CGFloat
    
    var body: some View {
        ZStack {
            let center = CGPoint(x: 200, y: 120)
            
            // Dashed Lines
            Path { path in
                // TL
                path.move(to: CGPoint(x: center.x - 45, y: center.y - 20))
                path.addQuadCurve(to: CGPoint(x: center.x - 100, y: center.y - 50), control: CGPoint(x: center.x - 80, y: center.y - 20))
                // BL
                path.move(to: CGPoint(x: center.x - 45, y: center.y + 20))
                path.addQuadCurve(to: CGPoint(x: center.x - 100, y: center.y + 50), control: CGPoint(x: center.x - 80, y: center.y + 20))
                // TR
                path.move(to: CGPoint(x: center.x + 45, y: center.y - 20))
                path.addQuadCurve(to: CGPoint(x: center.x + 100, y: center.y - 50), control: CGPoint(x: center.x + 80, y: center.y - 20))
                // BR
                path.move(to: CGPoint(x: center.x + 45, y: center.y + 20))
                path.addQuadCurve(to: CGPoint(x: center.x + 100, y: center.y + 50), control: CGPoint(x: center.x + 80, y: center.y + 20))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .foregroundColor(Color.black.opacity(0.15))
            .opacity(cardsOpacity)
            
            // Decorative Dots
            Group {
                Circle().fill(Color.black.opacity(0.2)).frame(width: 3, height: 3).position(x: 80, y: 30)
                Circle().fill(Color.black.opacity(0.2)).frame(width: 4, height: 4).position(x: 340, y: 190)
                Text("+").font(.system(size: 12, weight: .light)).foregroundColor(Color.black.opacity(0.3)).position(x: 130, y: 20)
                Text("+").font(.system(size: 14, weight: .light)).foregroundColor(Color.black.opacity(0.3)).position(x: 280, y: 210)
                Circle().fill(Color.black.opacity(0.2)).frame(width: 3, height: 3).position(x: 100, y: 130)
                Circle().fill(Color.black.opacity(0.2)).frame(width: 3, height: 3).position(x: 300, y: 80)
            }
            .opacity(cardsOpacity)
            
            // Floating Cards
            Group {
                FloatingCardView(title: "Text", subtitle: "", iconName: "T", isSystemIcon: false)
                    .position(x: center.x - 110, y: center.y - 60)
                
                FloatingCardView(title: "Image", subtitle: "", iconName: "photo.fill", isSystemIcon: true)
                    .position(x: center.x - 110, y: center.y + 60)
                
                FloatingCardView(title: "Link", subtitle: "https://", iconName: "link", isSystemIcon: true)
                    .position(x: center.x + 110, y: center.y - 60)
                
                FloatingCardView(title: "File", subtitle: ".pdf", iconName: "doc.fill", isSystemIcon: true)
                    .position(x: center.x + 110, y: center.y + 60)
            }
            .opacity(cardsOpacity)
            .offset(y: cardsOffset)
            
            // Mascot
            ClipboardIconView(faceOpacity: faceOpacity)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .position(x: center.x, y: center.y)
        }
        .frame(width: 400, height: 240)
    }
}

// MARK: - Animated First Slide

struct OnboardingFirstSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var iconScale: CGFloat = 0.96
    @State private var iconOpacity: Double = 0
    @State private var faceOpacity: Double = 0
    
    @State private var cardsOpacity: Double = 0
    @State private var cardsOffset: CGFloat = 10
    
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 8
    
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 8
    
    @State private var subTaglineOpacity: Double = 0
    @State private var subTaglineOffset: CGFloat = 8
    
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.96
    
    @State private var isHoveringButton = false
    @State private var isPressingButton = false
    @State private var hasAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero Graphic
            FirstSlideHeroGraphic(
                iconScale: iconScale,
                iconOpacity: iconOpacity,
                faceOpacity: faceOpacity,
                cardsOpacity: cardsOpacity,
                cardsOffset: cardsOffset
            )
            
            Spacer().frame(height: 48)
            
            // Typography
            Text("Clipmory")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .opacity(titleOpacity)
                .offset(y: titleOffset)
            
            Spacer().frame(height: 24)
            
            Text("Your clipboard,\nalways within reach.")
                .font(.system(size: 22, weight: .medium, design: .monospaced))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(taglineOpacity)
                .offset(y: taglineOffset)
            
            Spacer().frame(height: 20)
            
            Text("Everything you copy.\nOne shortcut away.")
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(subTaglineOpacity)
                .offset(y: subTaglineOffset)
            
            Spacer().frame(height: 48)
            
            // Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressingButton = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressingButton = false
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(Color.black)
                .cornerRadius(10)
                .shadow(color: isHoveringButton ? Color.black.opacity(0.15) : Color.clear, radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressingButton ? 0.98 : (isHoveringButton ? 1.02 : buttonScale))
            .brightness(isHoveringButton ? 0.05 : 0)
            .opacity(buttonOpacity)
            .onHover { hovering in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isHoveringButton = hovering
                }
            }
            
            Spacer()
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            
            if reduceMotion {
                iconScale = 1.0; iconOpacity = 1.0; faceOpacity = 1.0
                cardsOpacity = 1.0; cardsOffset = 0
                titleOpacity = 1.0; titleOffset = 0
                taglineOpacity = 1.0; taglineOffset = 0
                subTaglineOpacity = 1.0; subTaglineOffset = 0
                buttonOpacity = 1.0; buttonScale = 1.0
                return
            }
            
            // 1. Mascot entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            
            // 2. Eyes micro-movement / Smile
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                faceOpacity = 1.0
            }
            
            // 3. Cards slide/fade
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
                cardsOpacity = 1.0
                cardsOffset = 0
            }
            
            // 4. ClipFlow Title
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            
            // 5. Tagline
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                taglineOpacity = 1.0
                taglineOffset = 0
            }
            
            // 6. SubTagline
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                subTaglineOpacity = 1.0
                subTaglineOffset = 0
            }
            
            // 7. Button
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9)) {
                buttonOpacity = 1.0
                buttonScale = 1.0
            }
        }
    }
}

// MARK: - Animated Second Slide

struct OnboardingSecondSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var hasAnimated = false
    
    @State private var headingOpacity: Double = 0
    @State private var headingOffset: CGFloat = 12
    
    @State private var mockupOpacity: Double = 0
    @State private var mockupScale: CGFloat = 0.95
    
    @State private var featuresOpacity: [Double] = [0, 0, 0, 0]
    @State private var featuresOffset: [CGFloat] = [10, 10, 10, 10]
    
    @State private var privacyOpacity: Double = 0
    @State private var privacyOffset: CGFloat = 10
    
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.96
    
    @State private var isHoveringButton = false
    @State private var isPressingButton = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Heading
            Text("Everything you copy.\nOne place.")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headingOpacity)
                .offset(y: headingOffset)
            
            Spacer().frame(height: 16)
            
            // Subheading
            Text("Clipmory keeps your clipboard history\nready to use — text, images, links, and more.")
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.6))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headingOpacity)
                .offset(y: headingOffset)
            
            Spacer().frame(height: 50)
            
            // Main Hero Area
            HStack(spacing: 48) {
                // Left: App Preview
                ClipFlowAppPreview()
                    .opacity(mockupOpacity)
                    .scaleEffect(mockupScale)
                
                // Right: Feature Callouts
                VStack(spacing: 0) {
                    FeatureCallout(icon: "T", title: "Text", description: "Save any text you copy\nacross all your apps.")
                        .opacity(featuresOpacity[0])
                        .offset(y: featuresOffset[0])
                    
                    Divider().padding(.vertical, 10)
                        .opacity(featuresOpacity[0])
                    
                    FeatureCallout(icon: "photo", title: "Images", description: "Keep screenshots, visuals,\nand images.")
                        .opacity(featuresOpacity[1])
                        .offset(y: featuresOffset[1])
                    
                    Divider().padding(.vertical, 10)
                        .opacity(featuresOpacity[1])
                    
                    FeatureCallout(icon: "link", title: "Links", description: "Store links and access\nthem instantly.")
                        .opacity(featuresOpacity[2])
                        .offset(y: featuresOffset[2])
                    
                    Divider().padding(.vertical, 10)
                        .opacity(featuresOpacity[2])
                    
                    FeatureCallout(icon: "doc.text", title: "Files", description: "Keep important files\nwithin reach.")
                        .opacity(featuresOpacity[3])
                        .offset(y: featuresOffset[3])
                }
                .frame(width: 220)
            }
            
            Spacer().frame(height: 50)
            
            // Privacy Pill
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Everything stays on your device.")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                    Text("Your data is private and never leaves your Mac.")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.02))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
            .opacity(privacyOpacity)
            .offset(y: privacyOffset)
            
            Spacer().frame(height: 40)
            
            // CTA Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressingButton = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressingButton = false
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 220)
                .padding(.vertical, 14)
                .background(Color.black)
                .cornerRadius(10)
                .shadow(color: isHoveringButton ? Color.black.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressingButton ? 0.98 : (isHoveringButton ? 1.02 : buttonScale))
            .brightness(isHoveringButton ? 0.05 : 0)
            .opacity(buttonOpacity)
            .onHover { hovering in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isHoveringButton = hovering
                }
            }
            
            Spacer()
        }
        .onChange(of: viewModel.currentPage) { page in
            if page == 1 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
        .onAppear {
            if viewModel.currentPage == 1 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
    }
    
    private func triggerAnimation() {
        if reduceMotion {
            headingOpacity = 1.0; headingOffset = 0
            mockupOpacity = 1.0; mockupScale = 1.0
            featuresOpacity = [1,1,1,1]; featuresOffset = [0,0,0,0]
            privacyOpacity = 1.0; privacyOffset = 0
            buttonOpacity = 1.0; buttonScale = 1.0
            return
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            headingOpacity = 1.0; headingOffset = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            mockupOpacity = 1.0; mockupScale = 1.0
        }
        
        for i in 0..<4 {
            withAnimation(.easeOut(duration: 0.4).delay(0.4 + Double(i) * 0.1)) {
                featuresOpacity[i] = 1.0
                featuresOffset[i] = 0
            }
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
            privacyOpacity = 1.0; privacyOffset = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0)) {
            buttonOpacity = 1.0; buttonScale = 1.0
        }
    }
}

// MARK: - Animated Third Slide

struct OnboardingThirdSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var hasAnimated = false
    
    @State private var headingOpacity: Double = 0
    @State private var headingOffset: CGFloat = 10
    
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 10
    
    @State private var optionOpacity: Double = 0
    @State private var optionY: CGFloat = 0
    @State private var optionScale: CGFloat = 1.0
    
    @State private var cmdOpacity: Double = 0
    @State private var cmdY: CGFloat = 0
    @State private var cmdScale: CGFloat = 1.0
    
    @State private var vOpacity: Double = 0
    @State private var vY: CGFloat = 0
    @State private var vScale: CGFloat = 1.0
    
    @State private var arrowOpacity: Double = 0
    @State private var arrowOffset: CGFloat = -5
    
    @State private var mockupOpacity: Double = 0
    @State private var mockupScale: CGFloat = 0.95
    
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.96
    
    @State private var isHoveringButton = false
    @State private var isPressingButton = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Headline
            Text("Your clipboard,\none shortcut away.")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headingOpacity)
                .offset(y: headingOffset)
            
            Spacer().frame(height: 14)
            
            // Subtitle
            Text("Press ⌥⌘V to open Clipmory\nfrom anywhere, anytime.")
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(subtitleOpacity)
                .offset(y: subtitleOffset)
            
            Spacer().frame(height: 22)
            
            // Keys
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    ShortcutKeyView(title: "⌥", opacity: optionOpacity, yOffset: optionY, scale: optionScale)
                    ShortcutKeyView(title: "⌘", opacity: cmdOpacity, yOffset: cmdY, scale: cmdScale)
                    ShortcutKeyView(title: "V", opacity: vOpacity, yOffset: vY, scale: vScale)
                }
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black.opacity(0.4))
                    .opacity(arrowOpacity)
                    .offset(y: arrowOffset)
            }
            
            Spacer().frame(height: 14)
            
            // App Preview
            ClipFlowAppPreview()
                .frame(width: 440)
                .scaleEffect(mockupScale * 0.9)
                .opacity(mockupOpacity)
            
            Spacer().frame(height: 30)
            
            // CTA Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressingButton = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressingButton = false
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 220)
                .padding(.vertical, 12)
                .background(Color.black)
                .cornerRadius(10)
                .shadow(color: isHoveringButton ? Color.black.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressingButton ? 0.98 : (isHoveringButton ? 1.02 : buttonScale))
            .brightness(isHoveringButton ? 0.05 : 0)
            .opacity(buttonOpacity)
            .onHover { hovering in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isHoveringButton = hovering
                }
            }
            
            Spacer()
        }
        .onChange(of: viewModel.currentPage) { page in
            if page == 2 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
        .onAppear {
            if viewModel.currentPage == 2 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
    }
    
    private func triggerAnimation() {
        if reduceMotion {
            headingOpacity = 1; headingOffset = 0
            subtitleOpacity = 1; subtitleOffset = 0
            optionOpacity = 1; cmdOpacity = 1; vOpacity = 1
            arrowOpacity = 1; arrowOffset = 0
            mockupOpacity = 1; mockupScale = 1
            buttonOpacity = 1; buttonScale = 1
            return
        }
        
        let t = 0.2
        
        // 1. Headline fades in.
        withAnimation(.easeOut(duration: 0.6).delay(t)) {
            headingOpacity = 1; headingOffset = 0
        }
        
        // 2. Subtitle appears shortly afterward.
        withAnimation(.easeOut(duration: 0.6).delay(t + 0.2)) {
            subtitleOpacity = 1; subtitleOffset = 0
        }
        
        // 3. Keyboard keys appear one by one.
        withAnimation(.easeOut(duration: 0.3).delay(t + 0.5)) { optionOpacity = 1 }
        withAnimation(.easeOut(duration: 0.3).delay(t + 0.6)) { cmdOpacity = 1 }
        withAnimation(.easeOut(duration: 0.3).delay(t + 0.7)) { vOpacity = 1 }
        
        // 4. The keys subtly press down.
        withAnimation(.easeIn(duration: 0.1).delay(t + 1.0)) {
            optionY = 4; optionScale = 0.96
        }
        withAnimation(.easeOut(duration: 0.2).delay(t + 1.1)) {
            optionY = 0; optionScale = 1.0
        }
        
        withAnimation(.easeIn(duration: 0.1).delay(t + 1.1)) {
            cmdY = 4; cmdScale = 0.96
        }
        withAnimation(.easeOut(duration: 0.2).delay(t + 1.2)) {
            cmdY = 0; cmdScale = 1.0
        }
        
        withAnimation(.easeIn(duration: 0.1).delay(t + 1.2)) {
            vY = 4; vScale = 0.96
        }
        withAnimation(.easeOut(duration: 0.2).delay(t + 1.3)) {
            vY = 0; vScale = 1.0
        }
        
        // 5. A small arrow appears.
        withAnimation(.easeOut(duration: 0.4).delay(t + 1.4)) {
            arrowOpacity = 1; arrowOffset = 0
        }
        
        // 6. ClipFlow window smoothly scales/fades into view.
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(t + 1.6)) {
            mockupOpacity = 1; mockupScale = 1
        }
        
        // 7. "Next" button appears last.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(t + 1.9)) {
            buttonOpacity = 1; buttonScale = 1
        }
    }
}

// MARK: - Shortcut Key View

struct ShortcutKeyView: View {
    let title: String
    let opacity: Double
    let yOffset: CGFloat
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 3)
            
            Text(title)
                .font(.system(size: 22, weight: .medium, design: .default)) // Slightly smaller font
                .foregroundColor(.black)
        }
        .frame(width: 50, height: 50) // Smaller frame
        .opacity(opacity)
        .offset(y: yOffset)
        .scaleEffect(scale)
    }
}

// MARK: - Mini Panel

struct MiniClipFlowPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Circle().fill(Color.yellow).frame(width: 8, height: 8)
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Search bar
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
                .frame(height: 20)
            
            // Items
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue.opacity(0.8))
                .frame(height: 30)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.05))
                .frame(height: 30)
                
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.05))
                .frame(height: 30)
        }
        .padding(12)
        .frame(width: 160, height: 180)
        .background(Color(white: 0.15))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 15, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Custom Icons

struct ImageIcon: View {
    var body: some View {

        ZStack {
            // Background photo (red/orange)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.9, green: 0.4, blue: 0.4))
                .frame(width: 44, height: 34)
                .rotationEffect(.degrees(10))
                .offset(x: 4, y: 4)
            
            // Foreground photo (blue)
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .frame(width: 44, height: 34)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.3, green: 0.8, blue: 0.9))
                    .frame(width: 38, height: 28)
                
                // Sun
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                    .position(x: 12, y: 10)
                
                // Mountains
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 28))
                    path.addLine(to: CGPoint(x: 12, y: 15))
                    path.addLine(to: CGPoint(x: 20, y: 24))
                    path.addLine(to: CGPoint(x: 30, y: 9))
                    path.addLine(to: CGPoint(x: 38, y: 18))
                    path.addLine(to: CGPoint(x: 38, y: 28))
                }
                .fill(Color(red: 0.4, green: 0.9, blue: 0.5))
            }
            .frame(width: 44, height: 34)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        }
        .frame(width: 60, height: 40)
    }
}

struct LinkIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.blue], startPoint: .top, endPoint: .bottom))
                .frame(width: 56, height: 56)
                .shadow(color: Color.blue.opacity(0.4), radius: 6, y: 2)
            
            Image(systemName: "link")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct TextIcon: View {
    var body: some View {
        Text("TEXT")
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}

struct FileIcon: View {
    var body: some View {
        Image(systemName: "folder.fill")
            .font(.system(size: 34))
            .foregroundColor(Color(red: 0.3, green: 0.7, blue: 1.0))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Animated Permissions Slide

struct OnboardingPermissionsSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var hasAnimated = false
    
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 12
    @State private var itemsOpacity: Double = 0
    @State private var itemsOffset: CGFloat = 12
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.96
    
    @State private var isAccessibilityTrusted = AXIsProcessTrusted()
    @State private var isScreenRecordingTrusted = CGPreflightScreenCaptureAccess()
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Text("Set up Clipmory")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                
                Text("Allow these permissions to unlock Clipmory's full experience.")
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
            
            Spacer().frame(height: 40)
            
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "keyboard",
                    title: "Accessibility",
                    description: "Lets Clipmory paste your selected item instantly with ⌘V.",
                    isGranted: isAccessibilityTrusted,
                    action: {
                        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                        AXIsProcessTrustedWithOptions(options)
                    }
                )
                
                PermissionRow(
                    icon: "camera.viewfinder",
                    title: "Screen Recording",
                    description: "Lets Clipmory capture selected areas of your screen and extract text from them.",
                    isGranted: isScreenRecordingTrusted,
                    action: {
                        CGRequestScreenCaptureAccess()
                    }
                )
                
                if !isAccessibilityTrusted || !isScreenRecordingTrusted {
                    Text("Note: macOS will force quit the app when you grant these permissions.\nPlease reopen Clipmory from your Applications folder afterwards.")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.black.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .frame(width: 440)
            .opacity(itemsOpacity)
            .offset(y: itemsOffset)
            
            Spacer().frame(height: 40)
            
            // Next Button
            let allGranted = isAccessibilityTrusted && isScreenRecordingTrusted
            
            Button(action: {
                if allGranted {
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(allGranted ? .white : .black.opacity(0.3))
                .frame(width: 220)
                .padding(.vertical, 12)
                .background(allGranted ? Color.black : Color.black.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(allGranted ? Color.black : Color.black.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(!allGranted)
            .scaleEffect(buttonScale)
            .opacity(buttonOpacity)
            
            Spacer()
        }
        .onReceive(timer) { _ in
            let newAx = AXIsProcessTrusted()
            let newSr = CGPreflightScreenCaptureAccess()
            if isAccessibilityTrusted != newAx {
                withAnimation { isAccessibilityTrusted = newAx }
                if newAx {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            if isScreenRecordingTrusted != newSr {
                withAnimation { isScreenRecordingTrusted = newSr }
                if newSr {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
        .onChange(of: viewModel.currentPage) { page in
            if page == 3 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
        .onAppear {
            if viewModel.currentPage == 3 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
    }
    
    private func triggerAnimation() {
        if reduceMotion {
            titleOpacity = 1.0; titleOffset = 0
            subtitleOpacity = 1.0; subtitleOffset = 0
            itemsOpacity = 1.0; itemsOffset = 0
            buttonOpacity = 1.0; buttonScale = 1.0
            return
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            itemsOpacity = 1.0
            itemsOffset = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
            buttonOpacity = 1.0
            buttonScale = 1.0
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.black.opacity(0.8))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 20)
            
            if isGranted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Enabled")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                Button(action: action) {
                    Text("Grant")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGranted ? Color.black.opacity(0.3) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isHovering ? Color.black.opacity(0.06) : Color.black.opacity(0.02), radius: isHovering ? 8 : 4, x: 0, y: isHovering ? 4 : 2)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGranted)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Animated Final Slide

struct FeatureRow: View {
    let icon: String
    let text: String
    let shortcut: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
            
            Spacer()
            
            Text(shortcut)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.06))
                .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 1))
    }
}

struct OnboardingFinalSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var settings = SettingsRepository.shared.load()
    @State private var hasAnimated = false
    
    @State private var mascotScale: CGFloat = 0.9
    @State private var mascotOpacity: Double = 0
    @State private var mascotY: CGFloat = 15
    
    @State private var thumbRotation: Double = -20
    @State private var thumbY: CGFloat = 5
    
    @State private var star1Scale: CGFloat = 0.8
    @State private var star1Opacity: Double = 0
    @State private var star2Scale: CGFloat = 0.8
    @State private var star2Opacity: Double = 0
    @State private var star3Scale: CGFloat = 0.8
    @State private var star3Opacity: Double = 0
    
    @State private var headingOpacity: Double = 0
    @State private var headingY: CGFloat = 10
    
    @State private var featuresOpacity: Double = 0
    @State private var featuresY: CGFloat = 10
    
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.96
    
    @State private var isHoveringButton = false
    @State private var isPressingButton = false
    
    let hotkeyObserver = NotificationCenter.default.publisher(for: .clipFlowHotkeyFired)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Mascot
            ZStack {
                MascotThumbView(thumbRotation: thumbRotation, thumbY: thumbY)
                
                // Sparkles around mascot
                Sparkle(scale: star1Scale, opacity: star1Opacity, color: .black)
                    .offset(x: -60, y: -40)
                
                Sparkle(scale: star2Scale, opacity: star2Opacity, color: .black.opacity(0.6))
                    .offset(x: 70, y: -10)
                
                Sparkle(scale: star3Scale, opacity: star3Opacity, color: .black.opacity(0.3))
                    .offset(x: -50, y: 50)
            }
            .scaleEffect(mascotScale)
            .opacity(mascotOpacity)
            .offset(y: mascotY)
            
            Spacer().frame(height: 32)
            
            // Headline
            Text("You’re all set.")
                .font(.system(size: 36, weight: .semibold, design: .monospaced))
                .foregroundColor(.black)
                .opacity(headingOpacity)
                .offset(y: headingY)
            
            Spacer().frame(height: 24)
            
            // Features / Shortcuts
            VStack(spacing: 12) {
                FeatureRow(icon: "doc.on.clipboard", text: "Open Clipboard History", shortcut: "⌥⌘V")
                FeatureRow(icon: "text.viewfinder", text: "Extract Text from Screen", shortcut: "⌥⌘C")
                FeatureRow(icon: "camera.on.rectangle", text: "Capture Image to Clipboard", shortcut: "⌃⌥⌘C")
            }
            .frame(width: 380)
            .opacity(featuresOpacity)
            .offset(y: featuresY)
            
            Spacer().frame(height: 36)
            
            // CTA Button
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressingButton = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressingButton = false
                    finishAndTriggerPanel()
                }
            }) {
                HStack(spacing: 12) {
                    Text("Open Clipmory")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 300, height: 56)
                .background(Color.black)
                .cornerRadius(12)
                .shadow(color: isHoveringButton ? Color.black.opacity(0.15) : Color.clear, radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressingButton ? 0.97 : (isHoveringButton ? 1.01 : buttonScale))
            .opacity(isHoveringButton ? 0.9 : 1.0)
            .opacity(buttonOpacity)
            .onHover { hovering in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isHoveringButton = hovering
                }
            }
            
            Spacer()
        }
        .onChange(of: viewModel.currentPage) { page in
            if page == 4 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
        .onAppear {
            if viewModel.currentPage == 4 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
    }
    
    private func triggerAnimation() {
        if reduceMotion {
            mascotScale = 1.0; mascotOpacity = 1.0; mascotY = 0
            thumbRotation = 0; thumbY = 0
            star1Opacity = 1.0; star1Scale = 1.0
            star2Opacity = 1.0; star2Scale = 1.0
            star3Opacity = 1.0; star3Scale = 1.0
            headingOpacity = 1.0; headingY = 0
            featuresOpacity = 1.0; featuresY = 0
            buttonOpacity = 1.0; buttonScale = 1.0
            return
        }
        
        let t = 0.2
        
        // Mascot entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(t)) {
            mascotScale = 1.0
            mascotOpacity = 1.0
            mascotY = 0
        }
        
        // Thumb subtly moves up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(t + 0.4)) {
            thumbRotation = 0
            thumbY = 0
        }
        
        // Sparkles sequential
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(t + 0.6)) {
            star1Opacity = 1.0; star1Scale = 1.0
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(t + 0.8)) {
            star2Opacity = 1.0; star2Scale = 1.0
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(t + 1.0)) {
            star3Opacity = 1.0; star3Scale = 1.0
        }
        
        // Heading
        withAnimation(.easeOut(duration: 0.6).delay(t + 0.9)) {
            headingOpacity = 1.0
            headingY = 0
        }
        
        // Features
        withAnimation(.easeOut(duration: 0.5).delay(t + 1.2)) {
            featuresOpacity = 1.0
            featuresY = 0
        }
        
        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(t + 1.6)) {
            buttonOpacity = 1.0
            buttonScale = 1.0
        }
    }
    
    private func finishAndTriggerPanel() {
        viewModel.completeOnboarding()
        NotificationCenter.default.post(name: .clipFlowHotkeyFired, object: nil)
    }
}

// MARK: - Mascot Thumb View

struct MascotThumbView: View {
    let thumbRotation: Double
    let thumbY: CGFloat
    
    var body: some View {
        Image("NewMascot")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 140)
    }
}

// MARK: - Sparkle

struct Sparkle: View {
    let scale: CGFloat
    let opacity: Double
    let color: Color
    
    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 16))
            .foregroundColor(color)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

// MARK: - Side-by-side Layout Components

struct ChecklistItem: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Slide 2 Custom Views

struct ClipFlowAppPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            // Window Header
            HStack {
                // Traffic lights
                HStack(spacing: 6) {
                    Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34)).frame(width: 10, height: 10)
                    Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18)).frame(width: 10, height: 10)
                    Circle().fill(Color(red: 0.15, green: 0.79, blue: 0.25)).frame(width: 10, height: 10)
                }
                Spacer()
                // Toolbar icons
                HStack(spacing: 16) {
                    Image(systemName: "star.fill").foregroundColor(.white.opacity(0.4))
                    Image(systemName: "face.smiling").foregroundColor(.white.opacity(0.4))
                    Image(systemName: "play.tv").foregroundColor(.white.opacity(0.4))
                    Image(systemName: "photo").foregroundColor(.white.opacity(0.4))
                    Image(systemName: "text.bubble").foregroundColor(.white.opacity(0.4))
                    Text("Aa").font(.system(size: 14, weight: .medium, design: .serif)).foregroundColor(.white.opacity(0.4))
                    // Active copy icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15))
                            .frame(width: 32, height: 24)
                        Image(systemName: "doc.on.doc").foregroundColor(.white)
                    }
                }
                .font(.system(size: 13))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            
            // Sub header
            HStack {
                Text("Clipmory").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Spacer()
                Text("Clear all")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.70))
                    )
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)
            .padding(.bottom, 8)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.4))
                Text("Search your clipboard...").foregroundColor(.white.opacity(0.4))
                Spacer()
            }
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            
            // Divider
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            
            // List of items
            VStack(spacing: 0) {
                // Item 1: Text
                PreviewCard(
                    app: "FIREFOX",
                    content: {
                        Text("Text is any written, printed, or electronic set of words that forms a coherent message or body of work")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    },
                    badge: nil
                )
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                
                // Item 2: Image
                PreviewCard(
                    app: "FIREFOX",
                    content: {
                        HStack(alignment: .bottom) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.5))
                                    .frame(width: 50, height: 40)
                                Text("1 01").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }
                            Spacer()
                        }
                    },
                    badge: nil
                )
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                
                // Item 3: URL
                PreviewCard(
                    app: "FIREFOX",
                    content: {
                        Text("https://www.apple.com/")
                            .font(.system(size: 13))
                            .foregroundColor(CFColor.urlText)
                    },
                    badge: nil
                )
            }
        }
        .frame(width: 400)
        .background(Color(white: 0.11))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
    }
}

struct PreviewCard<Content: View>: View {
    let app: String
    let content: Content
    let badge: (String, Color)?
    
    init(app: String, @ViewBuilder content: () -> Content, badge: (String, Color)?) {
        self.app = app
        self.content = content()
        self.badge = badge
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(app).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.4))
                Spacer()
                Image(systemName: "ellipsis").foregroundColor(.white.opacity(0.4))
            }
            content
                .padding(.vertical, 2)
            HStack {
                if let badge = badge {
                    Text(badge.0)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badge.1.opacity(0.4))
                        .cornerRadius(4)
                }
                Spacer()
                Image(systemName: "star").foregroundColor(.white.opacity(0.4))
                Image(systemName: "pin").foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(10)
        .background(Color(white: 0.14))
    }
}

struct FeatureCallout: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.1), lineWidth: 1))
                
                if icon == "T" {
                    Text("T").font(.system(size: 20, weight: .bold, design: .serif))
                } else {
                    Image(systemName: icon).font(.system(size: 18, weight: .medium))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                Text(description)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            Spacer()
        }
    }
}
