import SwiftUI

/// One du’a per page: Arabic, pronunciation and meaning together on one
/// card. Swipe or tap for the next. Repetition is a first-class control.
struct DuaReaderView: View {
    private let sequence: [GuidanceSupplication]
    private let collectionTitle: String?
    private let practice: DuaPractice?
    private let mood: DuaMood?

    @State private var index: Int
    @State private var count = 0
    @State private var completed = false
    @State private var showSource = false
    @State private var advanceTask: Task<Void, Never>?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0
    @AppStorage(SettingsKeys.translationVisible) private var translationVisible = true
    @AppStorage(SettingsKeys.transliterationVisible) private var transliterationVisible = true
    @AppStorage(DuaCollection.savedKey) private var savedRaw = ""
    @AppStorage(DuaCollection.lastReadKey) private var lastReadID = ""
    @AppStorage(ReadingPlace.key) private var placesRaw = ""
    @AppStorage(PracticeLog.key) private var practiceLogRaw = ""
    @AppStorage(HeartLog.key) private var heartLogRaw = ""
    @ScaledMetric(relativeTo: .title) private var proseSize = 28.0

    init(dua: GuidanceSupplication, sequence: [GuidanceSupplication] = [], collectionTitle: String? = nil,
         practice: DuaPractice? = nil, mood: DuaMood? = nil) {
        let entries = sequence.isEmpty ? [dua] : sequence
        self.sequence = entries
        self.collectionTitle = collectionTitle
        self.practice = practice
        self.mood = mood
        let saved = practice.flatMap { ReadingPlace.entry(for: $0, in: UserDefaults.standard.string(forKey: ReadingPlace.key) ?? "") }
        _index = State(initialValue: entries.firstIndex { $0.id == (saved ?? dua.id) } ?? 0)
    }

