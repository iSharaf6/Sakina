import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Situation detail

struct SituationDetailView: View {
    let situation: Situation

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var bookmarks: [Bookmark]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var allEntries: [JournalEntry]
    @ObservedObject private var player = RecitationPlayer.shared
    @ObservedObject private var account = GoogleAccountManager.shared
    @EnvironmentObject private var scholarStore: ScholarContentStore

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0
    @AppStorage(SettingsKeys.reciter) private var reciterRaw = Reciter.alafasy.rawValue
    @AppStorage(SettingsKeys.translationVisible) private var translationVisible = true
    @AppStorage(SettingsKeys.transliterationVisible) private var transliterationVisible = true
    @ScaledMetric(relativeTo: .title2) private var arabicProseSize = 23

    @State private var selectedSection = GuidanceSection.quran
    @State private var draft = ""
    @State private var toast: String?
    @State private var shareImage: Image?
    @FocusState private var editorFocused: Bool
    @Namespace private var sectionNamespace

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var group: LifeGroup { GuidanceCatalog.group(containing: situation) }
    private var stage: GuidanceStage? { GuidanceCatalog.stage(containing: situation) }
    private var companion: SituationCompanionContent { CompanionContentCatalog.content(for: situation) }
    private var isBookmarked: Bool { bookmarks.contains { $0.situationID == situation.id } }
    private var entries: [JournalEntry] { allEntries.filter { $0.situationID == situation.id } }
    private var isPlaying: Bool { player.playingID == situation.id }
    private var draftTrimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var reciterName: String {
        Reciter(rawValue: reciterRaw)?.displayName ?? Reciter.alafasy.displayName
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AtmosphereBackground()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    header
                    quickActions

                    if !companion.safetyNotices.isEmpty {
                        safetyNotices
                    }

                    sourcePicker

                    selectedContent
                        .id(selectedSection)
                        .transition(.opacity.combined(with: .offset(y: 5)))

                    reflectionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 64)
            }
            .scrollDismissesKeyboard(.interactively)

            if let toast {
                Toast(message: toast)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                YaqeenMark()
                    .fill(Color.sakinaInk)
                    .frame(width: 16, height: 23)
                    .accessibilityLabel("Yaqeen")
            }
        }
        .task(id: "\(situation.id)-\(languageRaw)-\(translationVisible)") {
            renderShareCard()
        }
        .task(id: situation.id) {
            await scholarStore.loadInsights(forSituationID: situation.id)
        }
        .onDisappear { player.stopIfPlaying(id: situation.id) }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selectedSection)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 7) {
                Image(systemName: group.symbol)
                    .font(.caption.weight(.semibold))
                Text(group.title(language))
                if let stage {
                    Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(stage.title(language))
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.sakinaMuted)

            Text(situation.localizedTitle(language))
                .font(.display(34))
                .foregroundStyle(Color.sakinaInk)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 9) {
                sourceCount(
                    symbol: "book.closed",
                    count: situation.verses.count,
                    singular: copy("ayah", "آية"),
                    plural: copy("ayahs", "آيات")
                )
                sourceCount(
                    symbol: "text.book.closed",
                    count: companion.hadiths.count,
                    singular: copy("hadith", "حديث"),
                    plural: copy("hadith", "أحاديث")
                )
                sourceCount(
                    symbol: "hands.sparkles",
                    count: companion.supplications.count,
                    singular: copy("du’a", "دعاء"),
                    plural: copy("du’as", "أدعية")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private func sourceCount(
        symbol: String,
        count: Int,
        singular: String,
        plural: String
    ) -> some View {
        Label("\(count) \(count == 1 ? singular : plural)", systemImage: symbol)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.sakinaMuted)
            .lineLimit(1)
    }

    // MARK: Quick actions

    private var quickActions: some View {
        HStack(spacing: 9) {
            actionButton(
                symbol: isPlaying ? "pause.fill" : "play.fill",
                title: isPlaying ? copy("Pause", "إيقاف") : copy("Listen", "استمع"),
                isActive: isPlaying
            ) {
                player.toggle(situation: situation)
            }

            actionButton(
                symbol: isBookmarked ? "bookmark.fill" : "bookmark",
                title: isBookmarked ? copy("Saved", "محفوظ") : copy("Save", "احفظ"),
                isActive: isBookmarked
            ) {
                toggleBookmark()
            }

            actionButton(
                symbol: "pin.fill",
                title: copy("Widget", "الأداة")
            ) {
                pinToWidget()
            }

            if let shareImage {
                ShareLink(
                    item: shareImage,
                    preview: SharePreview(situation.localizedTitle(language), image: shareImage)
                ) {
                    actionLabel(symbol: "square.and.arrow.up", title: copy("Share", "شارك"))
                }
                .buttonStyle(.yaqeenPressable)
            } else {
                actionLabel(symbol: "square.and.arrow.up", title: copy("Share", "شارك"))
                    .opacity(0.45)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func actionButton(
        symbol: String,
        title: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionLabel(symbol: symbol, title: title, isActive: isActive)
        }
        .buttonStyle(.yaqeenPressable)
    }

    private func actionLabel(symbol: String, title: String, isActive: Bool = false) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isActive ? Color.sakinaCanvas : Color.sakinaInk)
        .frame(maxWidth: .infinity, minHeight: 66)
        .background(
            isActive ? Color.sakinaInk : Color.sakinaElevated,
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(isActive ? Color.clear : Color.sakinaHairline, lineWidth: 1)
        )
    }

    // MARK: Source picker

    private var sourcePicker: some View {
        HStack(spacing: 6) {
            ForEach(GuidanceSection.allCases) { section in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 1)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.symbol)
                            .font(.caption.weight(.semibold))
                        Text(section.title(language))
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedSection == section ? Color.sakinaCanvas : Color.sakinaInk)
                    .frame(maxWidth: .infinity, minHeight: 43)
                    .background {
                        if selectedSection == section {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.sakinaInk)
                                .matchedGeometryEffect(id: "source-selection", in: sectionNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedSection == section ? .isSelected : [])
            }
        }
        .padding(5)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedSection {
        case .quran:
            quranSection
        case .hadith:
            hadithSection
        case .dua:
            supplicationSection
        }
    }

    // MARK: Qur'an

    private var quranSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionIntroduction(
                title: copy("Read the Qur’an", "اقرأ القرآن"),
                detail: copy(
                    "Begin with Allah’s words, then open the source to study each ayah in context.",
                    "ابدأ بكلام الله، ثم افتح المصدر لدراسة كل آية في سياقها."
                ),
                symbol: "book.closed.fill"
            )

            ForEach(situation.verses) { verse in
                VStack(spacing: 12) {
                    verseCard(verse)

                    if let insight = scholarStore.insight(
                        situationID: situation.id,
                        verseKey: verse.key
                    ) {
                        ScholarInsightCard(
                            insight: insight,
                            profile: scholarStore.profile,
                            language: language,
                            store: scholarStore
                        )
                    }
                }
            }

            scholarInsightStatus

            contextCard

            Text(copy("Recitation by \(reciterName)", "تلاوة \(reciterName)"))
                .font(.caption2)
                .foregroundStyle(Color.sakinaMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private var scholarInsightStatus: some View {
        switch scholarStore.state(for: situation.id) {
        case .loading where situation.verses.allSatisfy({ verse in
            scholarStore.insight(situationID: situation.id, verseKey: verse.key) == nil
        }):
            HStack(spacing: 9) {
                ProgressView()
                    .controlSize(.small)
                Text(copy("Checking for published scholarly insights…", "جارٍ التحقق من الإضاءات الشرعية المنشورة…"))
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .combine)

        case .offline where situation.verses.contains(where: { verse in
            scholarStore.insight(situationID: situation.id, verseKey: verse.key) != nil
        }):
            Label(
                copy("Showing saved scholarly insight", "تُعرض إضاءة شرعية محفوظة"),
                systemImage: "wifi.slash"
            )
            .font(.caption2)
            .foregroundStyle(Color.sakinaMuted)
            .frame(maxWidth: .infinity, alignment: .center)

        case .failed:
            Button {
                Task { await scholarStore.loadInsights(forSituationID: situation.id, force: true) }
            } label: {
                Label(
                    copy("Couldn’t refresh scholarly insights · Try again", "تعذّر تحديث الإضاءات الشرعية · أعد المحاولة"),
                    systemImage: "arrow.clockwise"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.sakinaMuted)
            }
            .buttonStyle(.plain)

        default:
            EmptyView()
        }
    }

    private func verseCard(_ verse: Verse) -> some View {
        VStack(spacing: 22) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language == .arabic ? verse.surahNameArabic : "Surah \(verse.surahName)")
                        .font(.headline)
                        .foregroundStyle(Color.sakinaInk)
                    Text(copy("Ayah \(verse.ayah)", "الآية \(verse.ayah)"))
                        .font(.caption)
                        .foregroundStyle(Color.sakinaMuted)
                }
                Spacer()
                Text(verse.surahNameArabic)
                    .font(.arabic(18))
                    .foregroundStyle(Color.sakinaInk)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            Divider().overlay(Color.sakinaHairline)

            Text(verse.arabic)
                .font(.arabic(27 * arabicScale))
                .lineSpacing(15 * arabicScale)
                .foregroundStyle(Color.sakinaInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityLabel(verse.arabic)

            if translationVisible {
                VStack(alignment: .leading, spacing: 7) {
                    CapsLabel(
                        text: copy("Saheeh International", "المعنى بالإنجليزية — صحيح إنترناشونال"),
                        color: .sakinaMuted,
                        size: 9
                    )
                    Text(verse.translation)
                        .font(.reading(16))
                        .lineSpacing(6)
                        .foregroundStyle(Color.sakinaInk.opacity(0.94))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }

            if let url = URL(string: "https://quran.com/\(verse.surah):\(verse.ayah)/tafsirs") {
                Link(destination: url) {
                    HStack {
                        Label(copy("Read tafsir & full context", "اقرأ التفسير والسياق الكامل"), systemImage: "text.book.closed")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(Color.sakinaInk)
                    .padding(.top, 2)
                }
                .buttonStyle(.yaqeenPressable)
            }
        }
        .padding(21)
        .sakinaCard(tint: .yaqeenForest, cornerRadius: 25)
    }

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(copy("Why this reading", "لماذا هذه القراءة؟"), systemImage: "scope")
                .font(.headline)
                .foregroundStyle(Color.sakinaInk)

            Text(situation.localizedWhyNote(language))
                .font(.reading(15))
                .lineSpacing(6)
                .foregroundStyle(Color.sakinaInk.opacity(0.94))
                .fixedSize(horizontal: false, vertical: true)

            Text(copy(
                "A short orientation—not a fatwa or tafsir. Use the source links above for deeper study.",
                "إضاءة موجزة وليست فتوى أو تفسيرًا. استخدم روابط المصادر أعلاه للدراسة المتعمقة."
            ))
            .font(.caption)
            .foregroundStyle(Color.sakinaMuted)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(19)
        .sakinaCard(cornerRadius: 21)
    }

    // MARK: Hadith

    private var hadithSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionIntroduction(
                title: copy("Prophetic guidance", "الهدي النبوي"),
                detail: copy(
                    "Every narration includes its collection, number, grading, and how directly it applies.",
                    "يظهر مع كل حديث مصدره ورقمه ودرجته ومدى صلته بالموقف."
                ),
                symbol: "text.book.closed.fill"
            )

            ForEach(companion.hadiths) { hadith in
                hadithCard(hadith)
            }
        }
    }

    private func hadithCard(_ hadith: GuidanceHadith) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(hadith.title(language))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.sakinaInk)
                    applicabilityBadge(hadith.applicability)
                }
                Spacer(minLength: 8)
                if hadith.source.textForm == .excerpt {
                    textFormBadge
                }
            }

            Text(hadith.arabic)
                .font(.system(size: arabicProseSize * arabicScale, weight: .regular))
                .lineSpacing(13 * arabicScale)
                .foregroundStyle(Color.sakinaInk)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

            if translationVisible {
                Text(hadith.english)
                    .font(.reading(16))
                    .lineSpacing(6)
                    .foregroundStyle(Color.sakinaInk.opacity(0.94))
                    .environment(\.layoutDirection, .leftToRight)
            }

            contextBlock(hadith.context(language))

            if let caution = hadith.caution(language) {
                cautionBlock(caution)
            }

            sourceFooter(hadith.source)
        }
        .padding(20)
        .sakinaCard(tint: .yaqeenForest, cornerRadius: 24)
    }

    // MARK: Supplication

    private var supplicationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionIntroduction(
                title: copy("Make du’a", "ادعُ الله"),
                detail: copy(
                    "Use a Qur’anic or Prophetic supplication, with its source kept beside it.",
                    "ادعُ بدعاء قرآني أو نبوي مع إبقاء مصدره ظاهرًا بجانبه."
                ),
                symbol: "hands.sparkles.fill"
            )

            ForEach(companion.supplications) { supplication in
                supplicationCard(supplication)
            }
        }
    }

    private func supplicationCard(_ supplication: GuidanceSupplication) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(supplication.title(language))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.sakinaInk)
                    applicabilityBadge(supplication.applicability)
                }
                Spacer(minLength: 8)
                if supplication.source.textForm == .excerpt {
                    textFormBadge
                }
            }

            Text(supplication.arabic)
                .font(
                    supplication.kind == .quranic
                        ? .arabic(25 * arabicScale)
                        : .system(size: arabicProseSize * arabicScale, weight: .regular)
                )
                .lineSpacing(14 * arabicScale)
                .foregroundStyle(Color.sakinaInk)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

            if transliterationVisible && !supplication.transliteration.isEmpty {
                Text(supplication.transliteration)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .italic()
                    .foregroundStyle(Color.sakinaMuted)
                    .environment(\.layoutDirection, .leftToRight)
            }

            if language == .arabic || translationVisible {
                VStack(alignment: .leading, spacing: 6) {
                    CapsLabel(text: copy("Meaning", "المعنى"), size: 9)
                    Text(supplication.meaning(language))
                        .font(.reading(16))
                        .lineSpacing(6)
                        .foregroundStyle(Color.sakinaInk.opacity(0.94))
                }
            }

            contextBlock(supplication.context(language))

            if let caution = supplication.caution(language) {
                cautionBlock(caution)
            }

            sourceFooter(supplication.source)
        }
        .padding(20)
        .sakinaCard(tint: .yaqeenForest, cornerRadius: 24)
    }

    // MARK: Source trust components

    private func sectionIntroduction(title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.sakinaCanvas)
                .frame(width: 38, height: 38)
                .background(Color.sakinaInk, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.sakinaInk)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.sakinaMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func applicabilityBadge(_ metadata: GuidanceApplicabilityMetadata) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(metadata.level == .direct ? Color.sakinaInk : Color.sakinaMuted)
                .frame(width: 5, height: 5)
            Text(metadata.level.title(language))
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Color.sakinaMuted)
        .accessibilityLabel("\(metadata.level.title(language)). \(metadata.explanation(language))")
    }

    private var textFormBadge: some View {
        Text(copy("Excerpt", "مقتطف"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.sakinaMuted)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.sakinaInk.opacity(0.06), in: Capsule())
    }

    private func contextBlock(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.sakinaMuted)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .lineSpacing(4)
                .foregroundStyle(Color.sakinaMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func cautionBlock(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red.opacity(0.82))
                .padding(.top, 2)
            Text(text)
                .font(.subheadline.weight(.medium))
                .lineSpacing(4)
                .foregroundStyle(Color.sakinaInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .background(Color.red.opacity(0.055), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func sourceFooter(_ source: GuidanceSourceMetadata) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().overlay(Color.sakinaHairline)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(source.collection(language)) · \(source.number)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.sakinaInk)
                    Text(source.grade(language))
                        .font(.caption2)
                        .foregroundStyle(Color.sakinaMuted)
                }

                Spacer()

                if let url = URL(string: source.canonicalURL) {
                    Link(destination: url) {
                        HStack(spacing: 5) {
                            Text(copy("Source", "المصدر"))
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.sakinaInk)
                    }
                    .buttonStyle(.yaqeenPressable)
                }
            }
        }
    }

    private var safetyNotices: some View {
        VStack(spacing: 10) {
            ForEach(companion.safetyNotices) { notice in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: notice.kind.symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.red.opacity(0.82))
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.07), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notice.title(language))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sakinaInk)
                        Text(notice.message(language))
                            .font(.caption)
                            .lineSpacing(3)
                            .foregroundStyle(Color.sakinaMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.045), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.red.opacity(0.14), lineWidth: 1)
        )
    }

    // MARK: Reflection

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionEyebrow(
                title: copy("Your reflection", "تأملك"),
                detail: copy("Private by default", "خاص افتراضيًا")
            )

            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    if draft.isEmpty {
                        Text(copy(
                            "Write what you want to remember, ask, or act on.",
                            "اكتب ما تريد تذكره أو الدعاء به أو العمل عليه."
                        ))
                        .font(.body)
                        .foregroundStyle(Color.sakinaMuted)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                    }

                    TextEditor(text: $draft)
                        .font(.body)
                        .foregroundStyle(Color.sakinaInk)
                        .frame(minHeight: 108)
                        .scrollContentBackground(.hidden)
                        .focused($editorFocused)
                }

                HStack(spacing: 9) {
                    Image(systemName: account.isSignedIn ? "checkmark.icloud" : "iphone")
                    Text(account.isSignedIn
                         ? copy("Backed up after saving", "تُنسخ احتياطيًا بعد الحفظ")
                         : copy("Saved on this iPhone", "تُحفظ على هذا الهاتف"))
                    Spacer()
                    Button {
                        saveEntry()
                    } label: {
                        Text(copy("Save reflection", "حفظ التأمل"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(draftTrimmed.isEmpty ? Color.sakinaMuted : Color.sakinaCanvas)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 39)
                            .background(
                                draftTrimmed.isEmpty ? Color.sakinaMuted.opacity(0.12) : Color.sakinaInk,
                                in: Capsule()
                            )
                    }
                    .disabled(draftTrimmed.isEmpty)
                    .buttonStyle(.yaqeenPressable)
                }
                .font(.caption2)
                .foregroundStyle(Color.sakinaMuted)
            }
            .padding(17)
            .sakinaCard(cornerRadius: 21)

            ForEach(entries) { entry in
                entryCard(entry)
            }
        }
        .padding(.top, 6)
    }

    private func entryCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.sakinaMuted)
                Spacer()
                Button {
                    deleteEntry(entry)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.sakinaMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.yaqeenPressable)
                .accessibilityLabel(copy("Delete reflection", "حذف التأمل"))
            }

            Text(entry.text)
                .font(.body)
                .lineSpacing(5)
                .foregroundStyle(Color.sakinaInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(17)
        .sakinaCard(cornerRadius: 19)
    }

    // MARK: Mutations

    private func toggleBookmark() {
        let message: String
        if let existing = bookmarks.first(where: { $0.situationID == situation.id }) {
            context.delete(existing)
            message = copy("Removed from Saved", "أُزيل من المحفوظات")
        } else {
            context.insert(Bookmark(situationID: situation.id))
            message = copy("Saved for later", "حُفظ للرجوع إليه")
        }
        try? context.save()
        backUpIfConnected()
        showToast(message)
    }

    private func pinToWidget() {
        SharedStore.pinnedSituationID = situation.id
        WidgetCenter.shared.reloadAllTimelines()
        showToast(copy("Your widgets now follow this reading", "ستعرض أدواتك هذه القراءة الآن"))
    }

    private func saveEntry() {
        guard !draftTrimmed.isEmpty else { return }
        context.insert(JournalEntry(situationID: situation.id, text: draftTrimmed))
        try? context.save()
        draft = ""
        editorFocused = false
        backUpIfConnected()
        showToast(copy("Reflection saved", "حُفظ التأمل"))
    }

    private func deleteEntry(_ entry: JournalEntry) {
        context.delete(entry)
        try? context.save()
        backUpIfConnected()
        showToast(copy("Reflection deleted", "حُذف التأمل"))
    }

    private func backUpIfConnected() {
        guard account.isSignedIn, let backup = YaqeenBackup.snapshot(from: context) else { return }
        Task { _ = await account.upload(backup) }
    }

    private func showToast(_ message: String) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 1)) {
            toast = message
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                if toast == message { toast = nil }
            }
        }
    }

    // MARK: Share card

    @MainActor
    private func renderShareCard() {
        let renderer = ImageRenderer(
            content: VerseShareCard(
                situation: situation,
                language: language,
                showTranslation: translationVisible
            )
        )
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Reader sections

private enum GuidanceSection: String, CaseIterable, Identifiable {
    case quran
    case hadith
    case dua

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .quran: return "book.closed"
        case .hadith: return "text.book.closed"
        case .dua: return "hands.sparkles"
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .quran: return language.pick("Qur’an", "القرآن")
        case .hadith: return language.pick("Hadith", "الحديث")
        case .dua: return language.pick("Du’a", "الدعاء")
        }
    }
}

