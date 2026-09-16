import Foundation

// MARK: - SensitiveDataDetector
// Detects patterns indicative of sensitive data (API keys, secrets, tokens, credit cards).
// Regular expressions are pre-compiled once to guarantee 0ms latency during scrolling.

enum SensitiveDataDetector {
    
    static let patterns: [String] = [
        // Credit Cards (Visa, Mastercard, Amex, Discover)
        "(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})",
        
        // AWS Access Keys
        "(?:A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}",
        
        // Private Keys (RSA, DSA, EC, OPENSSH, PGP)
        "-----BEGIN (?:RSA|DSA|EC|OPENSSH|PRIVATE|PGP) KEY",
        
        // Generic Bearer Tokens
        "(?:Bearer\\s+[A-Za-z0-9\\-\\._~\\+/]+=*)",
        
        // OpenAI API Keys (standard, project, and admin keys)
        "sk-(?:proj-|admin-)?[a-zA-Z0-9_\\-]{32,160}",
        
        // Anthropic Claude API Keys
        "sk-ant-[a-zA-Z0-9_\\-]{30,120}",
        
        // Google / Gemini API Keys
        "AIza[0-9A-Za-z_\\-]{35}",
        
        // GitHub Tokens (classic, fine-grained, app, OAuth, refresh)
        "(?:gh[pousr]_[0-9a-zA-Z]{36}|github_pat_[0-9a-zA-Z_]{82})",
        
        // Stripe API Keys (secret & restricted, live & test)
        "[sr]k_(?:live|test)_[0-9a-zA-Z]{24,34}",
        
        // Slack Tokens (bot, user, app)
        "xox[baprs]-[0-9a-zA-Z]{10,72}",
        
        // Hugging Face Tokens
        "hf_[a-zA-Z0-9]{34}",
        
        // SendGrid API Keys
        "SG\\.[a-zA-Z0-9_\\-]{22}\\.[a-zA-Z0-9_\\-]{43}",
        
        // JSON Web Tokens (JWT)
        "eyJ[A-Za-z0-9-_=]+\\.eyJ[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_.+/=]+"
    ]
    
    private static let compiledPatterns: [NSRegularExpression] = {
        patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()
    
    /// Maximum character length to inspect to prevent ReDoS or excessive CPU on multi-megabyte clipboard copies
    private static let maxInspectionLength = 16_384

    /// Evaluates text against pre-compiled sensitive regex patterns with zero recompilation cost.
    static func containsSensitiveData(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let nsString = text as NSString
        let scanLength = min(nsString.length, maxInspectionLength)
        let range = NSRange(location: 0, length: scanLength)
        
        for regex in compiledPatterns {
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }
}