    private var dua: GuidanceSupplication { sequence[index] }
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var isSaved: Bool { DuaCollection.savedIDs(savedRaw).contains(dua.id) }
    private var target: Int { max(1, dua.repeatCount ?? 1) }
    private var isLast: Bool { index >= sequence.count - 1 }
    private var sharedText: String {
        [dua.title(language), dua.arabic, dua.meaning(language), DuaCollection.sourceLabel(dua, language: language),
         dua.source.canonicalURL].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            if completed {
                completion.transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                reader
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { if !completed { controls } }
        .toolbarRole(.editor)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !completed {
                ToolbarItem(placement: .principal) {
                    if let collectionTitle {
                        Text(collectionTitle)
                            .font(.yqSubheadBold)
                            .foregroundStyle(Color.yqInk)
                            .lineLimit(1)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Toggle(copy("Meaning", "المعنى"), isOn: $translationVisible)
                        Toggle(copy("Pronunciation", "النطق"), isOn: $transliterationVisible)
                        Section(copy("Arabic size", "حجم العربية")) {
                            Button(copy("Smaller", "أصغر")) { arabicScale = max(0.8, arabicScale - 0.1) }
                            Button(copy("Larger", "أكبر")) { arabicScale = min(1.6, arabicScale + 0.1) }
                        }
                        ShareLink(item: sharedText) { Label(copy("Share", "مشاركة"), systemImage: "square.and.arrow.up") }
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                    .accessibilityLabel(copy("Reading options", "خيارات القراءة"))
                    Button {
                        savedRaw = DuaCollection.toggling(dua.id, in: savedRaw)
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(isSaved ? copy("Remove saved du’a", "إلغاء حفظ الدعاء") : copy("Save du’a", "حفظ الدعاء"))
                }
            }
        }
        .sheet(isPresented: $showSource) { sourceSheet }
        .sensoryFeedback(.impact(weight: .light), trigger: count)
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.success, trigger: completed)
        .sensoryFeedback(.selection, trigger: isSaved)
        .onAppear {
            rememberPlace()
            if let mood { heartLogRaw = HeartLog.recording(mood, in: heartLogRaw) }
        }
        .onChange(of: index) { _, _ in
            advanceTask?.cancel()
            count = 0
            rememberPlace()
        }
        .onDisappear { advanceTask?.cancel() }
    }

    // MARK: Reader

    private var reader: some View {
        VStack(spacing: 0) {
            progressHeader
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 8)
            TabView(selection: $index) {
                ForEach(Array(sequence.enumerated()), id: \.element.id) { position, entry in
                    ScrollView(showsIndicators: false) {
                        page(entry, position: position)
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 24)
                    }
                    .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            if sequence.count > 1 {
                HStack(spacing: 3) {
                    ForEach(0..<min(sequence.count, 40), id: \.self) { position in
                        Capsule()
                            .fill(position <= index ? Color.yqAccent : Color.yqHairline)
                            .frame(height: 4)
                    }
                }
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9), value: index)
                .accessibilityHidden(true)
                HStack {
                    if let timing = dua.timing(language) {
                        Text(timing).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    }
                    Spacer()
                    Menu {
                        ForEach(Array(sequence.enumerated()), id: \.element.id) { position, entry in
                            Button("\(position + 1). \(entry.title(language))") { index = position }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(copy("\(index + 1) of \(sequence.count)", "\(index + 1) من \(sequence.count)"))
                                .font(.system(.caption, weight: .semibold).monospacedDigit())
                            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Color.yqSecondary)
                        .frame(minHeight: 28)
                    }
                    .accessibilityLabel(copy("Choose a reading", "اختر قراءة"))
                }
            }
        }
    }

    private func page(_ entry: GuidanceSupplication, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let mood, position == 0 {
                HStack(alignment: .top, spacing: 10) {
                    CompanionIllustration(artwork: mood.artwork, size: 42)
                    Text(mood.opening(language))
                        .font(.yqSubheadMedium)
                        .foregroundStyle(Color.yqSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 2)
            }
            if let mood, mood.family == .heavy, position == 0, mood != .suicidal {
                anchorRow
            }
            HStack(spacing: 6) {
                if let count = entry.repeatCount, count > 1 {
                    Tag(text: "\(count)×", tint: .yqAccentDeep)
                }
                if entry.source.textForm == .excerpt {
                    Tag(text: copy("Excerpt", "مقتطف"), tint: BadgeTint.slate.color)
                }
                Tag(text: entry.source.collection(language), tint: BadgeTint.slate.color)
            }
            Text(entry.title(language))
                .font(.yqTitle2)
                .tracking(-0.3)
                .foregroundStyle(Color.yqInk)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 18) {
                Text(entry.arabic)
                    .font(entry.kind == .quranic ? .arabic(30 * arabicScale) : .arabicProse(proseSize * arabicScale))
                    .lineSpacing(entry.kind == .quranic ? 16 * arabicScale : 12 * arabicScale)
                    .foregroundStyle(Color.yqInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .environment(\.layoutDirection, .rightToLeft)
                    .textSelection(.enabled)
                if transliterationVisible, !entry.transliteration.isEmpty {
                    Text(entry.transliteration)
                        .font(.yqSubhead)
                        .italic()
                        .lineSpacing(4)
                        .foregroundStyle(Color.yqSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.layoutDirection, .leftToRight)
                        .textSelection(.enabled)
                }
                if translationVisible || language == .arabic {
                    Text(entry.meaning(language))
                        .font(.yqBody)
                        .lineSpacing(6)
                        .foregroundStyle(Color.yqInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
            .padding(20)
            .yqCard(cornerRadius: 22)

            Button { showSource = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.yqAccentDeep)
                    Text(DuaCollection.sourceLabel(entry, language: language))
                        .font(.yqSubheadMedium)
                        .foregroundStyle(Color.yqInk)
                    Spacer()
                    Text(copy("Context", "السياق")).font(.yqSubheadBold).foregroundStyle(Color.yqAccentDeep)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .yqCard(cornerRadius: 14)
            }
            .buttonStyle(.yqPressSoft)

            if let caution = entry.caution(language) {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BadgeTint.red.color)
                        .padding(.top, 2)
                    Text(caution).font(.yqSubhead).foregroundStyle(Color.yqInk).fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(BadgeTint.red.color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var anchorRow: some View {
        HStack(spacing: 10) {
            CompanionIllustration(artwork: .breathe, size: 32)
            Text(copy("Breathe first if you need to. Then read.", "تنفس أولًا إن احتجت، ثم اقرأ."))
                .font(.yqCaption).foregroundStyle(Color.yqSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .background(Color.yqFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 10) {
            if target > 1 { counter }
            HStack(spacing: 10) {
                if index > 0 {
                    Button { index -= 1 } label: {
                        CircleButton(symbol: language == .arabic ? "arrow.right" : "arrow.left", size: 54)
                    }
                    .buttonStyle(.yqPress)
                    .accessibilityLabel(copy("Previous", "السابق"))
                }
                Button(action: advance) {
                    PrimaryButton(title: isLast ? copy("Finish", "إنهاء") : copy("Next", "التالي"),
                                  symbol: isLast ? "checkmark" : (language == .arabic ? "arrow.left" : "arrow.right"))
                }
                .buttonStyle(.yqPress)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background {
            Rectangle().fill(.regularMaterial).ignoresSafeArea()
        }
    }

    private var counter: some View {
        let done = count >= target
        return Button {
            guard !done else { return }
            count += 1
            if count >= target { scheduleAdvance() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(done ? Color.yqOnAccent.opacity(0.35) : Color.yqAccent.opacity(0.18), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: Double(count) / Double(target))
                        .stroke(done ? Color.yqOnAccent : Color.yqAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: count)
                    if done {
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Color.yqOnAccent)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("\(count)")
                            .font(.system(.headline, weight: .bold).monospacedDigit())
                            .foregroundStyle(Color.yqAccentDeep)
                            .contentTransition(.numericText())
                    }
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text(done ? copy("Complete", "اكتمل") : copy("Tap as you recite", "اضغط مع كل قراءة"))
                        .font(.yqSubheadBold)
                    Text(copy("\(min(count, target)) of \(target)", "\(min(count, target)) من \(target)"))
                        .font(.system(.caption, weight: .medium).monospacedDigit())
                        .opacity(0.8)
                }
                .foregroundStyle(done ? Color.yqOnAccent : Color.yqAccentDeep)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(done ? Color.yqAccent : Color.yqAccentTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: done)
        }
        .buttonStyle(.yqPress)
        .accessibilityLabel(copy("Recitation counter, \(count) of \(target)", "عداد التكرار، \(count) من \(target)"))
    }

    private func scheduleAdvance() {
        advanceTask?.cancel()
        advanceTask = Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 750))
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    private func advance() {
        if isLast {
            if let practice {
                placesRaw = ReadingPlace.updating(practice, entryID: nil, in: placesRaw)
                practiceLogRaw = PracticeLog.marking(practice, in: practiceLogRaw)
            }
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) { completed = true }
        } else {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) { index += 1 }
        }
    }

    // MARK: Completion

    private var completion: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 20)
            CompletionRosette()
            VStack(spacing: 8) {
                Text(copy("Alhamdulillah", "الحمد لله"))
                    .font(.yqLargeTitle)
                    .tracking(-0.5)
                    .foregroundStyle(Color.yqInk)
                Text(completionLine)
                    .font(.yqBody)
                    .lineSpacing(5)
                    .foregroundStyle(Color.yqSecondary)
            }
            Spacer(minLength: 20)
            VStack(spacing: 10) {
                Button { dismiss() } label: { PrimaryButton(title: copy("Done", "تم"), symbol: "checkmark") }
                    .buttonStyle(.yqPress)
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { completed = false; index = 0 }
                    rememberPlace()
                } label: {
                    Text(copy("Read again", "اقرأ مرة أخرى")).font(.yqSubheadBold).foregroundStyle(Color.yqAccentDeep).frame(minHeight: 44)
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
    }

    private var completionLine: String {
        if let practice {
            return copy("\(practice.title(language)) done for today. Come back whenever you need.", "أنجزت \(practice.title(language)) لليوم. عُد متى شئت.")
        }
        return copy("Carry these words into your day.", "احمل هذه الكلمات معك في يومك.")
    }

    // MARK: Source sheet

    private var sourceSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(dua.title(language)).font(.yqTitle2).foregroundStyle(Color.yqInk)
                    HStack(spacing: 6) {
                        Tag(text: DuaCollection.sourceLabel(dua, language: language))
                        Tag(text: dua.source.grade(language), tint: BadgeTint.slate.color)
                    }
                    Text(dua.context(language)).font(.yqBody).lineSpacing(6).foregroundStyle(Color.yqInk)
                    if dua.applicability.explanation(language) != dua.context(language) {
                        Text(dua.applicability.explanation(language)).font(.yqSubhead).lineSpacing(5).foregroundStyle(Color.yqSecondary)
                    }
                    if dua.source.textForm == .excerpt {
                        Text(copy("This is an excerpt. The source page has the full passage or narration.", "هذا مقتطف، وتجد النص أو الرواية كاملة في المصدر."))
                            .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    }
                    if let caution = dua.caution(language) {
                        Text(caution).font(.yqSubheadMedium).foregroundStyle(Color.yqInk)
                    }
                    Link(destination: URL(string: dua.source.canonicalURL)!) {
                        PrimaryButton(title: copy("Read the original source", "اقرأ المصدر الأصلي"), symbol: "arrow.up.right")
                    }
                    .buttonStyle(.yqPress)
                    if mood != nil {
                        Text(copy("Readings under a feeling are chosen for reflection. That placement does not prescribe a special use, count or promised outcome.",
                                  "اختيرت القراءات تحت الشعور للتأمل، ولا يثبت وضعها تخصيصًا شرعيًا أو عددًا أو نتيجة موعودة."))
                            .font(.yqCaption).foregroundStyle(Color.yqTertiary)
                    }
                    if practice != nil {
                        Text(copy("Selected readings, not a complete manual. Follow each source for timing and repetition.",
                                  "قراءات مختارة وليست دليلًا شاملًا. يُرجع إلى كل مصدر لوقته وعدده."))
                            .font(.yqCaption).foregroundStyle(Color.yqTertiary)
                    }
                }
                .padding(20)
            }
            .yqScreen(pattern: .none)
            .navigationTitle(copy("Source & context", "المصدر والسياق"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(copy("Done", "تم")) { showSource = false } } }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func rememberPlace() {
        lastReadID = dua.id
        if let practice { placesRaw = ReadingPlace.updating(practice, entryID: dua.id, in: placesRaw) }
    }
}

private struct CompletionRosette: View {
    @State private var drawn = false
    var body: some View {
        RosetteProgress(progress: drawn ? 1 : 0, size: 168)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.yqAccent)
                    .opacity(drawn ? 1 : 0)
                    .scaleEffect(drawn ? 1 : 0.6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.55), value: drawn)
            }
            .onAppear { drawn = true }
    }
}

