import Foundation

private func normalizedGuidanceSearchText(_ value: String) -> String {
    let arabicMarks = CharacterSet(charactersIn:
        "\u{0610}\u{0611}\u{0612}\u{0613}\u{0614}\u{0615}\u{0616}\u{0617}\u{0618}\u{0619}\u{061A}" +
        "\u{064B}\u{064C}\u{064D}\u{064E}\u{064F}\u{0650}\u{0651}\u{0652}\u{0653}\u{0654}\u{0655}" +
        "\u{0656}\u{0657}\u{0658}\u{0659}\u{065A}\u{065B}\u{065C}\u{065D}\u{065E}\u{065F}\u{0670}\u{06D6}\u{06D7}\u{06D8}\u{06D9}\u{06DA}\u{06DB}\u{06DC}\u{06DF}\u{06E0}\u{06E1}\u{06E2}\u{06E3}\u{06E4}\u{06E7}\u{06E8}\u{06EA}\u{06EB}\u{06EC}\u{06ED}"
    )

    let foldedScalars = value
        .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
        .unicodeScalars
        .filter { !arabicMarks.contains($0) && $0.value != 0x0640 }
        .map(String.init)
        .joined()

    let normalizedArabic = foldedScalars
        .replacingOccurrences(of: "أ", with: "ا")
        .replacingOccurrences(of: "إ", with: "ا")
        .replacingOccurrences(of: "آ", with: "ا")
        .replacingOccurrences(of: "ٱ", with: "ا")
        .replacingOccurrences(of: "ى", with: "ي")

    return normalizedArabic.unicodeScalars
        .map { CharacterSet.alphanumerics.contains($0) ? String($0) : " " }
        .joined()
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
}

// MARK: - Human-centred navigation

/// The old editorial chapters remain as source metadata on each situation. This
/// catalog is the user-facing information architecture: a life group, then the
/// moment within that life, then the exact feeling or situation.
enum LifeGroupID: String, Codable, CaseIterable {
    case marriage, family, faith, wellbeing, provision
}

struct GuidanceStage: Identifiable, Hashable {
    let id: String
    let titleEnglish: String
    let titleArabic: String
    let promptEnglish: String
    let promptArabic: String
    let situationIDs: [String]

    func title(_ language: AppLanguage) -> String {
        language.pick(titleEnglish, titleArabic)
    }

    func prompt(_ language: AppLanguage) -> String {
        language.pick(promptEnglish, promptArabic)
    }

    var situations: [Situation] {
        situationIDs.compactMap(SituationCatalog.by(id:))
    }
}

struct LifeGroup: Identifiable, Hashable {
    let id: LifeGroupID
    let titleEnglish: String
    let titleArabic: String
    let subtitleEnglish: String
    let subtitleArabic: String
    let symbol: String
    let stages: [GuidanceStage]

    func title(_ language: AppLanguage) -> String {
        language.pick(titleEnglish, titleArabic)
    }

    func subtitle(_ language: AppLanguage) -> String {
        language.pick(subtitleEnglish, subtitleArabic)
    }

    var situations: [Situation] {
        var seen = Set<String>()
        return stages.flatMap(\.situations).filter { seen.insert($0.id).inserted }
    }
}

// MARK: - Emergency guidance prompts

/// Short, human-language ways into the existing reviewed guidance catalog.
///
/// These prompts intentionally point to canonical `Situation` records instead
/// of repeating an ayah under a second situation ID. That keeps the Qur'an text,
/// contextual note, Arabic reflection, companion content, and scholar-review
/// identity in one place while still meeting people in the words they use.
struct EmergencyGuidancePrompt: Identifiable, Hashable {
    let id: String
    let titleEnglish: String
    let titleArabic: String
    let situationID: String
    let searchAliasesEnglish: [String]

    init(
        id: String,
        titleEnglish: String,
        titleArabic: String,
        situationID: String,
        searchAliasesEnglish: [String] = []
    ) {
        self.id = id
        self.titleEnglish = titleEnglish
        self.titleArabic = titleArabic
        self.situationID = situationID
        self.searchAliasesEnglish = searchAliasesEnglish
    }

    func title(_ language: AppLanguage) -> String {
        language.pick(titleEnglish, titleArabic)
    }

    var situation: Situation? {
        SituationCatalog.by(id: situationID)
    }

