import SwiftUI

// MARK: - OnboardingView
// Custom animated monochrome first-launch experience.

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    init(viewModel: OnboardingViewModel = OnboardingViewModel()) {
        self.viewModel = viewModel
    }
    
    let pageWidth: CGFloat = 740
    let pageHeight: CGFloat = 640
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
            
            // Bottom progress indicator (clickable to test any slide)
            HorizontalProgressIndicator(total: viewModel.totalPages, current: viewModel.currentPage) { index in
                withAnimation {
                    viewModel.currentPage = index
                }
            }
            .padding(.bottom, 22)
            
            // Top-right close button for testing/dismissal
            VStack {
                HStack {
                    Spacer()
                    Button {
                        viewModel.completeOnboarding()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black.opacity(0.22))
                            .padding(22)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .help("Close Onboarding")
                }
                Spacer()
            }
        }
        .frame(width: pageWidth, height: pageHeight)
        .background(lightBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .colorScheme(.light)
    }
}

// MARK: - Progress Indicator

struct HorizontalProgressIndicator: View {
    let total: Int
    let current: Int
    var onSelect: ((Int) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { index in
                Button {
                    onSelect?(index)
                } label: {
                    Circle()
                        .fill(index == current ? Color.black : Color.black.opacity(0.15))
                        .frame(width: index == current ? 8 : 8, height: index == current ? 8 : 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
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
            .scaleEffect(0.85)
            .frame(width: 340, height: 185)
            
            Spacer().frame(height: 18)
            
            // Typography
            Text("Clipmory")
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .opacity(titleOpacity)
                .offset(y: titleOffset)
            
            Spacer().frame(height: 14)
            
            Text("Your clipboard,\nalways within reach.")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(taglineOpacity)
                .offset(y: taglineOffset)
            
            Spacer().frame(height: 10)
            
            Text("Everything you copy.\nOne shortcut away.")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(subTaglineOpacity)
                .offset(y: subTaglineOffset)
            
            Spacer().frame(height: 24)
            
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
                        .font(.system(size: 14, weight: .bold))
                }
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 34)
                .padding(.vertical, 12)
                .background(Color.black)
                .cornerRadius(10)
                .shadow(color: isHoveringButton ? Color.black.opacity(0.15) : Color.clear, radius: 8, x: 0, y: 4)
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
            
            // 4. Clipmory Title
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
    
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.96
    
    @State private var isHoveringButton = false
    @State private var isPressingButton = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Heading
            Text("Everything you copy.\nOne place.")
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headingOpacity)
                .offset(y: headingOffset)
            
            Spacer().frame(height: 10)
            
            // Subheading
            Text("Clipmory keeps your clipboard history\nready to use — text, images, links, and more.")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.6))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headingOpacity)
                .offset(y: headingOffset)
            
            Spacer().frame(height: 24)
            
            // Main Hero Area
            HStack(spacing: 36) {
                // Left: App Preview (Size * 2)
                ClipmoryAppPreview(width: 275, height: 350)
                    .opacity(mockupOpacity)
                    .scaleEffect(mockupScale)
                
                // Right: Feature Callouts
                VStack(spacing: 0) {
                    FeatureCallout(icon: "T", title: "Text", description: "Save any text you copy\nacross all your apps.")
                        .opacity(featuresOpacity[0])
                        .offset(y: featuresOffset[0])
                    
                    Divider().padding(.vertical, 12)
                        .opacity(featuresOpacity[0])
                    
                    FeatureCallout(icon: "photo", title: "Images", description: "Keep screenshots,\nvisuals,\nand images.")
                        .opacity(featuresOpacity[1])
                        .offset(y: featuresOffset[1])
                    
                    Divider().padding(.vertical, 12)
                        .opacity(featuresOpacity[1])
                    
                    FeatureCallout(icon: "link", title: "Links", description: "Store links and access\nthem instantly.")
                        .opacity(featuresOpacity[2])
                        .offset(y: featuresOffset[2])
                    
                    Divider().padding(.vertical, 12)
                        .opacity(featuresOpacity[2])
                    
                    FeatureCallout(icon: "doc.text", title: "Files", description: "Keep important files\nwithin reach.")
                        .opacity(featuresOpacity[3])
                        .offset(y: featuresOffset[3])
                }
                .frame(width: 260)
            }
            
            Spacer().frame(height: 26)
            
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
                .frame(width: 200, height: 46)
                .background(Color.black)
                .cornerRadius(12)
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
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9)) {
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
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headingOpacity)
                .offset(y: headingOffset)
            
            Spacer().frame(height: 8)
            
            // Subtitle
            Text("Press ⌥⌘V to open Clipmory\nfrom anywhere, anytime.")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(subtitleOpacity)
                .offset(y: subtitleOffset)
            
            Spacer().frame(height: 14)
            
            // Keys
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    ShortcutKeyView(title: "⌥", opacity: optionOpacity, yOffset: optionY, scale: optionScale)
                    ShortcutKeyView(title: "⌘", opacity: cmdOpacity, yOffset: cmdY, scale: cmdScale)
                    ShortcutKeyView(title: "V", opacity: vOpacity, yOffset: vY, scale: vScale)
                }
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black.opacity(0.4))
                    .opacity(arrowOpacity)
                    .offset(y: arrowOffset)
            }
            
            Spacer().frame(height: 10)
            
            // App Preview
            ClipmoryAppPreview(maxHeight: 165)
                .opacity(mockupOpacity)
                .scaleEffect(mockupScale)
            
            Spacer().frame(height: 18)
            
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
                        .font(.system(size: 13, weight: .bold))
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 180)
                .padding(.vertical, 11)
                .background(Color.black)
                .cornerRadius(10)
                .shadow(color: isHoveringButton ? Color.black.opacity(0.2) : Color.clear, radius: 6, x: 0, y: 3)
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
        
        // 6. Clipmory window smoothly scales/fades into view.
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
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
            
            Text(title)
                .font(.system(size: 19, weight: .medium, design: .default))
                .foregroundColor(.black)
        }
        .frame(width: 44, height: 44)
        .opacity(opacity)
        .offset(y: yOffset)
        .scaleEffect(scale)
    }
}

