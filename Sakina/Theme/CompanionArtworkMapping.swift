import SwiftUI

extension DuaPractice {
    var artwork: CompanionArtwork {
        switch self {
        case .morning: return .morning
        case .evening: return .evening
        case .sleep: return .sleep
        case .tahajjud: return .tahajjud
        case .salah: return .salah
        case .afterSalah: return .afterSalah
        case .istighfar: return .istighfar
        case .praise: return .praise
        case .salawat: return .salawat
        case .anytime: return .anytime
        case .ummah: return .ummah
        case .healing: return .healing
        case .quran: return .quran
        case .sunnah: return .sunnah
        case .names: return .names
        }
    }
}


extension DuaMood {
    var artwork: CompanionArtwork {
        switch self {
        case .angry: return .angry
        case .anxious, .nervous: return .anxious
        case .urgeToSin, .seekingForgiveness: return .istighfar
        case .confident: return .confident
        case .confused, .doubtful: return .confused
        case .content: return .breathe
        case .depressed, .sad: return .sad
        case .grateful: return .grateful
        case .greedy: return .greedy
        case .guilty, .regret: return .guilty
        case .happy: return .happy
        case .hurt: return .hurt
        case .indecisive: return .indecisive
        case .hypocritical: return .hypocritical
        case .jealous: return .jealous
        case .lazy, .bored: return .lazy
        case .lonely: return .lonely
        case .lost: return .lost
        case .overwhelmed: return .overwhelmed
        case .scared: return .scared
        case .suicidal: return .support
        case .tired: return .sleep
        case .unloved: return .unloved
        case .weak: return .healing
        case .impatient: return .impatient
        case .hopeful: return .hopeful
        case .grieving: return .grieving
        }
    }
}

extension LifeGroup {
    var artwork: CompanionArtwork {
        switch id {
        case .marriage: return .ummah
        case .family: return .family
        case .faith: return .tahajjud
        case .wellbeing: return .shelter
        case .provision: return .work
        }
    }
}

// Explicit artwork assignments for legacy badge call sites. Small native controls
// (back, close, selection, playback) keep their familiar functional glyphs.
extension CompanionArtwork {
    static func badge(for symbol: String) -> CompanionArtwork? {
        switch symbol {
        case "building.columns.fill": return .mosque
        case "fork.knife": return .food
        case "gearshape.fill", "wrench.and.screwdriver.fill", "slider.horizontal.3": return .settings
        case "location.fill", "location.slash.fill", "map.fill", "location.slash", "location.slash.circle": return .lost
        case "function": return .calculator
        case "sun.max.fill": return .asr
        case "globe.europe.africa.fill", "globe": return .globe
        case "character.bubble.fill": return .language
        case "waveform", "music.note": return .reciter
        case "text.quote": return .translation
        case "textformat.abc": return .transliteration
        case "textformat.size": return .textSize
        case "bell.fill": return .reminder
        case "clock.fill", "clock.badge.checkmark.fill": return .clock
        case "hand.tap.fill", "iphone.gen3": return .haptics
        case "questionmark.circle.fill", "info.circle.fill": return .help
        case "envelope.fill": return .privacy
        case "person.2.fill": return .family
        case "person.fill", "person.crop.circle.fill": return .confident
        case "square.and.arrow.up.fill", "paperplane.fill": return .share
        case "star.fill": return .rating
        case "at", "number", "bubble.left.fill": return .social
        case "arrow.triangle.2.circlepath": return .backup
        case "arrow.down.doc.fill": return .download
        case "rectangle.portrait.and.arrow.right": return .signout
        case "xmark.circle.fill": return .deleteAccount
        case "lock.shield.fill", "shield.fill", "hand.raised.fill", "hand.raised", "lock.trianglebadge.exclamationmark": return .privacy
        case "checkmark.shield.fill", "checkmark.seal.fill", "text.badge.checkmark": return .verified
        case "book.closed.fill", "book.pages.fill", "text.book.closed": return .quran
        case "ladybug.fill": return .bug
        case "lightbulb.fill": return .idea
        case "camera.fill": return .camera
        case "heart.fill": return .salawat
        case "sparkles", "leaf.fill": return .praise
        case "hands.and.sparkles.fill", "hands.sparkles": return .istighfar
        case "brain.head.profile": return .breathe
        case "circle.dotted": return .anytime
        case "exclamationmark.triangle.fill", "wifi.exclamationmark": return .help
        case "cross.case.fill", "cross.case": return .healing
        case "moon.stars.fill": return .sleep
        case "sunrise.fill", "sun.horizon.fill": return .morning
        case "drop": return .water
        case "wind": return .breathe
        case "safari", "location.north.circle.fill": return .qibla
        case "exclamationmark.circle": return .help
        default: return nil
        }
    }
}
