import Foundation

// MARK: - Applicability and source metadata

/// How directly a text addresses the situation in which it is shown.
///
/// This distinction matters: a sound text can still be misrepresented when a
/// broad principle is presented as though it were a situation-specific ruling.
enum GuidanceApplicabilityLevel: String, Codable, CaseIterable, Hashable, Sendable {
    case direct
    case supportingPrinciple
    case generalRemembrance
}

struct GuidanceApplicabilityMetadata: Codable, Hashable, Sendable {
    let level: GuidanceApplicabilityLevel
    let explanationEnglish: String
    let explanationArabic: String

    func explanation(_ language: AppLanguage) -> String {
        language.pick(explanationEnglish, explanationArabic)
    }
}

enum GuidanceSourceKind: String, Codable, CaseIterable, Hashable, Sendable {
    case quran
    case hadith
}

/// Whether the displayed Arabic is the complete cited text or a clearly marked
/// excerpt. A supplication extracted from a longer ayah is always `.excerpt`.
enum GuidanceTextForm: String, Codable, CaseIterable, Hashable, Sendable {
    case complete
    case excerpt
}

struct GuidanceSourceMetadata: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let kind: GuidanceSourceKind
    let collectionEnglish: String
    let collectionArabic: String
    let number: String
    let gradeEnglish: String
    let gradeArabic: String
    let canonicalURL: String
    let textForm: GuidanceTextForm

    func collection(_ language: AppLanguage) -> String {
        language.pick(collectionEnglish, collectionArabic)
    }

    func grade(_ language: AppLanguage) -> String {
        language.pick(gradeEnglish, gradeArabic)
    }
}

// MARK: - Companion content models

struct GuidanceHadith: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let titleEnglish: String
    let titleArabic: String
    let arabic: String
    let english: String
    let contextEnglish: String
    let contextArabic: String
    let applicability: GuidanceApplicabilityMetadata
    let source: GuidanceSourceMetadata
    let cautionEnglish: String?
    let cautionArabic: String?

    init(
        id: String,
        titleEnglish: String,
        titleArabic: String,
        arabic: String,
        english: String,
        contextEnglish: String,
        contextArabic: String,
        applicability: GuidanceApplicabilityMetadata,
        source: GuidanceSourceMetadata,
        cautionEnglish: String? = nil,
        cautionArabic: String? = nil
    ) {
        self.id = id
        self.titleEnglish = titleEnglish
        self.titleArabic = titleArabic
        self.arabic = arabic
        self.english = english
        self.contextEnglish = contextEnglish
        self.contextArabic = contextArabic
        self.applicability = applicability
        self.source = source
        self.cautionEnglish = cautionEnglish
        self.cautionArabic = cautionArabic
    }

    func title(_ language: AppLanguage) -> String {
        language.pick(titleEnglish, titleArabic)
    }

    func context(_ language: AppLanguage) -> String {
        language.pick(contextEnglish, contextArabic)
    }

    func caution(_ language: AppLanguage) -> String? {
        language == .arabic ? cautionArabic : cautionEnglish
    }
}

enum GuidanceSupplicationKind: String, Codable, CaseIterable, Hashable, Sendable {
    case quranic
    case prophetic
    case remembrance
}

struct GuidanceSupplication: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let titleEnglish: String
    let titleArabic: String
    let arabic: String
    let transliteration: String
    let meaningEnglish: String
    let meaningArabic: String
    let contextEnglish: String
    let contextArabic: String
    let kind: GuidanceSupplicationKind
    let applicability: GuidanceApplicabilityMetadata
    let source: GuidanceSourceMetadata
    let cautionEnglish: String?
    let cautionArabic: String?

    init(
        id: String,
        titleEnglish: String,
        titleArabic: String,
        arabic: String,
        transliteration: String,
        meaningEnglish: String,
        meaningArabic: String,
        contextEnglish: String,
        contextArabic: String,
        kind: GuidanceSupplicationKind,
        applicability: GuidanceApplicabilityMetadata,
        source: GuidanceSourceMetadata,
        cautionEnglish: String? = nil,
        cautionArabic: String? = nil
    ) {
        self.id = id
        self.titleEnglish = titleEnglish
        self.titleArabic = titleArabic
        self.arabic = arabic
        self.transliteration = transliteration
        self.meaningEnglish = meaningEnglish
        self.meaningArabic = meaningArabic
        self.contextEnglish = contextEnglish
        self.contextArabic = contextArabic
        self.kind = kind
        self.applicability = applicability
        self.source = source
        self.cautionEnglish = cautionEnglish
        self.cautionArabic = cautionArabic
    }

    func title(_ language: AppLanguage) -> String {
        language.pick(titleEnglish, titleArabic)
    }

    func meaning(_ language: AppLanguage) -> String {
        language.pick(meaningEnglish, meaningArabic)
    }

    func context(_ language: AppLanguage) -> String {
        language.pick(contextEnglish, contextArabic)
    }

    func caution(_ language: AppLanguage) -> String? {
        language == .arabic ? cautionArabic : cautionEnglish
    }
}

enum GuidanceSafetyNoticeKind: String, Codable, CaseIterable, Hashable, Sendable {
    case immediateSafety
    case specialistSupport
    case legalAndScholarly
}

struct GuidanceSafetyNotice: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let kind: GuidanceSafetyNoticeKind
    let titleEnglish: String
    let titleArabic: String
    let messageEnglish: String
    let messageArabic: String

    func title(_ language: AppLanguage) -> String {
        language.pick(titleEnglish, titleArabic)
    }

    func message(_ language: AppLanguage) -> String {
        language.pick(messageEnglish, messageArabic)
    }
}

struct SituationCompanionContent: Hashable, Sendable {
    let hadiths: [GuidanceHadith]
    let supplications: [GuidanceSupplication]
    let safetyNotices: [GuidanceSafetyNotice]
}

// MARK: - Vetted catalog

/// Curated hadith and du'a that accompany a situation's Qur'an reading.
///
/// The catalog deliberately stays small. Every hadith below is from Sahih
/// al-Bukhari, Sahih Muslim, or is individually graded Sahih/Hasan on the linked
/// canonical collection page. Qur'anic du'a use the Uthmani text of the cited
/// ayah. Context copy is pastoral orientation, not a fatwa or tafsir.
enum CompanionContentCatalog {

    // MARK: Public lookup

    static func content(for situation: Situation) -> SituationCompanionContent {
        SituationCompanionContent(
            hadiths: hadiths(for: situation),
            supplications: supplications(for: situation),
            safetyNotices: safetyNotices(for: situation)
        )
    }

    static func content(forSituationID id: String) -> SituationCompanionContent? {
        guard let situation = SituationCatalog.by(id: id) else { return nil }
        return content(for: situation)
    }

    static func hadiths(for situation: Situation) -> [GuidanceHadith] {
        let ids = situationHadithIDs[situation.id] ?? chapterHadithFallbacks[situation.chapter] ?? []
        return unique(ids.compactMap { hadithByID[$0] })
    }

    static func supplications(for situation: Situation) -> [GuidanceSupplication] {
        let ids = situationSupplicationIDs[situation.id] ?? chapterSupplicationFallbacks[situation.chapter] ?? []
        return unique(ids.compactMap { supplicationByID[$0] })
    }

    static func safetyNotices(for situation: Situation) -> [GuidanceSafetyNotice] {
        let ids = situationSafetyNoticeIDs[situation.id] ?? []
        return unique(ids.compactMap { safetyNoticeByID[$0] })
    }

    /// Useful for tests and content QA. This should remain empty.
    static var uncoveredSituationIDs: [String] {
        SituationCatalog.all.compactMap { situation in
            let companion = content(for: situation)
            return companion.hadiths.isEmpty || companion.supplications.isEmpty ? situation.id : nil
        }
    }

    /// Structural checks that can be surfaced by a debug build or unit test.
    static var validationIssues: [String] {
        var issues: [String] = []

        issues += duplicateIDs(in: hadiths.map(\.id), label: "hadith")
        issues += duplicateIDs(in: supplications.map(\.id), label: "supplication")
        issues += duplicateIDs(in: safetyNotices.map(\.id), label: "safety notice")

        let knownSituationIDs = Set(SituationCatalog.all.map(\.id))
        for id in Set(situationHadithIDs.keys).union(situationSupplicationIDs.keys).union(situationSafetyNoticeIDs.keys)
            where !knownSituationIDs.contains(id) {
            issues.append("Unknown situation id: \(id)")
        }

        for source in hadiths.map(\.source) + supplications.map(\.source) {
            guard let url = URL(string: source.canonicalURL),
                  let scheme = url.scheme,
                  ["https", "http"].contains(scheme) else {
                issues.append("Invalid canonical source URL: \(source.id)")
                continue
            }
        }

        issues += uncoveredSituationIDs.map { "Situation has incomplete companion content: \($0)" }
        return issues
    }

    // MARK: Hadith

