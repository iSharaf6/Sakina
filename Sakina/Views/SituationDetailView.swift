import SwiftUI
import SwiftData
import WidgetKit

// MARK: Situation detail

struct SituationDetailView: View {
    let situation: Situation

    @Environment(\.modelContext) private var context
    @Query private var bookmarks: [Bookmark]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var allEntries: [JournalEntry]
    @ObservedObject private var player = RecitationPlayer.shared
    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0
    @AppStorage(SettingsKeys.reciter) private var reciterRaw = Reciter.alafasy.rawValue

    @State private var draft = ""
    @State private var toast: String?
    @State private var shareImage: Image?
    @FocusState private var editorFocused: Bool

    private var hue: Color { .chapterHue(situation.chapter) }
    private var chapter: Chapter { .by(situation.chapter) }
    private var isBookmarked: Bool { bookmarks.contains { $0.situationID == situation.id } }
    private var entries: [JournalEntry] { allEntries.filter { $0.situationID == situation.id } }
    private var isPlaying: Bool { player.playingID == situation.id }
    private var draftTrimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var reciterName: String {
        Reciter(rawValue: reciterRaw)?.displayName ?? Reciter.alafasy.displayName
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AtmosphereBackground(hue: hue)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    headerBlock
                    versesCard
                    surahPlate
                    actionBar
                    whyCard
                    reflectionSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 64)
            }
            .scrollDismissesKeyboard(.interactively)

            if let toast {
                Toast(message: toast)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { renderShareCard() }
        .onDisappear { player.stopIfPlaying(id: situation.id) }
    }

    // MARK: Header

    private var headerBlock: some View {
        VStack(spacing: 14) {
            CapsLabel(text: chapter.title, color: hue, size: 10)
            Text(situation.title)
                .font(.display(26))
                .italic()
                .foregroundStyle(Color.sakinaInk)
                .multilineTextAlignment(.center)
            StarDivider(color: hue)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Verses

    private var versesCard: some View {
        VStack(spacing: 28) {
            ForEach(situation.verses) { verse in
                VStack(spacing: 18) {
                    if situation.verses.count > 1 {
                        ayahMedallion(verse.ayah)
                    }
                    Text(verse.arabic)
                        .font(.arabic(28 * arabicScale))
                        .lineSpacing(16 * arabicScale)
                        .foregroundStyle(Color.sakinaInk)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .environment(\.layoutDirection, .rightToLeft)
                        .shadow(color: Color.sakinaGold.opacity(0.22), radius: 22)
                    Text(verse.translation)
                        .font(.reading(17))
                        .lineSpacing(7)
                        .foregroundStyle(Color.sakinaInk.opacity(0.93))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(24)
        .sakinaCard(tint: hue, cornerRadius: 28)
    }

    private func ayahMedallion(_ number: Int) -> some View {
        ZStack {
            EightPointStar()
                .stroke(hue.opacity(0.6), lineWidth: 1)
                .frame(width: 30, height: 30)
            Text("\(number)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(hue)
        }
    }

    // MARK: Surah plate

    private var surahPlate: some View {
        Group {
            if let verse = situation.primaryVerse {
                HStack(spacing: 14) {
                    Text(verse.surahNameArabic)
                        .font(.arabic(20))
                        .foregroundStyle(Color.sakinaGold)
                    Rectangle()
                        .fill(Color.sakinaHairline)
                        .frame(width: 1, height: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Surah \(verse.surahName)")
                            .font(.display(15, weight: .medium))
                            .foregroundStyle(Color.sakinaInk)
                        Text("“\(verse.surahNameTranslated)”, Ayah \(ayahRangeLabel)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.sakinaMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 6)
            }
        }
    }

    private var ayahRangeLabel: String {
        let numbers = situation.verses.map { "\($0.ayah)" }
        switch numbers.count {
        case 0: return ""
        case 1: return numbers[0]
        case 2: return "\(numbers[0]) and \(numbers[1])"
        default: return "\(numbers.first!) to \(numbers.last!)"
        }
    }

    // MARK: Actions

    private var tafsirURL: URL? {
        guard let verse = situation.primaryVerse else { return nil }
        return URL(string: "https://quran.com/\(verse.surah):\(verse.ayah)/tafsirs")
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                actionButton(
                    icon: isPlaying ? "pause.fill" : "play.fill",
                    label: isPlaying ? "Pause" : "Listen",
                    prominent: true
                ) {
                    player.toggle(situation: situation)
                }
                actionButton(
                    icon: isBookmarked ? "heart.fill" : "heart",
                    label: isBookmarked ? "Saved" : "Save"
                ) {
                    toggleBookmark()
                }
                actionButton(icon: "pin", label: "Pin widget") {
                    pinToWidget()
                }
            }
            HStack(spacing: 12) {
                if let tafsirURL {
                    Link(destination: tafsirURL) {
                        wideActionLabel(icon: "book", label: "Tafsir on Quran.com")
                    }
                    .buttonStyle(PressableCard())
                }
                if let shareImage {
                    ShareLink(
                        item: shareImage,
                        preview: SharePreview(situation.title, image: shareImage)
                    ) {
                        wideActionLabel(icon: "square.and.arrow.up", label: "Share card")
                    }
                    .buttonStyle(PressableCard())
                }
            }
            CapsLabel(text: "Recitation by \(reciterName)", size: 9)
        }
    }

    private func actionButton(
        icon: String, label: String, prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(prominent ? Color.black.opacity(0.82) : Color.sakinaInk)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: prominent ? .infinity : nil)
            .background(
                Capsule().fill(prominent ? Color.sakinaGold : Color.sakinaElevated)
            )
            .overlay(
                Capsule().strokeBorder(
                    prominent ? Color.clear : Color.sakinaHairline, lineWidth: 1
                )
            )
        }
        .buttonStyle(PressableCard())
    }

    private func wideActionLabel(icon: String, label: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Color.sakinaInk)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(Color.sakinaElevated))
        .overlay(Capsule().strokeBorder(Color.sakinaHairline, lineWidth: 1))
    }

    private func toggleBookmark() {
        if let existing = bookmarks.first(where: { $0.situationID == situation.id }) {
            context.delete(existing)
            showToast("Removed from your library")
        } else {
            context.insert(Bookmark(situationID: situation.id))
            showToast("Saved to your library")
        }
    }

    private func pinToWidget() {
        SharedStore.pinnedSituationID = situation.id
        WidgetCenter.shared.reloadAllTimelines()
        showToast("Pinned to your home screen widget")
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.3)) {
                if toast == message { toast = nil }
            }
        }
    }

    // MARK: Share card

    @MainActor
    private func renderShareCard() {
        let renderer = ImageRenderer(content: VerseShareCard(situation: situation))
        renderer.scale = 3
        if let ui = renderer.uiImage {
            shareImage = Image(uiImage: ui)
        }
    }

    // MARK: Why this ayah

    private var whyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CapsLabel(text: "Why this ayah", color: hue)
                Spacer()
                EightPointStar()
                    .fill(hue.opacity(0.6))
                    .frame(width: 10, height: 10)
            }
            Text(situation.whyNote)
                .font(.reading(15.5))
                .lineSpacing(6)
                .foregroundStyle(Color.sakinaInk.opacity(0.95))
            Text("A brief reflection on the verse's plain meaning, not tafsir. For deeper study, open the tafsir on Quran.com above or ask a scholar you trust.")
                .font(.system(size: 11))
                .foregroundStyle(Color.sakinaMuted)
                .padding(.top, 2)
        }
        .padding(20)
        .sakinaCard(tint: hue)
    }

    // MARK: Reflection

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            CapsLabel(text: "Your reflection", color: .sakinaGold)

            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    if draft.isEmpty {
                        Text("Write a thought or du'a. Only you can see this.")
                            .font(.reading(15))
                            .foregroundStyle(Color.sakinaMuted)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $draft)
                        .font(.reading(15))
                        .foregroundStyle(Color.sakinaInk)
                        .frame(minHeight: 96)
                        .scrollContentBackground(.hidden)
                        .focused($editorFocused)
                }
                HStack {
                    Spacer()
                    Button {
                        saveEntry()
                    } label: {
                        Label("Save reflection", systemImage: "arrow.down.heart")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(
                                draftTrimmed.isEmpty ? Color.sakinaMuted : Color.black.opacity(0.82)
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(
                                    draftTrimmed.isEmpty
                                        ? Color.sakinaMuted.opacity(0.18)
                                        : Color.sakinaGold
                                )
                            )
                    }
                    .disabled(draftTrimmed.isEmpty)
                }
            }
            .padding(16)
            .sakinaCard()

            ForEach(entries) { entry in
                entryCard(entry)
            }
        }
    }

    private func saveEntry() {
        guard !draftTrimmed.isEmpty else { return }
        context.insert(JournalEntry(situationID: situation.id, text: draftTrimmed))
        draft = ""
        editorFocused = false
        showToast("Reflection saved")
    }

    private func entryCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CapsLabel(
                    text: entry.createdAt.formatted(date: .abbreviated, time: .shortened),
                    size: 9
                )
                Spacer()
                Button {
                    context.delete(entry)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sakinaMuted)
                }
                .accessibilityLabel("Delete reflection")
            }
            Text(entry.text)
                .font(.reading(15))
                .lineSpacing(5)
                .foregroundStyle(Color.sakinaInk.opacity(0.92))
        }
        .padding(16)
        .sakinaCard(cornerRadius: 18)
    }
}

