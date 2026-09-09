import Foundation

/// Editorial discovery categories, not claims that a text was prescribed for a mood.
/// Every entry resolves to the existing reviewed Arabic and source metadata.
enum DuaMood: String, CaseIterable, Identifiable, Hashable {
    case angry, anxious, urgeToSin, confident, confused, content, depressed, doubtful, grateful, greedy, guilty, happy, hurt, indecisive, hypocritical, jealous, lazy, lonely, lost, nervous, overwhelmed, regret, sad, scared, suicidal, tired, unloved, weak, bored, impatient, hopeful, grieving, seekingForgiveness
    var id: String { rawValue }
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .angry: return language.pick("Angry", "غاضب")
        case .anxious: return language.pick("Anxious", "قلق")
        case .urgeToSin: return language.pick("Urge to sin", "رغبة في المعصية")
        case .confident: return language.pick("Confident", "واثق")
        case .confused: return language.pick("Confused", "حائر")
        case .content: return language.pick("Content", "راضٍ")
        case .depressed: return language.pick("Depressed", "مكتئب")
        case .doubtful: return language.pick("Doubtful", "تساورني الشكوك")
        case .grateful: return language.pick("Grateful", "ممتن")
        case .greedy: return language.pick("Greedy", "طامع")
        case .guilty: return language.pick("Guilty", "مذنب")
        case .happy: return language.pick("Happy", "سعيد")
        case .hurt: return language.pick("Hurt", "مجروح")
        case .indecisive: return language.pick("Indecisive", "متردد")
        case .hypocritical: return language.pick("Hypocritical", "أخشى النفاق")
        case .jealous: return language.pick("Jealous", "حسود")
        case .lazy: return language.pick("Lazy", "كسول")
        case .lonely: return language.pick("Lonely", "وحيد")
        case .lost: return language.pick("Lost", "تائه")
        case .nervous: return language.pick("Nervous", "متوتر")
        case .overwhelmed: return language.pick("Overwhelmed", "مثقل")
        case .regret: return language.pick("Regret", "نادم")
        case .sad: return language.pick("Sad", "حزين")
        case .scared: return language.pick("Scared", "خائف")
        case .suicidal: return language.pick("Suicidal", "أفكار انتحارية")
        case .tired: return language.pick("Tired", "متعب")
        case .unloved: return language.pick("Unloved", "أشعر أنني غير محبوب")
        case .weak: return language.pick("Weak", "ضعيف")
        case .bored: return language.pick("Bored", "أشعر بالملل")
        case .impatient: return language.pick("Impatient", "قليل الصبر")
        case .hopeful: return language.pick("Hopeful", "متفائل")
        case .grieving: return language.pick("Grieving", "مفجوع")
        case .seekingForgiveness: return language.pick("Returning", "تائب")
        }
    }
    var family: FeelingFamily {
        switch self {
        case .sad, .hurt, .depressed, .grieving, .lonely, .unloved, .suicidal: return .heavy
        case .anxious, .nervous, .overwhelmed, .scared, .angry, .impatient: return .restless
        case .confused, .doubtful, .indecisive, .lost: return .direction
        case .urgeToSin, .guilty, .regret, .hypocritical, .jealous, .greedy, .seekingForgiveness: return .returning
        case .grateful, .content, .happy, .confident, .hopeful: return .peace
        case .tired, .weak, .lazy, .bored: return .energy
        }
    }
    var supplicationIDs: [String] {
        if let ids = DuaLibrary.moods[rawValue], !ids.isEmpty { return ids }
        return legacySupplicationIDs
    }
    private var legacySupplicationIDs: [String] {
        switch self {
        case .angry: return ["prophetic-anger-refuge", "quran-guidance", "quran-steadfast-hearts"]
        case .anxious: return ["prophetic-anxiety-and-debt", "quran-steadfast-hearts", "quran-distress-yunus"]
        case .urgeToSin: return ["quran-repentance-adam", "prophetic-master-repentance", "quran-distress-yunus"]
        case .confident: return ["quran-gratitude-and-good-deeds", "prophetic-help-to-worship", "quran-family-comfort"]
        case .confused: return ["quran-guidance", "quran-steadfast-hearts", "quran-need-any-good"]
        case .content: return ["quran-gratitude-and-good-deeds", "prophetic-help-to-worship", "quran-family-comfort"]
        case .depressed: return ["quran-need-any-good", "quran-burdens-and-mercy", "quran-guidance"]
        case .doubtful: return ["quran-guidance", "quran-steadfast-hearts", "quran-need-any-good"]
        case .grateful: return ["quran-gratitude-and-good-deeds", "prophetic-help-to-worship", "quran-family-comfort"]
        case .greedy: return ["quran-repentance-adam", "prophetic-master-repentance", "quran-distress-yunus"]
        case .guilty: return ["quran-repentance-adam", "prophetic-master-repentance", "quran-distress-yunus"]
        case .happy: return ["quran-gratitude-and-good-deeds", "prophetic-help-to-worship", "quran-family-comfort"]
        case .hurt: return ["quran-need-any-good", "quran-burdens-and-mercy", "quran-guidance"]
        case .indecisive: return ["prophetic-istikhara", "quran-guidance", "quran-steadfast-hearts"]
        case .hypocritical: return ["quran-repentance-adam", "prophetic-master-repentance", "quran-distress-yunus"]
        case .jealous: return ["quran-repentance-adam", "prophetic-master-repentance", "quran-distress-yunus"]
        case .lazy: return ["prophetic-help-to-worship", "prophetic-anxiety-and-debt", "quran-need-any-good"]
        case .lonely: return ["quran-need-any-good", "quran-steadfast-hearts", "quran-guidance"]
        case .lost: return ["quran-guidance", "quran-steadfast-hearts", "quran-need-any-good"]
        case .nervous: return ["prophetic-anxiety-and-debt", "quran-steadfast-hearts", "quran-distress-yunus"]
        case .overwhelmed: return ["quran-burdens-and-mercy", "prophetic-anxiety-and-debt", "quran-distress-yunus"]
        case .regret: return ["quran-repentance-adam", "prophetic-master-repentance", "quran-distress-yunus"]
        case .sad: return ["quran-need-any-good", "quran-burdens-and-mercy", "quran-guidance"]
        case .scared: return ["prophetic-anxiety-and-debt", "quran-steadfast-hearts", "quran-distress-yunus"]
        case .suicidal: return ["quran-need-any-good", "quran-burdens-and-mercy", "quran-guidance"]
        case .tired: return ["prophetic-help-to-worship", "prophetic-anxiety-and-debt", "quran-need-any-good"]
        case .unloved: return ["quran-need-any-good", "quran-burdens-and-mercy", "quran-guidance"]
        case .weak: return ["prophetic-help-to-worship", "prophetic-anxiety-and-debt", "quran-need-any-good"]
        case .bored: return ["prophetic-help-to-worship", "prophetic-anxiety-and-debt", "quran-need-any-good"]
        case .impatient: return ["prophetic-anxiety-and-debt", "quran-steadfast-hearts", "quran-distress-yunus"]
        case .hopeful: return ["quran-need-any-good", "quran-guidance", "quran-righteous-offspring"]
        case .grieving: return ["prophetic-calamity", "quran-burdens-and-mercy", "quran-need-any-good"]
        case .seekingForgiveness: return ["quran-repentance-adam", "prophetic-master-repentance", "quran-distress-yunus"]
        }
    }
    var searchWords: [String] {
        switch self {
        case .angry: return ["angry", "غاضب", "anger"]
        case .anxious: return ["anxious", "قلق", "anxiety", "worried"]
        case .urgeToSin: return ["urge to sin", "رغبة في المعصية", "temptation", "sin", "urge"]
        case .confident: return ["confident", "واثق", "confidence"]
        case .confused: return ["confused", "حائر", "confusion"]
        case .content: return ["content", "راضٍ", "contentment", "satisfied"]
        case .depressed: return ["depressed", "مكتئب", "depression"]
        case .doubtful: return ["doubtful", "تساورني الشكوك", "doubt", "uncertainty"]
        case .grateful: return ["grateful", "ممتن", "gratitude", "thankful"]
        case .greedy: return ["greedy", "طامع", "greed"]
        case .guilty: return ["guilty", "مذنب", "guilt"]
        case .happy: return ["happy", "سعيد", "happiness", "joy"]
        case .hurt: return ["hurt", "مجروح", "pain", "hurting"]
        case .indecisive: return ["indecisive", "متردد", "decision", "choices", "istikhara"]
        case .hypocritical: return ["hypocritical", "أخشى النفاق", "hypocrisy", "hypocritical", "sincerity"]
        case .jealous: return ["jealous", "حسود", "jealousy", "envy"]
        case .lazy: return ["lazy", "كسول", "laziness"]
        case .lonely: return ["lonely", "وحيد", "loneliness", "alone"]
        case .lost: return ["lost", "تائه", "direction"]
        case .nervous: return ["nervous", "متوتر", "nerves"]
        case .overwhelmed: return ["overwhelmed", "مثقل", "overwhelming", "burden", "stressed"]
        case .regret: return ["regret", "نادم", "regret", "remorse"]
        case .sad: return ["sad", "حزين", "sadness"]
        case .scared: return ["scared", "خائف", "fear", "afraid"]
        case .suicidal: return ["suicidal", "أفكار انتحارية", "suicide", "suicidal", "self", "harm"]
        case .tired: return ["tired", "متعب", "fatigue", "exhaustion"]
        case .unloved: return ["unloved", "أشعر أنني غير محبوب", "unloved", "rejected"]
        case .weak: return ["weak", "ضعيف", "weakness"]
        case .bored: return ["bored", "أشعر بالملل", "boredom"]
        case .impatient: return ["impatient", "قليل الصبر", "impatience"]
        case .hopeful: return ["hopeful", "متفائل", "hope", "optimistic"]
        case .grieving: return ["grieving", "مفجوع", "grief", "loss"]
        case .seekingForgiveness: return ["returning", "تائب", "forgiveness", "repentance"]
        }
    }
}

