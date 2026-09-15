import SwiftUI

// MARK: - UpgradePaywallView
// Modal paywall sheet presenting Pro benefits and unlocking access via Lemon Squeezy.

struct UpgradePaywallView: View {
    @ObservedObject var proManager = ProManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var licenseKey: String = ""
    @State private var showLicenseField: Bool = false
    @State private var licenseError: String? = nil
    @State private var isUpgrading: Bool = false
    @State private var isActivating: Bool = false
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
                    .font(.system(size: 11.5))
                    .foregroundStyle(CFColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
            }
            .padding(.bottom, 16)
            
            // Feature List
            VStack(spacing: 10) {
                featureRow(
                    icon: "clock.arrow.circlepath",
                    title: "Unlimited History",
                    description: "Never lose a copied snippet, image, or link again."
                )
                
                featureRow(
                    icon: "pin.fill",
                    title: "Unlimited Pins",
                    description: "Pin all your critical commands, templates, and text."
                )
                
                featureRow(
                    icon: "magnifyingglass",
                    title: "Smart Search & OCR",
                    description: "Search text within copied images, code, and links."
                )
                
                featureRow(
                    icon: "lock.shield.fill",
                    title: "Sensitive Data Masking",
                    description: "Automatic detection and masking of passwords and API keys."
                )
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
            
            // Action Buttons
            VStack(spacing: 8) {
                if showSuccessAnimation {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.green)
                        
                        Text("Clipmory Pro Activated!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                    .padding(.vertical, 8)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button {
                        upgradeNow()
                    } label: {
                        HStack {
                            if isUpgrading {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Text("Upgrade to Pro — $29.99 (Lifetime)")
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
                                TextField("Code (e.g. 7F3A-8B1C-...)", text: $licenseKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11))
                                    .disabled(isActivating)
                                
                                Button {
                                    activateKey()
                                } label: {
                                    if isActivating {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                            .frame(width: 48)
                                    } else {
                                        Text("Activate")
                                            .font(.system(size: 11))
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(isActivating || licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        // Open Lemon Squeezy checkout directly in default browser
        if let url = URL(string: "https://clipmory.lemonsqueezy.com/checkout/buy/e20a9d58-b852-4fae-8a37-d860e88dae66") {
            NSWorkspace.shared.open(url)
        }
        withAnimation { showLicenseField = true }
    }
    
    private func activateKey() {
        let key = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        
        licenseError = nil
        isActivating = true
        
        Task { @MainActor in
            let success = await proManager.activateLicenseAsync(key: key)
            isActivating = false
            
            if success {
                withAnimation { showSuccessAnimation = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    closeModal()
                }
            } else {
                licenseError = proManager.activationError ?? "Invalid license key."
            }
        }
    }
}
