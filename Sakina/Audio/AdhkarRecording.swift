import SwiftUI

/// Recordings by Abu Islam, bundled with permission reported by the app owner.
/// The source URLs are attribution links; playback uses the bundled MP3 files.
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

    var duration: TimeInterval {
        switch self {
        case .morning: return 1291.938
        case .evening: return 1332.793
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .morning: return language.pick("Morning adhkar", "أذكار الصباح")
        case .evening: return language.pick("Evening adhkar", "أذكار المساء")
        }
    }

    static func timestamp(_ seconds: TimeInterval) -> String {
        let value = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}

/// Keeps the reader compact; opens the full transport controls on demand.
struct AdhkarRecordingCard: View {
    let recording: AdhkarRecording
    let language: AppLanguage

    @ObservedObject private var player = AdhkarAudioPlayer.shared
    @State private var showPlayer = false
    private var copy: AppCopy { AppCopy(language: language) }
    private var active: Bool { player.recording == recording }

    var body: some View {
        HStack(spacing: 8) {
            Button { showPlayer = true } label: {
                HStack(spacing: 10) {
                    CompanionIllustration(artwork: .reciter, size: 46)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(recording.title(language))
                            .font(.yqSubheadBold)
                            .foregroundStyle(Color.yqInk)
                        Text(copy("Abu Islam, listen offline", "بصوت أبي إسلام، متاح دون إنترنت"))
                            .font(.yqCaption)
                            .foregroundStyle(Color.yqSecondary)
                        Text(active ? copy("Open player", "افتح المشغّل") : copy("Play the full recording", "استمع إلى التسجيل كاملًا"))
                            .font(.yqCaptionBold)
                            .foregroundStyle(Color.yqAccentDeep)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(copy("Opens playback controls, seeking and recording sections.", "يفتح أدوات التشغيل والتنقّل وأجزاء التسجيل."))

            Button {
                if active { player.toggle() } else { player.play(recording: recording) }
            } label: {
                Image(systemName: active && player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(Color.yqCanvas)
                    .background(Color.yqAccentDeep, in: Circle())
            }
            .buttonStyle(.yqPressSoft)
            .accessibilityLabel(active && player.isPlaying ? copy("Pause adhkar", "إيقاف الأذكار مؤقتًا") : copy("Play adhkar", "تشغيل الأذكار"))
        }
        .padding(12)
        .yqCard(cornerRadius: 18)
        .sheet(isPresented: $showPlayer) {
            AdhkarPlayerSheet(recording: recording, language: language)
        }
        .alert(copy("Couldn’t play the recording", "تعذّر تشغيل التسجيل"),
               isPresented: Binding(get: { player.errorMessage != nil && !showPlayer },
                                    set: { if !$0 { player.clearError() } })) {
            Button(copy("OK", "حسنًا")) { player.clearError() }
        } message: {
            Text(copy("Please try again.", "يرجى المحاولة مجددًا."))
        }
    }
}

struct AdhkarPlayerSheet: View {
    let recording: AdhkarRecording
    let language: AppLanguage

    @ObservedObject private var player = AdhkarAudioPlayer.shared
    @Environment(\.dismiss) private var dismiss
    @State private var scrubbing = false
    @State private var scrubTime = 0.0
    private var copy: AppCopy { AppCopy(language: language) }
    private var active: Bool { player.recording == recording }
    private var duration: TimeInterval { active && player.duration > 0 ? player.duration : recording.duration }
    private var position: TimeInterval { scrubbing ? scrubTime : active ? player.currentTime : 0 }
    private var activeChapter: AdhkarChapter? {
        guard active else { return nil }
        return recording.chapters.first { $0.start == player.startTime && $0.end == player.endTime }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        CompanionIllustration(artwork: .reciter, size: 116)
                            .accessibilityHidden(true)
                        Text(recording.title(language))
                            .font(.yqTitle2)
                            .foregroundStyle(Color.yqInk)
                        Text(copy("Recited by Abu Islam", "بصوت المنشد أبي إسلام"))
                            .font(.yqSubhead)
                            .foregroundStyle(Color.yqSecondary)
                        Text(copy("Ready whenever you are, even offline.", "أذكارك معك، حتى دون اتصال بالإنترنت."))
                            .font(.yqCaption)
                            .foregroundStyle(Color.yqSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        if active, !player.isFullRecording {
                            HStack {
                                Text(activeChapter?.title(language) ?? copy("Playing a section", "تشغيل جزء من التسجيل"))
                                    .font(.yqCaptionBold)
                                    .foregroundStyle(Color.yqAccentDeep)
                                Spacer()
                                Button(copy("Play all", "تشغيل الكل")) { player.play(recording: recording) }
                                    .font(.yqCaptionBold)
                            }
                        }
                        VStack(spacing: 2) {
                            Slider(value: Binding(get: { min(max(0, position), max(1, duration)) }, set: {
                                scrubTime = $0
                                if !scrubbing { player.seek(to: $0) }
                            }),
                                   in: 0...max(1, duration), onEditingChanged: { editing in
                                if editing { scrubTime = player.currentTime }
                                scrubbing = editing
                                if !editing { player.seek(to: scrubTime) }
                            })
                            .tint(.yqAccentDeep)
                            .disabled(!active || player.duration <= 0)
                            .accessibilityLabel(copy("Playback position", "موضع التشغيل"))
                            .accessibilityValue(AdhkarRecording.timestamp(position))
                            HStack {
                                Text(AdhkarRecording.timestamp(position))
                                Spacer()
                                Text(AdhkarRecording.timestamp(duration))
                            }
                            .font(.yqCaption)
                            .monospacedDigit()
                            .foregroundStyle(Color.yqSecondary)
                        }
                        .environment(\.layoutDirection, .leftToRight)

                        HStack(spacing: 36) {
                            Button { player.skip(seconds: -15) } label: {
                                Image(systemName: "gobackward.15")
                                    .font(.system(size: 27, weight: .medium))
                                    .frame(width: 50, height: 50)
                            }
                            .disabled(!active)
                            .accessibilityLabel(copy("Back 15 seconds", "الرجوع ١٥ ثانية"))

                            Button {
                                if active { player.toggle() } else { player.play(recording: recording) }
                            } label: {
                                Group {
                                    if active && player.isBuffering {
                                        ProgressView().tint(Color.yqCanvas)
                                    } else {
                                        Image(systemName: active && player.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 28, weight: .semibold))
                                    }
                                }
                                .frame(width: 76, height: 76)
                                .foregroundStyle(Color.yqCanvas)
                                .background(Color.yqAccentDeep, in: Circle())
                            }
                            .accessibilityLabel(active && player.isPlaying ? copy("Pause", "إيقاف مؤقت") : copy("Play", "تشغيل"))

                            Button { player.skip(seconds: 15) } label: {
                                Image(systemName: "goforward.15")
                                    .font(.system(size: 27, weight: .medium))
                                    .frame(width: 50, height: 50)
                            }
                            .disabled(!active)
                            .accessibilityLabel(copy("Forward 15 seconds", "التقدّم ١٥ ثانية"))
                        }
                        .buttonStyle(.yqPressSoft)
                        .foregroundStyle(Color.yqAccentDeep)
                        .environment(\.layoutDirection, .leftToRight)

                        if player.errorMessage != nil {
                            Text(copy("The recording couldn’t play. Please try again.", "تعذّر تشغيل التسجيل. يرجى المحاولة مجددًا."))
                                .font(.yqCaption)
                                .foregroundStyle(Color.yqSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                    .yqCard(cornerRadius: 24)

                    chapters

                    Link(destination: recording.url) {
                        Text(copy("Original recording by Abu Islam on SoundCloud", "التسجيل الأصلي للمنشد أبي إسلام على SoundCloud"))
                            .font(.yqCaption)
                            .underline()
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Color.yqAccentDeep)
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 22)
            }
            .background(Color.yqCanvas)
            .navigationTitle(copy("Listen", "استمع"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }.font(.yqSubheadBold)
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var chapters: some View {
        // Exact section boundaries are supplied only after checking the recording.
        if !recording.chapters.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(copy("Choose a section", "اختر جزءًا من التسجيل"))
                    .font(.yqSubheadBold)
                    .foregroundStyle(Color.yqInk)
                Text(copy("Each section plays one recitation.", "يُشغّل كل جزء قراءة واحدة."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                VStack(spacing: 0) {
                    ForEach(recording.chapters) { chapter in
                        Button {
                            player.play(recording: recording, startTime: chapter.start, endTime: chapter.end)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 25, weight: .regular))
                                    .accessibilityHidden(true)
                                Text(chapter.title(language)).font(.yqSubhead)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(AdhkarRecording.timestamp(chapter.end - chapter.start))
                                    .font(.yqCaption).monospacedDigit()
                            }
                            .foregroundStyle(Color.yqInk)
                            .padding(14)
                            .frame(minHeight: 52)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.yqPressSoft)
                        if chapter.id != recording.chapters.last?.id { Divider().padding(.horizontal, 14) }
                    }
                }
                .yqCard(cornerRadius: 18)
            }
        }
    }
}

struct AdhkarExcerptButton: View {
    let recording: AdhkarRecording
    let chapter: AdhkarChapter
    let language: AppLanguage
    @ObservedObject private var player = AdhkarAudioPlayer.shared
    private var active: Bool {
        player.recording == recording && player.startTime == chapter.start && player.endTime == chapter.end
    }

    var body: some View {
        Button {
            if active { player.toggle() }
            else { player.play(recording: recording, startTime: chapter.start, endTime: chapter.end) }
        } label: {
            HStack(spacing: 10) {
                CompanionIllustration(artwork: .reciter, size: 32).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(active && player.isPlaying ? language.pick("Pause recitation", "إيقاف القراءة مؤقتًا")
                         : language.pick("Listen to this dhikr", "استمع إلى هذا الذكر"))
                        .font(.yqCaptionBold)
                    Text(language.pick("Abu Islam, one recitation", "أبو إسلام، قراءة واحدة"))
                        .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                }
                Spacer(minLength: 4)
                Image(systemName: active && player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold)).accessibilityHidden(true)
            }
            .foregroundStyle(Color.yqAccentDeep)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.yqPressSoft)
        .accessibilityElement(children: .combine)
    }
}