    static let hadiths: [GuidanceHadith] = [
        GuidanceHadith(
            id: "marry-when-able",
            titleEnglish: "Marriage and chastity",
            titleArabic: "الزواج والعفة",
            arabic: "يَا مَعْشَرَ الشَّبَابِ مَنِ اسْتَطَاعَ الْبَاءَةَ فَلْيَتَزَوَّجْ، فَإِنَّهُ أَغَضُّ لِلْبَصَرِ، وَأَحْصَنُ لِلْفَرْجِ، وَمَنْ لَمْ يَسْتَطِعْ فَعَلَيْهِ بِالصَّوْمِ، فَإِنَّهُ لَهُ وِجَاءٌ",
            english: "Young people, whoever among you is able to marry should marry; it is more effective in lowering the gaze and guarding chastity. Whoever cannot should fast, for fasting restrains desire.",
            contextEnglish: "A direct Prophetic direction for someone who is able to take on marriage, and a practical act of worship for someone who is not yet able.",
            contextArabic: "توجيه نبوي مباشر لمن يقدر على مسؤوليات الزواج، مع عبادة عملية لمن لم يقدر عليه بعد.",
            applicability: direct(
                "Directly addresses readiness for marriage and the waiting period before it.",
                "يتناول مباشرة الاستعداد للزواج ومرحلة الانتظار قبله."
            ),
            source: hadithSource(
                id: "bukhari-5066", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "5066",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:5066"
            )
        ),
        GuidanceHadith(
            id: "choose-religion",
            titleEnglish: "What to prioritise in a spouse",
            titleArabic: "ما يُقدَّم في اختيار الزوجة",
            arabic: "تُنْكَحُ الْمَرْأَةُ لِأَرْبَعٍ لِمَالِهَا وَلِحَسَبِهَا وَجَمَالِهَا وَلِدِينِهَا، فَاظْفَرْ بِذَاتِ الدِّينِ تَرِبَتْ يَدَاكَ",
            english: "A woman is married for four things: her wealth, her lineage, her beauty, and her religion. Choose the one of religion; may your hands prosper.",
            contextEnglish: "This narration addresses a man's choice of a wife and teaches him not to let status or attraction displace religious commitment. It should not be turned into a formula that ignores character, compatibility, consent, or due diligence.",
            contextArabic: "يخاطب الحديث الرجل عند اختيار الزوجة، ويعلّمه ألّا يقدّم المكانة أو الجمال على الدين. ولا يصح تحويله إلى معادلة تتجاهل الخلق والتوافق والرضا والتحرّي.",
            applicability: direct(
                "Direct guidance for a man choosing a wife; its priority of faith is a supporting principle in broader spouse selection.",
                "توجيه مباشر للرجل عند اختيار الزوجة، وأولوية الدين فيه مبدأ مساند في اختيار شريك الحياة عمومًا."
            ),
            source: hadithSource(
                id: "bukhari-5090", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "5090",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:5090"
            )
        ),
        GuidanceHadith(
            id: "marriage-consent",
            titleEnglish: "Consent is required",
            titleArabic: "لا بد من الرضا",
            arabic: "لَا تُنْكَحُ الْأَيِّمُ حَتَّى تُسْتَأْمَرَ وَلَا تُنْكَحُ الْبِكْرُ حَتَّى تُسْتَأْذَنَ. قَالُوا يَا رَسُولَ اللَّهِ وَكَيْفَ إِذْنُهَا قَالَ أَنْ تَسْكُتَ",
            english: "A previously married woman is not to be married until she is consulted, and a virgin is not to be married until her permission is sought. They asked, ‘Messenger of Allah, how is her permission known?’ He said, ‘By her silence.’",
            contextEnglish: "The hadith establishes that a woman's consent must be sought. Silence in its historical wording cannot be used to override an expressed refusal, fear, coercion, or the legal consent requirements where she lives.",
            contextArabic: "يثبت الحديث وجوب استئذان المرأة. ولا يجوز اتخاذ السكوت الوارد في سياقه التاريخي ذريعة لتجاوز رفض صريح أو خوف أو إكراه أو متطلبات الرضا القانونية في بلدها.",
            applicability: direct(
                "Directly governs consent before a marriage contract.",
                "يتعلق مباشرة بالرضا قبل عقد الزواج."
            ),
            source: hadithSource(
                id: "bukhari-5136", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "5136",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:5136"
            ),
            cautionEnglish: "Coercion is not consent. If pressure or threats are present, seek safe, independent support.",
            cautionArabic: "الإكراه ليس رضا. إذا وُجد ضغط أو تهديد فاطلب دعمًا مستقلًا وآمنًا."
        ),
        GuidanceHadith(
            id: "forced-marriage-rejected",
            titleEnglish: "A forced marriage was rejected",
            titleArabic: "رَدُّ النكاح بالإكراه",
            arabic: "أَنَّ أَبَاهَا زَوَّجَهَا وَهِيَ ثَيِّبٌ، فَكَرِهَتْ ذَلِكَ، فَأَتَتْ رَسُولَ اللَّهِ صلى الله عليه وسلم فَرَدَّ نِكَاحَهَا",
            english: "Her father married her off when she had previously been married, and she disliked it. She came to the Messenger of Allah ﷺ, and he rejected that marriage.",
            contextEnglish: "This report shows that objection to a coerced marriage was heard and acted upon. Questions about the validity or annulment of a contract need a qualified local scholar and, where relevant, a lawyer.",
            contextArabic: "يبين الخبر أن اعتراض المرأة على زواج أُكرهت عليه سُمِع وعولج. أما صحة العقد أو فسخه فتحتاج إلى عالم مؤهل في البلد، ومحامٍ عند الحاجة.",
            applicability: direct(
                "Direct evidence against imposing a marriage on an unwilling woman.",
                "دليل مباشر على منع فرض الزواج على امرأة غير راضية."
            ),
            source: hadithSource(
                id: "bukhari-5138", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "5138",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:5138", textForm: .excerpt
            ),
            cautionEnglish: "Do not confront a coercive person alone if doing so could place you in danger.",
            cautionArabic: "لا تواجه شخصًا مُكرِهًا وحدك إذا كانت المواجهة قد تعرّضك للخطر."
        ),
        GuidanceHadith(
            id: "best-to-family",
            titleEnglish: "The best are best to their families",
            titleArabic: "خير الناس خيرهم لأهله",
            arabic: "خَيْرُكُمْ خَيْرُكُمْ لِأَهْلِهِ وَأَنَا خَيْرُكُمْ لِأَهْلِي",
            english: "The best of you are those who are best to their families, and I am the best of you to my family.",
            contextEnglish: "Character at home is part of the Prophetic measure of excellence. The wording shown is the relevant complete sentence from a longer narration.",
            contextArabic: "حسن الخلق داخل البيت من ميزان الخيرية في الهدي النبوي. والنص المعروض هو الجملة المقصودة من رواية أطول.",
            applicability: supporting(
                "A governing principle for conduct between spouses and within the family.",
                "مبدأ حاكم لحسن المعاملة بين الزوجين وداخل الأسرة."
            ),
            source: hadithSource(
                id: "tirmidhi-3895", collectionEnglish: "Jami` at-Tirmidhi",
                collectionArabic: "جامع الترمذي", number: "3895",
                gradeEnglish: "Sahih (Darussalam)", gradeArabic: "صحيح (دار السلام)",
                url: "https://sunnah.com/tirmidhi:3895", textForm: .excerpt
            )
        ),
        GuidanceHadith(
            id: "do-not-despise-spouse",
            titleEnglish: "See the whole person",
            titleArabic: "انظر إلى الصورة كاملة",
            arabic: "لَا يَفْرَكْ مُؤْمِنٌ مُؤْمِنَةً إِنْ كَرِهَ مِنْهَا خُلُقًا رَضِيَ مِنْهَا آخَرَ",
            english: "A believing man should not despise a believing woman. If he dislikes one quality in her, he should be pleased with another.",
            contextEnglish: "A direct instruction to a husband not to reduce his wife to one disliked trait. It encourages fair perspective; it does not require anyone to minimise abuse, danger, or persistent injustice.",
            contextArabic: "توجيه مباشر للزوج ألّا يختزل زوجته في خُلُق يكرهه، بل ينظر بإنصاف إلى سائر خصالها. ولا يعني التقليل من العنف أو الخطر أو الظلم المستمر.",
            applicability: direct(
                "Directly addresses a husband's negative feelings toward his wife.",
                "يتناول مباشرة شعور الزوج بالنفور من بعض صفات زوجته."
            ),
            source: hadithSource(
                id: "muslim-1468b", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "1468b",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:1468b"
            ),
            cautionEnglish: "Balanced perspective is not a duty to remain in danger or accept abuse.",
            cautionArabic: "الإنصاف في النظر لا يوجب البقاء في خطر أو قبول الإساءة."
        ),
        GuidanceHadith(
            id: "gentleness",
            titleEnglish: "Allah loves gentleness",
            titleArabic: "الله يحب الرفق",
            arabic: "يَا عَائِشَةُ إِنَّ اللَّهَ رَفِيقٌ يُحِبُّ الرِّفْقَ وَيُعْطِي عَلَى الرِّفْقِ مَا لَا يُعْطِي عَلَى الْعُنْفِ وَمَا لَا يُعْطِي عَلَى مَا سِوَاهُ",
            english: "Aishah, Allah is gentle and loves gentleness. He grants for gentleness what He does not grant for harshness, or for anything else.",
            contextEnglish: "Use this as a standard for your own speech and conduct. It is not an instruction to answer another person's violence with passivity or to attempt unsafe mediation.",
            contextArabic: "اجعل الحديث ميزانًا لكلامك وسلوكك أنت. وليس أمرًا بمقابلة عنف شخص آخر بالسلبية أو الدخول في صلح غير آمن.",
            applicability: supporting(
                "A broad Prophetic principle for conflict, speech, and family conduct.",
                "مبدأ نبوي عام في الخلاف والكلام والمعاملة الأسرية."
            ),
            source: hadithSource(
                id: "muslim-2593", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "2593",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:2593"
            )
        ),
        GuidanceHadith(
            id: "spending-on-family",
            titleEnglish: "Provision for family is rewarded",
            titleArabic: "النفقة على الأهل مأجورة",
            arabic: "دِينَارٌ أَنْفَقْتَهُ فِي سَبِيلِ اللَّهِ وَدِينَارٌ أَنْفَقْتَهُ فِي رَقَبَةٍ وَدِينَارٌ تَصَدَّقْتَ بِهِ عَلَى مِسْكِينٍ وَدِينَارٌ أَنْفَقْتَهُ عَلَى أَهْلِكَ أَعْظَمُهَا أَجْرًا الَّذِي أَنْفَقْتَهُ عَلَى أَهْلِكَ",
            english: "A dinar you spend in Allah's path, a dinar you spend to free a slave, a dinar you give to someone in need, and a dinar you spend on your family: the greatest in reward is the one you spend on your family.",
            contextEnglish: "Meeting a family's needs with a sincere intention is worship, not spiritually insignificant routine.",
            contextArabic: "القيام بحاجة الأسرة بنية صالحة عبادة، وليس شأنًا دنيويًا قليل الأثر في الميزان.",
            applicability: direct(
                "Directly addresses spending on one's family.",
                "يتناول مباشرة النفقة على الأهل."
            ),
            source: hadithSource(
                id: "muslim-995", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "995",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:995"
            )
        ),
        GuidanceHadith(
            id: "strength-at-anger",
            titleEnglish: "Strength at the moment of anger",
            titleArabic: "القوة عند الغضب",
            arabic: "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ",
            english: "The strong person is not the one who overcomes others in wrestling. The strong person is the one who controls himself when angry.",
            contextEnglish: "Prophetic strength is self-command at the heated moment. Step away, lower the temperature, and return only when the conversation can be safe.",
            contextArabic: "القوة في الهدي النبوي هي ضبط النفس لحظة الاحتدام. ابتعد لتهدأ، ولا تعد إلى الحوار إلا حين يكون آمنًا.",
            applicability: direct(
                "Direct guidance for anger and escalating arguments.",
                "توجيه مباشر للغضب وتصاعد الجدال."
            ),
            source: hadithSource(
                id: "bukhari-6114", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "6114",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:6114"
            )
        ),
        GuidanceHadith(
            id: "charity-pardon-humility",
            titleEnglish: "Giving and pardoning do not diminish you",
            titleArabic: "الصدقة والعفو لا ينقصانك",
            arabic: "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلَّا رَفَعَهُ اللَّهُ",
            english: "Charity does not decrease wealth. Allah increases a servant in honour through pardon, and no one humbles himself for Allah except that Allah raises him.",
            contextEnglish: "The narration joins generosity, pardon, and humility to a deeper kind of increase. Pardon remains a moral choice; it does not erase accountability or require renewed access for someone unsafe.",
            contextArabic: "يجمع الحديث بين الصدقة والعفو والتواضع وبين زيادة أعمق. ويبقى العفو فضيلة اختيارية، ولا يلغي المحاسبة ولا يوجب إعادة تمكين شخص غير آمن.",
            applicability: supporting(
                "Direct for charity and supportive for forgiveness and reconciliation.",
                "مباشر في الصدقة، ومساند في العفو والإصلاح."
            ),
            source: hadithSource(
                id: "muslim-2588", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "2588",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:2588"
            )
        ),
        GuidanceHadith(
            id: "seek-what-benefits",
            titleEnglish: "Pursue what benefits you",
            titleArabic: "احرص على ما ينفعك",
            arabic: "الْمُؤْمِنُ الْقَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللَّهِ مِنَ الْمُؤْمِنِ الضَّعِيفِ وَفِي كُلٍّ خَيْرٌ احْرِصْ عَلَى مَا يَنْفَعُكَ وَاسْتَعِنْ بِاللَّهِ وَلَا تَعْجِزْ وَإِنْ أَصَابَكَ شَيْءٌ فَلَا تَقُلْ لَوْ أَنِّي فَعَلْتُ كَانَ كَذَا وَكَذَا وَلَكِنْ قُلْ قَدَرُ اللَّهِ وَمَا شَاءَ فَعَلَ فَإِنَّ لَوْ تَفْتَحُ عَمَلَ الشَّيْطَانِ",
            english: "The strong believer is better and more beloved to Allah than the weak believer, though there is good in both. Pursue what benefits you, seek Allah's help, and do not give up. If something befalls you, do not say, ‘If only I had done this or that.’ Say instead, ‘Allah decreed, and He did what He willed,’ for ‘if only’ opens the work of Satan.",
            contextEnglish: "The hadith combines responsible action, seeking Allah's help, and a way to stop counterfactual regret after the outcome.",
            contextArabic: "يجمع الحديث بين الأخذ بالأسباب والاستعانة بالله، ثم يعلّم إغلاق باب الندم الافتراضي بعد وقوع النتيجة.",
            applicability: supporting(
                "A broad principle for decisions, setbacks, work, and recovery.",
                "مبدأ عام للقرارات والتعثر والعمل والتعافي."
            ),
            source: hadithSource(
                id: "muslim-2664", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "2664",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:2664"
            )
        ),
        GuidanceHadith(
            id: "true-richness",
            titleEnglish: "Richness of the soul",
            titleArabic: "غنى النفس",
            arabic: "لَيْسَ الْغِنَى عَنْ كَثْرَةِ الْعَرَضِ، وَلَكِنَّ الْغِنَى غِنَى النَّفْسِ",
            english: "Richness is not having many possessions. True richness is richness of the soul.",
            contextEnglish: "Contentment changes the heart's measure of enough. It does not deny real poverty, debt, or the duty to pursue lawful provision.",
            contextArabic: "تغيّر القناعة ميزان الكفاية في القلب، لكنها لا تنكر الفقر الحقيقي أو الدَّين أو وجوب السعي في الرزق الحلال.",
            applicability: supporting(
                "A principle for comparison, attachment to money, and contentment.",
                "مبدأ للمقارنة والتعلق بالمال والقناعة."
            ),
            source: hadithSource(
                id: "bukhari-6446", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "6446",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:6446"
            )
        ),
        GuidanceHadith(
            id: "hearts-and-deeds",
            titleEnglish: "What Allah looks at",
            titleArabic: "ما ينظر الله إليه",
            arabic: "إِنَّ اللَّهَ لَا يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ",
            english: "Allah does not look at your appearance or your wealth, but He looks at your hearts and your deeds.",
            contextEnglish: "Worth before Allah is not ranked by appearance, status, or possessions. The hadith redirects attention to the inner life and what it produces in action.",
            contextArabic: "لا تُقاس المنزلة عند الله بالشكل أو المكانة أو المال؛ بل يرد الحديث القلب إلى باطنه وما يثمره من عمل.",
            applicability: supporting(
                "A direct correction for status comparison and appearance-based insecurity.",
                "تصحيح مباشر للمقارنة بالمكانة والقلق المبني على المظهر."
            ),
            source: hadithSource(
                id: "muslim-2564c", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "2564c",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:2564c"
            )
        ),
        GuidanceHadith(
            id: "allah-rejoices-at-repentance",
            titleEnglish: "Allah welcomes repentance",
            titleArabic: "فرح الله بتوبة عبده",
            arabic: "لَلَّهُ أَشَدُّ فَرَحًا بِتَوْبَةِ عَبْدِهِ حِينَ يَتُوبُ إِلَيْهِ",
            english: "Allah is more joyful at His servant's repentance when the servant turns back to Him.",
            contextEnglish: "This is the central sentence of a longer parable about recovering what seemed completely lost. It is shown as an excerpt so the source is not mistaken for only this sentence.",
            contextArabic: "هذه الجملة هي مقصد مثل أطول في استرداد ما بدا مفقودًا تمامًا، ولذلك عُرضت بوصفها مقتطفًا لا كامل الرواية.",
            applicability: direct(
                "Direct encouragement to repent without despair.",
                "تشجيع مباشر على التوبة من غير يأس."
            ),
            source: hadithSource(
                id: "muslim-2747a", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "2747a",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:2747a", textForm: .excerpt
            )
        ),
        GuidanceHadith(
            id: "closest-in-prostration",
            titleEnglish: "Closest in prostration",
            titleArabic: "أقرب ما يكون العبد في السجود",
            arabic: "أَقْرَبُ مَا يَكُونُ الْعَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ فَأَكْثِرُوا الدُّعَاءَ",
            english: "The closest a servant is to his Lord is while he is prostrating, so make abundant supplication.",
            contextEnglish: "When prayer feels distant, this hadith gives one simple point of return: remain present in sujud and ask Allah often.",
            contextArabic: "حين تبدو الصلاة بعيدة، يمنحك الحديث نقطة عودة بسيطة: احضر بقلبك في السجود وأكثر من الدعاء.",
            applicability: direct(
                "Directly addresses du'a during prostration and supports reconnection in salah.",
                "يتناول الدعاء في السجود مباشرة، ويساند استعادة الصلة في الصلاة."
            ),
            source: hadithSource(
                id: "muslim-482", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "482",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:482"
            )
        ),
        GuidanceHadith(
            id: "practice-patience",
            titleEnglish: "Patience can be practised",
            titleArabic: "من يتصبر يصبره الله",
            arabic: "وَمَنْ يَتَصَبَّرْ يُصَبِّرْهُ اللَّهُ، وَمَا أُعْطِيَ أَحَدٌ عَطَاءً خَيْرًا وَأَوْسَعَ مِنَ الصَّبْرِ",
            english: "Whoever seeks to practise patience, Allah will make him patient. No one is given a gift better and more expansive than patience.",
            contextEnglish: "The displayed wording is the patience section of a longer narration. Patience here is an active quality developed with Allah's help, not a command to tolerate danger or injustice.",
            contextArabic: "النص المعروض هو فقرة الصبر من رواية أطول. والصبر هنا خُلُق فاعل يُطلب بعون الله، لا أمر بتحمل الخطر أو الظلم.",
            applicability: supporting(
                "A broad principle for waiting and enduring a difficult season.",
                "مبدأ عام للانتظار وتجاوز المواسم الصعبة."
            ),
            source: hadithSource(
                id: "bukhari-1469", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "1469",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:1469", textForm: .excerpt
            )
        ),
        GuidanceHadith(
            id: "hardship-expiates",
            titleEnglish: "No pain is unnoticed",
            titleArabic: "لا يضيع ألم المؤمن",
            arabic: "مَا يُصِيبُ الْمُسْلِمَ مِنْ نَصَبٍ وَلَا وَصَبٍ وَلَا هَمٍّ وَلَا حُزْنٍ وَلَا أَذًى وَلَا غَمٍّ حَتَّى الشَّوْكَةِ يُشَاكُهَا، إِلَّا كَفَّرَ اللَّهُ بِهَا مِنْ خَطَايَاهُ",
            english: "No fatigue, illness, anxiety, grief, harm, or distress afflicts a Muslim—even the prick of a thorn—except that Allah removes some sins through it.",
            contextEnglish: "Suffering is seen by Allah and can carry expiation. Seeking medical, psychological, financial, or practical help is fully compatible with patience.",
            contextArabic: "الألم منظور عند الله وقد يكون كفارة. وطلب العلاج أو الدعم النفسي أو المالي أو العملي لا ينافي الصبر.",
            applicability: supporting(
                "A broad consolation for grief, anxiety, illness, and hardship.",
                "تسلية عامة في الحزن والهم والمرض والابتلاء."
            ),
            source: hadithSource(
                id: "bukhari-5641-5642", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "5641–5642",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:5641"
            )
        ),
        GuidanceHadith(
            id: "work-of-ones-hands",
            titleEnglish: "The dignity of earned provision",
            titleArabic: "فضل الكسب من عمل اليد",
            arabic: "مَا أَكَلَ أَحَدٌ طَعَامًا قَطُّ خَيْرًا مِنْ أَنْ يَأْكُلَ مِنْ عَمَلِ يَدِهِ، وَإِنَّ نَبِيَّ اللَّهِ دَاوُدَ عَلَيْهِ السَّلَامُ كَانَ يَأْكُلُ مِنْ عَمَلِ يَدِهِ",
            english: "No one has ever eaten food better than what he eats from the work of his own hands. Allah's Prophet Dawud, peace be upon him, used to eat from the work of his own hands.",
            contextEnglish: "Lawful work has dignity even when progress feels ordinary or slow. The hadith praises effort; it does not shame someone who cannot work or needs assistance.",
            contextArabic: "للعمل الحلال كرامة ولو بدا التقدم بطيئًا أو عاديًا. ويمدح الحديث السعي، ولا يعيّر من عجز عن العمل أو احتاج إلى مساعدة.",
            applicability: direct(
                "Directly praises lawful earnings from one's work.",
                "يمدح مباشرة الكسب الحلال من عمل الإنسان."
            ),
            source: hadithSource(
                id: "bukhari-2072", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "2072",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:2072"
            )
        ),
        GuidanceHadith(
            id: "deeds-by-intentions",
            titleEnglish: "Begin with intention",
            titleArabic: "ابدأ بالنية",
            arabic: "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى",
            english: "Actions are judged by intentions, and every person will have what they intended.",
            contextEnglish: "This famous opening principle is shown as an excerpt from the longer narration. Renewing intention gives ordinary effort—repair, work, worship, or care—a clear direction.",
            contextArabic: "يُعرض هذا الأصل المشهور مقتطفًا من رواية أطول. وتجديد النية يمنح السعي العادي في الإصلاح أو العمل أو العبادة أو الرعاية وجهة واضحة.",
            applicability: supporting(
                "A broad principle for beginning or renewing any beneficial action.",
                "مبدأ عام لبدء أي عمل نافع أو تجديده."
            ),
            source: hadithSource(
                id: "bukhari-1", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "1",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:1", textForm: .excerpt
            )
        ),
        GuidanceHadith(
            id: "oppression-is-darkness",
            titleEnglish: "Injustice is darkness",
            titleArabic: "الظلم ظلمات",
            arabic: "الظُّلْمُ ظُلُمَاتٌ يَوْمَ الْقِيَامَةِ",
            english: "Injustice will be layers of darkness on the Day of Resurrection.",
            contextEnglish: "Marriage and family language never make injustice acceptable. Name harm accurately, preserve evidence where safe, and seek qualified help when rights or safety are involved.",
            contextArabic: "لا تجعل لغة الزواج والأسرة الظلم مقبولًا. سمِّ الأذى باسمه، واحفظ الأدلة إن كان ذلك آمنًا، واطلب مساعدة مؤهلة عند تعلق الأمر بالحقوق أو السلامة.",
            applicability: direct(
                "Direct condemnation of injustice in every relationship.",
                "ذم مباشر للظلم في كل علاقة."
            ),
            source: hadithSource(
                id: "bukhari-2447", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "2447",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:2447", textForm: .excerpt
            )
        ),
    ]