// MARK: - Mini Panel

struct MiniClipmoryPanel: View {
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
    
    @State private var isHoveringContinue = false
    @State private var isPressingContinue = false
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var hasGrantedPermission: Bool {
        return isScreenRecordingTrusted || isAccessibilityTrusted
    }
    
    var allGranted: Bool {
        #if !APP_STORE
        return isScreenRecordingTrusted && isAccessibilityTrusted
        #else
        return isScreenRecordingTrusted
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 8) {
                Text("Set up Clipmory")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                
                Text("Configure your preferences and permissions for the best experience.")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
            
            Spacer().frame(height: 20)
            
            VStack(spacing: 12) {
                #if !APP_STORE
                PermissionRow(
                    icon: "keyboard",
                    title: "Auto-Paste",
                    description: "Grant permission to use auto-paste to insert items directly into your active apps.",
                    isGranted: isAccessibilityTrusted,
                    action: {
                        PermissionManager.shared.requestAccessibility()
                        schedulePermissionChecks()
                        var current = SettingsRepository.shared.load()
                        current.assistiveAutoInsert = true
                        SettingsRepository.shared.save(current)
                    }
                )
                #else
                PermissionRow(
                    icon: "figure.roll",
                    title: "Assistive Tools (Optional)",
                    description: "Enables single-action insertion for users with motor difficulty or who cannot press keyboard shortcuts.",
                    isGranted: isAccessibilityTrusted,
                    action: {
                        PermissionManager.shared.requestAccessibility()
                        schedulePermissionChecks()
                        var current = SettingsRepository.shared.load()
                        current.assistiveAutoInsert = true
                        SettingsRepository.shared.save(current)
                    }
                )
                #endif
                
                PermissionRow(
                    icon: "camera.viewfinder",
                    title: "Screen Recording",
                    description: "Grant permission to extract text from images and capture screenshots directly to your clipboard.",
                    isGranted: isScreenRecordingTrusted,
                    action: {
                        PermissionManager.shared.requestScreenRecording()
                        schedulePermissionChecks()
                    }
                )
                
                VStack(spacing: 4) {
                    Text("Click Grant to open System Settings, then turn on the switch for Clipmory.")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text("If Clipmory is not in the list, click the '+' button below and choose Clipmory from Applications.")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(.black.opacity(0.4))
                }
                .multilineTextAlignment(.center)
                .padding(.top, 6)
            }
            .frame(width: 440)
            .opacity(itemsOpacity)
            .offset(y: itemsOffset)
            
            Spacer().frame(height: 20)
            
            // Next / Continue Button
            Button(action: {
                refreshPermissions()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    isPressingContinue = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressingContinue = false
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 8) {
                    Text(allGranted ? "Next" : "Continue")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(hasGrantedPermission ? .white : .black)
                .frame(width: 180)
                .padding(.vertical, 11)
                .background(hasGrantedPermission ? Color.black : Color.black.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(hasGrantedPermission ? Color.black : Color.black.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(10)
                .contentShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: (hasGrantedPermission && isHoveringContinue) ? Color.black.opacity(0.25) : Color.clear, radius: 6, x: 0, y: 3)
                .scaleEffect(isPressingContinue ? 0.96 : (isHoveringContinue ? 1.02 : 1.0))
            }
            .buttonStyle(.plain)
            .scaleEffect(buttonScale)
            .opacity(buttonOpacity)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasGrantedPermission)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHoveringContinue)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressingContinue)
            .onHover { hovering in
                isHoveringContinue = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            if !allGranted {
                Button(action: {
                    viewModel.nextPage()
                }) {
                    Text(hasGrantedPermission ? "Skip remaining optional permissions" : "Skip for now (you can enable anytime in Settings)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.black.opacity(0.5))
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            
            Spacer()
        }
        .onReceive(timer) { _ in
            refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refreshPermissions()
        }
        .onChange(of: viewModel.currentPage) { page in
            if page == 3 {
                refreshPermissions()
                if !hasAnimated {
                    hasAnimated = true
                    triggerAnimation()
                }
            }
        }
        .onAppear {
            refreshPermissions()
            if viewModel.currentPage == 3 && !hasAnimated {
                hasAnimated = true
                triggerAnimation()
            }
        }
    }
    
    private func schedulePermissionChecks() {
        for delay in [0.2, 0.5, 1.0, 2.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                refreshPermissions()
            }
        }
    }
    
    private func refreshPermissions() {
        #if !APP_STORE
        let newAx = AXIsProcessTrusted()
        PermissionManager.shared.isAccessibilityGranted = newAx
        if isAccessibilityTrusted != newAx {
            withAnimation(.easeInOut(duration: 0.2)) {
                isAccessibilityTrusted = newAx
            }
            if newAx {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        #endif
        let newSr = CGPreflightScreenCaptureAccess()
        
        PermissionManager.shared.isScreenRecordingGranted = newSr
        
        if isScreenRecordingTrusted != newSr {
            withAnimation(.easeInOut(duration: 0.2)) {
                isScreenRecordingTrusted = newSr
            }
            if newSr {
                NSApp.activate(ignoringOtherApps: true)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.black.opacity(0.8))
                .frame(width: 26)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1.5)
            }
            
            Spacer(minLength: 12)
            
            if isGranted {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("Enabled")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                Button(action: action) {
                    Text("Grant")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black)
                        .cornerRadius(6)
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .onHover { h in
                    if h { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isGranted ? Color.black.opacity(0.3) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isHovering ? Color.black.opacity(0.05) : Color.black.opacity(0.02), radius: isHovering ? 6 : 3, x: 0, y: isHovering ? 3 : 1)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGranted)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Launch At Login Row

struct LaunchAtLoginRow: View {
    @Binding var isLaunchAtLogin: Bool
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "macbook.and.iphone")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.black.opacity(0.8))
                .frame(width: 26)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Launch at Login")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                    
                    Text("RECOMMENDED")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.08))
                        .cornerRadius(4)
                }
                