// MARK: - Persistence

enum ReadingPlace {
    static let key = "yaqeen.readingPlaces"
    private static func values(_ raw: String) -> [String: String] {
        raw.split(separator: "|").reduce(into: [:]) { result, pair in
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2, let practice = DuaPractice(rawValue: parts[0]), practice.entryIDs.contains(parts[1]) { result[parts[0]] = parts[1] }
        }
    }
    static func entry(for practice: DuaPractice, in raw: String) -> String? { values(raw)[practice.rawValue] }
    static func updating(_ practice: DuaPractice, entryID: String?, in raw: String) -> String {
        var places = values(raw)
        if let entryID, practice.entryIDs.contains(entryID) { places[practice.rawValue] = entryID }
        else { places.removeValue(forKey: practice.rawValue) }
        return places.keys.sorted().compactMap { key in places[key].map { "\(key)=\($0)" } }.joined(separator: "|")
    }
}

/// Which collections were finished today. `yyyy-MM-dd:practice` pairs.
enum PracticeLog {
    static let key = "yaqeen.practiceLog"

    private static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func isDone(_ practice: DuaPractice, on date: Date = .now, in raw: String) -> Bool {
        raw.split(separator: "|").contains("\(day(date)):\(practice.rawValue)")
    }

    static func marking(_ practice: DuaPractice, on date: Date = .now, in raw: String) -> String {
        let today = day(date)
        var kept = raw.split(separator: "|").map(String.init).filter { $0.hasPrefix(today + ":") }
        let entry = "\(today):\(practice.rawValue)"
        if !kept.contains(entry) { kept.append(entry) }
        return kept.joined(separator: "|")
    }
}