    // MARK: Supplications

    static let supplications: [GuidanceSupplication] = [
        GuidanceSupplication(
            id: "quran-family-comfort",
            titleEnglish: "For a family that brings comfort",
            titleArabic: "لأسرة تكون قرة عين",
            arabic: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَٰجِنَا وَذُرِّيَّـٰتِنَا قُرَّةَ أَعْيُنٍ وَٱجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا",
            transliteration: "Rabbana hab lana min azwajina wa dhurriyyatina qurrata a'yunin waj'alna lil-muttaqina imama.",
            meaningEnglish: "Our Lord, grant us from among our spouses and offspring comfort to our eyes, and make us an example for the righteous.",
            meaningArabic: "يا ربنا، هب لنا من أزواجنا وذرياتنا ما تقر به أعيننا، واجعلنا قدوة لأهل التقوى.",
            contextEnglish: "A Qur'anic prayer for the goodness of spouses, children, and the example a family leaves. It asks Allah; it is not a guarantee of a particular marriage outcome.",
            contextArabic: "دعاء قرآني بصلاح الأزواج والذرية وبأن تكون الأسرة قدوة في التقوى. هو سؤال لله، وليس ضمانًا لنتيجة زوجية بعينها.",
            kind: .quranic,
            applicability: direct(
                "A direct Qur'anic supplication for spouses and offspring.",
                "دعاء قرآني مباشر للأزواج والذرية."
            ),
            source: quranSource(number: "25:74", url: "https://quran.com/25/74", textForm: .excerpt)
        ),
        GuidanceSupplication(
            id: "quran-guidance",
            titleEnglish: "For guidance",
            titleArabic: "دعاء الهداية",
            arabic: "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ",
            transliteration: "Ihdina-s-sirata-l-mustaqim.",
            meaningEnglish: "Guide us to the straight path.",
            meaningArabic: "دلنا وثبتنا على الطريق المستقيم.",
            contextEnglish: "The central request of al-Fatihah. It is fitting whenever the next faithful step is unclear.",
            contextArabic: "هو الطلب المحوري في سورة الفاتحة، ويُدعى به كلما خفيت الخطوة الأقوم.",
            kind: .quranic,
            applicability: direct(
                "A direct Qur'anic request for guidance.",
                "طلب قرآني مباشر للهداية."
            ),
            source: quranSource(number: "1:6", url: "https://quran.com/1/6", textForm: .complete)
        ),
        GuidanceSupplication(
            id: "quran-steadfast-hearts",
            titleEnglish: "For a heart that stays guided",
            titleArabic: "لثبات القلب على الهداية",
            arabic: "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ ٱلْوَهَّابُ",
            transliteration: "Rabbana la tuzigh qulubana ba'da idh hadaytana wa hab lana min ladunka rahmah; innaka Anta-l-Wahhab.",
            meaningEnglish: "Our Lord, do not let our hearts deviate after You have guided us. Grant us mercy from Yourself; You alone are the Great Giver.",
            meaningArabic: "يا ربنا، لا تمل قلوبنا عن الحق بعد هدايتك، وهب لنا رحمة من عندك؛ إنك كثير العطاء.",
            contextEnglish: "Ask for steadiness rather than assuming faith will remain strong without care, worship, and Allah's mercy.",
            contextArabic: "اسأل الثبات بدل أن تفترض بقاء الإيمان قويًا من غير تعاهد وعبادة ورحمة من الله.",
            kind: .quranic,
            applicability: direct(
                "A direct request for steadfastness after guidance.",
                "طلب مباشر للثبات بعد الهداية."
            ),
            source: quranSource(number: "3:8", url: "https://quran.com/3/8", textForm: .complete)
        ),
        GuidanceSupplication(
            id: "quran-righteous-offspring",
            titleEnglish: "For good offspring",
            titleArabic: "للذرية الطيبة",
            arabic: "رَبِّ هَبْ لِى مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً ۖ إِنَّكَ سَمِيعُ ٱلدُّعَآءِ",
            transliteration: "Rabbi hab li min ladunka dhurriyyatan tayyibah; innaka sami'u-d-du'a'.",
            meaningEnglish: "My Lord, grant me from Yourself good offspring. You are truly the Hearer of prayer.",
            meaningArabic: "يا رب، هب لي من عندك ذرية صالحة طيبة؛ إنك سميع الدعاء.",
            contextEnglish: "Zakariyya's Qur'anic prayer is appropriate while hoping for children. It does not promise a timeline or remove the legitimacy of medical care and grief support.",
            contextArabic: "دعاء زكريا القرآني مناسب عند رجاء الذرية، لكنه لا يَعِد بوقت محدد ولا يلغي مشروعية العلاج ودعم الحزن.",
            kind: .quranic,
            applicability: direct(
                "A direct Qur'anic request for good offspring.",
                "طلب قرآني مباشر للذرية الطيبة."
            ),
            source: quranSource(number: "3:38", url: "https://quran.com/3/38", textForm: .excerpt)
        ),
        GuidanceSupplication(
            id: "quran-repentance-adam",
            titleEnglish: "For forgiveness and mercy",
            titleArabic: "للمغفرة والرحمة",
            arabic: "رَبَّنَا ظَلَمْنَآ أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ ٱلْخَـٰسِرِينَ",
            transliteration: "Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakunanna mina-l-khasirin.",
            meaningEnglish: "Our Lord, we have wronged ourselves. If You do not forgive us and have mercy on us, we will surely be among the losers.",
            meaningArabic: "يا ربنا، ظلمنا أنفسنا، وإن لم تغفر لنا وترحمنا فسنكون من الخاسرين.",
            contextEnglish: "A complete model of repentance: honest responsibility, then hope in Allah's forgiveness and mercy.",
            contextArabic: "نموذج مكتمل للتوبة: اعتراف صادق بالمسؤولية، ثم رجاء مغفرة الله ورحمته.",
            kind: .quranic,
            applicability: direct(
                "A direct Qur'anic prayer of repentance.",
                "دعاء قرآني مباشر للتوبة."
            ),
            source: quranSource(number: "7:23", url: "https://quran.com/7/23", textForm: .excerpt)
        ),
        GuidanceSupplication(
            id: "quran-distress-yunus",
            titleEnglish: "In constriction and distress",
            titleArabic: "عند الكرب والضيق",
            arabic: "لَّآ إِلَـٰهَ إِلَّآ أَنتَ سُبْحَـٰنَكَ إِنِّى كُنتُ مِنَ ٱلظَّـٰلِمِينَ",
            transliteration: "La ilaha illa Anta, subhanaka, inni kuntu mina-z-zalimin.",
            meaningEnglish: "There is no god worthy of worship except You. Glory be to You; I have truly been among the wrongdoers.",
            meaningArabic: "لا معبود بحق إلا أنت، تنزهت عن كل نقص؛ إني كنت من الظالمين.",
            contextEnglish: "The prayer Yunus called with in the darkness: tawhid, glorification, and honest self-accounting. The displayed prayer is an excerpt from the ayah's narrative.",
            contextArabic: "هو نداء يونس في الظلمات: توحيد وتسبيح ومحاسبة صادقة للنفس. والدعاء المعروض مقتطف من سياق الآية.",
            kind: .quranic,
            applicability: supporting(
                "A Qur'anic supplication used in distress and when returning to Allah.",
                "دعاء قرآني عند الكرب والعودة إلى الله."
            ),
            source: quranSource(number: "21:87", url: "https://quran.com/21/87", textForm: .excerpt)
        ),
        GuidanceSupplication(
            id: "quran-gratitude-and-good-deeds",
            titleEnglish: "For gratitude that becomes action",
            titleArabic: "لشكر يتحول إلى عمل",
            arabic: "رَبِّ أَوْزِعْنِىٓ أَنْ أَشْكُرَ نِعْمَتَكَ ٱلَّتِىٓ أَنْعَمْتَ عَلَىَّ وَعَلَىٰ وَٰلِدَىَّ وَأَنْ أَعْمَلَ صَـٰلِحًا تَرْضَىٰهُ وَأَدْخِلْنِى بِرَحْمَتِكَ فِى عِبَادِكَ ٱلصَّـٰلِحِينَ",
            transliteration: "Rabbi awzi'ni an ashkura ni'mataka-llati an'amta 'alayya wa 'ala walidayya wa an a'mala salihan tardahu wa adkhilni bi-rahmatika fi 'ibadika-s-salihin.",
            meaningEnglish: "My Lord, inspire me to be grateful for Your favour upon me and my parents, to do good that pleases You, and admit me by Your mercy among Your righteous servants.",
            meaningArabic: "يا رب، ألهمني شكر نعمتك عليّ وعلى والديّ، ووفقني لعمل صالح ترضاه، وأدخلني برحمتك في عبادك الصالحين.",
            contextEnglish: "This prayer asks for more than a grateful feeling: awareness, action Allah accepts, and righteous company.",
            contextArabic: "لا يطلب الدعاء مجرد شعور بالشكر، بل وعيًا بالنعمة وعملًا يرضاه الله وصحبة للصالحين.",
            kind: .quranic,
            applicability: direct(
                "A direct Qur'anic request for gratitude and accepted action.",
                "طلب قرآني مباشر للشكر والعمل المقبول."
            ),
            source: quranSource(number: "27:19", url: "https://quran.com/27/19", textForm: .excerpt)
        ),
        GuidanceSupplication(
            id: "quran-need-any-good",
            titleEnglish: "In need of any good",
            titleArabic: "عند الافتقار إلى الخير",
            arabic: "رَبِّ إِنِّى لِمَآ أَنزَلْتَ إِلَىَّ مِنْ خَيْرٍ فَقِيرٌ",
            transliteration: "Rabbi inni lima anzalta ilayya min khayrin faqir.",
            meaningEnglish: "My Lord, I am truly in need of whatever good You send down to me.",
            meaningArabic: "يا رب، إني محتاج إلى كل خير تنزله إليّ.",
            contextEnglish: "Musa said this while exposed and in need after helping others. It is a broad prayer for Allah's good—not a text promising a spouse, job, or money on demand.",
            contextArabic: "قالها موسى وهو غريب محتاج بعد أن أعان غيره. هي دعاء عام بخير الله، وليست نصًا يضمن زوجًا أو وظيفة أو مالًا عند الطلب.",
            kind: .quranic,
            applicability: supporting(
                "A broad Qur'anic expression of need for whatever good Allah sends.",
                "تعبير قرآني عام عن الافتقار إلى كل خير ينزله الله."
            ),
            source: quranSource(number: "28:24", url: "https://quran.com/28/24", textForm: .excerpt),
            cautionEnglish: "Do not label this a guaranteed ‘du'a for marriage’ or ‘du'a for a job’; the ayah makes no such promise.",
            cautionArabic: "لا تُسمِّه دعاءً مضمونًا للزواج أو الوظيفة؛ فالآية لا تتضمن هذا الوعد."
        ),
        GuidanceSupplication(
            id: "quran-burdens-and-mercy",
            titleEnglish: "When the burden feels too heavy",
            titleArabic: "عندما يثقل الحمل",
            arabic: "رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعْفُ عَنَّا وَٱغْفِرْ لَنَا وَٱرْحَمْنَآ ۚ أَنتَ مَوْلَىٰنَا فَٱنصُرْنَا عَلَى ٱلْقَوْمِ ٱلْكَـٰفِرِينَ",
            transliteration: "Rabbana la tu'akhidhna in nasina aw akhta'na. Rabbana wa la tahmil 'alayna isran kama hamaltahu 'ala-lladhina min qablina. Rabbana wa la tuhammilna ma la taqata lana bih. Wa'fu 'anna, waghfir lana, warhamna. Anta mawlana fansurna 'ala-l-qawmi-l-kafirin.",
            meaningEnglish: "Our Lord, do not hold us to account if we forget or make a mistake. Do not place on us a burden like the one placed on those before us. Do not load us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our Protector, so grant us victory over the disbelieving people.",
            meaningArabic: "يا ربنا، لا تؤاخذنا إن نسينا أو أخطأنا، ولا تحمل علينا تكليفًا شاقًا كما حملته على من قبلنا، ولا تحملنا ما لا قدرة لنا عليه. واعف عنا واغفر لنا وارحمنا؛ أنت ولينا فانصرنا على القوم الكافرين.",
            contextEnglish: "The closing prayer of al-Baqarah names error, weight, pardon, forgiveness, mercy, and reliance. The displayed text is the supplication section of the longer ayah.",
            contextArabic: "يجمع ختام البقرة بين الخطأ والثقل والعفو والمغفرة والرحمة والاعتماد على الله. والنص المعروض هو فقرة الدعاء من آية أطول.",
            kind: .quranic,
            applicability: supporting(
                "A Qur'anic supplication for error, overwhelming burdens, mercy, and help.",
                "دعاء قرآني عند الخطأ وثقل الأعباء وطلب الرحمة والنصر."
            ),
            source: quranSource(number: "2:286", url: "https://quran.com/2/286", textForm: .excerpt)
        ),
        GuidanceSupplication(
            id: "prophetic-istikhara",
            titleEnglish: "Istikhara for a permissible decision",
            titleArabic: "دعاء الاستخارة في الأمر المباح",
            arabic: "اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ وَتَعْلَمُ وَلَا أَعْلَمُ وَأَنْتَ عَلَّامُ الْغُيُوبِ، اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي ـ أَوْ قَالَ عَاجِلِ أَمْرِي وَآجِلِهِ ـ فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي ـ أَوْ قَالَ فِي عَاجِلِ أَمْرِي وَآجِلِهِ ـ فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِي الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ",
            transliteration: "Allahumma inni astakhiruka bi'ilmika, wa astaqdiruka bi-qudratika, wa as'aluka min fadlika-l-'azim. Fa-innaka taqdiru wa la aqdir, wa ta'lamu wa la a'lam, wa Anta 'Allamu-l-ghuyub. Allahumma in kunta ta'lamu anna hadha-l-amra khayrun li fi dini wa ma'ashi wa 'aqibati amri—or 'ajili amri wa ajilihi—faqdurhu li wa yassirhu li, thumma barik li fih. Wa in kunta ta'lamu anna hadha-l-amra sharrun li fi dini wa ma'ashi wa 'aqibati amri—or fi 'ajili amri wa ajilihi—fasrifhu 'anni wasrifni 'anhu, waqdur li-l-khayra haythu kana, thumma ardini bih.",
            meaningEnglish: "O Allah, I seek the better choice through Your knowledge, seek ability through Your power, and ask You from Your immense favour. You are able and I am not; You know and I do not; You are the Knower of the unseen. O Allah, if You know this matter is good for me in my religion, livelihood, and outcome—or in its near and distant effects—decree it for me, make it easy, then bless it for me. If You know it is bad for me in my religion, livelihood, and outcome—or in its near and distant effects—turn it away from me and turn me away from it. Decree the good for me wherever it may be, then make me content with it.",
            meaningArabic: "اللهم إني أطلب منك اختيار الخير بعلمك، وأطلب القدرة بقدرتك، وأسألك من فضلك العظيم؛ فأنت تقدر ولا أقدر، وتعلم ولا أعلم، وأنت علام الغيوب. إن كان هذا الأمر خيرًا لي في ديني ومعاشي وعاقبتي، في عاجله وآجله، فاقدره لي ويسره وبارك لي فيه. وإن كان شرًا لي فاصرفه عني واصرفني عنه، واقدر لي الخير حيث كان ثم أرضني به.",
            contextEnglish: "For a genuinely permissible choice, pray two non-obligatory rak'ahs, say the du'a, and name the matter. Then use sound information, consultation, and responsible action. Istikhara does not require a dream and does not make an unsafe or forbidden option permissible.",
            contextArabic: "في قرار مباح حقًا، صل ركعتين من غير الفريضة، ثم ادع بهذا الدعاء وسمِّ حاجتك. وبعدها خذ بالمعلومات الصحيحة والمشاورة والأسباب المسؤولة. لا تشترط الاستخارة رؤيا، ولا تجعل الخيار المحرم أو غير الآمن مباحًا.",
            kind: .prophetic,
            applicability: direct(
                "Direct Prophetic guidance for seeking Allah's choice in a permissible decision.",
                "هدي نبوي مباشر لطلب اختيار الله في قرار مباح."
            ),
            source: hadithSource(
                id: "bukhari-1166", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "1166",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:1166", textForm: .excerpt
            ),
            cautionEnglish: "Do not use istikhara to bypass consent, safety checks, professional advice, or a clear religious prohibition.",
            cautionArabic: "لا تستخدم الاستخارة لتجاوز الرضا أو فحوص السلامة أو المشورة المتخصصة أو حكم شرعي واضح."
        ),
        GuidanceSupplication(
            id: "prophetic-wedding-blessing",
            titleEnglish: "A blessing for newlyweds",
            titleArabic: "التهنئة النبوية للمتزوج",
            arabic: "بَارَكَ اللَّهُ لَكَ وَبَارَكَ عَلَيْكَ وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ",
            transliteration: "Baraka-llahu laka, wa baraka 'alayka, wa jama'a baynakuma fi khayr.",
            meaningEnglish: "May Allah bless you, send blessing upon you, and unite you both in goodness.",
            meaningArabic: "بارك الله لك، وأنزل عليك البركة، وجمع بينكما في خير.",
            contextEnglish: "The Prophetic congratulations offered to someone who married—brief, warm, and centred on blessing and shared goodness.",
            contextArabic: "التهنئة النبوية لمن تزوج: موجزة دافئة، محورها البركة والخير المشترك.",
            kind: .prophetic,
            applicability: direct(
                "Directly narrated as a wedding blessing.",
                "ورد مباشرة تهنئةً عند الزواج."
            ),
            source: hadithSource(
                id: "abudawud-2130", collectionEnglish: "Sunan Abi Dawud",
                collectionArabic: "سنن أبي داود", number: "2130",
                gradeEnglish: "Sahih (Al-Albani)", gradeArabic: "صحيح (الألباني)",
                url: "https://sunnah.com/abudawud:2130", textForm: .excerpt
            )
        ),
        GuidanceSupplication(
            id: "prophetic-before-intimacy",
            titleEnglish: "Before marital intimacy",
            titleArabic: "قبل المعاشرة الزوجية",
            arabic: "بِسْمِ اللَّهِ، اللَّهُمَّ جَنِّبْنَا الشَّيْطَانَ وَجَنِّبِ الشَّيْطَانَ مَا رَزَقْتَنَا",
            transliteration: "Bismi-llah. Allahumma jannibna-sh-shaytana wa jannibi-sh-shaytana ma razaqtana.",
            meaningEnglish: "In the name of Allah. O Allah, keep Satan away from us and keep Satan away from whatever You grant us.",
            meaningArabic: "باسم الله. اللهم أبعد الشيطان عنا، وأبعده عما ترزقنا.",
            contextEnglish: "A private Prophetic remembrance before consensual marital intimacy. Consent, gentleness, privacy, and freedom from harm remain essential.",
            contextArabic: "ذكر نبوي خاص قبل معاشرة زوجية قائمة على الرضا. ويبقى الرضا والرفق والخصوصية والسلامة من الأذى أصولًا لازمة.",
            kind: .prophetic,
            applicability: direct(
                "Directly narrated for before marital intimacy.",
                "ورد مباشرة قبل المعاشرة الزوجية."
            ),
            source: hadithSource(
                id: "bukhari-141", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "141",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:141", textForm: .excerpt
            ),
            cautionEnglish: "A supplication never substitutes for consent. Sexual coercion is harm.",
            cautionArabic: "لا يغني الدعاء أبدًا عن الرضا. الإكراه الجنسي أذى."
        ),
        GuidanceSupplication(
            id: "prophetic-new-wife",
            titleEnglish: "A husband's prayer at the beginning of marriage",
            titleArabic: "دعاء الزوج في بداية الزواج",
            arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَهَا وَخَيْرَ مَا جَبَلْتَهَا عَلَيْهِ وَأَعُوذُ بِكَ مِنْ شَرِّهَا وَمِنْ شَرِّ مَا جَبَلْتَهَا عَلَيْهِ",
            transliteration: "Allahumma inni as'aluka khayraha wa khayra ma jabaltaha 'alayh, wa a'udhu bika min sharriha wa min sharri ma jabaltaha 'alayh.",
            meaningEnglish: "O Allah, I ask You for the good in her and the good You have formed in her, and I seek Your protection from the evil in her and the evil You have formed in her.",
            meaningArabic: "اللهم إني أسألك خيرها وخير ما فطرتها عليه، وأعوذ بك من شرها وشر ما فطرتها عليه.",
            contextEnglish: "This gender-specific narration teaches a husband to begin married life by asking Allah for good and protection. It is not a judgement that his wife is dangerous or morally suspect.",
            contextArabic: "هذا النص الخاص بالزوج يعلّمه أن يبدأ الحياة الزوجية بسؤال الخير والاستعاذة من الشر، وليس حكمًا على الزوجة بأنها موضع خطر أو اتهام.",
            kind: .prophetic,
            applicability: direct(
                "Directly narrated for a husband when beginning life with his wife.",
                "ورد مباشرة للزوج عند بدء حياته مع زوجته."
            ),
            source: hadithSource(
                id: "abudawud-2160", collectionEnglish: "Sunan Abi Dawud",
                collectionArabic: "سنن أبي داود", number: "2160",
                gradeEnglish: "Hasan (Al-Albani)", gradeArabic: "حسن (الألباني)",
                url: "https://sunnah.com/abudawud:2160", textForm: .excerpt
            )
        ),
        GuidanceSupplication(
            id: "prophetic-anxiety-and-debt",
            titleEnglish: "For anxiety, incapacity, and debt",
            titleArabic: "من الهم والعجز والدَّين",
            arabic: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ",
            transliteration: "Allahumma inni a'udhu bika mina-l-hammi wa-l-hazan, wa-l-'ajzi wa-l-kasal, wa-l-jubni wa-l-bukhl, wa dala'i-d-dayn, wa ghalabati-r-rijal.",
            meaningEnglish: "O Allah, I seek Your protection from anxiety and grief, incapacity and laziness, cowardice and miserliness, the crushing burden of debt, and being overpowered by people.",
            meaningArabic: "اللهم إني أستجير بك من الهم والحزن، والعجز والكسل، والجبن والبخل، وثقل الدَّين، وقهر الناس.",
            contextEnglish: "A Prophetic prayer that names emotional weight and material pressure together. Pair it with a realistic budget, creditor communication, and qualified financial or mental-health support where needed.",
            contextArabic: "دعاء نبوي يجمع ثقل النفس وضغط المال. اجمع معه ميزانية واقعية والتواصل مع الدائنين ودعمًا ماليًا أو نفسيًا مؤهلًا عند الحاجة.",
            kind: .prophetic,
            applicability: direct(
                "Directly seeks protection from anxiety, grief, incapacity, and oppressive debt.",
                "استعاذة مباشرة من الهم والحزن والعجز وثقل الدَّين."
            ),
            source: hadithSource(
                id: "bukhari-6369", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "6369",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:6369", textForm: .excerpt
            )
        ),
        GuidanceSupplication(
            id: "prophetic-calamity",
            titleEnglish: "When calamity strikes",
            titleArabic: "عند المصيبة",
            arabic: "إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ، اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا",
            transliteration: "Inna li-llahi wa inna ilayhi raji'un. Allahumma'jurni fi musibati wa akhlif li khayran minha.",
            meaningEnglish: "We belong to Allah, and to Him we return. O Allah, reward me in my calamity and replace it for me with something better.",
            meaningArabic: "إنا ملك لله وإليه عائدون. اللهم اكتب لي الأجر في مصيبتي، واخلف لي خيرًا منها.",
            contextEnglish: "Umm Salamah was taught these words in bereavement. ‘Better’ belongs to Allah's wisdom and may appear as faith, healing, protection, new good, or reward—not a forced timetable for grief.",
            contextArabic: "عُلّمت أم سلمة هذه الكلمات عند الفقد. والخير البديل إلى حكمة الله؛ قد يكون إيمانًا أو شفاءً أو حماية أو خيرًا جديدًا أو أجرًا، وليس جدولًا مفروضًا لانتهاء الحزن.",
            kind: .prophetic,
            applicability: direct(
                "Directly narrated for a person struck by calamity.",
                "ورد مباشرة لمن أصابته مصيبة."
            ),
            source: hadithSource(
                id: "muslim-918a", collectionEnglish: "Sahih Muslim",
                collectionArabic: "صحيح مسلم", number: "918a",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/muslim:918a", textForm: .excerpt
            )
        ),
        GuidanceSupplication(
            id: "prophetic-help-to-worship",
            titleEnglish: "For help in worship and gratitude",
            titleArabic: "للعون على الذكر والشكر والعبادة",
            arabic: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ",
            transliteration: "Allahumma a'inni 'ala dhikrika wa shukrika wa husni 'ibadatik.",
            meaningEnglish: "O Allah, help me to remember You, thank You, and worship You well.",
            meaningArabic: "اللهم أعنّي على ذكرك وشكرك وإحسان عبادتك.",
            contextEnglish: "The Prophet ﷺ taught Mu'adh to say this at the end of every prayer. It turns spiritual difficulty into a direct request for help.",
            contextArabic: "علّم النبي ﷺ معاذًا أن يقولها دبر كل صلاة. تحوّل صعوبة العبادة إلى سؤال مباشر للعون.",
            kind: .prophetic,
            applicability: direct(
                "Directly asks for help with remembrance, gratitude, and excellent worship.",
                "طلب مباشر للعون على الذكر والشكر وحسن العبادة."
            ),
            source: hadithSource(
                id: "abudawud-1522", collectionEnglish: "Sunan Abi Dawud",
                collectionArabic: "سنن أبي داود", number: "1522",
                gradeEnglish: "Sahih (Al-Albani)", gradeArabic: "صحيح (الألباني)",
                url: "https://sunnah.com/abudawud:1522", textForm: .excerpt
            )
        ),
        GuidanceSupplication(
            id: "prophetic-master-repentance",
            titleEnglish: "The foremost prayer for forgiveness",
            titleArabic: "سيد الاستغفار",
            arabic: "اللَّهُمَّ أَنْتَ رَبِّي، لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ لَكَ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
            transliteration: "Allahumma Anta Rabbi, la ilaha illa Anta. Khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't. A'udhu bika min sharri ma sana't. Abu'u laka bi-ni'matika 'alayya, wa abu'u laka bi-dhanbi, faghfir li, fa-innahu la yaghfiru-dh-dhunuba illa Anta.",
            meaningEnglish: "O Allah, You are my Lord; none is worthy of worship except You. You created me and I am Your servant. I hold to Your covenant and promise as much as I can. I seek Your protection from the evil of what I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me; no one forgives sins except You.",
            meaningArabic: "اللهم أنت ربي لا معبود بحق إلا أنت. خلقتني وأنا عبدك، وأنا متمسك بعهدك ووعدك قدر استطاعتي. أستجير بك من شر عملي، وأعترف بنعمتك عليّ وبذنبي، فاغفر لي؛ فلا يغفر الذنوب إلا أنت.",
            contextEnglish: "A morning-and-evening prayer of tawhid, gratitude, responsibility, and hope. Repentance also includes leaving the wrong, regretting it, resolving not to return, and restoring another person's rights where applicable.",
            contextArabic: "دعاء صباح ومساء يجمع التوحيد والشكر وتحمل المسؤولية والرجاء. وتشمل التوبة ترك الذنب والندم والعزم على عدم العودة ورد حقوق الناس عند تعلقها به.",
            kind: .prophetic,
            applicability: direct(
                "Directly narrated as the foremost formula for seeking forgiveness.",
                "ورد مباشرة بوصفه سيد صيغ الاستغفار."
            ),
            source: hadithSource(
                id: "bukhari-6306", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "6306",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:6306", textForm: .excerpt
            )
        ),
        GuidanceSupplication(
            id: "prophetic-anger-refuge",
            titleEnglish: "When anger rises",
            titleArabic: "عند اشتداد الغضب",
            arabic: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ",
            transliteration: "A'udhu bi-llahi mina-sh-shaytan.",
            meaningEnglish: "I seek Allah's protection from Satan.",
            meaningArabic: "أستجير بالله من الشيطان.",
            contextEnglish: "The Prophet ﷺ recommended these words when he saw anger overtaking a man. Say them, pause the exchange, and create physical distance if escalation is possible.",
            contextArabic: "أرشد النبي ﷺ إلى هذه الكلمات حين رأى الغضب يشتد برجل. قلها وأوقف الجدال وابتعد جسديًا إذا خفت التصعيد.",
            kind: .remembrance,
            applicability: direct(
                "Direct Prophetic remembrance for an episode of anger.",
                "ذكر نبوي مباشر عند نوبة الغضب."
            ),
            source: hadithSource(
                id: "bukhari-3282", collectionEnglish: "Sahih al-Bukhari",
                collectionArabic: "صحيح البخاري", number: "3282",
                gradeEnglish: "Sahih by collection", gradeArabic: "صحيح بإخراجه في الصحيح",
                url: "https://sunnah.com/bukhari:3282", textForm: .excerpt
            )
        ),
    ]