// MARK: Share card view

/// Fixed dark rendition of a verse, exported as an image by ShareLink.
struct VerseShareCard: View {
    let situation: Situation

    private let ink = Color(red: 0.95, green: 0.92, blue: 0.87)
    private let gold = Color(red: 0.85, green: 0.70, blue: 0.42)

    var body: some View {
        VStack(spacing: 20) {
            EightPointStar()
                .fill(gold)
                .frame(width: 14, height: 14)
                .padding(.top, 34)

            ForEach(situation.verses) { verse in
                VStack(spacing: 14) {
                    Text(verse.arabic)
                        .font(.custom("KFGQPC HAFS Uthmanic Script", size: 24))
                        .lineSpacing(12)
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.center)
                        .environment(\.layoutDirection, .rightToLeft)
                    Text(verse.translation)
                        .font(.system(size: 13.5, design: .serif))
                        .lineSpacing(5)
                        .foregroundStyle(ink.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
            }

            Text(situation.referenceLabel.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(gold)

            Text("SAKINA")
                .font(.system(size: 9, weight: .semibold))
                .tracking(3.5)
                .foregroundStyle(ink.opacity(0.4))
                .padding(.bottom, 30)
        }
        .padding(.horizontal, 34)
        .frame(width: 400)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.13),
                    Color(red: 0.03, green: 0.045, blue: 0.08),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}
