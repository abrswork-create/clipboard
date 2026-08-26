import Foundation
import Combine

// MARK: - OnboardingViewModel
// Drives the onboarding flow. Implemented in TASK 20.

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    let totalPages: Int = 4
    
    var onComplete: (() -> Void)?
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete?()
    }
}