    // MARK: Safety and context notices

    static let safetyNotices: [GuidanceSafetyNotice] = [
        GuidanceSafetyNotice(
            id: "relationship-immediate-safety",
            kind: .immediateSafety,
            titleEnglish: "Safety comes before reconciliation",
            titleArabic: "السلامة قبل الصلح",
            messageEnglish: "If there is violence, coercive control, threats, sexual harm, stalking, or immediate danger, do not use mediation or forgiveness guidance as a substitute for safety. Contact local emergency services and a trusted domestic or family-violence specialist. If your device may be monitored, seek help from a safer device when possible.",
            messageArabic: "إذا وُجد عنف أو سيطرة قسرية أو تهديد أو أذى جنسي أو ملاحقة أو خطر مباشر، فلا تجعل إرشادات الصلح أو العفو بديلًا عن الأمان. تواصل مع خدمات الطوارئ المحلية وجهة موثوقة مختصة بالعنف الأسري. وإذا كان جهازك مراقبًا فاطلب المساعدة من جهاز أكثر أمانًا متى أمكن."
        ),
        GuidanceSafetyNotice(
            id: "relationship-qualified-support",
            kind: .specialistSupport,
            titleEnglish: "Choose support that screens for harm",
            titleArabic: "اختر دعمًا يتحرى عن الأذى",
            messageEnglish: "For repeated conflict without immediate danger, seek a qualified couples counsellor or trusted local scholar who understands safeguarding and speaks to each person privately before joint work. Joint counselling can increase risk where coercive control or abuse is present.",
            messageArabic: "عند تكرر الخلاف من غير خطر مباشر، اطلب مستشارًا أسريًا مؤهلًا أو عالمًا محليًا موثوقًا يفهم إجراءات الحماية ويتحدث مع كل طرف على انفراد قبل الجلسات المشتركة. فقد تزيد الجلسات المشتركة الخطر عند وجود سيطرة قسرية أو إساءة."
        ),
        GuidanceSafetyNotice(
            id: "separation-local-advice",
            kind: .legalAndScholarly,
            titleEnglish: "Separation needs local, qualified advice",
            titleArabic: "الفراق يحتاج إلى مشورة محلية مؤهلة",
            messageEnglish: "Divorce, khul', maintenance, custody, property, and waiting-period questions depend on facts and jurisdiction. Seek a qualified local scholar and, where relevant, a family lawyer. Do not rely on an app to determine rights, deadlines, or the validity of a divorce statement.",
            messageArabic: "تختلف مسائل الطلاق والخلع والنفقة والحضانة والممتلكات والعدّة باختلاف الوقائع والبلد. استشر عالمًا محليًا مؤهلًا ومحامي أسرة عند الحاجة، ولا تعتمد على تطبيق لتحديد الحقوق أو المهل أو صحة لفظ الطلاق."
        ),
        GuidanceSafetyNotice(
            id: "bereavement-support",
            kind: .specialistSupport,
            titleEnglish: "Grief has no forced timetable",
            titleArabic: "لا جدول قسري للحزن",
            messageEnglish: "Grief is not weak faith. Accept practical support, and seek a qualified health professional if sleep, eating, daily safety, or the ability to function remains severely affected. Seek urgent local help if you may harm yourself or cannot stay safe.",
            messageArabic: "الحزن ليس ضعفًا في الإيمان. اقبل الدعم العملي، واطلب مختصًا صحيًا إذا استمر اضطراب النوم أو الأكل أو السلامة اليومية أو القدرة على أداء شؤون الحياة بدرجة شديدة. واطلب مساعدة محلية عاجلة إذا خشيت أن تؤذي نفسك أو لم تستطع البقاء آمنًا."
        ),
    ]

