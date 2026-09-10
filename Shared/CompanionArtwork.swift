import SwiftUI

/// Original pencil illustrations. Names are explicit so collection art never
/// depends on a coincidentally matching SF Symbol.
enum CompanionArtwork: String, CaseIterable {
    case morning, evening, sleep, tahajjud, salah, afterSalah
    case istighfar, praise, salawat, anytime, ummah, healing
    case quran, sunnah, names
    case angry, anxious, confident, confused, grateful, greedy, guilty, happy
    case hurt, indecisive, hypocritical, jealous, lazy, lonely, lost, overwhelmed
    case sad, scared, unloved, impatient, hopeful, grieving, breathe
    case family, shelter, work, qibla, support
    case fajr, sunrise, dhuhr, asr, maghrib, isha
    case journal, privacy, settings, saved

    var assetName: String { "Companion-\(rawValue)" }
}

struct CompanionIllustration: View {
    let artwork: CompanionArtwork
    var size: CGFloat = 80
    var onDarkSurface = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(artwork.assetName)
            .resizable()
            .scaledToFit()
            .padding(size * 0.045)
            .frame(width: size, height: size)
            // A paper backing keeps the charcoal marks legible in dark mode.
            .background {
                if colorScheme == .dark || onDarkSurface {
                    RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                        .fill(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
            .accessibilityHidden(true)
    }
}

extension PrayerKind {
    var artwork: CompanionArtwork {
        switch self {
        case .fajr: return .fajr
        case .sunrise: return .sunrise
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        }
    }
}
