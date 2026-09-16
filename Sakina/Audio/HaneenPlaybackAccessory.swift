import Combine
import SwiftUI

/// Only source changes redraw the tab container; progress ticks stay inside the
/// compact controls. The three players hand ownership to one another before play.
@MainActor
final class HaneenPlaybackPresence: ObservableObject {
    enum Source: Equatable { case adhkar, quran, situation }
    struct Failure {
        let source: Source
        let message: String
    }
    static let shared = HaneenPlaybackPresence()
    @Published private(set) var source: Source?
    @Published private(set) var failure: Failure?
    private var subscription: AnyCancellable?
    private var errorSubscription: AnyCancellable?

    private init() {
        subscription = AdhkarAudioPlayer.shared.$recording
            .combineLatest(MushafPlayer.shared.$playingKey, RecitationPlayer.shared.$playingID)
            .map { recording, key, situationID -> Source? in
                if recording != nil { return .adhkar }
                if key != nil { return .quran }
                if situationID != nil { return .situation }
                return nil
            }
            .removeDuplicates()
            .sink { [weak self] in self?.source = $0 }
        errorSubscription = MushafPlayer.shared.$errorMessage
            .combineLatest(RecitationPlayer.shared.$errorMessage)
            .sink { [weak self] quranError, situationError in
                self?.failure = quranError.map { Failure(source: .quran, message: $0) }
                    ?? situationError.map { Failure(source: .situation, message: $0) }
            }
    }

    func clearFailure() {
        MushafPlayer.shared.clearError()
        RecitationPlayer.shared.clearError()
    }

    func retry(_ failure: Failure) {
        switch failure.source {
        case .quran: MushafPlayer.shared.retryAfterFailure()
        case .situation: RecitationPlayer.shared.retryAfterFailure()
        case .adhkar: break
        }
    }
}

extension View {
    /// Attach once to the root TabView so navigation never owns audio lifetime.
    func haneenPlaybackAccessory(language: AppLanguage,
                                 onOpenQuran: @escaping (String) -> Void,
                                 onOpenSituation: @escaping (Situation) -> Void) -> some View {
        modifier(HaneenPlaybackAccessoryModifier(language: language,
                                                  onOpenQuran: onOpenQuran,
                                                  onOpenSituation: onOpenSituation))
    }
}

private struct HaneenPlaybackAccessoryModifier: ViewModifier {
    let language: AppLanguage
    let onOpenQuran: (String) -> Void
    let onOpenSituation: (Situation) -> Void
    @ObservedObject private var presence = HaneenPlaybackPresence.shared
    @State private var showPlayer = false

    @ViewBuilder
    func body(content: Content) -> some View {
        accessory(in: content)
            .sheet(isPresented: $showPlayer) {
                HaneenPlaybackSheet(language: language,
                                     onOpenQuran: { key in showPlayer = false; onOpenQuran(key) },
                                     onOpenSituation: { situation in showPlayer = false; onOpenSituation(situation) })
            }
            .onChange(of: presence.source) { _, source in
                if source == nil { showPlayer = false }
            }
            .alert(language.pick("Couldn’t play audio", "تعذّر تشغيل الصوت"),
                   isPresented: Binding(get: { !showPlayer && presence.failure != nil },
                                        set: { if !$0 { presence.clearFailure() } }),
                   presenting: presence.failure) { failure in
                Button(language.pick("Try again", "حاول مجددًا")) { presence.retry(failure) }
                Button(language.pick("Dismiss", "إغلاق"), role: .cancel) { presence.clearFailure() }
            } message: { failure in
                Text(failure.message)
            }
    }

    @ViewBuilder
    private func accessory(in content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: presence.source != nil) {
                HaneenMiniPlayer(language: language) { showPlayer = true }
            }
        } else {
            // iOS 17–26.0 cannot conditionally enable the native tab accessory.
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                if presence.source != nil {
                    HaneenMiniPlayer(language: language) { showPlayer = true }
                        .background(.regularMaterial)
                }
            }
        }
    }
}

private struct HaneenMiniPlayer: View {
    let language: AppLanguage
    let open: () -> Void
    @ObservedObject private var adhkar = AdhkarAudioPlayer.shared
    @ObservedObject private var quran = MushafPlayer.shared
    @ObservedObject private var recitation = RecitationPlayer.shared