    // MARK: Situation mappings

    /// Marriage is intentionally mapped situation by situation so the app does
    /// not flatten consent, tenderness, conflict, and separation into one mood.
    /// The remaining groups are also mapped where a more precise item exists;
    /// chapter fallbacks keep new catalog additions safely covered.
    private static let situationHadithIDs: [String: [String]] = [
        // Marriage — before
        "beforeMarriage": ["marry-when-able", "choose-religion"],
        "lookingForSpouse": ["marry-when-able", "choose-religion", "marriage-consent"],
        "choosingSpouse": ["choose-religion", "marriage-consent", "forced-marriage-rejected"],
        "waitingForTiming": ["practice-patience", "seek-what-benefits"],
        "worriedNeverMarry": ["practice-patience", "true-richness"],
        "strugglingPatience": ["practice-patience", "hardship-expiates"],

        // Marriage — growing together
        "peaceInMarriage": ["best-to-family", "do-not-despise-spouse", "gentleness"],
        "treatSpouseKindly": ["best-to-family", "gentleness"],
        "becomeBetterSpouse": ["best-to-family", "spending-on-family", "deeds-by-intentions"],
        "speakKindly": ["gentleness", "strength-at-anger"],
        "decidingTogether": ["gentleness", "seek-what-benefits"],
        "fairnessInMarriage": ["oppression-is-darkness", "best-to-family"],
        "rebuildingTrust": ["deeds-by-intentions", "gentleness", "oppression-is-darkness"],
        "duaForFamily": ["best-to-family", "spending-on-family"],
        "feelingDistant": ["do-not-despise-spouse", "gentleness"],

        // Marriage — hard seasons
        "marriageProblems": ["gentleness", "seek-what-benefits"],
        "constantlyArguing": ["strength-at-anger", "gentleness"],
        "spouseWrongedYou": ["oppression-is-darkness", "charity-pardon-humility"],
        "loweringAnger": ["strength-at-anger", "gentleness"],
        "forgivingSpouse": ["charity-pardon-humility", "oppression-is-darkness"],
        "temptedToDivorce": ["seek-what-benefits", "gentleness"],
        "marriageTested": ["hardship-expiates", "do-not-despise-spouse"],
        "afraidWontLast": ["practice-patience", "seek-what-benefits"],
        "questioningChoice": ["seek-what-benefits", "deeds-by-intentions"],
        "trustingPlan": ["seek-what-benefits", "practice-patience"],
        "trustingTiming": ["practice-patience", "seek-what-benefits"],
        "stayOrLeave": ["oppression-is-darkness", "seek-what-benefits"],

        // Family, separation, and bereavement
        "raisingChildren": ["best-to-family", "spending-on-family", "deeds-by-intentions"],
        "prayingForChildren": ["best-to-family", "deeds-by-intentions"],
        "infertility": ["practice-patience", "hardship-expiates"],
        "spouseAway": ["best-to-family", "hardship-expiates"],
        "divorceUnavoidable": ["oppression-is-darkness", "seek-what-benefits"],
        "afterDivorce": ["hardship-expiates", "seek-what-benefits"],
        "grievingSpouse": ["hardship-expiates", "practice-patience"],

        // Faith and worship
        "needGuidance": ["deeds-by-intentions", "seek-what-benefits"],
        "imanLow": ["allah-rejoices-at-repentance", "deeds-by-intentions"],
        "salahConnection": ["closest-in-prostration", "deeds-by-intentions"],
        "hardToPray": ["closest-in-prostration", "practice-patience"],
        "losingFocus": ["deeds-by-intentions", "seek-what-benefits"],
        "forgettingBlessings": ["true-richness", "hearts-and-deeds"],
        "strugglingGrateful": ["true-richness", "deeds-by-intentions"],
        "fightingTemptation": ["seek-what-benefits", "deeds-by-intentions"],
        "madeAMistake": ["allah-rejoices-at-repentance", "deeds-by-intentions"],
        "forgiveYourself": ["allah-rejoices-at-repentance", "hardship-expiates"],
        "sameSin": ["allah-rejoices-at-repentance", "seek-what-benefits"],
        "selfControl": ["strength-at-anger", "seek-what-benefits"],

        // Worry and hardship
        "scaredOfFuture": ["seek-what-benefits", "practice-patience"],
        "afraidOfFailure": ["seek-what-benefits", "deeds-by-intentions"],
        "worriedTomorrow": ["practice-patience", "true-richness"],
        "feelAlone": ["hardship-expiates", "closest-in-prostration"],
        "tooManyBurdens": ["hardship-expiates", "practice-patience"],
        "disappointed": ["seek-what-benefits", "hardship-expiates"],
        "movingOn": ["seek-what-benefits", "hardship-expiates"],
        "everyoneAhead": ["hearts-and-deeds", "true-richness"],
        "someoneHurtsYou": ["oppression-is-darkness", "charity-pardon-humility"],
        "needToForgive": ["charity-pardon-humility", "oppression-is-darkness"],
        "afraidPeopleThink": ["hearts-and-deeds", "deeds-by-intentions"],
        "feelingInsecure": ["hearts-and-deeds", "true-richness"],
        "facingRejection": ["hardship-expiates", "seek-what-benefits"],

        // Work and provision
        "worriedAboutRizq": ["true-richness", "work-of-ones-hands"],
        "strugglingFinancially": ["work-of-ones-hands", "hardship-expiates"],
        "hesitantCharity": ["charity-pardon-humility", "true-richness"],
        "comparingFinances": ["true-richness", "hearts-and-deeds"],
        "financialBurdens": ["hardship-expiates", "seek-what-benefits"],
        "moneyStress": ["true-richness", "seek-what-benefits"],
        "afraidToSpend": ["true-richness", "seek-what-benefits"],
        "tomorrowRizq": ["practice-patience", "true-richness"],
        "workNoResults": ["work-of-ones-hands", "seek-what-benefits"],
        "heartAttachedMoney": ["true-richness", "hearts-and-deeds"],
        "barakahInWealth": ["spending-on-family", "charity-pardon-humility"],
        "provisionDelayed": ["practice-patience", "work-of-ones-hands"],
        "salaryNotEnough": ["work-of-ones-hands", "spending-on-family"],
        "scaredStartBusiness": ["seek-what-benefits", "deeds-by-intentions"],
        "stuckFinancially": ["seek-what-benefits", "work-of-ones-hands"],
        "jealousOfSuccess": ["true-richness", "hearts-and-deeds"],
        "providingForFamily": ["spending-on-family", "work-of-ones-hands"],
        "afraidToRisk": ["seek-what-benefits", "deeds-by-intentions"],
        "majorFinancialDecision": ["seek-what-benefits", "deeds-by-intentions"],
        "impatientForResults": ["practice-patience", "work-of-ones-hands"],
        "everyoneAheadDuha": ["true-richness", "work-of-ones-hands"],
        "payingBills": ["spending-on-family", "work-of-ones-hands"],
        "stressedAboutDebt": ["hardship-expiates", "seek-what-benefits"],
        "losingJob": ["seek-what-benefits", "hardship-expiates"],
        "savingsLow": ["true-richness", "seek-what-benefits"],
    ]

