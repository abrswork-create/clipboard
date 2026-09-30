import Foundation

// MARK: - Emoji Item & Category

struct EmojiItem: Identifiable, Hashable {
    let id = UUID()
    let char: String
    let name: String
    let keywords: [String]
}

enum EmojiCategory: String, CaseIterable, Identifiable {
    case smileys = "Smileys"
    case gestures = "Gestures"
    case hearts = "Hearts"
    case nature = "Nature"
    case food = "Food"
    case activities = "Tech & Objects"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .smileys: return "face.smiling"
        case .gestures: return "hand.thumbsup"
        case .hearts: return "heart.fill"
        case .nature: return "leaf"
        case .food: return "fork.knife"
        case .activities: return "laptopcomputer"
        }
    }
}

// MARK: - EmojiData Library

enum EmojiData {
    static let library: [EmojiCategory: [EmojiItem]] = [
        .smileys: [
            EmojiItem(char: "😀", name: "Grinning Face", keywords: ["happy", "smile", "grin"]),
            EmojiItem(char: "😃", name: "Grinning Face with Big Eyes", keywords: ["happy", "joy"]),
            EmojiItem(char: "😄", name: "Grinning Face with Smiling Eyes", keywords: ["happy", "laugh"]),
            EmojiItem(char: "😁", name: "Beaming Face", keywords: ["teeth", "grin"]),
            EmojiItem(char: "😆", name: "Grinning Squinting Face", keywords: ["laugh", "satisfied"]),
            EmojiItem(char: "😅", name: "Grinning Face with Sweat", keywords: ["sweat", "nervous", "relief"]),
            EmojiItem(char: "😂", name: "Face with Tears of Joy", keywords: ["laugh", "cry", "funny", "lol"]),
            EmojiItem(char: "🤣", name: "Rolling on the Floor Laughing", keywords: ["rofl", "lol", "laugh"]),
            EmojiItem(char: "🥲", name: "Smiling Face with Tear", keywords: ["proud", "cry", "happy"]),
            EmojiItem(char: "🥹", name: "Face Holding Back Tears", keywords: ["emotional", "pleading"]),
            EmojiItem(char: "😊", name: "Smiling Face with Smiling Eyes", keywords: ["blush", "kind"]),
            EmojiItem(char: "😇", name: "Smiling Face with Halo", keywords: ["angel", "innocent"]),
            EmojiItem(char: "🙂", name: "Slightly Smiling Face", keywords: ["fine", "okay"]),
            EmojiItem(char: "🙃", name: "Upside-Down Face", keywords: ["silly", "irony", "sarcasm"]),
            EmojiItem(char: "😉", name: "Winking Face", keywords: ["wink", "flirt"]),
            EmojiItem(char: "😌", name: "Relieved Face", keywords: ["calm", "zen", "peace"]),
            EmojiItem(char: "😍", name: "Heart Eyes", keywords: ["love", "crush", "adoration"]),
            EmojiItem(char: "🥰", name: "Smiling Face with Hearts", keywords: ["love", "affection"]),
            EmojiItem(char: "😘", name: "Face Blowing a Kiss", keywords: ["kiss", "love"]),
            EmojiItem(char: "😋", name: "Face Savoring Food", keywords: ["yum", "delicious", "tasty"]),
            EmojiItem(char: "😛", name: "Face with Tongue", keywords: ["playful", "joke"]),
            EmojiItem(char: "😜", name: "Winking Face with Tongue", keywords: ["crazy", "party"]),
            EmojiItem(char: "🤪", name: "Zany Face", keywords: ["wild", "goofy"]),
            EmojiItem(char: "🤨", name: "Face with Raised Eyebrow", keywords: ["skeptical", "suspicious"]),
            EmojiItem(char: "🧐", name: "Face with Monocle", keywords: ["inspect", "detective", "curious"]),
            EmojiItem(char: "🤓", name: "Nerd Face", keywords: ["geek", "smart", "glasses"]),
            EmojiItem(char: "😎", name: "Smiling Face with Sunglasses", keywords: ["cool", "chill"]),
            EmojiItem(char: "🥳", name: "Partying Face", keywords: ["celebrate", "birthday", "party"]),
            EmojiItem(char: "😏", name: "Smirking Face", keywords: ["smug", "sly"]),
            EmojiItem(char: "😒", name: "Unamused Face", keywords: ["meh", "bored"]),
            EmojiItem(char: "😞", name: "Disappointed Face", keywords: ["sad", "upset"]),
            EmojiItem(char: "😔", name: "Pensive Face", keywords: ["regret", "depressed"]),
            EmojiItem(char: "😟", name: "Worried Face", keywords: ["anxious", "nervous"]),
            EmojiItem(char: "😕", name: "Confused Face", keywords: ["unsure", "huh"]),
            EmojiItem(char: "🥺", name: "Pleading Face", keywords: ["puppy eyes", "please", "beg"]),
            EmojiItem(char: "😢", name: "Crying Face", keywords: ["tear", "sad", "cry"]),
            EmojiItem(char: "😭", name: "Loudly Crying Face", keywords: ["bawling", "sad", "tears"]),
            EmojiItem(char: "😤", name: "Face with Steam from Nose", keywords: ["triumph", "frustrated"]),
            EmojiItem(char: "😠", name: "Angry Face", keywords: ["mad", "annoyed"]),
            EmojiItem(char: "😡", name: "Pouting Face", keywords: ["rage", "furious"]),
            EmojiItem(char: "🤬", name: "Face with Symbols on Mouth", keywords: ["swearing", "curse"]),
            EmojiItem(char: "🤯", name: "Exploding Head", keywords: ["mind blown", "shocked"]),
            EmojiItem(char: "😳", name: "Flushed Face", keywords: ["embarrassed", "gasp"]),
            EmojiItem(char: "🥵", name: "Hot Face", keywords: ["sweating", "heat", "summer"]),
            EmojiItem(char: "🥶", name: "Cold Face", keywords: ["freezing", "ice", "winter"]),
            EmojiItem(char: "😱", name: "Face Screaming in Fear", keywords: ["horror", "scared", "scream"]),
            EmojiItem(char: "🤗", name: "Hugging Face", keywords: ["hug", "warm"]),
            EmojiItem(char: "🤔", name: "Thinking Face", keywords: ["wonder", "hmmm", "question"]),
            EmojiItem(char: "🫣", name: "Face with Peeking Eye", keywords: ["shy", "cringe", "peeking"]),
            EmojiItem(char: "🤫", name: "Shushing Face", keywords: ["quiet", "secret", "shh"]),
            EmojiItem(char: "🫠", name: "Melting Face", keywords: ["melt", "disappear", "overwhelmed"]),
            EmojiItem(char: "🤐", name: "Zipper-Mouth Face", keywords: ["silent", "zip", "quiet"]),
            EmojiItem(char: "😴", name: "Sleeping Face", keywords: ["tired", "sleep", "zzz"]),
            EmojiItem(char: "🤤", name: "Drooling Face", keywords: ["hungry", "craving"]),
            EmojiItem(char: "🤑", name: "Money-Mouth Face", keywords: ["cash", "dollar", "rich"]),
            EmojiItem(char: "🤠", name: "Cowboy Hat Face", keywords: ["western", "yeehaw"]),
            EmojiItem(char: "🤡", name: "Clown Face", keywords: ["fool", "circus"]),
            EmojiItem(char: "💩", name: "Pile of Poo", keywords: ["poop", "turd"]),
            EmojiItem(char: "👻", name: "Ghost", keywords: ["spooky", "halloween"]),
            EmojiItem(char: "💀", name: "Skull", keywords: ["dead", "skeleton", "death"]),
            EmojiItem(char: "👽", name: "Alien", keywords: ["ufo", "space"]),
            EmojiItem(char: "🤖", name: "Robot", keywords: ["ai", "bot", "droid"])
        ],
        .gestures: [
            EmojiItem(char: "👋", name: "Waving Hand", keywords: ["hello", "bye", "wave"]),
            EmojiItem(char: "🤚", name: "Raised Back of Hand", keywords: ["hand", "back"]),
            EmojiItem(char: "🖐️", name: "Hand with Fingers Splayed", keywords: ["five", "stop"]),
            EmojiItem(char: "✋", name: "Raised Hand", keywords: ["high five", "stop"]),
            EmojiItem(char: "🖖", name: "Vulcan Salute", keywords: ["spock", "star trek"]),
            EmojiItem(char: "👌", name: "OK Hand", keywords: ["perfect", "okay"]),
            EmojiItem(char: "🤌", name: "Pinched Fingers", keywords: ["italian", "chef"]),
            EmojiItem(char: "🤏", name: "Pinching Hand", keywords: ["small", "tiny", "little"]),
            EmojiItem(char: "✌️", name: "Victory Hand", keywords: ["peace", "v", "two"]),
            EmojiItem(char: "🤞", name: "Crossed Fingers", keywords: ["luck", "hope"]),
            EmojiItem(char: "🫰", name: "Hand with Index and Thumb Crossed", keywords: ["finger heart", "money"]),
            EmojiItem(char: "🤟", name: "Love-You Gesture", keywords: ["ily", "love"]),
            EmojiItem(char: "🤘", name: "Sign of the Horns", keywords: ["rock", "metal"]),
            EmojiItem(char: "🤙", name: "Call Me Hand", keywords: ["shaka", "phone", "hang loose"]),
            EmojiItem(char: "🫵", name: "Index Pointing at Viewer", keywords: ["you", "point"]),
            EmojiItem(char: "👍", name: "Thumbs Up", keywords: ["like", "good", "approve", "yes"]),
            EmojiItem(char: "👎", name: "Thumbs Down", keywords: ["dislike", "bad", "no"]),
            EmojiItem(char: "✊", name: "Raised Fist", keywords: ["power", "strength"]),
            EmojiItem(char: "👊", name: "Oncoming Fist", keywords: ["fist bump", "punch"]),
            EmojiItem(char: "👏", name: "Clapping Hands", keywords: ["applause", "bravo", "praise"]),
            EmojiItem(char: "🙌", name: "Raising Hands", keywords: ["celebrate", "hooray", "praise"]),
            EmojiItem(char: "🫶", name: "Heart Hands", keywords: ["love", "care"]),
            EmojiItem(char: "👐", name: "Open Hands", keywords: ["open", "welcome"]),
            EmojiItem(char: "🤲", name: "Palms Up Together", keywords: ["prayer", "offering"]),
            EmojiItem(char: "🤝", name: "Handshake", keywords: ["deal", "agreement", "partner"]),
            EmojiItem(char: "🙏", name: "Folded Hands", keywords: ["please", "thank you", "pray", "namaste"]),
            EmojiItem(char: "✍️", name: "Writing Hand", keywords: ["write", "pen", "notes"]),
            EmojiItem(char: "💅", name: "Nail Polish", keywords: ["slay", "beauty", "sassy"]),
            EmojiItem(char: "🤳", name: "Selfie", keywords: ["camera", "phone"]),
            EmojiItem(char: "💪", name: "Flexed Biceps", keywords: ["strong", "workout", "gym", "muscle"]),
            EmojiItem(char: "👀", name: "Eyes", keywords: ["look", "see", "watching"])
        ],
        .hearts: [
            EmojiItem(char: "❤️", name: "Red Heart", keywords: ["love", "passion"]),
            EmojiItem(char: "🧡", name: "Orange Heart", keywords: ["warmth", "friendship"]),
            EmojiItem(char: "💛", name: "Yellow Heart", keywords: ["joy", "friendship"]),
            EmojiItem(char: "💚", name: "Green Heart", keywords: ["nature", "jealousy"]),
            EmojiItem(char: "💙", name: "Blue Heart", keywords: ["trust", "loyalty"]),
            EmojiItem(char: "💜", name: "Purple Heart", keywords: ["royalty", "glamour"]),
            EmojiItem(char: "🖤", name: "Black Heart", keywords: ["dark", "goth"]),
            EmojiItem(char: "🤍", name: "White Heart", keywords: ["pure", "peace"]),
            EmojiItem(char: "🤎", name: "Brown Heart", keywords: ["chocolate", "earth"]),
            EmojiItem(char: "💔", name: "Broken Heart", keywords: ["heartbreak", "sad"]),
            EmojiItem(char: "❤️‍🔥", name: "Heart on Fire", keywords: ["passionate", "hot"]),
            EmojiItem(char: "❤️‍🩹", name: "Mending Heart", keywords: ["healing", "recovery"]),
            EmojiItem(char: "❣️", name: "Heart Exclamation", keywords: ["alert", "love"]),
            EmojiItem(char: "💕", name: "Two Hearts", keywords: ["love", "affection"]),
            EmojiItem(char: "💞", name: "Revolving Hearts", keywords: ["romance"]),
            EmojiItem(char: "💓", name: "Beating Heart", keywords: ["pulse", "alive"]),
            EmojiItem(char: "💗", name: "Growing Heart", keywords: ["excited", "expanding"]),
            EmojiItem(char: "💖", name: "Sparkling Heart", keywords: ["sparkle", "special"]),
            EmojiItem(char: "💘", name: "Heart with Arrow", keywords: ["cupid", "struck"]),
            EmojiItem(char: "💝", name: "Heart with Ribbon", keywords: ["gift", "present"]),
            EmojiItem(char: "✨", name: "Sparkles", keywords: ["magic", "clean", "shine", "stars"]),
            EmojiItem(char: "⭐️", name: "Star", keywords: ["favorite", "gold"]),
            EmojiItem(char: "🌟", name: "Glowing Star", keywords: ["bright", "shine"]),
            EmojiItem(char: "💥", name: "Collision", keywords: ["boom", "bang", "impact"]),
            EmojiItem(char: "🔥", name: "Fire", keywords: ["flame", "lit", "hot", "trending"]),
            EmojiItem(char: "⚡️", name: "High Voltage", keywords: ["lightning", "power", "fast"]),
            EmojiItem(char: "🎉", name: "Party Popper", keywords: ["celebrate", "congrats", "tada"]),
            EmojiItem(char: "🎊", name: "Confetti Ball", keywords: ["party", "festival"]),
            EmojiItem(char: "🏆", name: "Trophy", keywords: ["winner", "champion", "first"])
        ],
        .nature: [
            EmojiItem(char: "🐶", name: "Dog Face", keywords: ["puppy", "pet", "bark"]),
            EmojiItem(char: "🐱", name: "Cat Face", keywords: ["kitten", "meow", "feline"]),
            EmojiItem(char: "🐭", name: "Mouse Face", keywords: ["rodent", "cheese"]),
            EmojiItem(char: "🐹", name: "Hamster Face", keywords: ["cute", "pet"]),
            EmojiItem(char: "🐰", name: "Rabbit Face", keywords: ["bunny", "easter"]),
            EmojiItem(char: "🦊", name: "Fox", keywords: ["clever", "wild"]),
            EmojiItem(char: "🐻", name: "Bear", keywords: ["grizzly", "teddy"]),
            EmojiItem(char: "🐼", name: "Panda", keywords: ["bamboo", "china"]),
            EmojiItem(char: "🐨", name: "Koala", keywords: ["australia", "cute"]),
            EmojiItem(char: "🐯", name: "Tiger Face", keywords: ["stripes", "wild"]),
            EmojiItem(char: "🦁", name: "Lion", keywords: ["king", "safari"]),
            EmojiItem(char: "🐮", name: "Cow Face", keywords: ["milk", "moo"]),
            EmojiItem(char: "🐷", name: "Pig Face", keywords: ["oink", "bacon"]),
            EmojiItem(char: "🐸", name: "Frog", keywords: ["toad", "ribbit"]),
            EmojiItem(char: "🐵", name: "Monkey Face", keywords: ["chimp", "banana"]),
            EmojiItem(char: "🦄", name: "Unicorn", keywords: ["magic", "fantasy"]),
            EmojiItem(char: "🐝", name: "Honeybee", keywords: ["honey", "buzz", "sting"]),
            EmojiItem(char: "🦋", name: "Butterfly", keywords: ["wings", "pretty"]),
            EmojiItem(char: "🐢", name: "Turtle", keywords: ["slow", "shell"]),
            EmojiItem(char: "🐬", name: "Dolphin", keywords: ["ocean", "sea"]),
            EmojiItem(char: "🐳", name: "Spouting Whale", keywords: ["sea", "mammal"]),
            EmojiItem(char: "🦈", name: "Shark", keywords: ["predator", "ocean"]),
            EmojiItem(char: "🌸", name: "Cherry Blossom", keywords: ["flower", "spring", "sakura"]),
            EmojiItem(char: "🌹", name: "Rose", keywords: ["flower", "romance", "red"]),
            EmojiItem(char: "🌻", name: "Sunflower", keywords: ["summer", "yellow"]),
            EmojiItem(char: "🌱", name: "Seedling", keywords: ["grow", "plant", "sprout"]),
            EmojiItem(char: "🌲", name: "Evergreen Tree", keywords: ["pine", "forest"]),
            EmojiItem(char: "🍀", name: "Four Leaf Clover", keywords: ["lucky", "irish"]),
            EmojiItem(char: "🍁", name: "Maple Leaf", keywords: ["canada", "autumn", "fall"]),
            EmojiItem(char: "🌈", name: "Rainbow", keywords: ["colors", "sky", "pride"])
        ],
        .food: [
            EmojiItem(char: "☕️", name: "Hot Beverage", keywords: ["coffee", "tea", "caffeine", "morning"]),
            EmojiItem(char: "🍵", name: "Teacup Without Handle", keywords: ["matcha", "green tea"]),
            EmojiItem(char: "🧋", name: "Bubble Tea", keywords: ["boba", "tea", "milk"]),
            EmojiItem(char: "🍺", name: "Beer Mug", keywords: ["drink", "alcohol", "cheers"]),
            EmojiItem(char: "🍷", name: "Wine Glass", keywords: ["red wine", "alcohol"]),
            EmojiItem(char: "🍕", name: "Pizza", keywords: ["cheese", "italian", "slice"]),
            EmojiItem(char: "🍔", name: "Hamburger", keywords: ["fast food", "burger", "beef"]),
            EmojiItem(char: "🍟", name: "French Fries", keywords: ["fries", "potato", "fast food"]),
            EmojiItem(char: "🌭", name: "Hot Dog", keywords: ["sausage", "bbq"]),
            EmojiItem(char: "🥪", name: "Sandwich", keywords: ["lunch", "bread"]),
            EmojiItem(char: "🌮", name: "Taco", keywords: ["mexican", "food"]),
            EmojiItem(char: "🌯", name: "Burrito", keywords: ["wrap", "mexican"]),
            EmojiItem(char: "🍣", name: "Sushi", keywords: ["japanese", "fish", "rice"]),
            EmojiItem(char: "🍜", name: "Steaming Bowl", keywords: ["ramen", "noodles", "soup"]),
            EmojiItem(char: "🍝", name: "Spaghetti", keywords: ["pasta", "italian"]),
            EmojiItem(char: "🥗", name: "Green Salad", keywords: ["healthy", "diet", "vegan"]),
            EmojiItem(char: "🍩", name: "Doughnut", keywords: ["donut", "sweet"]),
            EmojiItem(char: "🍪", name: "Cookie", keywords: ["chocolate chip", "biscuit"]),
            EmojiItem(char: "🎂", name: "Birthday Cake", keywords: ["celebrate", "party", "dessert"]),
            EmojiItem(char: "🍫", name: "Chocolate Bar", keywords: ["sweet", "candy"]),
            EmojiItem(char: "🍿", name: "Popcorn", keywords: ["movie", "snack"]),
            EmojiItem(char: "🍎", name: "Red Apple", keywords: ["fruit", "healthy"]),
            EmojiItem(char: "🍌", name: "Banana", keywords: ["fruit", "potassium"]),
            EmojiItem(char: "🍓", name: "Strawberry", keywords: ["berry", "fruit", "sweet"]),
            EmojiItem(char: "🥑", name: "Avocado", keywords: ["guacamole", "healthy"])
        ],
        .activities: [
            EmojiItem(char: "💻", name: "Laptop", keywords: ["computer", "mac", "pc", "tech", "work"]),
            EmojiItem(char: "📱", name: "Mobile Phone", keywords: ["iphone", "smartphone", "call"]),
            EmojiItem(char: "💡", name: "Light Bulb", keywords: ["idea", "bright", "smart"]),
            EmojiItem(char: "🔑", name: "Key", keywords: ["password", "lock", "access"]),
            EmojiItem(char: "🔒", name: "Locked", keywords: ["security", "safe", "private"]),
            EmojiItem(char: "🚀", name: "Rocket", keywords: ["launch", "fast", "space"]),
            EmojiItem(char: "🚗", name: "Automobile", keywords: ["car", "vehicle", "drive"]),
            EmojiItem(char: "✈️", name: "Airplane", keywords: ["flight", "travel", "vacation"]),
            EmojiItem(char: "📦", name: "Package", keywords: ["delivery", "box", "amazon"]),
            EmojiItem(char: "💰", name: "Money Bag", keywords: ["cash", "dollar", "wealth"]),
            EmojiItem(char: "💳", name: "Credit Card", keywords: ["payment", "bank", "buy"]),
            EmojiItem(char: "💎", name: "Gem Stone", keywords: ["diamond", "jewel", "rich"]),
            EmojiItem(char: "🎮", name: "Video Game", keywords: ["gaming", "controller", "play"]),
            EmojiItem(char: "🎧", name: "Headphone", keywords: ["music", "audio", "listen"]),
            EmojiItem(char: "📸", name: "Camera with Flash", keywords: ["photo", "picture"]),
            EmojiItem(char: "⏰", name: "Alarm Clock", keywords: ["time", "wake up"]),
            EmojiItem(char: "🔔", name: "Bell", keywords: ["notification", "alert", "ring"])
        ]
    ]
}
