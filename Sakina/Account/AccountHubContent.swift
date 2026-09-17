import SwiftData
import SwiftUI

/// Keep the account hub and its browse screens in the Settings value path.
/// Mixing view-based parent pushes with value-based practice or guidance links
/// can prevent the later push from being retained by NavigationStack.
enum AccountHubRoute: Hashable {
    case space
    case dailyGoals
    case saved(AccountSavedContentView.Collection)
    case browseDuas
}

struct AccountHubDestination: View {
    let route: AccountHubRoute
    let language: AppLanguage

    var body: some View {
        switch route {
        case .space: CompanionAccountView()
        case .dailyGoals: DailyGoalsView(language: language)
        case .saved(let collection): AccountSavedContentView(collection: collection, language: language)
        case .browseDuas: DuasView(showsNavigationBar: true)
        }
    }
}

/// The hub counts only content that can actually be opened on this device.
/// An ayah with both a note and a highlight is still one saved ayah.
@MainActor
struct AccountLibrarySummary {
    let ayat: Int
    let notes: Int
    let duas: Int
    let moments: Int
    let reflections: Int

    init(marks: [AyahMark], savedDuas: String, situationIDs: [String], reflectionTexts: [String]) {
        let validMarks = marks.filter { !$0.isEmpty && QuranStore.shared.ayah($0.key) != nil }
        ayat = Set(validMarks.map(\.key)).count
        notes = Set(validMarks.filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.map(\.key)).count
        duas = DuaCollection.savedIDs(savedDuas).count
        moments = Set(situationIDs.filter { SituationCatalog.by(id: $0) != nil }).count
        reflections = reflectionTexts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    static func readingAyah(for key: String?) -> QuranAyah? {
        key.flatMap { QuranStore.shared.ayah($0) }
    }
}

struct AccountRoutineSummary {
    let enabled: [DailyGoal]
    let completed: Int
    let nextGoal: DailyGoal?
    var progress: Double { enabled.isEmpty ? 0 : Double(completed) / Double(enabled.count) }