    private static let situationSupplicationIDs: [String: [String]] = [
        // Marriage — before
        "beforeMarriage": ["quran-family-comfort", "prophetic-istikhara", "quran-need-any-good"],
        "lookingForSpouse": ["prophetic-istikhara", "quran-family-comfort", "quran-need-any-good"],
        "choosingSpouse": ["prophetic-istikhara", "quran-guidance"],
        "waitingForTiming": ["quran-need-any-good", "quran-steadfast-hearts"],
        "worriedNeverMarry": ["quran-need-any-good", "quran-family-comfort"],
        "strugglingPatience": ["quran-burdens-and-mercy", "prophetic-help-to-worship"],

        // Marriage — growing together
        "peaceInMarriage": ["quran-family-comfort", "prophetic-help-to-worship"],
        "treatSpouseKindly": ["quran-family-comfort", "prophetic-help-to-worship"],
        "becomeBetterSpouse": ["quran-family-comfort", "prophetic-help-to-worship"],
        "speakKindly": ["prophetic-anger-refuge", "quran-family-comfort"],
        "decidingTogether": ["prophetic-istikhara", "quran-guidance"],
        "fairnessInMarriage": ["quran-guidance", "quran-family-comfort"],
        "rebuildingTrust": ["quran-repentance-adam", "quran-family-comfort"],
        "duaForFamily": ["quran-family-comfort", "prophetic-help-to-worship"],
        "feelingDistant": ["quran-family-comfort", "quran-steadfast-hearts"],

        // Marriage — hard seasons
        "marriageProblems": ["quran-family-comfort", "prophetic-istikhara"],
        "constantlyArguing": ["prophetic-anger-refuge", "quran-family-comfort"],
        "spouseWrongedYou": ["quran-distress-yunus", "quran-burdens-and-mercy"],
        "loweringAnger": ["prophetic-anger-refuge", "prophetic-help-to-worship"],
        "forgivingSpouse": ["quran-burdens-and-mercy", "quran-guidance"],
        "temptedToDivorce": ["prophetic-istikhara", "quran-family-comfort"],
        "marriageTested": ["quran-burdens-and-mercy", "quran-family-comfort"],
        "afraidWontLast": ["quran-family-comfort", "prophetic-anxiety-and-debt"],
        "questioningChoice": ["prophetic-istikhara", "quran-guidance"],
        "trustingPlan": ["prophetic-istikhara", "quran-need-any-good"],
        "trustingTiming": ["quran-need-any-good", "quran-steadfast-hearts"],
        "stayOrLeave": ["prophetic-istikhara", "quran-guidance"],

        // Family, separation, and bereavement
        "raisingChildren": ["quran-family-comfort", "prophetic-help-to-worship"],
        "prayingForChildren": ["quran-righteous-offspring", "quran-family-comfort"],
        "infertility": ["quran-righteous-offspring", "quran-burdens-and-mercy"],
        "spouseAway": ["quran-family-comfort", "prophetic-anxiety-and-debt"],
        "divorceUnavoidable": ["prophetic-istikhara", "quran-burdens-and-mercy"],
        "afterDivorce": ["prophetic-calamity", "quran-burdens-and-mercy"],
        "grievingSpouse": ["prophetic-calamity", "quran-burdens-and-mercy"],

        // Faith and worship
        "needGuidance": ["quran-guidance", "prophetic-istikhara"],
        "imanLow": ["quran-steadfast-hearts", "prophetic-help-to-worship"],
        "salahConnection": ["prophetic-help-to-worship", "quran-guidance"],
        "hardToPray": ["prophetic-help-to-worship", "quran-steadfast-hearts"],
        "losingFocus": ["prophetic-help-to-worship", "quran-guidance"],
        "forgettingBlessings": ["quran-gratitude-and-good-deeds", "prophetic-help-to-worship"],
        "strugglingGrateful": ["quran-gratitude-and-good-deeds", "prophetic-help-to-worship"],
        "fightingTemptation": ["quran-steadfast-hearts", "quran-repentance-adam"],
        "madeAMistake": ["quran-repentance-adam", "prophetic-master-repentance"],
        "forgiveYourself": ["prophetic-master-repentance", "quran-repentance-adam"],
        "sameSin": ["prophetic-master-repentance", "quran-steadfast-hearts"],
        "selfControl": ["prophetic-help-to-worship", "quran-steadfast-hearts"],

        // Worry and hardship
        "scaredOfFuture": ["prophetic-anxiety-and-debt", "quran-burdens-and-mercy"],
        "afraidOfFailure": ["prophetic-istikhara", "quran-burdens-and-mercy"],
        "worriedTomorrow": ["prophetic-anxiety-and-debt", "quran-need-any-good"],
        "feelAlone": ["quran-burdens-and-mercy", "quran-guidance"],
        "tooManyBurdens": ["quran-burdens-and-mercy", "prophetic-anxiety-and-debt"],
        "disappointed": ["prophetic-calamity", "quran-burdens-and-mercy"],
        "movingOn": ["prophetic-calamity", "quran-guidance"],
        "everyoneAhead": ["quran-gratitude-and-good-deeds", "quran-guidance"],
        "someoneHurtsYou": ["quran-burdens-and-mercy", "quran-distress-yunus"],
        "needToForgive": ["quran-burdens-and-mercy", "quran-guidance"],
        "afraidPeopleThink": ["quran-guidance", "quran-steadfast-hearts"],
        "feelingInsecure": ["quran-guidance", "quran-gratitude-and-good-deeds"],
        "facingRejection": ["prophetic-calamity", "quran-need-any-good"],

        // Work and provision
        "worriedAboutRizq": ["quran-need-any-good", "prophetic-anxiety-and-debt"],
        "strugglingFinancially": ["quran-need-any-good", "prophetic-anxiety-and-debt"],
        "hesitantCharity": ["quran-gratitude-and-good-deeds", "quran-need-any-good"],
        "comparingFinances": ["quran-gratitude-and-good-deeds", "quran-guidance"],
        "financialBurdens": ["prophetic-anxiety-and-debt", "quran-burdens-and-mercy"],
        "moneyStress": ["prophetic-anxiety-and-debt", "quran-need-any-good"],
        "afraidToSpend": ["prophetic-istikhara", "quran-guidance"],
        "tomorrowRizq": ["quran-need-any-good", "prophetic-anxiety-and-debt"],
        "workNoResults": ["quran-need-any-good", "quran-burdens-and-mercy"],
        "heartAttachedMoney": ["quran-gratitude-and-good-deeds", "quran-guidance"],
        "barakahInWealth": ["quran-gratitude-and-good-deeds", "quran-family-comfort"],
        "provisionDelayed": ["quran-need-any-good", "quran-burdens-and-mercy"],
        "salaryNotEnough": ["prophetic-anxiety-and-debt", "quran-need-any-good"],
        "scaredStartBusiness": ["prophetic-istikhara", "quran-need-any-good"],
        "stuckFinancially": ["prophetic-anxiety-and-debt", "quran-burdens-and-mercy"],
        "jealousOfSuccess": ["quran-gratitude-and-good-deeds", "quran-steadfast-hearts"],
        "providingForFamily": ["quran-family-comfort", "quran-need-any-good"],
        "afraidToRisk": ["prophetic-istikhara", "quran-guidance"],
        "majorFinancialDecision": ["prophetic-istikhara", "quran-guidance"],
        "impatientForResults": ["quran-burdens-and-mercy", "quran-need-any-good"],
        "everyoneAheadDuha": ["quran-gratitude-and-good-deeds", "quran-need-any-good"],
        "payingBills": ["prophetic-anxiety-and-debt", "quran-need-any-good"],
        "stressedAboutDebt": ["prophetic-anxiety-and-debt", "quran-burdens-and-mercy"],
        "losingJob": ["prophetic-calamity", "quran-need-any-good"],
        "savingsLow": ["prophetic-anxiety-and-debt", "quran-need-any-good"],
    ]