enum FeelingFamily: String, CaseIterable, Identifiable {
    case heavy, restless, direction, returning, peace, energy
    var id: String { rawValue }
    var moods: [DuaMood] { DuaMood.allCases.filter { $0.family == self } }
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .heavy: return language.pick("A heavy heart", "قلب مثقل")
        case .restless: return language.pick("A restless mind", "ذهن مشغول")
        case .direction: return language.pick("Finding my way", "أبحث عن طريقي")
        case .returning: return language.pick("Coming back", "أعود إلى الله")
        case .peace: return language.pick("In a good place", "بخير وطمأنينة")
        case .energy: return language.pick("Running on empty", "أحتاج إلى قوة")
        }
    }
    func subtitle(_ language: AppLanguage) -> String {
        moods.prefix(2).map { $0.title(language) }.joined(separator: language == .arabic ? "، " : " · ")
    }
}

enum DuaCollection {
    static let allEntries = CompanionContentCatalog.supplications + DailyDuaCatalog.entries + DuaLibrary.entries
    private static let byID = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.id, $0) })
    static let savedKey = "yaqeen.savedDuaIDs"
    static let lastReadKey = "yaqeen.lastReadDuaID"

    static func dua(_ id: String) -> GuidanceSupplication? { byID[id] }

    static func entries(mood: DuaMood? = nil, query: String = "", savedOnly: Bool = false, savedIDs: [String] = []) -> [GuidanceSupplication] {
        let values = mood.map { $0.supplicationIDs.compactMap(dua) } ?? allEntries
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let moodMatches = Set(DuaMood.allCases.filter { mood in
            mood.searchWords.contains { $0.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
        }.flatMap(\.supplicationIDs))
        return values.filter { entry in
            (!savedOnly || savedIDs.contains(entry.id)) && (trimmed.isEmpty ||
                moodMatches.contains(entry.id) ||
                [entry.titleEnglish, entry.titleArabic, entry.arabic, entry.meaningEnglish,
                 entry.meaningArabic, entry.transliteration, entry.source.number, entry.source.collectionEnglish,
                 entry.source.collectionArabic].contains { $0.localizedStandardContains(trimmed) })
        }
    }

    static func savedIDs(_ raw: String) -> [String] {
        var seen = Set<String>()
        return raw.split(separator: "|").map(String.init).filter { dua($0) != nil && seen.insert($0).inserted }
    }

    static func toggling(_ id: String, in raw: String) -> String {
        var ids = savedIDs(raw)
        if ids.contains(id) { ids.removeAll { $0 == id } }
        else if dua(id) != nil { ids.insert(id, at: 0) }
        return ids.joined(separator: "|")
    }

    static func sourceLabel(_ entry: GuidanceSupplication, language: AppLanguage) -> String {
        "\(entry.source.collection(language)) · \(entry.source.number)"
    }
}
