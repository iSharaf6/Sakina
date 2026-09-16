import SwiftUI

/// Public recordings shared by the uploader on SoundCloud. Haneen opens the
/// original recording; it does not embed, copy, cache or split the audio.
/// Track titles and uploader were checked against SoundCloud oEmbed metadata.
enum AdhkarRecording: String, CaseIterable {
    case morning, evening

    init?(practice: DuaPractice) {
        switch practice {
        case .morning: self = .morning
        case .evening: self = .evening
        default: return nil
        }
    }

    var url: URL {
        switch self {
        case .morning:
            return URL(string: "https://soundcloud.com/ahmed-saber-458881404/zr1jlpx1apjh")!
        case .evening:
            return URL(string: "https://soundcloud.com/ahmed-saber-458881404/b1wxqzar07gb")!
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .morning: return language.pick("Morning adhkar", "أذكار الصباح")
        case .evening: return language.pick("Evening adhkar", "أذكار المساء")
        }
    }
}

struct AdhkarRecordingCard: View {
    let recording: AdhkarRecording
    let language: AppLanguage

    @Environment(\.openURL) private var openURL
    @State private var couldNotOpen = false
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        Button(action: listen) {
            HStack(spacing: 12) {
                CompanionIllustration(artwork: .reciter, size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(recording.title(language))
                        .font(.yqSubheadBold)
                        .foregroundStyle(Color.yqInk)
                    Text(copy("Abu Islam, full recording", "بصوت أبي إسلام، التسجيل الكامل"))
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                    Text(copy("Listen on SoundCloud", "استمع على SoundCloud"))
                        .font(.yqCaptionBold)
                        .foregroundStyle(Color.yqAccentDeep)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.yqAccentDeep)
                    .accessibilityHidden(true)
            }
            .multilineTextAlignment(.leading)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .yqCard(cornerRadius: 18)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.yqPressSoft)
        .accessibilityElement(children: .combine)
        .accessibilityHint(copy("Opens the full recording in SoundCloud or your browser.",
                                "يفتح التسجيل الكامل في SoundCloud أو في المتصفح."))
        .alert(copy("Couldn’t open SoundCloud", "تعذّر فتح SoundCloud"), isPresented: $couldNotOpen) {
            Button(copy("OK", "حسنًا"), role: .cancel) {}
        } message: {
            Text(copy("Please try again. The recording opens outside Haneen.",
                      "يرجى المحاولة مجددًا. يُفتح التسجيل خارج حنين."))
        }
    }

    private func listen() {
        // Hand off audio before opening the provider so recitations do not overlap.
        MushafPlayer.shared.pause()
        RecitationPlayer.shared.stop()
        openURL(recording.url) { accepted in
            couldNotOpen = !accepted
        }
    }
}
