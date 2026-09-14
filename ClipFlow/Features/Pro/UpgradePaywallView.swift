import SwiftUI

// MARK: - UpgradePaywallView
// Modal paywall sheet presenting Pro benefits and unlocking access.

struct UpgradePaywallView: View {
    @ObservedObject var proManager = ProManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var licenseKey: String = ""
    @State private var showLicenseField: Bool = false
    @State private var licenseError: String? = nil
    @State private var isUpgrading: Bool = false
    @State private var showSuccessAnimation: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with dismiss button
            HStack {
                Spacer()
                Button {
                    closeModal()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(CFColor.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
            .padding(.horizontal, 14)
            
            // Hero section
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                
                Text("Upgrade to Clipmory Pro")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CFColor.primaryText)
                
                Text(proManager.paywallReason)
                    .font(.system(size: 11))
                    .foregroundStyle(CFColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
            }
            .padding(.bottom, 14)
            
            // Feature comparison list
            VStack(spacing: 10) {
                featureRow(
                    icon: "infinity",
                    title: "Unlimited History",
                    description: "Free tier capped at 20 items. Store 1,000+ items."
                )
                
                featureRow(
                    icon: "pin.fill",
                    title: "Unlimited Pinned Items",
                    description: "Keep all your important snippets & links at hand."
                )
                
                featureRow(
                    icon: "touchid",
                    title: "Touch ID Security",
                    description: "Biometric & passcode lock for sensitive keys."
                )
                
                featureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Lifetime Updates",
                    description: "One-time purchase, no subscription or recurring fees."
                )
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
            
            // Action buttons
            VStack(spacing: 8) {
                if showSuccessAnimation {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Welcome to Clipmory Pro!")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 8)
                } else {
                    Button {
                        upgradeNow()
                    } label: {
                        HStack {
                            if isUpgrading {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Text("Upgrade to Pro — $9.99 (Lifetime)")
                                    .font(.system(size: 12.5, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: CFRadius.button, style: .continuous)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)
                        .cfShadow(CFShadow.card)
                    }
                    .buttonStyle(.plain)
                    
                    // License Key Accordion
                    if showLicenseField {
                        VStack(spacing: 4) {
                            HStack {
                                TextField("Code (e.g. PRO-2026)", text: $licenseKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11))
                                
                                Button("Activate") {
                                    if proManager.activateLicense(key: licenseKey) {
                                        licenseError = nil
                                        withAnimation { showSuccessAnimation = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            closeModal()
                                        }
                                    } else {
                                        licenseError = "Invalid key. Use code PRO-2026."
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .font(.system(size: 11))
                            }
                            
                            if let err = licenseError {
                                Text(err)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.top, 2)
                    } else {
                        Button("Already have a license key?") {
                            withAnimation { showLicenseField = true }
                        }
                        .font(.system(size: 10.5))
                        .foregroundStyle(CFColor.secondaryText)
                        .buttonStyle(.plain)
                    }
                }
                
                Button("Continue with Free Tier") {
                    closeModal()
                }
                .font(.system(size: 10.5))
                .foregroundStyle(CFColor.secondaryText)
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 10)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 26, height: 26)
                
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CFColor.primaryText)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(CFColor.primaryText)
                
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(CFColor.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
    
    private func closeModal() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            proManager.showPaywall = false
        }
        dismiss()
    }
    
    private func upgradeNow() {
        isUpgrading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isUpgrading = false
            proManager.unlockPro()
            withAnimation { showSuccessAnimation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                closeModal()
            }
        }
    }
}
