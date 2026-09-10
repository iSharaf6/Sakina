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
