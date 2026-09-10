import SwiftUI

/// Original pencil illustrations. Names are explicit so collection art never
/// depends on a coincidentally matching SF Symbol.
enum CompanionArtwork: String, CaseIterable {
    case morning, evening, sleep, tahajjud, salah, afterSalah
    case istighfar, praise, salawat, anytime, ummah, healing
    case quran, sunnah, names

    var assetName: String { "Companion-\(rawValue)" }
}

struct CompanionIllustration: View {
    let artwork: CompanionArtwork
    var size: CGFloat = 80
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(artwork.assetName)
            .resizable()
            .scaledToFit()
            .padding(size * 0.045)
            .frame(width: size, height: size)
            // A paper backing keeps the charcoal marks legible in dark mode.
            .background {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                        .fill(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
            .accessibilityHidden(true)
    }
}

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
