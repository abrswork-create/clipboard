import Foundation

// MARK: - Symbol Item & Category

struct SymbolItem: Identifiable, Hashable {
    let id = UUID()
    let char: String
    let name: String
    let keywords: [String]
}

enum SymbolCategory: String, CaseIterable, Identifiable {
    case arrows = "Arrows"
    case math = "Math"
    case currency = "Currency"
    case typography = "Typography"
    case stars = "Stars & Badges"
    case greek = "Greek"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .arrows: return "arrow.right"
        case .math: return "plus.forwardslash.minus"
        case .currency: return "dollarsign.circle"
        case .typography: return "paragraphsign"
        case .stars: return "star"
        case .greek: return "textformat.characters"
        }
    }
}

// MARK: - Symbols Library

enum SymbolsData {
    static let library: [SymbolCategory: [SymbolItem]] = [
        .arrows: [
            SymbolItem(char: "→", name: "Right Arrow", keywords: ["right", "next", "arrow"]),
            SymbolItem(char: "←", name: "Left Arrow", keywords: ["left", "back", "arrow"]),
            SymbolItem(char: "↑", name: "Up Arrow", keywords: ["up", "top", "arrow"]),
            SymbolItem(char: "↓", name: "Down Arrow", keywords: ["down", "bottom", "arrow"]),
            SymbolItem(char: "↔", name: "Left-Right Arrow", keywords: ["horizontal", "both"]),
            SymbolItem(char: "↕", name: "Up-Down Arrow", keywords: ["vertical"]),
            SymbolItem(char: "↗", name: "North-East Arrow", keywords: ["diagonal", "up right"]),
            SymbolItem(char: "↘", name: "South-East Arrow", keywords: ["diagonal", "down right"]),
            SymbolItem(char: "↙", name: "South-West Arrow", keywords: ["diagonal", "down left"]),
            SymbolItem(char: "↖", name: "North-West Arrow", keywords: ["diagonal", "up left"]),
            SymbolItem(char: "⇒", name: "Rightwards Double Arrow", keywords: ["implies", "double"]),
            SymbolItem(char: "⇐", name: "Leftwards Double Arrow", keywords: ["double left"]),
            SymbolItem(char: "⇔", name: "Left-Right Double Arrow", keywords: ["equivalent", "iff"]),
            SymbolItem(char: "➔", name: "Heavy Right Arrow", keywords: ["bold right"]),
            SymbolItem(char: "➜", name: "Round Right Arrow", keywords: ["pointer"]),
            SymbolItem(char: "↳", name: "Downwards Arrow with Corner Leftwards", keywords: ["branch", "reply"]),
            SymbolItem(char: "↵", name: "Downwards Arrow with Corner Rightwards", keywords: ["return", "enter"]),
            SymbolItem(char: "⇄", name: "Rightwards Arrow Over Leftwards", keywords: ["exchange", "swap"]),
            SymbolItem(char: "↺", name: "Anticlockwise Open Circle Arrow", keywords: ["undo", "refresh", "rotate"]),
            SymbolItem(char: "↻", name: "Clockwise Open Circle Arrow", keywords: ["redo", "reload"])
        ],
        .math: [
            SymbolItem(char: "±", name: "Plus-Minus", keywords: ["plus", "minus", "math"]),
            SymbolItem(char: "×", name: "Multiplication", keywords: ["multiply", "times"]),
            SymbolItem(char: "÷", name: "Division", keywords: ["divide"]),
            SymbolItem(char: "≠", name: "Not Equal", keywords: ["inequality", "different"]),
            SymbolItem(char: "≈", name: "Almost Equal", keywords: ["approximate"]),
            SymbolItem(char: "≤", name: "Less Than or Equal", keywords: ["less", "lte"]),
            SymbolItem(char: "≥", name: "Greater Than or Equal", keywords: ["greater", "gte"]),
            SymbolItem(char: "∞", name: "Infinity", keywords: ["infinite", "forever"]),
            SymbolItem(char: "∑", name: "N-Ary Summation", keywords: ["sum", "sigma"]),
            SymbolItem(char: "√", name: "Square Root", keywords: ["radical", "root"]),
            SymbolItem(char: "π", name: "Pi", keywords: ["3.14", "circle"]),
            SymbolItem(char: "∫", name: "Integral", keywords: ["calculus"]),
            SymbolItem(char: "∆", name: "Increment / Delta", keywords: ["delta", "triangle"]),
            SymbolItem(char: "∂", name: "Partial Differential", keywords: ["derivative"]),
            SymbolItem(char: "‰", name: "Per Mille", keywords: ["thousandth", "percent"]),
            SymbolItem(char: "∈", name: "Element Of", keywords: ["in", "set"]),
            SymbolItem(char: "∉", name: "Not An Element Of", keywords: ["not in", "set"]),
            SymbolItem(char: "⊂", name: "Subset Of", keywords: ["subset"]),
            SymbolItem(char: "∩", name: "Intersection", keywords: ["intersection", "cap"]),
            SymbolItem(char: "∪", name: "Union", keywords: ["union", "cup"])
        ],
        .currency: [
            SymbolItem(char: "$", name: "Dollar Sign", keywords: ["dollar", "usd", "cash"]),
            SymbolItem(char: "€", name: "Euro Sign", keywords: ["euro", "eur", "europe"]),
            SymbolItem(char: "£", name: "Pound Sign", keywords: ["pound", "gbp", "uk"]),
            SymbolItem(char: "¥", name: "Yen Sign", keywords: ["yen", "jpy", "cny", "japan"]),
            SymbolItem(char: "₩", name: "Won Sign", keywords: ["won", "krw", "korea"]),
            SymbolItem(char: "₹", name: "Indian Rupee", keywords: ["rupee", "inr", "india"]),
            SymbolItem(char: "₽", name: "Russian Ruble", keywords: ["ruble", "rub", "russia"]),
            SymbolItem(char: "₺", name: "Turkish Lira", keywords: ["lira", "try", "turkey"]),
            SymbolItem(char: "₿", name: "Bitcoin Sign", keywords: ["bitcoin", "btc", "crypto"]),
            SymbolItem(char: "¢", name: "Cent Sign", keywords: ["cent", "penny"]),
            SymbolItem(char: "﷼", name: "Rial Sign", keywords: ["rial", "saudi", "middle east"]),
            SymbolItem(char: "฿", name: "Thai Baht", keywords: ["baht", "thb", "thailand"])
        ],
        .typography: [
            SymbolItem(char: "•", name: "Bullet", keywords: ["bullet", "dot", "list"]),
            SymbolItem(char: "—", name: "Em Dash", keywords: ["dash", "long dash", "emdash"]),
            SymbolItem(char: "–", name: "En Dash", keywords: ["dash", "short dash"]),
            SymbolItem(char: "…", name: "Horizontal Ellipsis", keywords: ["dots", "ellipsis"]),
            SymbolItem(char: "¶", name: "Pilcrow Sign", keywords: ["paragraph", "section"]),
            SymbolItem(char: "§", name: "Section Sign", keywords: ["section", "law", "legal"]),
            SymbolItem(char: "©", name: "Copyright", keywords: ["copyright", "rights"]),
            SymbolItem(char: "®", name: "Registered Trademark", keywords: ["registered", "trademark"]),
            SymbolItem(char: "™", name: "Trade Mark", keywords: ["trademark", "tm"]),
            SymbolItem(char: "°", name: "Degree Sign", keywords: ["degree", "celsius", "fahrenheit"]),
            SymbolItem(char: "†", name: "Dagger", keywords: ["dagger", "footnote"]),
            SymbolItem(char: "‡", name: "Double Dagger", keywords: ["double dagger", "footnote"]),
            SymbolItem(char: "«", name: "Left-Pointing Guillemet", keywords: ["quote", "french"]),
            SymbolItem(char: "»", name: "Right-Pointing Guillemet", keywords: ["quote", "french"])
        ],
        .stars: [
            SymbolItem(char: "★", name: "Black Star", keywords: ["star", "rating", "favorite"]),
            SymbolItem(char: "☆", name: "White Star", keywords: ["star", "outline"]),
            SymbolItem(char: "✓", name: "Check Mark", keywords: ["check", "done", "yes", "correct"]),
            SymbolItem(char: "✔", name: "Heavy Check Mark", keywords: ["check", "bold", "correct"]),
            SymbolItem(char: "✕", name: "Multiplication X", keywords: ["x", "cross", "cancel"]),
            SymbolItem(char: "✖", name: "Heavy Multiplication X", keywords: ["x", "cross", "wrong", "no"]),
            SymbolItem(char: "✦", name: "Black Four Pointed Star", keywords: ["sparkle", "star"]),
            SymbolItem(char: "✧", name: "White Four Pointed Star", keywords: ["sparkle", "star"]),
            SymbolItem(char: "✪", name: "Circled White Star", keywords: ["star", "circle"]),
            SymbolItem(char: "❂", name: "Circled Open Centre Eight Pointed Star", keywords: ["emblem", "star"]),
            SymbolItem(char: "❄", name: "Snowflake", keywords: ["snow", "winter", "cold"]),
            SymbolItem(char: "♠", name: "Black Spade Suit", keywords: ["spade", "cards"]),
            SymbolItem(char: "♣", name: "Black Club Suit", keywords: ["club", "cards"]),
            SymbolItem(char: "♥", name: "Black Heart Suit", keywords: ["heart", "cards"]),
            SymbolItem(char: "♦", name: "Black Diamond Suit", keywords: ["diamond", "cards"])
        ],
        .greek: [
            SymbolItem(char: "α", name: "Alpha", keywords: ["alpha", "greek"]),
            SymbolItem(char: "β", name: "Beta", keywords: ["beta", "greek"]),
            SymbolItem(char: "γ", name: "Gamma", keywords: ["gamma", "greek"]),
            SymbolItem(char: "δ", name: "Delta", keywords: ["delta", "greek"]),
            SymbolItem(char: "ε", name: "Epsilon", keywords: ["epsilon", "greek"]),
            SymbolItem(char: "θ", name: "Theta", keywords: ["theta", "greek"]),
            SymbolItem(char: "λ", name: "Lambda", keywords: ["lambda", "greek"]),
            SymbolItem(char: "μ", name: "Mu", keywords: ["mu", "micro"]),
            SymbolItem(char: "π", name: "Pi", keywords: ["pi", "greek"]),
            SymbolItem(char: "σ", name: "Sigma", keywords: ["sigma", "greek"]),
            SymbolItem(char: "τ", name: "Tau", keywords: ["tau", "greek"]),
            SymbolItem(char: "φ", name: "Phi", keywords: ["phi", "golden ratio"]),
            SymbolItem(char: "ω", name: "Omega", keywords: ["omega", "last"]),
            SymbolItem(char: "Ω", name: "Capital Omega", keywords: ["omega", "ohm"])
        ]
    ]
}
