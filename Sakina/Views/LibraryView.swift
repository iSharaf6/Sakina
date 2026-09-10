import SwiftData
import SwiftUI

struct LibraryView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case saved, duas, reflections
        var id: String { rawValue }
    }

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(DuaCollection.savedKey) private var savedDuasRaw = ""
    @AppStorage("yaqeen.libraryMode") private var mode: Mode = .saved
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var account = GoogleAccountManager.shared
    @Namespace private var selector
    @State private var showSettings = false

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var savedDuas: [GuidanceSupplication] { DuaCollection.savedIDs(savedDuasRaw).compactMap(DuaCollection.dua) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 12) {
                        PageHeader(title: copy("Saved", "المحفوظات"),
                                   subtitle: copy("Keep what speaks to you.", "احتفظ بما يلامس قلبك."))
                        SettingsButton(language: language) { showSettings = true }
                    }
                    NavigationLink { AyahLibraryView(language: language) } label: {
                        BadgeRow(symbol: "bookmark.fill", title: copy("My ayat", "آياتي"),
                                 subtitle: copy("Highlights, bookmarks, notes and categories from the mushaf",
                                                "تظليلات وعلامات وملاحظات وتصنيفات من المصحف"), artwork: .quran)
                            .yqCard()
                    }
                    .buttonStyle(.yqPress)
                    modeSelector
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .yqScreen()
            .navigationDestination(for: Situation.self) { SituationDetailView(situation: $0) }
            .navigationDestination(for: GuidanceSupplication.self) { DuaReaderView(dua: $0) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView(showsDismissButton: true) }
            .sensoryFeedback(.selection, trigger: mode)
        }
    }

    // MARK: Selector

    private var modeSelector: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases) { item in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) { mode = item }
                } label: {
                    HStack(spacing: 6) {
                        Text(modeTitle(item))
                        Text("\(count(item))")
                            .font(.system(.caption2, weight: .bold).monospacedDigit())
                            .foregroundStyle(mode == item ? Color.yqOnAccent.opacity(0.85) : Color.yqTertiary)
                    }
                    .font(.yqSubheadBold)
                    .foregroundStyle(mode == item ? Color.yqOnAccent : Color.yqSecondary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 38)
                    .background {
                        if mode == item {
                            Capsule(style: .continuous).fill(Color.yqAccent)
                                .matchedGeometryEffect(id: "selector", in: selector)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.yqPressSoft)
            }
        }
        .padding(4)
        .background(Color.yqFill, in: Capsule(style: .continuous))
    }

    private func modeTitle(_ mode: Mode) -> String {
        switch mode {
        case .saved: return copy("Moments", "المواقف")
        case .duas: return copy("Du’as", "الأدعية")
        case .reflections: return copy("Reflections", "التأملات")
        }
    }

    private func count(_ mode: Mode) -> Int {
        switch mode {
        case .saved: return bookmarks.count
        case .duas: return savedDuas.count
        case .reflections: return entries.count
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .duas:
            if savedDuas.isEmpty {
                DuaEmptyState(savedOnly: true, language: language)
                NavigationLink { DuasView(showsNavigationBar: true) } label: {
                    SecondaryButton(title: copy("Find a du’a to keep", "اختر دعاءً لتحفظه"), symbol: language == .arabic ? "arrow.left" : "arrow.right")
                }
                .buttonStyle(.yqPress)
            } else {
                RowGroup {
                    ForEach(Array(savedDuas.enumerated()), id: \.element.id) { index, dua in
                        NavigationLink(value: dua) {
                            DuaListRow(dua: dua, index: index + 1, language: language, saved: true)
                        }
                        .buttonStyle(.yqPressSoft)
                        .contextMenu {
                            Button(role: .destructive) { savedDuasRaw = DuaCollection.toggling(dua.id, in: savedDuasRaw) } label: {
                                Label(copy("Remove", "إزالة"), systemImage: "bookmark.slash")
                            }
                        }
                        if index < savedDuas.count - 1 { RowDivider(inset: 54) }
                    }
                }
                Text(copy("Saved on this iPhone.", "محفوظة على هذا الهاتف."))
                    .font(.yqCaption).foregroundStyle(Color.yqTertiary)
            }
        case .saved:
            if bookmarks.isEmpty {
                EmptyGuidanceState(
                    title: copy("Nothing saved yet", "لا توجد محفوظات بعد"),
                    detail: copy("Save a moment from any guidance screen and it will wait here for you.",
                                 "احفظ أي موقف من شاشة الهداية وستجده هنا عند عودتك."),
                    symbol: "bookmark", artwork: .saved
                )
                NavigationLink { QuickGuidanceView() } label: {
                    SecondaryButton(title: copy("Find a moment", "اختر موقفًا"), symbol: language == .arabic ? "arrow.left" : "arrow.right")
                }
                .buttonStyle(.yqPress)
            } else {
                let saved = bookmarks.compactMap { bookmark in bookmark.situation.map { (bookmark, $0) } }
                RowGroup {
                    ForEach(Array(saved.enumerated()), id: \.element.0.id) { index, pair in
                        NavigationLink(value: pair.1) {
                            SituationRow(situation: pair.1, language: language)
                        }
                        .buttonStyle(.yqPressSoft)
                        .contextMenu {
                            Button(role: .destructive) { deleteBookmark(pair.0) } label: {
                                Label(copy("Remove", "إزالة"), systemImage: "bookmark.slash")
                            }
                        }
                        if index < saved.count - 1 { RowDivider(inset: 60) }
                    }
                }
            }
        case .reflections:
            if entries.isEmpty {
                EmptyGuidanceState(
                    title: copy("A quiet place for your words", "مكان هادئ لكلماتك"),
                    detail: copy("Your private reflections stay on this iPhone. If you connect a backup, Yaqeen explains what is shared first.",
                                 "تبقى تأملاتك الخاصة على هذا الهاتف. وإذا ربطت نسخة احتياطية، فسيشرح يقين ما تتم مشاركته أولًا."),
                    symbol: "square.and.pencil", artwork: .journal
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(entries) { entry in reflectionCard(entry) }
                }
            }
        }
    }

    private func reflectionCard(_ entry: JournalEntry) -> some View {
        let situation = entry.situation
        return Group {
            if let situation {
                NavigationLink(value: situation) { reflectionBody(entry, situation: situation) }
                    .buttonStyle(.yqPressSoft)
            } else {
                reflectionBody(entry, situation: nil)
            }
        }
        .contextMenu {
            Button(role: .destructive) { deleteReflection(entry) } label: {
                Label(copy("Delete reflection", "حذف التأمل"), systemImage: "trash")
            }
        }
    }

    private func reflectionBody(_ entry: JournalEntry, situation: Situation?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(situation?.localizedTitle(language) ?? copy("Reflection", "تأمل"))
                    .font(.yqCaptionBold)
                    .foregroundStyle(Color.yqAccentDeep)
                    .lineLimit(1)
                Spacer()
                Text(entry.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
            }
            Text(entry.text)
                .font(.yqBody)
                .lineSpacing(4)
                .lineLimit(4)
                .foregroundStyle(Color.yqInk)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yqCard()
    }

    private func deleteBookmark(_ bookmark: Bookmark) {
        context.delete(bookmark)
        persistAndBackUpIfConnected()
    }

    private func deleteReflection(_ entry: JournalEntry) {
        context.delete(entry)
        persistAndBackUpIfConnected()
    }

    private func persistAndBackUpIfConnected() {
        try? context.save()
        guard account.isSignedIn, let backup = YaqeenBackup.snapshot(from: context) else { return }
        Task { _ = await account.upload(backup) }
    }
}
