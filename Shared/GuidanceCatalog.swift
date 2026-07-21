import Foundation

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
                    promptArabic: "ماذا يحتاج زواجك اليوم؟",
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
                    promptArabic: "ما الذي تحمله بعد انتهاء العلاقة؟",
                    situationIDs: ["divorceUnavoidable", "afterDivorce", "grievingSpouse"]
                ),
            ]
        ),
        LifeGroup(
            id: .family,
            titleEnglish: "Family & Parenthood",
            titleArabic: "الأسرة والأبوة",
            subtitleEnglish: "Guidance for children, the home, absence, and longing.",
            subtitleArabic: "هداية للأبناء والبيت والغياب والاشتياق.",
            symbol: "figure.2.and.child.holdinghands",
            stages: [
                GuidanceStage(
                    id: "family-children",
                    titleEnglish: "Children",
                    titleArabic: "الأبناء",
                    promptEnglish: "What are you hoping for as a parent?",
                    promptArabic: "ما الذي ترجوه بصفتك والدًا؟",
                    situationIDs: ["raisingChildren", "prayingForChildren", "infertility"]
                ),
                GuidanceStage(
                    id: "family-home",
                    titleEnglish: "Home & absence",
                    titleArabic: "البيت والغياب",
                    promptEnglish: "What is your family carrying?",
                    promptArabic: "ما الذي تحمله أسرتك؟",
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
                    promptArabic: "أين يحتاج قلبك إلى الثبات؟",
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
            subtitleArabic: "للخوف والوحدة والأذى والمقارنة ومواسم عدم اليقين.",
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
                    promptArabic: "ما الذي يحتاج إلى التعافي؟",
                    situationIDs: ["feelAlone", "disappointed", "movingOn", "someoneHurtsYou", "needToForgive"]
                ),
                GuidanceStage(
                    id: "wellbeing-worth",
                    titleEnglish: "Worth & comparison",
                    titleArabic: "القيمة والمقارنة",
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
            subtitleArabic: "لضغوط المال والعمل والدَّين والقرارات والتوكل.",
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
                    promptArabic: "أي قرار يحتاج إلى وضوح؟",
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

    static func search(_ query: String) -> [Situation] {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return [] }
        return SituationCatalog.all.filter { situation in
            let group = group(containing: situation)
            return situation.title.localizedCaseInsensitiveContains(value)
                || situation.arabicTitle.localizedCaseInsensitiveContains(value)
                || situation.referenceLabel.localizedCaseInsensitiveContains(value)
                || group.titleEnglish.localizedCaseInsensitiveContains(value)
                || group.titleArabic.localizedCaseInsensitiveContains(value)
        }
    }
}

// MARK: - Arabic situation labels

extension Situation {
    func localizedTitle(_ language: AppLanguage) -> String {
        language.pick(title, arabicTitle)
    }

    var arabicTitle: String {
        ArabicSituationTitles.values[id] ?? title
    }
}

private enum ArabicSituationTitles {
    static let values: [String: String] = [
        "beforeMarriage": "قبل الزواج",
        "lookingForSpouse": "عندما تبحث عن شريك صالح",
        "choosingSpouse": "عندما تختار من تتزوج",
        "waitingForTiming": "عندما تنتظر توقيت الله",
        "worriedNeverMarry": "عندما تخشى ألا تتزوج",
        "strugglingPatience": "عندما يصعب عليك الصبر",
        "peaceInMarriage": "عندما تطلب السكينة في زواجك",
        "treatSpouseKindly": "عندما تحتاج إلى حسن معاملة زوجك",
        "becomeBetterSpouse": "عندما تريد أن تكون زوجًا أفضل",
        "speakKindly": "عندما تحتاج إلى الكلام بلطف مع زوجك",
        "decidingTogether": "عندما تتخذان قرارًا معًا",
        "fairnessInMarriage": "عندما تحتاج إلى العدل في زواجك",
        "rebuildingTrust": "عندما تحاول إعادة بناء الثقة",
        "duaForFamily": "عندما تدعو لأسرتك",
        "feelingDistant": "عندما تشعر بالبعد عن زوجك",
        "marriageProblems": "عندما تواجه مشكلات زوجية",
        "constantlyArguing": "عندما يكثر الجدال بينكما",
        "spouseWrongedYou": "عندما يظلمك زوجك",
        "loweringAnger": "عندما يصعب عليك كظم الغيظ",
        "forgivingSpouse": "عندما تحتاج إلى مسامحة زوجك",
        "temptedToDivorce": "عندما تفكر في الطلاق بسبب خلاف",
        "marriageTested": "عندما يمر زواجك بابتلاء",
        "afraidWontLast": "عندما تخشى ألا يستمر زواجك",
        "questioningChoice": "عندما تراجع اختيارك",
        "trustingPlan": "عندما يصعب عليك الثقة بتدبير الله",
        "trustingTiming": "عندما تثق بتوقيت الله",
        "stayOrLeave": "عندما تحتار بين البقاء والفراق",
        "raisingChildren": "عندما تربيان أبناءكما معًا",
        "prayingForChildren": "عندما تدعو بأبناء صالحين",
        "infertility": "عندما تواجه تأخر الإنجاب",
        "spouseAway": "عندما يكون زوجك بعيدًا عن البيت",
        "divorceUnavoidable": "عندما يصبح الطلاق لا مفر منه",
        "afterDivorce": "عندما تتعافى بعد الطلاق",
        "grievingSpouse": "عندما تحزن على وفاة زوجك",
        "needGuidance": "عندما تحتاج إلى الهداية",
        "imanLow": "عندما يضعف إيمانك",
        "salahConnection": "عندما لا تجد الخشوع في الصلاة",
        "hardToPray": "عندما تصعب عليك الصلاة",
        "losingFocus": "عندما تفقد تركيزك",
        "forgettingBlessings": "عندما تنسى نعم الله",
        "strugglingGrateful": "عندما يصعب عليك الشكر",
        "fightingTemptation": "عندما تجاهد الإغراء",
        "madeAMistake": "عندما ترتكب خطأ",
        "forgiveYourself": "عندما يدفعك الخجل إلى اليأس من رحمة الله",
        "sameSin": "عندما تعود إلى الذنب نفسه",
        "selfControl": "عندما تجاهد لضبط نفسك",
        "scaredOfFuture": "عندما تخاف من المستقبل",
        "afraidOfFailure": "عندما تخاف من الفشل",
        "worriedTomorrow": "عندما تقلق بشأن الغد",
        "feelAlone": "عندما تشعر بالوحدة",
        "tooManyBurdens": "عندما تحمل أعباء كثيرة",
        "disappointed": "عندما تشعر بخيبة الأمل",
        "movingOn": "عندما تحاول المضي قدمًا",
        "everyoneAhead": "عندما يبدو أن الجميع سبقوك",
        "someoneHurtsYou": "عندما يؤذيك أحد",
        "needToForgive": "عندما تحتاج إلى العفو",
        "afraidPeopleThink": "عندما تخاف من كلام الناس",
        "feelingInsecure": "عندما تشعر بعدم الأمان",
        "facingRejection": "عندما تواجه الرفض",
        "worriedAboutRizq": "عندما تقلق بشأن الرزق",
        "strugglingFinancially": "عندما تمر بضائقة مالية",
        "hesitantCharity": "عندما تتردد في الصدقة",
        "comparingFinances": "عندما تقارن مالك بمال غيرك",
        "financialBurdens": "عندما تثقل عليك الأعباء المالية",
        "moneyStress": "عندما يسبب لك المال توترًا",
        "afraidToSpend": "عندما تخاف من الإنفاق في سبيل الله",
        "tomorrowRizq": "عندما تقلق بشأن رزق الغد",
        "workNoResults": "عندما تعمل ولا ترى نتيجة",
        "heartAttachedMoney": "عندما يتعلق قلبك بالمال",
        "barakahInWealth": "عندما تطلب البركة في مالك",
        "provisionDelayed": "عندما تظن أن رزقك تأخر",
        "salaryNotEnough": "عندما لا يكفي راتبك",
        "scaredStartBusiness": "عندما تخاف من بدء مشروع",
        "stuckFinancially": "عندما تشعر أنك عالق ماليًا",
        "jealousOfSuccess": "عندما تغار من نجاح غيرك",
        "providingForFamily": "عندما تقلق بشأن الإنفاق على أسرتك",
        "afraidToRisk": "عندما تخاف من المخاطرة",
        "majorFinancialDecision": "عندما تتخذ قرارًا ماليًا كبيرًا",
        "impatientForResults": "عندما تستعجل النتائج",
        "everyoneAheadDuha": "عندما تشعر أن الجميع سبقوك",
        "payingBills": "عندما تقلق بشأن سداد الفواتير",
        "stressedAboutDebt": "عندما يرهقك الدَّين",
        "losingJob": "عندما تخاف من فقدان عملك",
        "savingsLow": "عندما تقل مدخراتك",
    ]
}