    private static let situationSafetyNoticeIDs: [String: [String]] = [
        "rebuildingTrust": ["relationship-immediate-safety", "relationship-qualified-support"],
        "marriageProblems": ["relationship-immediate-safety", "relationship-qualified-support"],
        "constantlyArguing": ["relationship-immediate-safety", "relationship-qualified-support"],
        "spouseWrongedYou": ["relationship-immediate-safety"],
        "forgivingSpouse": ["relationship-immediate-safety"],
        "temptedToDivorce": ["relationship-qualified-support", "separation-local-advice"],
        "marriageTested": ["relationship-immediate-safety", "relationship-qualified-support"],
        "afraidWontLast": ["relationship-qualified-support"],
        "questioningChoice": ["relationship-qualified-support"],
        "stayOrLeave": ["relationship-immediate-safety", "separation-local-advice"],
        "divorceUnavoidable": ["relationship-immediate-safety", "separation-local-advice"],
        "afterDivorce": ["separation-local-advice"],
        "grievingSpouse": ["bereavement-support"],
    ]

    private static let chapterHadithFallbacks: [ChapterID: [String]] = [
        .search: ["marry-when-able", "practice-patience"],
        .bond: ["best-to-family", "gentleness"],
        .storm: ["gentleness", "strength-at-anger"],
        .family: ["best-to-family", "hardship-expiates"],
        .heart: ["deeds-by-intentions", "closest-in-prostration"],
        .trials: ["hardship-expiates", "seek-what-benefits"],
        .provision: ["true-richness", "work-of-ones-hands"],
    ]

