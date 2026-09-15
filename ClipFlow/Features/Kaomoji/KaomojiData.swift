import Foundation

// MARK: - Kaomoji Item & Category

struct KaomojiItem: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let name: String
    let keywords: [String]
}

enum KaomojiCategory: String, CaseIterable, Identifiable {
    case happy = "Happy"
    case shrug = "Shrug"
    case love = "Love"
    case angry = "Angry"
    case surprise = "Shock"
    case cute = "Animals"
    case sad = "Sad"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .happy: return "sparkles"
        case .shrug: return "questionmark.circle"
        case .love: return "heart.fill"
        case .angry: return "flame.fill"
        case .surprise: return "exclamationmark.triangle"
        case .cute: return "pawprint.fill"
        case .sad: return "cloud.rain"
        }
    }
}

// MARK: - Kaomoji Library

enum KaomojiData {
    static let library: [KaomojiCategory: [KaomojiItem]] = [
        .happy: [
            KaomojiItem(text: "(✿◠‿◠)", name: "Flower Smile", keywords: ["smile", "flower", "cute"]),
            KaomojiItem(text: "(◕‿◕✿)", name: "Cute Blossom", keywords: ["blossom", "happy"]),
            KaomojiItem(text: "(*^ω^*)", name: "Joyful Grin", keywords: ["grin", "joy"]),
            KaomojiItem(text: "(≧◡≦)", name: "Big Smile", keywords: ["laugh", "happy"]),
            KaomojiItem(text: "(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧", name: "Magic Sparkles", keywords: ["magic", "yay", "tada"]),
            KaomojiItem(text: "(⌒▽⌒)☆", name: "Star Happiness", keywords: ["star", "cheer"]),
            KaomojiItem(text: "(o^▽^o)", name: "Cheerful", keywords: ["excited", "smile"]),
            KaomojiItem(text: "٩(◕‿◕｡)۶", name: "Hooray Hands", keywords: ["hooray", "success"]),
            KaomojiItem(text: "( ´ ▽ ` )b", name: "Thumbs Up", keywords: ["good", "approve"]),
            KaomojiItem(text: "＼(＾▽＾)／", name: "Celebration", keywords: ["cheer", "party"])
        ],
        .shrug: [
            KaomojiItem(text: "¯\\_(ツ)_/¯", name: "Classic Shrug", keywords: ["shrug", "whatever", "idk"]),
            KaomojiItem(text: "┐(‘～` )┌", name: "Casual Shrug", keywords: ["meh", "dunno"]),
            KaomojiItem(text: "¯\\(°_o)/¯", name: "Derp Shrug", keywords: ["confused", "huh"]),
            KaomojiItem(text: "(¬_¬)", name: "Side Eye", keywords: ["suspicious", "doubt"]),
            KaomojiItem(text: "(￣ヘ￣)", name: "Thinking Shrug", keywords: ["ponder", "hmmm"]),
            KaomojiItem(text: "(⇀‸↼‶)", name: "Reluctant", keywords: ["grumpy", "whatever"]),
            KaomojiItem(text: "╮(︶︿︶)╭", name: "Sigh Shrug", keywords: ["sigh", "resigned"]),
            KaomojiItem(text: "¯\\(º_o)/¯", name: "Clueless", keywords: ["lost", "idk"])
        ],
        .love: [
            KaomojiItem(text: "(♥ω♥*)", name: "Heart Struck", keywords: ["love", "crush", "heart"]),
            KaomojiItem(text: "(♡˙︶˙♡)", name: "Warm Affection", keywords: ["sweet", "gentle"]),
            KaomojiItem(text: "(づ￣ ³￣)づ", name: "Blowing Kiss", keywords: ["kiss", "muah", "hug"]),
            KaomojiItem(text: "(❤ω❤)", name: "Love Gaze", keywords: ["adoration", "cherish"]),
            KaomojiItem(text: "(´｡• ᵕ •｡`) ♡", name: "Blushing Love", keywords: ["blush", "cute"]),
            KaomojiItem(text: "(◕‿◕)♡", name: "Heart Smile", keywords: ["fond", "lovely"]),
            KaomojiItem(text: "(*♡∀♡)", name: "Infatuated", keywords: ["in love", "obsessed"]),
            KaomojiItem(text: "(/^-^(^ ^*)/ ♡", name: "Cuddle Hug", keywords: ["hug", "cuddle", "together"])
        ],
        .angry: [
            KaomojiItem(text: "(╯°□°)╯︵ ┻━┻", name: "Table Flip", keywords: ["flip table", "rage", "mad"]),
            KaomojiItem(text: "(ง'̀-'́)ง", name: "Put 'Em Up", keywords: ["fight", "punch", "boxer"]),
            KaomojiItem(text: "ಠ_ಠ", name: "Look of Disapproval", keywords: ["disapprove", "stare"]),
            KaomojiItem(text: "(ノಠ益ಠ)ノ彡┻━┻", name: "Furious Table Flip", keywords: ["rage", "destroy"]),
            KaomojiItem(text: "凸(｀⌒´メ)凸", name: "Double Middle Finger", keywords: ["angry", "furious"]),
            KaomojiItem(text: "(╬ Ò﹏Ó)", name: "Boiling Anger", keywords: ["mad", "steam"]),
            KaomojiItem(text: "(｀Д´)", name: "Roaring Mad", keywords: ["scream", "yell"]),
            KaomojiItem(text: "┬─┬ノ( º _ ºノ)", name: "Table Respect", keywords: ["unflip", "calm down"])
        ],
        .surprise: [
            KaomojiItem(text: "(⊙_⊙)", name: "Wide Eyed", keywords: ["shock", "stare"]),
            KaomojiItem(text: "(°o°)", name: "Gasp", keywords: ["wow", "surprised"]),
            KaomojiItem(text: "Σ(°△°|||)", name: "Sweating Shock", keywords: ["panic", "oh no"]),
            KaomojiItem(text: "(・o・)", name: "Awe", keywords: ["astonished"]),
            KaomojiItem(text: "(o_O)", name: "Baffled", keywords: ["confused", "huh"]),
            KaomojiItem(text: "w(ﾟｏﾟ)w", name: "Mind Blown", keywords: ["whoa", "crazy"]),
            KaomojiItem(text: "(O_O)", name: "Speechless", keywords: ["blank", "shocked"])
        ],
        .cute: [
            KaomojiItem(text: "(=^･ω･^=)", name: "Kitty Cat", keywords: ["cat", "meow", "kitten"]),
            KaomojiItem(text: "ʕ•ᴥ•ʔ", name: "Teddy Bear", keywords: ["bear", "fuzzy", "hug"]),
            KaomojiItem(text: "(・ω・)", name: "Cute Whiskers", keywords: ["pet", "cute"]),
            KaomojiItem(text: "(V)(°,,,,°)(V)", name: "Zoidberg", keywords: ["crab", "lobster"]),
            KaomojiItem(text: "(ᵔᴥᵔ)", name: "Happy Pup", keywords: ["dog", "puppy", "seal"]),
            KaomojiItem(text: "(=^･ｪ･^=)", name: "Curious Cat", keywords: ["cat", "animal"]),
            KaomojiItem(text: "ฅ^•ﻌ•^ฅ", name: "Paws Up Cat", keywords: ["kitty", "paws"]),
            KaomojiItem(text: "ʕっ•ᴥ•ʔっ", name: "Bear Hug", keywords: ["hug", "snuggle"])
        ],
        .sad: [
            KaomojiItem(text: "(╥﹏╥)", name: "Weeping", keywords: ["cry", "tears", "sad"]),
            KaomojiItem(text: "(T_T)", name: "Simple Tears", keywords: ["crying", "sob"]),
            KaomojiItem(text: "(｡•́︿•̀｡)", name: "Pouty Sad", keywords: ["unhappy", "down"]),
            KaomojiItem(text: "(ಥ﹏ಥ)", name: "Grief", keywords: ["emotional", "devastated"]),
            KaomojiItem(text: "(╯︵╰,)", name: "Lonely Tear", keywords: ["alone", "depressed"]),
            KaomojiItem(text: "(っ˘̩╭╮˘̩)っ", name: "Needs A Hug", keywords: ["consoling", "comfort"])
        ]
    ]
}