                Text("Start Clipmory automatically when you log in.")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1.5)
            }
            
            Spacer(minLength: 12)
            
            Toggle("", isOn: $isLaunchAtLogin)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.black)
                .onChange(of: isLaunchAtLogin) { newValue in
                    let success = LaunchAtLoginManager.shared.setLaunchAtLogin(newValue)
                    var settings = SettingsRepository.shared.load()
                    if success {
                        settings.launchAtLogin = newValue
                    } else {
                        isLaunchAtLogin = LaunchAtLoginManager.shared.isEnabled
                        settings.launchAtLogin = isLaunchAtLogin
                    }
                    SettingsRepository.shared.save(settings)
                }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isLaunchAtLogin ? Color.black.opacity(0.3) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isHovering ? Color.black.opacity(0.05) : Color.black.opacity(0.02), radius: isHovering ? 6 : 3, x: 0, y: isHovering ? 3 : 1)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLaunchAtLogin)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
            
            Spacer()
            
            Text(shortcut)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.06))
                .cornerRadius(5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.08), lineWidth: 1))
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
    
    let hotkeyObserver = NotificationCenter.default.publisher(for: .clipmoryHotkeyFired)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Mascot
            ZStack {
                MascotThumbView(thumbRotation: thumbRotation, thumbY: thumbY)
                
                // Sparkles around mascot
                Sparkle(scale: star1Scale, opacity: star1Opacity, color: .black)
                    .offset(x: -45, y: -30)
                
                Sparkle(scale: star2Scale, opacity: star2Opacity, color: .black.opacity(0.6))
                    .offset(x: 55, y: -8)
                
                Sparkle(scale: star3Scale, opacity: star3Opacity, color: .black.opacity(0.3))
                    .offset(x: -40, y: 40)
            }
            .scaleEffect(mascotScale)
            .opacity(mascotOpacity)
            .offset(y: mascotY)
            
            Spacer().frame(height: 18)
            
            // Headline
            Text("You’re all set.")
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundColor(.black)
                .opacity(headingOpacity)
                .offset(y: headingY)
            
            Spacer().frame(height: 14)
            
            // Features / Shortcuts
            VStack(spacing: 8) {
                FeatureRow(icon: "doc.on.clipboard", text: "Open Clipboard History", shortcut: "⌥⌘V")
                FeatureRow(icon: "text.viewfinder", text: "Extract Text from Screen", shortcut: "⌥⌘C")
                FeatureRow(icon: "camera.on.rectangle", text: "Capture Image to Clipboard", shortcut: "⌃⌥⌘C")
            }
            .frame(width: 350)
            .opacity(featuresOpacity)
            .offset(y: featuresY)
            
            Spacer().frame(height: 22)
            
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
                HStack(spacing: 8) {
                    Text("Open Clipmory")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 240, height: 46)
                .background(Color.black)
                .cornerRadius(10)
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
        NotificationCenter.default.post(name: .clipmoryHotkeyFired, object: nil)
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
            .frame(width: 80, height: 95)
    }
}

// MARK: - Sparkle

struct Sparkle: View {
    let scale: CGFloat
    let opacity: Double
    let color: Color
    
    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 14))
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
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Slide 2 & 3 App Preview

struct ClipmoryAppPreview: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var maxHeight: CGFloat? = nil
    
    var body: some View {
        Image("AppPreview")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .frame(maxHeight: maxHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(app).font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.4))
                Spacer()
                Image(systemName: "ellipsis").foregroundColor(.white.opacity(0.4))
            }
            content
                .padding(.vertical, 2)
            HStack {
                if let badge = badge {
                    Text(badge.0)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badge.1.opacity(0.4))
                        .cornerRadius(3)
                }
                Spacer()
                Image(systemName: "star").foregroundColor(.white.opacity(0.4))
                Image(systemName: "pin").foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(8)
        .background(Color(white: 0.14))
    }
}

struct FeatureCallout: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
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
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
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