    private static let chapterSupplicationFallbacks: [ChapterID: [String]] = [
        .search: ["quran-family-comfort", "quran-need-any-good"],
        .bond: ["quran-family-comfort", "prophetic-help-to-worship"],
        .storm: ["quran-family-comfort", "prophetic-istikhara"],
        .family: ["quran-family-comfort", "quran-burdens-and-mercy"],
        .heart: ["prophetic-help-to-worship", "quran-guidance"],
        .trials: ["quran-burdens-and-mercy", "prophetic-anxiety-and-debt"],
        .provision: ["quran-need-any-good", "prophetic-anxiety-and-debt"],
    ]

    // MARK: Indexes and construction helpers

    private static let hadithByID = Dictionary(uniqueKeysWithValues: hadiths.map { ($0.id, $0) })
    private static let supplicationByID = Dictionary(uniqueKeysWithValues: supplications.map { ($0.id, $0) })
    private static let safetyNoticeByID = Dictionary(uniqueKeysWithValues: safetyNotices.map { ($0.id, $0) })

    private static func direct(_ english: String, _ arabic: String) -> GuidanceApplicabilityMetadata {
        GuidanceApplicabilityMetadata(
            level: .direct,
            explanationEnglish: english,
            explanationArabic: arabic
        )
    }

    private static func supporting(_ english: String, _ arabic: String) -> GuidanceApplicabilityMetadata {
        GuidanceApplicabilityMetadata(
            level: .supportingPrinciple,
            explanationEnglish: english,
            explanationArabic: arabic
        )
    }

    private static func quranSource(
        number: String,
        url: String,
        textForm: GuidanceTextForm
    ) -> GuidanceSourceMetadata {
        GuidanceSourceMetadata(
            id: "quran-\(number)",
            kind: .quran,
            collectionEnglish: "The Qur'an",
            collectionArabic: "القرآن الكريم",
            number: number,
            gradeEnglish: "Qur'an",
            gradeArabic: "قرآن كريم",
            canonicalURL: url,
            textForm: textForm
        )
    }

    private static func hadithSource(
        id: String,
        collectionEnglish: String,
        collectionArabic: String,
        number: String,
        gradeEnglish: String,
        gradeArabic: String,
        url: String,
        textForm: GuidanceTextForm = .complete
    ) -> GuidanceSourceMetadata {
        GuidanceSourceMetadata(
            id: id,
            kind: .hadith,
            collectionEnglish: collectionEnglish,
            collectionArabic: collectionArabic,
            number: number,
            gradeEnglish: gradeEnglish,
            gradeArabic: gradeArabic,
            canonicalURL: url,
            textForm: textForm
        )
    }

    private static func unique<T: Identifiable & Hashable>(_ values: [T]) -> [T] {
        var seen = Set<T.ID>()
        return values.filter { seen.insert($0.id).inserted }
    }

    private static func duplicateIDs(in ids: [String], label: String) -> [String] {
        var seen = Set<String>()
        var duplicates = Set<String>()
        for id in ids where !seen.insert(id).inserted {
            duplicates.insert(id)
        }
        return duplicates.sorted().map { "Duplicate \(label) id: \($0)" }
    }
}
