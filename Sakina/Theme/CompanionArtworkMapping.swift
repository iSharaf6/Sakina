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

/// The twelve category symbols keep their stored names (they sync with the
/// account library) and draw as twelve distinct companion poses.
extension CompanionArtwork {
    static func category(for symbol: String) -> CompanionArtwork {
        switch symbol {
        case "folder.fill": return .saved
        case "heart.fill": return .happy
        case "cloud.rain.fill": return .sad
        case "sun.max.fill": return .hopeful
        case "leaf.fill": return .grateful
        case "moon.stars.fill": return .sleep
        case "sparkles": return .praise
        case "hand.raised.fill": return .istighfar
        case "drop.fill": return .grieving
        case "flame.fill": return .angry
        case "star.fill": return .confident
        case "bolt.heart.fill": return .hurt
        default: return badge(for: symbol) ?? .saved
        }
    }
}

/// A section title led by a companion drawing, replacing symbol labels.
struct CompanionLabel: View {
    let title: String
    let artwork: CompanionArtwork
    var size: CGFloat = 34

    var body: some View {
        HStack(spacing: 8) {
            CompanionIllustration(artwork: artwork, size: size)
            Text(title)
        }
    }
}

/// Toolbar-sized companion; a saved or active state gains the accent ring.
struct CompanionToolbarIcon: View {
    let artwork: CompanionArtwork
    var active = false

    var body: some View {
        CompanionIllustration(artwork: artwork, size: 30)
            .background(active ? Color.yqAccentTint : .clear, in: Circle())
            .overlay(Circle().strokeBorder(active ? Color.yqAccent : .clear, lineWidth: 1.5))
            .animation(.easeOut(duration: 0.15), value: active)
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
        case "book.closed", "book.closed.fill", "book.pages.fill", "text.book.closed": return .quran
        case "circle.lefthalf.filled": return .appearance
        case "bookmark", "bookmark.fill": return .saved
        case "highlighter": return .journal
        case "note.text", "square.and.pencil": return .journal
        case "ladybug.fill": return .bug
        case "lightbulb.fill": return .idea
        case "camera.fill": return .camera
        case "suit.heart.fill", "heart.fill": return .salawat
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
        case "checkmark.shield": return .verified
        case "lock", "lock.shield", "iphone": return .privacy
        case "textformat", "textformat.size.smaller", "textformat.size.larger": return .textSize
        case "person.crop.circle": return .confident
        case "icloud": return .backup
        case "square.and.arrow.up": return .share
        case "envelope": return .social
        case "location", "location.circle": return .lost
        case "book", "text.book.closed.fill", "character.book.closed", "books.vertical": return .quran
        case "text.bubble": return .journal
        case "trash": return .deleteAccount
        case "folder.badge.plus", "folder.fill": return .saved
        case "sparkle": return .praise
        case "wifi.slash", "network.slash", "exclamationmark.arrow.triangle.2.circlepath": return .help
        case "info.circle": return .help
        default: return nil
        }
    }
}