private extension GuidanceApplicabilityLevel {
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .direct:
            return language.pick("Direct guidance", "هدي مباشر")
        case .supportingPrinciple:
            return language.pick("Supporting principle", "مبدأ مساند")
        case .generalRemembrance:
            return language.pick("General remembrance", "ذكر عام")
        }
    }
}

private extension GuidanceSafetyNoticeKind {
    var symbol: String {
        switch self {
        case .immediateSafety: return "shield.lefthalf.filled.badge.checkmark"
        case .specialistSupport: return "cross.case.fill"
        case .legalAndScholarly: return "person.2.badge.gearshape.fill"
        }
    }
}

// MARK: - Share card

/// A fixed light rendition designed for sharing without exposing user data.
struct VerseShareCard: View {
    let situation: Situation
    let language: AppLanguage
    let showTranslation: Bool

    private let forest = Color(red: 0.09, green: 0.25, blue: 0.22)
    private let ivory = Color(red: 0.98, green: 0.965, blue: 0.925)

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                YaqeenMark()
                    .fill(forest)
                    .frame(width: 27, height: 39)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Yaqeen  يقين")
                        .font(.system(size: 18, weight: .bold))
                    Text("CERTAINTY IN EVERY STEP")
                        .font(.system(size: 7, weight: .semibold))
                        .tracking(1.4)
                }
                .foregroundStyle(forest)
                Spacer()
            }

            Rectangle()
                .fill(forest.opacity(0.15))
                .frame(height: 1)

            ForEach(situation.verses) { verse in
                VStack(spacing: 15) {
                    Text(verse.arabic)
                        .font(.custom("KFGQPC HAFS Uthmanic Script", size: 25))
                        .lineSpacing(13)
                        .foregroundStyle(forest)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .environment(\.layoutDirection, .rightToLeft)

                    if showTranslation {
                        Text(verse.translation)
                            .font(.system(size: 13.5, weight: .regular, design: .serif))
                            .lineSpacing(5)
                            .foregroundStyle(forest.opacity(0.84))
                            .multilineTextAlignment(.center)
                    }

                    Text(language == .arabic
                         ? "\(verse.surahNameArabic) · الآية \(verse.ayah)"
                         : "\(verse.surahName) · Ayah \(verse.ayah)")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(forest.opacity(0.64))
                }
            }

            Text(situation.localizedTitle(language))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(forest)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(34)
        .frame(width: 430)
        .background(ivory)
    }
}
