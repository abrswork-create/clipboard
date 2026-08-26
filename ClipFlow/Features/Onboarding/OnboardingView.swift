import SwiftUI

// MARK: - OnboardingView
// First-launch experience. Implemented in TASK 20.

struct OnboardingView: View {
    @StateObject var viewModel = OnboardingViewModel()
    
    // Using a fixed size for the onboarding window
    let pageWidth: CGFloat = 500
    let pageHeight: CGFloat = 400
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    OnboardingSlide(
                        icon: "doc.on.clipboard.fill",
                        title: "Welcome to ClipFlow",
                        description: "Your ultimate clipboard manager. Seamlessly store and retrieve everything you copy.",
                        color: .blue
                    )
                    .frame(width: geometry.size.width)
                    
                    OnboardingSlide(
                        icon: "bolt.fill",
                        title: "Instant Access",
                        description: "Press ⌥⌘V anywhere to instantly bring up your clipboard history right by your cursor.",
                        color: .yellow
                    )
                    .frame(width: geometry.size.width)
                    
                    OnboardingSlide(
                        icon: "star.fill",
                        title: "Smart Features",
                        description: "Pin your favorite snippets, filter your history, and securely store text, images, and files.",
                        color: .purple
                    )
                    .frame(width: geometry.size.width)
                    
                    OnboardingSlide(
                        icon: "lock.shield.fill",
                        title: "Privacy First",
                        description: "Everything is stored 100% locally on your Mac. No cloud, no tracking.",
                        color: .green
                    )
                    .frame(width: geometry.size.width)
                }
                .frame(width: geometry.size.width * CGFloat(viewModel.totalPages), alignment: .leading)
                .offset(x: -CGFloat(viewModel.currentPage) * geometry.size.width)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentPage)
            }
            .frame(height: 250)
            .padding(.top, 40)
            
            Spacer()
            
            // Footer
            HStack {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == viewModel.currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
                    }
                }
                
                Spacer()
                
                // Navigation Buttons
                if viewModel.currentPage > 0 {
                    Button("Back") {
                        viewModel.previousPage()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 10)
                }
                
                Button(action: {
                    if viewModel.currentPage == viewModel.totalPages - 1 {
                        viewModel.completeOnboarding()
                    } else {
                        viewModel.nextPage()
                    }
                }) {
                    Text(viewModel.currentPage == viewModel.totalPages - 1 ? "Get Started" : "Next")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .animation(.none, value: viewModel.currentPage) // Prevent text morphing issues
            }
            .padding(30)
        }
        .frame(width: pageWidth, height: pageHeight)
        .background(.regularMaterial)
    }
}

// MARK: - Slide View

struct OnboardingSlide: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(color)
                .symbolRenderingMode(.multicolor)
                .padding()
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)
            
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
            
            Text(description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }
}
