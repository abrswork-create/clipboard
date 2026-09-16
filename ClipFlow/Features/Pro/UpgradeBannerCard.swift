import SwiftUI

// MARK: - UpgradeBannerCard
// A card displayed at the bottom of history indicating 7-day free trial status or expiration,
// seamlessly styled with the app's clean card design system.

struct UpgradeBannerCard: View {
    let isExpired: Bool
    let daysRemaining: Int
    let onUpgrade: () -> Void
    
    @State private var isHovered = false
    @State private var isButtonHovered = false
    
    var body: some View {
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: 8) {
                // Top header: Label, status badge, and Upgrade button
                HStack(alignment: .center, spacing: 6) {
                    Text(isExpired ? "TRIAL EXPIRED" : "FREE TRIAL")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isExpired ? Color.red.opacity(0.85) : CFColor.secondaryText)
                    
                    if !isExpired {
                        Text("\(daysRemaining) DAYS LEFT")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                    }
                    
                    Spacer()
                    
                    // Native sleek Upgrade button
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Upgrade")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: CFRadius.button, style: .continuous)
                            .fill(Color.accentColor.opacity(isButtonHovered ? 0.9 : 1.0))
                    )
                    .cfShadow(CFShadow.card)
                    .onHover { isButtonHovered = $0 }
                }
                
                // Content row: lock/clock icon + title and description
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isExpired ? Color.red.opacity(0.1) : Color.primary.opacity(0.06))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: isExpired ? "lock.fill" : "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isExpired ? Color.red : CFColor.primaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isExpired ? "Your 7-Day Free Trial Has Expired" : "Enjoying Full Access?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CFColor.primaryText)
                        
                        Text(isExpired 
                             ? "Upgrade to Clipmory Pro to restore clipboard history access, pinning, and lifetime updates."
                             : "You have full access during your trial. Upgrade to Pro anytime for lifetime access and updates.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CFColor.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .fill(isHovered ? CFColor.cardHover : CFColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .strokeBorder(
                        isHovered ? (isExpired ? Color.red.opacity(0.4) : Color.accentColor.opacity(0.4)) : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .cfShadow(isHovered ? CFShadow.cardSelected : CFShadow.card)
            .scaleEffect(isHovered ? 1.005 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .padding(.vertical, 4)
    }
}
