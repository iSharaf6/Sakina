import SwiftUI

// MARK: - Feelings
//
// Each family carries one tint; each feeling carries one symbol. The symbol
// is a quiet cue, never an illustration of the emotion.

extension FeelingFamily {
    var tint: Color {
        switch self {
        case .heavy: return BadgeTint.indigo.color
        case .restless: return BadgeTint.orange.color
        case .direction: return BadgeTint.teal.color
        case .returning: return BadgeTint.purple.color
        case .peace: return BadgeTint.green.color
        case .energy: return BadgeTint.blue.color
        }
    }

    var symbol: String {
        switch self {
        case .heavy: return "cloud.rain"
        case .restless: return "waveform.path.ecg"
        case .direction: return "arrow.triangle.branch"
        case .returning: return "arrow.uturn.backward"
        case .peace: return "sun.max"
        case .energy: return "battery.25"
        }
    }

    /// One line under the family title on the feelings screen.
    func line(_ language: AppLanguage) -> String {
        switch self {
        case .heavy: return language.pick("When it weighs on you", "حين يثقل قلبك")
        case .restless: return language.pick("When it won’t settle", "حين لا يهدأ ذهنك")
        case .direction: return language.pick("When the way isn’t clear", "حين يغيب الطريق")
        case .returning: return language.pick("When you want to come back", "حين تريد العودة")
        case .peace: return language.pick("When things are good", "حين تكون بخير")
        case .energy: return language.pick("When you’re running low", "حين تنفد طاقتك")
        }
    }
}

extension DuaMood {
    var tint: Color { family.tint }

    var symbol: String {
        switch self {
        case .angry: return "flame"
        case .anxious: return "waveform.path.ecg"
        case .urgeToSin: return "hand.raised"
        case .confident: return "star"
        case .confused: return "questionmark.circle"
        case .content: return "leaf"
        case .depressed: return "cloud.rain"
        case .doubtful: return "circle.lefthalf.filled"
        case .grateful: return "hands.sparkles"
        case .greedy: return "banknote"
        case .guilty: return "exclamationmark.bubble"
        case .happy: return "sun.max"
        case .hurt: return "bandage"
        case .indecisive: return "arrow.triangle.branch"
        case .hypocritical: return "theatermasks"
        case .jealous: return "eye"
        case .lazy: return "tortoise"
        case .lonely: return "person"
        case .lost: return "location.slash"
        case .nervous: return "bolt.heart"
        case .overwhelmed: return "square.stack.3d.up"
        case .regret: return "arrow.uturn.backward"
        case .sad: return "cloud.drizzle"
        case .scared: return "exclamationmark.triangle"
        case .suicidal: return "lifepreserver"
        case .tired: return "battery.25"
        case .unloved: return "heart.slash"
        case .weak: return "wind"
        case .bored: return "hourglass"
        case .impatient: return "timer"
        case .hopeful: return "sunrise"
        case .grieving: return "drop"
        case .seekingForgiveness: return "arrow.uturn.left.circle"
        }
    }

    /// The six feelings shown on Home.
    static let featured: [DuaMood] = [.anxious, .grateful, .overwhelmed, .sad, .lost, .tired]
}

// MARK: - Collections

extension DuaPractice {
    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "sunset.fill"
        case .sleep: return "moon.zzz.fill"
        case .tahajjud: return "moon.stars.fill"
        case .salah: return "sparkles"
        case .afterSalah: return "checkmark.seal.fill"
        case .ummah: return "globe.europe.africa.fill"
        case .healing: return "bandage.fill"
        case .praise: return "star.circle.fill"
        case .salawat: return "heart.fill"
        case .quran: return "book.closed.fill"
        case .sunnah: return "text.book.closed.fill"
        case .istighfar: return "arrow.counterclockwise.circle.fill"
        case .anytime: return "repeat"
        case .names: return "circle.hexagongrid.fill"
        }
    }

    var tint: Color {
        switch self {
        case .morning: return BadgeTint.orange.color
        case .evening: return BadgeTint.purple.color
        case .sleep: return BadgeTint.indigo.color
        case .tahajjud: return BadgeTint.night.color
        case .salah: return BadgeTint.green.color
        case .afterSalah: return BadgeTint.teal.color
        case .ummah: return BadgeTint.blue.color
        case .healing: return BadgeTint.pink.color
        case .praise: return BadgeTint.orange.color
        case .salawat: return BadgeTint.red.color
        case .quran: return BadgeTint.green.color
        case .sunnah: return BadgeTint.teal.color
        case .istighfar: return BadgeTint.cyan.color
        case .anytime: return BadgeTint.slate.color
        case .names: return BadgeTint.indigo.color
        }
    }

    /// A one-or-two-word title for tiles.
    func shortTitle(_ language: AppLanguage) -> String {
        switch self {
        case .anytime: return language.pick("Dhikr", "الذكر")
        case .healing: return language.pick("Healing", "الرقية")
        case .praise: return language.pick("Praise", "الثناء")
        case .names: return language.pick("99 names", "الأسماء الحسنى")
        case .quran: return language.pick("Qur’anic", "قرآنية")
        case .salah: return language.pick("In salah", "في الصلاة")
        case .ummah: return language.pick("Ummah", "الأمة")
        default: return title(language)
        }
    }

    /// Short editorial label for the tile subtitle when no progress exists.
    func countLabel(_ language: AppLanguage) -> String {
        if self == .names { return language.pick("99 names", "٩٩ اسمًا") }
        let count = entries.count
        return language.pick(count == 1 ? "1 du’a" : "\(count) du’as", "\(count) أدعية")
    }

    /// The four groupings used by the collections screen.
    enum Group: CaseIterable, Identifiable {
        case day, prayer, remembrance, sources
        var id: Self { self }
        var practices: [DuaPractice] {
            switch self {
            case .day: return [.morning, .evening, .sleep, .tahajjud]
            case .prayer: return [.salah, .afterSalah, .ummah, .healing]
            case .remembrance: return [.praise, .salawat, .istighfar, .anytime]
            case .sources: return [.quran, .sunnah, .names]
            }
        }
        func title(_ language: AppLanguage) -> String {
            switch self {
            case .day: return language.pick("Through the day", "على مدار اليوم")
            case .prayer: return language.pick("Prayer & care", "الصلاة والرعاية")
            case .remembrance: return language.pick("Remembrance", "الذكر")
            case .sources: return language.pick("From the sources", "من المصادر")
            }
        }
    }
}

// MARK: - Life groups

extension LifeGroup {
    var tint: Color {
        switch id {
        case .marriage: return BadgeTint.pink.color
        case .family: return BadgeTint.orange.color
        case .faith: return BadgeTint.green.color
        case .wellbeing: return BadgeTint.blue.color
        case .provision: return BadgeTint.teal.color
        }
    }

    var badgeSymbol: String {
        switch id {
        case .marriage: return "heart.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .faith: return "moon.stars.fill"
        case .wellbeing: return "cloud.sun.fill"
        case .provision: return "briefcase.fill"
        }
    }
}