    private var copy: AppCopy { AppCopy(language: language) }
    private var isPlaying: Bool { adhkar.recording != nil ? adhkar.isPlaying : quran.playingKey != nil ? quran.isPlaying : recitation.isPlaying }
    private var isBuffering: Bool { adhkar.recording != nil ? adhkar.isBuffering : quran.playingKey != nil ? quran.isBuffering : recitation.isBuffering }
    private var title: String {
        if adhkar.recording != nil { return adhkar.playbackTitle(language) }
        if let key = quran.playingKey { return QuranStore.shared.ayah(key)?.reference(language) ?? key }
        return recitation.situation?.localizedTitle(language) ?? "Haneen"
    }
    private var subtitle: String {
        if isBuffering { return copy("Loading audio…", "جارٍ تحميل الصوت…") }
        if adhkar.recording != nil { return copy("Abu Islam", "أبو إسلام") }
        return (quran.playingKey != nil ? quran.reciter : recitation.reciter).name(language)
    }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: open) {
                HStack(spacing: 10) {
                    Image("HaneenNowPlaying")
                        .resizable().scaledToFit().frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.yqSubheadBold).foregroundStyle(Color.yqInk)
                        Text(subtitle).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(copy("Opens the audio player", "يفتح مشغّل الصوت"))

            Button(action: toggle) {
                ZStack {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .opacity(isBuffering ? 0 : 1)
                    if isBuffering { ProgressView().tint(Color.yqAccentDeep) }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.yqAccentDeep)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? copy("Pause audio", "إيقاف الصوت مؤقتًا") : copy("Resume audio", "متابعة الصوت"))

            Button(action: stop) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.yqSecondary)
                    .frame(width: 44, height: 44).contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copy("Stop audio", "إيقاف الصوت"))
        }
        .padding(.leading, 12).padding(.trailing, 2).padding(.vertical, 6)
        .yaqeenLanguage(language)
    }

    private func toggle() {
        if adhkar.recording != nil { adhkar.toggle() }
        else if quran.playingKey != nil { if quran.isPlaying { quran.pause() } else { quran.resume() } }
        else if recitation.isPlaying { recitation.pause() } else { recitation.resume() }
    }

    private func stop() {
        if adhkar.recording != nil { adhkar.stop() }
        else if quran.playingKey != nil { quran.stop() }
        else { recitation.stop() }
    }
}

private struct HaneenPlaybackSheet: View {
    let language: AppLanguage
    let onOpenQuran: (String) -> Void
    let onOpenSituation: (Situation) -> Void
    @ObservedObject private var adhkar = AdhkarAudioPlayer.shared
    @ObservedObject private var quran = MushafPlayer.shared
    @ObservedObject private var recitation = RecitationPlayer.shared
    @Environment(\.dismiss) private var dismiss
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        if let recording = adhkar.recording {
            AdhkarPlayerSheet(recording: recording, language: language)
        } else {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        Image("HaneenNowPlaying")
                            .resizable().scaledToFit().frame(maxWidth: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 36))
                            .accessibilityHidden(true)
                        if let key = quran.playingKey {
                            Text(QuranStore.shared.ayah(key)?.reference(language) ?? key)
                                .font(.yqTitle2).foregroundStyle(Color.yqInk)
                            MushafPlayerBar(language: language, onJump: onOpenQuran)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            Button(copy("Return to the Qur’an", "العودة إلى القرآن")) { onOpenQuran(key) }
                                .font(.yqSubheadBold).buttonStyle(.bordered)
                        } else if let situation = recitation.situation {
                            Text(situation.localizedTitle(language))
                                .font(.yqTitle2).foregroundStyle(Color.yqInk)
                            if let verse = recitation.currentVerse {
                                Text(language == .arabic ? "\(verse.surahNameArabic) \(verse.key)" : verse.reference)
                                    .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                            }
                            Text(recitation.reciter.name(language))
                                .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                            ProgressView(value: recitation.currentTime, total: max(1, recitation.duration))
                                .tint(.yqAccentDeep)
                                .accessibilityLabel(copy("Ayah progress", "تقدّم التلاوة"))
                            HStack(spacing: 30) {
                                Button { recitation.playPrevious() } label: {
                                    CircleButton(symbol: "backward.fill", size: 46)
                                }.accessibilityLabel(copy("Previous ayah", "الآية السابقة"))
                                Button { if recitation.isPlaying { recitation.pause() } else { recitation.resume() } } label: {
                                    CircleButton(symbol: recitation.isPlaying ? "pause.fill" : "play.fill", size: 60, filled: true)
                                }.accessibilityLabel(recitation.isPlaying ? copy("Pause", "إيقاف مؤقت") : copy("Play", "تشغيل"))
                                Button { recitation.playNext() } label: {
                                    CircleButton(symbol: "forward.fill", size: 46)
                                }.accessibilityLabel(copy("Next ayah", "الآية التالية"))
                            }
                            .buttonStyle(.plain)
                            Button(copy("Return to the reading", "العودة إلى القراءة")) { onOpenSituation(situation) }
                                .font(.yqSubheadBold).buttonStyle(.bordered)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(24)
                }
                .yqScreen()
                .navigationTitle(copy("Now playing", "قيد التشغيل"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(copy("Done", "تم")) { dismiss() }.font(.yqSubheadBold)
                    }
                }
            }
            .yaqeenLanguage(language)
        }
    }
}