    var searchablePhrases: [String] {
        [titleEnglish, titleArabic] + searchAliasesEnglish
    }
}

/// A deduplicated interpretation of the supplied “Qur'an emergency numbers”
/// references. Screenshot phrases that express the same need are consolidated,
/// and each prompt leads to an already reviewed situation whose ayat are present
/// in `verses.json`.
enum EmergencyGuidanceCatalog {
    static let prompts: [EmergencyGuidancePrompt] = [
        EmergencyGuidancePrompt(
            id: "overwhelmed-responsibilities",
            titleEnglish: "When deadlines and responsibilities feel overwhelming",
            titleArabic: "عندما ترهقك المواعيد والمسؤوليات",
            situationID: "tooManyBurdens",
            searchAliasesEnglish: [
                "When you're overwhelmed with deadlines",
                "When you feel like you're carrying too much alone",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "worry-will-not-settle",
            titleEnglish: "When worry or overthinking will not settle",
            titleArabic: "عندما لا يهدأ القلق أو التفكير المفرط",
            situationID: "scaredOfFuture",
            searchAliasesEnglish: [
                "When you're anxious before an exam",
                "When you're afraid of what's coming",
                "When you feel crushed by anxiety",
                "When you can't stop overthinking",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "doubting-ability",
            titleEnglish: "When you doubt your ability or feel unqualified",
            titleArabic: "عندما تشك في قدرتك أو تشعر أنك غير مؤهل",
            situationID: "feelingInsecure",
            searchAliasesEnglish: [
                "When you feel like you're not smart enough",
                "When you feel unqualified for the task ahead",
                "When you're questioning your own worth",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "comparing-progress",
            titleEnglish: "When you compare your progress with other people",
            titleArabic: "عندما تقارن تقدمك بتقدم الآخرين",
            situationID: "everyoneAhead",
            searchAliasesEnglish: [
                "When you're comparing your grades to others",
                "When you feel behind everyone else",
                "When you feel like you're falling behind in life",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "struggling-to-continue",
            titleEnglish: "When you're exhausted and struggling to keep going",
            titleArabic: "عندما ترهقك المحاولة ويصعب عليك الاستمرار",
            situationID: "movingOn",
            searchAliasesEnglish: [
                "When you're burned out from studying",
                "When you need motivation to keep going",
                "When you're tired of trying",
                "When you feel like giving up on a goal",
                "When you feel like giving up on your goals",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "lost-next-step",
            titleEnglish: "When you feel lost or do not know what to do next",
            titleArabic: "عندما تشعر بالضياع أو لا تعرف خطوتك التالية",
            situationID: "needGuidance",
            searchAliasesEnglish: [
                "When you don't know what to major in",
                "When you feel lost in life",
                "When you don't know your purpose",
                "When you're seeking guidance",
                "When you feel stuck between two decisions",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "setback-after-effort",
            titleEnglish: "When something you worked hard for does not work out",
            titleArabic: "عندما لا ينجح أمر بذلت فيه جهدًا كبيرًا",
            situationID: "disappointed",
            searchAliasesEnglish: [
                "When you fail at something you worked hard for",
                "When it feels like nothing is going right",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "effort-feels-unseen",
            titleEnglish: "When your effort feels unseen or produces no result",
            titleArabic: "عندما تشعر أن جهدك لا يُقدَّر أو لا يثمر",
            situationID: "workNoResults",
            searchAliasesEnglish: [
                "When you feel unseen for your effort",
                "When you're working hard but see no results",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "alone-or-misunderstood",
            titleEnglish: "When you feel alone, invisible, or misunderstood",
            titleArabic: "عندما تشعر بالوحدة أو بأن لا أحد يلاحظك أو يفهمك",
            situationID: "feelAlone",
            searchAliasesEnglish: [
                "When you're studying alone and it feels lonely",
                "When you feel like no one understands you",
                "When you feel invisible or unseen",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "distant-from-faith",
            titleEnglish: "When you feel distant from Allah or your faith feels low",
            titleArabic: "عندما تشعر بالبعد عن الله أو بضعف إيمانك",
            situationID: "imanLow",
            searchAliasesEnglish: [
                "When you feel disconnected from Allah",
                "When you feel far from your deen",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "repeating-mistake",
            titleEnglish: "When you keep returning to the same mistake",
            titleArabic: "عندما تعود إلى الخطأ نفسه مرارًا",
            situationID: "sameSin",
            searchAliasesEnglish: [
                "When you're stuck in the same cycle",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "fear-too-late-to-return",
            titleEnglish: "When you fear it is too late to return to Allah",
            titleArabic: "عندما تخشى أن يكون قد فات أوان العودة إلى الله",
            situationID: "madeAMistake",
            searchAliasesEnglish: [
                "When you're afraid it's too late to change",
                "When you feel like you've messed up too much",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "outcome-beyond-control",
            titleEnglish: "When the outcome is outside your control",
            titleArabic: "عندما تكون النتيجة خارج سيطرتك",
            situationID: "afraidOfFailure",
            searchAliasesEnglish: [
                "When you're stressed about results out of your control",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "fear-of-judgment",
            titleEnglish: "When you fear other people's judgment",
            titleArabic: "عندما تخشى أحكام الناس عليك",
            situationID: "afraidPeopleThink",
            searchAliasesEnglish: [
                "When you're afraid of judgment from others",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "hurt-or-wronged",
            titleEnglish: "When someone has hurt or wronged you",
            titleArabic: "عندما يؤذيك شخص أو يظلمك",
            situationID: "someoneHurtsYou"
        ),
        EmergencyGuidancePrompt(
            id: "hope-feels-far",
            titleEnglish: "When hope feels far away",
            titleArabic: "عندما يبدو الأمل بعيدًا",
            situationID: "disappointed",
            searchAliasesEnglish: [
                "When you feel hopeless",
                "When you feel like giving up",
            ]
        ),
        EmergencyGuidancePrompt(
            id: "beginning-again",
            titleEnglish: "When you need to begin again after a setback",
            titleArabic: "عندما تحتاج إلى بداية جديدة بعد انتكاسة",
            situationID: "movingOn",
            searchAliasesEnglish: [
                "When you're starting over",
            ]
        ),
    ]

    static func matching(_ query: String) -> [EmergencyGuidancePrompt] {
        let value = normalizedGuidanceSearchText(query)
        guard !value.isEmpty else { return [] }
        return prompts.filter { prompt in
            prompt.searchablePhrases.contains {
                normalizedGuidanceSearchText($0).contains(value)
            }
        }
    }
}

enum GuidanceCatalog {
    static let groups: [LifeGroup] = [
        LifeGroup(
            id: .marriage,
            titleEnglish: "Marriage",
            titleArabic: "الزواج",
            subtitleEnglish: "From seeking a spouse to building, repairing, and releasing with ihsan.",
            subtitleArabic: "من البحث عن شريك الحياة إلى بناء المودة والإصلاح والفراق بإحسان.",
            symbol: "heart.text.square",
            stages: [
                GuidanceStage(
                    id: "marriage-before",
                    titleEnglish: "Before marriage",
                    titleArabic: "قبل الزواج",
                    promptEnglish: "Where are you in the search?",
                    promptArabic: "أين أنت في رحلة البحث؟",
                    situationIDs: [
                        "beforeMarriage", "lookingForSpouse", "choosingSpouse",
                        "waitingForTiming", "worriedNeverMarry", "strugglingPatience",
                    ]
                ),
                GuidanceStage(
                    id: "marriage-together",
                    titleEnglish: "Growing together",
                    titleArabic: "الحياة معًا",
                    promptEnglish: "What does your marriage need today?",
                    promptArabic: "ما الذي تحتاج إليه علاقتكما اليوم؟",
                    situationIDs: [
                        "peaceInMarriage", "treatSpouseKindly", "becomeBetterSpouse",
                        "speakKindly", "decidingTogether", "fairnessInMarriage",
                        "rebuildingTrust", "duaForFamily", "feelingDistant",
                    ]
                ),
                GuidanceStage(
                    id: "marriage-repair",
                    titleEnglish: "Hard seasons",
                    titleArabic: "الأوقات الصعبة",
                    promptEnglish: "Name what feels difficult.",
                    promptArabic: "ما الذي يشق عليك الآن؟",
                    situationIDs: [
                        "marriageProblems", "constantlyArguing", "spouseWrongedYou",
                        "loweringAnger", "forgivingSpouse", "temptedToDivorce",
                        "marriageTested", "afraidWontLast", "questioningChoice",
                        "trustingPlan", "trustingTiming", "stayOrLeave",
                    ]
                ),
                GuidanceStage(
                    id: "marriage-after",
                    titleEnglish: "Separation & grief",
                    titleArabic: "الفراق والحزن",
                    promptEnglish: "What are you carrying after the relationship?",
                    promptArabic: "ما الذي يثقل قلبك بعد انتهاء العلاقة؟",
                    situationIDs: ["divorceUnavoidable", "afterDivorce", "grievingSpouse"]
                ),
            ]
        ),
        LifeGroup(
            id: .family,
            titleEnglish: "Family & Parenthood",
            titleArabic: "الأسرة وتربية الأبناء",
            subtitleEnglish: "Guidance for children, the home, absence, and longing.",
            subtitleArabic: "إرشاد لحياتك الأسرية وتربية أبنائك والتعامل مع الغياب والاشتياق.",
            symbol: "figure.2.and.child.holdinghands",
            stages: [
                GuidanceStage(
                    id: "family-children",
                    titleEnglish: "Children",
                    titleArabic: "الأبناء",
                    promptEnglish: "What are you hoping for as a parent?",
                    promptArabic: "ما الذي تتمناه لأبنائك وأسرتك؟",
                    situationIDs: ["raisingChildren", "prayingForChildren", "infertility"]
                ),
                GuidanceStage(
                    id: "family-home",
                    titleEnglish: "Home & absence",
                    titleArabic: "البيت والغياب",
                    promptEnglish: "What is your family carrying?",
                    promptArabic: "ما الذي يثقل على أسرتك؟",
                    situationIDs: ["spouseAway"]
                ),
            ]
        ),
        LifeGroup(
            id: .faith,
            titleEnglish: "Faith & Worship",
            titleArabic: "الإيمان والعبادة",
            subtitleEnglish: "Return to prayer, gratitude, repentance, and a steadier heart.",
            subtitleArabic: "عودة إلى الصلاة والشكر والتوبة وثبات القلب.",
            symbol: "moon.stars",
            stages: [
                GuidanceStage(
                    id: "faith-connection",
                    titleEnglish: "Connection",
                    titleArabic: "الصلة بالله",
                    promptEnglish: "Where does your heart need anchoring?",
                    promptArabic: "في أي أمر تحتاج إلى الثبات؟",
                    situationIDs: [
                        "needGuidance", "imanLow", "salahConnection", "hardToPray",
                        "losingFocus", "forgettingBlessings", "strugglingGrateful",
                    ]
                ),
                GuidanceStage(
                    id: "faith-return",
                    titleEnglish: "Returning",
                    titleArabic: "العودة والتوبة",
                    promptEnglish: "What are you trying to leave behind?",
                    promptArabic: "ما الذي تحاول أن تتجاوزه؟",
                    situationIDs: [
                        "fightingTemptation", "madeAMistake", "forgiveYourself",
                        "sameSin", "selfControl",
                    ]
                ),
            ]
        ),
        LifeGroup(
            id: .wellbeing,
            titleEnglish: "Worry & Hardship",
            titleArabic: "الهم والابتلاء",
            subtitleEnglish: "For fear, loneliness, hurt, comparison, and uncertain seasons.",
            subtitleArabic: "للخوف والوحدة والأذى ومقارنة النفس بالآخرين وأوقات الحيرة.",
            symbol: "cloud.sun",
            stages: [
                GuidanceStage(
                    id: "wellbeing-future",
                    titleEnglish: "Fear of the future",
                    titleArabic: "الخوف من المستقبل",
                    promptEnglish: "What are you afraid may happen?",
                    promptArabic: "ما الذي تخشى حدوثه؟",
                    situationIDs: ["scaredOfFuture", "afraidOfFailure", "worriedTomorrow", "tooManyBurdens"]
                ),
                GuidanceStage(
                    id: "wellbeing-healing",
                    titleEnglish: "Hurt & healing",
                    titleArabic: "الأذى والتعافي",
                    promptEnglish: "What is asking to be healed?",
                    promptArabic: "ما الذي تتمنى التعافي منه؟",
                    situationIDs: ["feelAlone", "disappointed", "movingOn", "someoneHurtsYou", "needToForgive"]
                ),
                GuidanceStage(
                    id: "wellbeing-worth",
                    titleEnglish: "Worth & comparison",
                    titleArabic: "تقدير الذات والمقارنة",
                    promptEnglish: "What is making you doubt yourself?",
                    promptArabic: "ما الذي يجعلك تشك في نفسك؟",
                    situationIDs: ["everyoneAhead", "afraidPeopleThink", "feelingInsecure", "facingRejection"]
                ),
            ]
        ),
        LifeGroup(
            id: .provision,
            titleEnglish: "Work & Provision",
            titleArabic: "العمل والرزق",
            subtitleEnglish: "For money pressure, work, debt, decisions, and tawakkul.",
            subtitleArabic: "إرشاد في شؤون المال والعمل والدَّين، واتخاذ القرارات والتوكل على الله.",
            symbol: "briefcase",
            stages: [
                GuidanceStage(
                    id: "provision-needs",
                    titleEnglish: "Daily needs",
                    titleArabic: "الاحتياجات اليومية",
                    promptEnglish: "What feels financially heavy?",
                    promptArabic: "ما الذي يثقلك ماليًا؟",
                    situationIDs: [
                        "worriedAboutRizq", "strugglingFinancially", "financialBurdens",
                        "moneyStress", "tomorrowRizq", "salaryNotEnough", "stuckFinancially",
                        "providingForFamily", "payingBills", "stressedAboutDebt", "savingsLow",
                    ]
                ),
                GuidanceStage(
                    id: "provision-work",
                    titleEnglish: "Work & progress",
                    titleArabic: "العمل والتقدم",
                    promptEnglish: "Where does progress feel blocked?",
                    promptArabic: "أين تشعر أن تقدمك متعثر؟",
                    situationIDs: [
                        "workNoResults", "provisionDelayed", "scaredStartBusiness",
                        "impatientForResults", "losingJob", "everyoneAheadDuha",
                    ]
                ),
                GuidanceStage(
                    id: "provision-contentment",
                    titleEnglish: "Contentment & giving",
                    titleArabic: "القناعة والإنفاق",
                    promptEnglish: "What has your heart attached to?",
                    promptArabic: "بماذا تعلق قلبك؟",
                    situationIDs: [
                        "hesitantCharity", "comparingFinances", "afraidToSpend",
                        "heartAttachedMoney", "barakahInWealth", "jealousOfSuccess",
                    ]
                ),
                GuidanceStage(
                    id: "provision-decisions",
                    titleEnglish: "Decisions & risk",
                    titleArabic: "القرارات والمخاطرة",
                    promptEnglish: "What decision needs clarity?",
                    promptArabic: "ما القرار الذي تحاول حسمه؟",
                    situationIDs: ["afraidToRisk", "majorFinancialDecision"]
                ),
            ]
        ),
    ]

    static func group(_ id: LifeGroupID) -> LifeGroup {
        groups.first { $0.id == id }!
    }

    static func group(containing situation: Situation) -> LifeGroup {
        groups.first { $0.situations.contains(situation) } ?? group(.wellbeing)
    }

    static func stage(containing situation: Situation) -> GuidanceStage? {
        groups.flatMap(\.stages).first { $0.situationIDs.contains(situation.id) }
    }

    private struct SearchEntry {
        let situation: Situation
        let index: Int
        let title: String
        let document: String
    }

    /// The catalog is immutable. Normalize its bilingual text once, not on every keystroke.
    private static let searchIndex: [SearchEntry] = SituationCatalog.all.enumerated().map { index, situation in
        SearchEntry(
            situation: situation,
            index: index,
            title: normalizedGuidanceSearchText("\(situation.title) \(situation.arabicTitle) \(situation.referenceLabel)"),
            document: searchDocument(for: situation)
        )
    }

    static func prepareSearch() { _ = searchIndex }

    static func search(_ query: String) -> [Situation] {
        let value = normalizedGuidanceSearchText(query)
        guard !value.isEmpty else { return [] }

        let emergencySituationIDs = Set(
            EmergencyGuidanceCatalog.matching(value).map(\.situationID)
        )

        let queryTokens = value.split(separator: " ").map(String.init).filter {
            !searchStopWords.contains($0)
        }

        let scored: [(situation: Situation, score: Int, index: Int)] =
            searchIndex.compactMap { entry -> (Situation, Int, Int)? in
            let situation = entry.situation
            let title = entry.title
            let document = entry.document
            var score = 0

            if title == value { score += 1_000 }
            if title.hasPrefix(value) { score += 500 }
            if title.contains(value) { score += 300 }
            if document.contains(value) { score += 150 }

            let matchedTokens = queryTokens.filter { document.contains($0) }.count
            if !queryTokens.isEmpty && matchedTokens == queryTokens.count {
                score += 120 + matchedTokens * 20
            } else {
                score += matchedTokens * 18
            }

            if emergencySituationIDs.contains(situation.id) { score += 800 }
            score += semanticCueScore(for: situation.id, query: value)

            guard score > 0 else { return nil }
            return (situation, score, entry.index)
        }

        return scored.sorted {
            if $0.score == $1.score { return $0.index < $1.index }
            return $0.score > $1.score
        }
        .map(\.situation)
    }

    private static let searchStopWords: Set<String> = [
        "a", "an", "and", "are", "at", "be", "do", "for", "i", "in", "is", "it",
        "me", "my", "of", "on", "or", "the", "to", "when", "with", "you", "your",
        "من", "في", "على", "عن", "الى", "إلى", "انا", "أنا", "عندما", "مع",
    ]

    private static func searchDocument(for situation: Situation) -> String {
        let group = group(containing: situation)
        let stage = stage(containing: situation)
        let companion = CompanionContentCatalog.content(for: situation)

        let verseText = situation.verses.flatMap {
            [$0.arabic, $0.translation, $0.surahName, $0.surahNameArabic, $0.surahNameTranslated]
        }
        let hadithText = companion.hadiths.flatMap {
            [$0.titleEnglish, $0.titleArabic, $0.english, $0.arabic, $0.contextEnglish, $0.contextArabic]
        }
        let duaText = companion.supplications.flatMap {
            [
                $0.titleEnglish, $0.titleArabic, $0.arabic, $0.transliteration,
                $0.meaningEnglish, $0.meaningArabic, $0.contextEnglish, $0.contextArabic,
            ]
        }

        return normalizedGuidanceSearchText(([
            situation.title,
            situation.arabicTitle,
            situation.referenceLabel,
            situation.whyNote,
            group.titleEnglish,
            group.titleArabic,
            stage?.titleEnglish ?? "",
            stage?.titleArabic ?? "",
        ] + verseText + hadithText + duaText).joined(separator: " "))
    }

    private static let semanticCues: [(terms: [String], targets: Set<String>)] = [
            (["anxious", "anxiety", "overthinking", "overthink", "exam"], ["scaredOfFuture", "afraidOfFailure"]),
            (["failed", "failure", "setback", "rejected", "rejection"], ["disappointed", "facingRejection", "afraidOfFailure"]),
            (["job", "career", "unemployed", "fired"], ["losingJob", "workNoResults", "worriedAboutRizq"]),
            (["toxic marriage", "marriage conflict", "arguing"], ["marriageProblems", "constantlyArguing", "spouseWrongedYou"]),
            (["lonely", "loneliness", "alone", "misunderstood"], ["feelAlone"]),
            (["debt", "bills", "money", "rent"], ["stressedAboutDebt", "payingBills", "moneyStress"]),
            (["lost", "purpose", "decision", "guidance"], ["needGuidance", "majorFinancialDecision"]),
            (["sin", "mistake", "repent", "guilt", "shame"], ["madeAMistake", "sameSin", "forgiveYourself"]),
            (["compare", "comparison", "behind", "grades"], ["everyoneAhead", "everyoneAheadDuha", "comparingFinances"]),
            (["burnout", "burned out", "exhausted", "tired"], ["tooManyBurdens", "movingOn"]),
            (["rizq", "provision", "salary", "savings"], ["worriedAboutRizq", "salaryNotEnough", "savingsLow"]),
            (["pray", "prayer", "salah", "khushu"], ["salahConnection", "hardToPray", "losingFocus"]),
        ]

    private static func semanticCueScore(for situationID: String, query: String) -> Int {
        return semanticCues.reduce(into: 0) { score, cue in
            guard cue.targets.contains(situationID), cue.terms.contains(where: query.contains) else { return }
            score += 260
        }
    }
}
