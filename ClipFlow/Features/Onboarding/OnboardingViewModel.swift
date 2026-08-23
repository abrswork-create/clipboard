import Foundation
import Combine

// MARK: - OnboardingViewModel
// Drives the onboarding flow. Implemented in TASK 20.

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    let totalPages: Int = 4
}
