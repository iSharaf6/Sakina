import SwiftUI

/// The reader's now-playing strip: a hairline of progress, the ayah being
/// recited, the voice, and transport controls.
struct MushafPlayerBar: View {
    let language: AppLanguage
    let onJump: (String) -> Void

    @ObservedObject private var player = MushafPlayer.shared
    @State private var showReciter = false

    init(language: AppLanguage, onJump: @escaping (String) -> Void) {
        self.language = language
        self.onJump = onJump
    }

    private var copy: AppCopy { AppCopy(language: language) }

    private var reference: String {
        player.playingKey.flatMap { QuranStore.shared.ayah($0) }?.reference(language) ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            progressLine
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Button {
                        Haptics.press()
                        if let key = player.playingKey { onJump(key) }
                    } label: {
                        Text(reference)
                            .font(.yqSubheadBold)
                            .foregroundStyle(Color.yqInk)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(copy("Shows this ayah", "يعرض هذه الآية"))

                    Button {
                        Haptics.press()
                        showReciter = true
                    } label: {
                        HStack(spacing: 3) {
                            Text(player.reciter.name(language))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(copy("Reciter", "القارئ"))
                }
                .layoutPriority(1)

                Spacer(minLength: 4)

                Button {
                    Haptics.tap()
                    player.playPrevious()
                } label: {
                    CircleButton(symbol: "backward.fill", size: 36)
                }
                .buttonStyle(.yqPress)
                .accessibilityLabel(copy("Previous ayah", "الآية السابقة"))

                Button {
                    Haptics.tap()
                    if player.isPlaying { player.pause() } else { player.resume() }
                } label: {
                    ZStack {
                        CircleButton(symbol: player.isPlaying ? "pause.fill" : "play.fill", size: 44, filled: true)
                            .opacity(player.isBuffering ? 0 : 1)
                        if player.isBuffering {
                            ProgressView()
                                .tint(Color.yqOnAccent)
                                .frame(width: 44, height: 44)
                                .background(Color.yqAccent, in: Circle())
                        }
                    }
                }
                .buttonStyle(.yqPress)
                .accessibilityLabel(player.isPlaying ? copy("Pause", "إيقاف مؤقت") : copy("Play", "تشغيل"))

                Button {
                    Haptics.tap()
                    player.playNext()
                } label: {
                    CircleButton(symbol: "forward.fill", size: 36)
                }
                .buttonStyle(.yqPress)
                .accessibilityLabel(copy("Next ayah", "الآية التالية"))

                Button {
                    Haptics.press()
                    player.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.yqSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy("Stop", "إيقاف"))
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
        .sheet(isPresented: $showReciter) {
            ReciterPickerSheet(language: language)
        }
        .yaqeenLanguage(language)
    }

    private var progressLine: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Color.yqHairline
                Color.yqAccent
                    .frame(width: proxy.size.width * player.progress)
            }
        }
        .frame(height: 2)
        .animation(.linear(duration: 0.25), value: player.progress)
        .accessibilityHidden(true)
    }
}

// MARK: - Reciter picker

/// Every voice we ship, grouped by style, with the downloaded-audio footer.
struct ReciterPickerSheet: View {
    let language: AppLanguage

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = MushafPlayer.shared
    @State private var cacheBytes: Int64 = 0
    @State private var confirmClear = false

    init(language: AppLanguage) {
        self.language = language
    }

    private var copy: AppCopy { AppCopy(language: language) }

    private static let styleOrder = ["Murattal", "Mujawwad", "Muallim"]

    private var groups: [(style: String, reciters: [Reciter])] {
        Self.styleOrder.compactMap { style in
            let reciters = Reciter.allCases.filter { $0.style == style }
            return reciters.isEmpty ? nil : (style, reciters)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(groups, id: \.style) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(styleTitle(group.style)) {
                                Text(styleDetail(group.style))
                                    .font(.yqCaption)
                                    .foregroundStyle(Color.yqSecondary)
                            }
                            RowGroup {
                                ForEach(Array(group.reciters.enumerated()), id: \.element.id) { index, reciter in
                                    if index > 0 { RowDivider(inset: 14) }
                                    Button {
                                        select(reciter)
                                    } label: {
                                        row(reciter)
                                    }
                                    .buttonStyle(.yqPressSoft)
                                    .accessibilityAddTraits(reciter == player.reciter ? .isSelected : [])
                                }
                            }
                        }
                    }
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .yqScreen()
            .navigationTitle(copy("Reciter", "القارئ"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                        .font(.yqSubheadBold)
                }
            }
        }
        .yaqeenLanguage(language)
        .task { await refreshSize() }
        .confirmationDialog(
            copy("Clear downloaded audio?", "حذف الصوت المحمّل؟"),
            isPresented: $confirmClear,
            titleVisibility: .visible
        ) {
            Button(copy("Clear", "حذف"), role: .destructive) {
                Task {
                    await RecitationCache.shared.clear()
                    await refreshSize()
                    Haptics.success()
                }
            }
        } message: {
            Text(copy(
                "Ayat will download again the next time they play.",
                "سيتم تحميل الآيات مجددًا عند تشغيلها في المرة القادمة."
            ))
        }
    }

    private func row(_ reciter: Reciter) -> some View {
        let selected = reciter == player.reciter
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reciter.name(language))
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                Text(language == .arabic ? reciter.displayName : reciter.arabicName)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Tag(text: "\(reciter.bitrate) kbps", tint: selected ? .yqAccentDeep : .yqSecondary)
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.yqAccentDeep)
                .opacity(selected ? 1 : 0)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(copy("Downloaded audio", "الصوت المحمّل"))
            RowGroup {
                BadgeRow(
                    symbol: "arrow.down.circle.fill",
                    title: copy("On this device", "على هذا الجهاز"),
                    subtitle: copy("Played ayat are kept for offline listening, up to 300 MB.",
                                   "تُحفظ الآيات المشغّلة للاستماع دون اتصال، حتى 300 ميغابايت.")
                ) {
                    Text(ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file))
                        .font(.yqSubheadBold)
                        .foregroundStyle(Color.yqSecondary)
                        .monospacedDigit()
                }
                RowDivider(inset: 14)
                Button {
                    Haptics.press()
                    confirmClear = true
                } label: {
                    Text(copy("Clear downloaded audio", "حذف الصوت المحمّل"))
                        .font(.yqBodyMedium)
                        .foregroundStyle(cacheBytes > 0 ? Color.red : Color.yqTertiary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.yqPressSoft)
                .disabled(cacheBytes == 0)
            }
        }
    }

    private func select(_ reciter: Reciter) {
        guard reciter != player.reciter else { return }
        Haptics.selection()
        player.setReciter(reciter)
    }

    private func refreshSize() async {
        cacheBytes = await RecitationCache.shared.size()
    }

    private func styleTitle(_ style: String) -> String {
        switch style {
        case "Mujawwad": return copy("Mujawwad", "مجوّد")
        case "Muallim": return copy("Muallim", "معلّم")
        default: return copy("Murattal", "مرتّل")
        }
    }

    private func styleDetail(_ style: String) -> String {
        switch style {
        case "Mujawwad": return copy("Slow, melodic", "بطيء، مُلحّن")
        case "Muallim": return copy("Repeats for learners", "يكرر للمتعلمين")
        default: return copy("Measured, everyday", "متّزن، للقراءة اليومية")
        }
    }
}
