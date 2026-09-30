import Foundation

// MARK: - SensitiveDataDetector
// Detects patterns indicative of sensitive data (passwords, API keys, secrets, tokens, credit cards).
// Pre-compiled regular expressions and character-entropy heuristics ensure 0ms latency during scrolling.

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
        
        // Explicit Password Assignments (e.g. password = "...", pwd: "...", DB_PASSWORD=...)
        "(?i)(?:password|passwd|pwd|passcode|passphrase|db_pass|database_password|mysql_pwd|admin_password)\\s*[:=]\\s*['\"]?([^\\s'\"]{4,64})['\"]?",
        
        // Explicit API Key & Secret Key Assignments (e.g. api_key = "...", secret: "...", client_secret=...)
        "(?i)(?:api_key|apikey|api-key|secret_key|secretkey|client_secret|app_secret|access_token|auth_token|refresh_token|private_key|auth_secret)\\s*[:=]\\s*['\"]?([a-zA-Z0-9_\\-\\.\\+]{12,128})['\"]?",
        
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
        
        // Paddle API Keys
        "paddlev2_(?:live|test)_[0-9a-zA-Z_\\-]{30,}",
        
        // Lemon Squeezy API Keys
        "ls_(?:live|test)_[0-9a-zA-Z_\\-]{30,}",
        
        // Webhook Secrets
        "whsec_[0-9a-zA-Z]{32,}",
        
        // Generic API Key Prefixes (key_..., token_..., sec_..., secret_..., pk_..., sk_...)
        "(?:key|token|sec|secret|live|test|pk|sk)_[0-9a-zA-Z]{24,64}",
        
        // GitLab Personal Access Tokens
        "glpat-[0-9a-zA-Z\\-]{20,}",
        
        // NPM Access Tokens
        "npm_[0-9a-zA-Z]{36}",
        
        // Slack Tokens (bot, user, app)
        "xox[baprs]-[0-9a-zA-Z]{10,72}",
        
        // Hugging Face Tokens
        "hf_[a-zA-Z0-9]{34}",
        
        // SendGrid API Keys
        "SG\\.[a-zA-Z0-9_\\-]{22}\\.[a-zA-Z0-9_\\-]{43}",
        
        // JSON Web Tokens (JWT)
        "eyJ[A-Za-z0-9-_=]+\\.eyJ[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_.+/=]+",
        
        // Standalone Hex Secrets / API Hashes (32, 40, or 64 hex characters)
        "(?i)(?:key|secret|token|hash|salt)\\s*[:=]\\s*['\"]?[a-f0-9]{32,64}['\"]?"
    ]
    
    private static let compiledPatterns: [NSRegularExpression] = {
        patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()
    
    /// Maximum character length to inspect to prevent ReDoS or excessive CPU on multi-megabyte clipboard copies
    private static let maxInspectionLength = 16_384

    /// Evaluates whether a standalone string has the complexity and hallmarks of a password or raw secret token
    static func isLikelyPassword(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = trimmed.count
        
        // Passwords are typically between 8 and 64 characters with no whitespace
        guard count >= 8 && count <= 64 else { return false }
        guard !trimmed.contains(where: { $0.isWhitespace }) else { return false }
        
        let lower = trimmed.lowercased()
        
        // Exclude common URLs, emails, file paths, and bundle identifiers
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("ftp://") ||
           lower.hasPrefix("file://") || lower.hasPrefix("mailto:") || lower.hasPrefix("ssh://") {
            return false
        }
        if trimmed.contains("@") && trimmed.contains(".") { return false } // Email
        if trimmed.contains("/") || trimmed.contains("\\") { return false } // Path
        if trimmed.hasPrefix("com.") || trimmed.hasPrefix("org.") || trimmed.hasPrefix("net.") { return false }
        
        // Character class diversity
        var hasLower = false
        var hasUpper = false
        var hasDigit = false
        var hasSpecial = false
        
        let specialSet = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",.<>?/~`\\")
        
        for scalar in trimmed.unicodeScalars {
            if CharacterSet.lowercaseLetters.contains(scalar) {
                hasLower = true
            } else if CharacterSet.uppercaseLetters.contains(scalar) {
                hasUpper = true
            } else if CharacterSet.decimalDigits.contains(scalar) {
                hasDigit = true
            } else if specialSet.contains(scalar) {
                hasSpecial = true
            }
        }
        
        let classesCount = (hasLower ? 1 : 0) + (hasUpper ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSpecial ? 1 : 0)
        
        // Rule 1: High complexity password (all 4 character classes)
        if classesCount >= 4 {
            return true
        }
        
        // Rule 2: 3 classes including symbols (e.g. Letters + Digits + Symbols like "P@ssw0rd")
        if classesCount >= 3 && hasSpecial {
            return true
        }
        
        // Rule 3: 3 classes with length >= 12 (e.g. "MySecurePassword123")
        if classesCount >= 3 && count >= 12 {
            return true
        }
        
        // Rule 4: Generated high-entropy token (>= 16 chars with letters and digits, rich character set)
        if count >= 16 && (hasLower || hasUpper) && hasDigit && classesCount >= 2 {
            let uniqueCount = Set(trimmed).count
            if uniqueCount >= 8 {
                return true
            }
        }
        
        return false
    }

    /// Evaluates text against sensitive regex patterns and password heuristics with zero recompilation cost.
    static func containsSensitiveData(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        
        // 1. Check standalone password heuristic
        if isLikelyPassword(text) {
            return true
        }
        
        // 2. Check regex patterns
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