    init(enabledRaw: String, logRaw: String, on date: Date = .now) {
        enabled = GoalPreferences.enabled(from: enabledRaw)
        let done = GoalLog.doneIDs(on: date, in: logRaw)
        completed = enabled.filter { done.contains($0.id) }.count
        nextGoal = enabled.first { !done.contains($0.id) }
    }
}

/// These destinations keep the Settings navigation stack instead of nesting the
/// Saved tab's NavigationStack or changing its selected segment behind the user.
struct AccountSavedContentView: View {
    enum Collection: Hashable { case duas, moments, reflections }
    let collection: Collection
    let language: AppLanguage
    @AppStorage(DuaCollection.savedKey) private var savedRaw = ""
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]
    private var copy: AppCopy { AppCopy(language: language) }
    private var savedDuas: [GuidanceSupplication] { DuaCollection.savedIDs(savedRaw).compactMap(DuaCollection.dua) }
    private var savedSituations: [Situation] { bookmarks.compactMap(\.situation) }
    private var reflections: [JournalEntry] {
        entries.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var title: String {
        switch collection {
        case .duas: return copy("Saved du’as", "الأدعية المحفوظة")
        case .moments: return copy("Saved moments", "المواقف المحفوظة")
        case .reflections: return copy("Your reflections", "تأملاتك")
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: title, subtitle: copy("Saved on this iPhone.", "محفوظة على هذا الهاتف."))
                switch collection {
                case .duas: duaContent
                case .moments: momentContent
                case .reflections: reflectionContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var duaContent: some View {
        if savedDuas.isEmpty {
            empty(title: copy("Keep a du’a close", "احتفظ بدعاء قريبًا منك"),
                  detail: copy("Tap the bookmark while reading a du’a. You’ll find it here whenever you need it.",
                               "اضغط على علامة الحفظ أثناء قراءة الدعاء، لتجده هنا متى احتجت إليه."), artwork: .saved)
        } else {
            RowGroup {
                ForEach(Array(savedDuas.enumerated()), id: \.element.id) { index, dua in
                    NavigationLink(value: dua) {
                        DuaListRow(dua: dua, index: index + 1, language: language, saved: true)
                    }
                    .buttonStyle(.yqPressSoft)
                    if index < savedDuas.count - 1 { RowDivider() }
                }
            }
        }
        NavigationLink(value: AccountHubRoute.browseDuas) {
            SecondaryButton(title: copy("Explore du’as", "تصفّح الأدعية"), symbol: "text.book.closed")
        }
        .buttonStyle(.yqPress)
    }

    @ViewBuilder
    private var momentContent: some View {
        if savedSituations.isEmpty {
            empty(title: copy("A reading to return to", "قراءة ترجع إليها"),
                  detail: copy("Save a life moment or a reading that speaks to you. It will be waiting here.",
                               "احفظ موقفًا أو قراءة تلامس قلبك، لتعود إليها من هنا."), artwork: .saved)
        } else {
            RowGroup {
                ForEach(Array(savedSituations.enumerated()), id: \.element.id) { index, situation in
                    NavigationLink(value: GuidanceRoute.situation(situation.id)) {
                        SituationRow(situation: situation, language: language)
                    }
                    .buttonStyle(.yqPressSoft)
                    if index < savedSituations.count - 1 { RowDivider() }
                }
            }
        }
        findReading
    }

    @ViewBuilder
    private var reflectionContent: some View {
        if reflections.isEmpty {
            empty(title: copy("Make room for your words", "فسحة لكلماتك"),
                  detail: copy("Open a reading, then choose “Make space for a reflection” to write something you want to keep.",
                               "افتح إحدى القراءات، ثم اختر «فسحة للتأمل» لتكتب ما ترغب في الاحتفاظ به."), artwork: .journal)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(reflections) { entry in
                    NavigationLink { AccountReflectionView(entry: entry, language: language) } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(entry.situation?.localizedTitle(language) ?? copy("Reflection", "تأمل"))
                                    .font(.yqCaptionBold).foregroundStyle(Color.yqAccentDeep)
                                Spacer(minLength: 8)
                                Chevron()
                            }
                            Text(entry.text).font(.yqBody).foregroundStyle(Color.yqInk).lineLimit(4)
                            Text(entry.updatedAt.formatted(.dateTime.day().month(.abbreviated).year().locale(language.locale)))
                                .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                        }
                        .multilineTextAlignment(.leading)
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading).yqCard()
                    }
                    .buttonStyle(.yqPressSoft)
                }
            }
        }
        findReading
    }

    private var findReading: some View {
        NavigationLink(value: GuidanceRoute.quickGuidance) {
            SecondaryButton(title: copy("Find a reading", "اختر قراءة"), symbol: "book")
        }
        .buttonStyle(.yqPress)
    }

    private func empty(title: String, detail: String, artwork: CompanionArtwork) -> some View {
        EmptyGuidanceState(title: title, detail: detail, symbol: "bookmark", artwork: artwork)
            .yqCard(cornerRadius: 20)
    }
}

private struct AccountReflectionView: View {
    let entry: JournalEntry
    let language: AppLanguage
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(entry.situation?.localizedTitle(language) ?? copy("Your reflection", "تأملك"))
                    .font(.yqTitle2).foregroundStyle(Color.yqInk)
                Text(entry.updatedAt.formatted(.dateTime.day().month(.wide).year().locale(language.locale)))
                    .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                Text(entry.text).font(.yqBody).lineSpacing(6)
                    .foregroundStyle(Color.yqInk).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20).yqCard()
                if let situation = entry.situation {
                    NavigationLink { SituationDetailView(situation: situation) } label: {
                        SecondaryButton(title: copy("Open the reading", "افتح القراءة"), symbol: "book")
                    }
                    .buttonStyle(.yqPress)
                }
            }.padding(20)
        }
        .yqScreen()
        .navigationTitle(copy("Reflection", "تأمل"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
