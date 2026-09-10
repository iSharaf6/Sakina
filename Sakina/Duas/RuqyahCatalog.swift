import Foundation

// MARK: - Ruqyah catalog
//
// Qur'an passages come from the bundled `ruqyah.json`, produced by
// scratchpad/gen/fetch_ruqyah.py from Quran.com API v4 (Uthmani script,
// Saheeh International). Hadith Arabic below was copied character for
// character from the cited sunnah.com pages. Do not edit Arabic by hand.

enum RuqyahCatalog {

    // MARK: Passages

    struct Ayah: Codable, Hashable, Sendable {
        let key: String
        let arabic: String
        let translation: String

        var number: Int { Int(key.split(separator: ":").last ?? "") ?? 0 }
    }

    struct Passage: Codable, Identifiable, Hashable, Sendable {
        let id: String
        let surah: Int
        let surahName: String
        let surahNameArabic: String
        let from: Int
        let to: Int
        let titleEnglish: String
        let titleArabic: String
        let ayat: [Ayah]

        /// "2:255-257" or "20:69".
        var reference: String { from == to ? "\(surah):\(from)" : "\(surah):\(from)-\(to)" }

        /// "سورة البقرة ٢٥٥–٢٥٧"
        var referenceArabic: String {
            let range = from == to ? arabicDigits(from) : "\(arabicDigits(from))–\(arabicDigits(to))"
            return "سورة \(surahNameArabic) \(range)"
        }

        var canonicalURL: String {
            from == to ? "https://quran.com/\(surah)/\(from)" : "https://quran.com/\(surah)/\(from)-\(to)"
        }
    }

    private struct File: Codable {
        let source: String
        let passages: [Passage]
    }

    /// Loaded once from the bundle, mirroring `VerseStore`.
    static let passages: [Passage] = {
        guard let url = Bundle.main.url(forResource: "ruqyah", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            assertionFailure("ruqyah.json missing from bundle")
            return []
        }
        return file.passages
    }()

    // MARK: Qur'an

    static let quran: [GuidanceSupplication] = passages.map(supplication)

    private static func supplication(_ passage: Passage) -> GuidanceSupplication {
        let context = contexts[passage.id] ?? defaultContext
        let meaning = passage.ayat.map { "(\($0.number)) \($0.translation)" }.joined(separator: " ")
        return GuidanceSupplication(
            id: passage.id,
            titleEnglish: passage.titleEnglish,
            titleArabic: passage.titleArabic,
            arabic: passage.ayat.map(\.arabic).joined(separator: " "),
            transliteration: "",
            meaningEnglish: meaning,
            meaningArabic: "\(passage.titleArabic) · \(passage.referenceArabic)",
            contextEnglish: context.english,
            contextArabic: context.arabic,
            kind: .quranic,
            applicability: .init(level: .direct, explanationEnglish: context.english, explanationArabic: context.arabic),
            source: .init(id: "ruqyah-\(passage.id)", kind: .quran, collectionEnglish: "The Qur’an", collectionArabic: "القرآن الكريم",
                          number: passage.reference, gradeEnglish: "Qur’an", gradeArabic: "قرآن",
                          canonicalURL: passage.canonicalURL, textForm: .complete),
            cautionEnglish: medicalCaution.english,
            cautionArabic: medicalCaution.arabic
        )
    }

    private static let medicalCaution = (
        english: "Ruqyah is du’a. It accompanies medical care and never replaces it; do not delay urgent treatment.",
        arabic: "الرقية دعاء، تصاحب العلاج الطبي ولا تغني عنه؛ لا تؤخر العلاج العاجل."
    )

    private static let defaultContext = (
        english: "A passage widely read in ruqyah. The Qur’an describes itself as a healing and a mercy for the believers (17:82); recite it clearly and with conviction over yourself or the person who is unwell.",
        arabic: "مقطع يُقرأ كثيرًا في الرقية. وصف القرآن نفسه بأنه شفاء ورحمة للمؤمنين (الإسراء ٨٢)؛ اقرأه بوضوح ويقين على نفسك أو على المريض."
    )

    /// Why each passage is read in ruqyah. Editorial, citing only well-known reports.
    private static let contexts: [String: (english: String, arabic: String)] = [
        "ruqyah-quran-1-1-7": (
            "Companions treated a man bitten by a scorpion by reciting al-Fatihah over him, and the Prophet ﷺ approved, asking how they knew it was a ruqyah (Sahih al-Bukhari 5736). It opens almost every ruqyah.",
            "رقى الصحابة رجلًا لُدغ بقراءة الفاتحة عليه فأقرّهم النبي ﷺ وقال: وما أدراك أنها رقية؟ (صحيح البخاري ٥٧٣٦). تُفتتح بها الرقية غالبًا."
        ),
        "ruqyah-quran-2-1-5": (
            "The opening of al-Baqarah affirms the Book, guidance and the unseen. The Prophet ﷺ said that Shaytan flees from a house in which al-Baqarah is recited (Sahih Muslim 780), so its opening, its heart and its close are read together in ruqyah.",
            "تفتتح البقرة بتثبيت الكتاب والهدى والإيمان بالغيب. أخبر النبي ﷺ أن الشيطان ينفر من البيت الذي تُقرأ فيه سورة البقرة (صحيح مسلم ٧٨٠)، فتُقرأ فاتحتها وقلبها وخاتمتها معًا في الرقية."
        ),
        "ruqyah-quran-2-102": (
            "This ayah recounts the origin of magic taught in Babylon and states plainly that magicians harm no one except by Allah’s permission. It is read in ruqyah against sihr because it names the thing and strips it of any power of its own.",
            "تروي هذه الآية أصل السحر الذي عُلِّم ببابل، وتقرر أن السحرة لا يضرون أحدًا إلا بإذن الله. تُقرأ في الرقية من السحر لأنها تسميه وتنزع عنه كل قدرة ذاتية."
        ),
        "ruqyah-quran-2-163-164": (
            "A declaration of Allah’s oneness followed by His signs in creation. Read in ruqyah to fill the heart with tawhid, the foundation on which every protection rests.",
            "إعلان لوحدانية الله يتبعه ذكر آياته في الخلق. يُقرأ في الرقية ليملأ القلب بالتوحيد الذي تقوم عليه كل حماية."
        ),
        "ruqyah-quran-2-255-257": (
            "Abu Hurayrah was told that whoever recites Ayat al-Kursi before sleeping has a guardian from Allah and no devil approaches him until morning; the Prophet ﷺ confirmed it (Sahih al-Bukhari 2311). The two ayat after it declare that Allah is the protector of those who believe.",
            "قيل لأبي هريرة: من قرأ آية الكرسي عند النوم لم يزل عليه من الله حافظ ولا يقربه شيطان حتى يصبح، فصدّقه النبي ﷺ (صحيح البخاري ٢٣١١). والآيتان بعدها تقرران أن الله ولي الذين آمنوا."
        ),
        "ruqyah-quran-2-284-286": (
            "The Prophet ﷺ said that whoever recites the last two ayat of al-Baqarah at night, they suffice him (Sahih al-Bukhari 5009). They end with a du’a for pardon, forgiveness, mercy and help.",
            "قال النبي ﷺ: من قرأ بالآيتين من آخر سورة البقرة في ليلة كفتاه (صحيح البخاري ٥٠٠٩). وتُختم بدعاء بالعفو والمغفرة والرحمة والنصر."
        ),
        "ruqyah-quran-3-18-19": (
            "Allah, the angels and people of knowledge bear witness that there is no god but Him. Read in ruqyah as a testimony of tawhid over the person being treated.",
            "شهادة من الله والملائكة وأولي العلم أنه لا إله إلا هو. تُقرأ في الرقية شهادةً بالتوحيد على المرقي."
        ),
        "ruqyah-quran-7-54-56": (
            "Creation, command and all of it belong to Allah alone, who then invites us to call on Him humbly and in secret. Read in ruqyah to remind the heart Who holds every cause.",
            "الخلق والأمر كله لله وحده، ثم يدعونا أن ندعوه تضرعًا وخفية. تُقرأ في الرقية لتذكير القلب بمن بيده كل سبب."
        ),
        "ruqyah-quran-7-117-122": (
            "Musa’s staff swallows what the magicians had faked, the truth is established and the magicians themselves fall in prostration. Read in ruqyah against magic because it shows sihr undone before Allah’s command.",
            "تلقف عصا موسى ما زوّره السحرة، فيثبت الحق ويخر السحرة أنفسهم ساجدين. تُقرأ في الرقية من السحر لأنها تصور بطلان السحر أمام أمر الله."
        ),
        "ruqyah-quran-10-81-82": (
            "Musa tells the magicians: what you have brought is magic; Allah will make it void, for Allah does not set right the work of corrupters. Read in ruqyah against sihr for that plain statement.",
            "يقول موسى للسحرة: ما جئتم به السحر، إن الله سيبطله، إن الله لا يصلح عمل المفسدين. تُقرأ في الرقية من السحر لهذا التقرير الصريح."
        ),
        "ruqyah-quran-20-69": (
            "\"Throw what is in your right hand; it will swallow up what they have crafted. What they have crafted is but the trick of a magician, and the magician does not succeed wherever he is.\" One ayah that those who perform ruqyah read often against magic.",
            "﴿وألق ما في يمينك تلقف ما صنعوا﴾، فما صنعوه كيد ساحر، ولا يفلح الساحر حيث أتى. آية واحدة يكثر الرقاة من قراءتها ضد السحر."
        ),
        "ruqyah-quran-23-115-118": (
            "\"Did you think We created you in vain?\" The passage exalts Allah the true King, warns whoever calls on another god, and closes with a du’a for forgiveness and mercy. Read in ruqyah as an address to whatever may be harming the person.",
            "﴿أفحسبتم أنما خلقناكم عبثًا﴾. يعظم المقطع الله الملك الحق، ويتوعد من يدعو إلهًا آخر، ويُختم بدعاء بالمغفرة والرحمة. يُقرأ في الرقية خطابًا لما قد يؤذي الإنسان."
        ),
        "ruqyah-quran-37-1-10": (
            "The opening of as-Saffat describes how the lowest heaven is guarded against every rebellious devil, who is pelted and driven away. Read in ruqyah for that description of the devils’ defeat.",
            "تصف فاتحة الصافات حفظ السماء الدنيا من كل شيطان مارد يُقذف ويُدحر. تُقرأ في الرقية لما فيها من وصف هزيمة الشياطين."
        ),
        "ruqyah-quran-46-29-32": (
            "A group of jinn listened to the Qur’an, believed, and went back to warn their people. Read in ruqyah because it addresses the jinn directly with the call to answer Allah’s caller.",
            "استمع نفر من الجن إلى القرآن فآمنوا ورجعوا إلى قومهم منذرين. تُقرأ في الرقية لأنها تخاطب الجن مباشرة بدعوة إجابة داعي الله."
        ),
        "ruqyah-quran-55-33-36": (
            "Allah challenges the jinn and mankind: you cannot pass beyond the heavens and the earth except by His authority, and a flame of fire will be sent against you. Read in ruqyah as a warning to any jinn.",
            "يتحدى الله الجن والإنس: لا تنفذون من أقطار السماوات والأرض إلا بسلطان، ويُرسل عليكم شواظ من نار. تُقرأ في الرقية تهديدًا لأي جني."
        ),
        "ruqyah-quran-59-21-24": (
            "Had the Qur’an been sent down on a mountain it would have crumbled from awe of Allah. The close of al-Hashr then lists His most beautiful names. Read in ruqyah for the weight of the Qur’an and the majesty of the One it describes.",
            "لو أُنزل القرآن على جبل لتصدع من خشية الله. ثم تسرد خاتمة الحشر أسماءه الحسنى. تُقرأ في الرقية لعظمة القرآن وجلال من يصفه."
        ),
        "ruqyah-quran-72-1-9": (
            "The jinn themselves testify that they heard a wondrous Qur’an, that Allah has neither wife nor child, and that the heavens are now guarded from them. Read in ruqyah as testimony from the jinn against any who would harm.",
            "يشهد الجن أنفسهم أنهم سمعوا قرآنًا عجبًا، وأن الله لم يتخذ صاحبة ولا ولدًا، وأن السماء صارت محروسة منهم. تُقرأ في الرقية شهادةً من الجن على من يؤذي."
        ),
        "ruqyah-quran-112-1-4": (
            "When the Prophet ﷺ was unwell he would recite the Mu‘awwidhat over himself and blow into his hands (Sahih al-Bukhari 5016). Al-Ikhlas states the pure oneness of Allah in four ayat.",
            "كان النبي ﷺ إذا اشتكى قرأ على نفسه بالمعوذات ونفث (صحيح البخاري ٥٠١٦). وتقرر الإخلاص توحيد الله الخالص في أربع آيات."
        ),
        "ruqyah-quran-113-1-5": (
            "Refuge in the Lord of daybreak from the evil of what He created, from darkness, from those who blow on knots, and from the envier. ‘A’ishah reports that the Prophet ﷺ recited the Mu‘awwidhat over himself when ill (Sahih al-Bukhari 5016).",
            "استعاذة برب الفلق من شر ما خلق، ومن الغاسق، ومن النفاثات في العقد، ومن الحاسد. تروي عائشة أن النبي ﷺ كان يقرأ على نفسه بالمعوذات إذا اشتكى (صحيح البخاري ٥٠١٦)."
        ),
        "ruqyah-quran-114-1-6": (
            "Refuge in the Lord, King and God of mankind from the retreating whisperer, from jinn and from people. With al-Falaq it is the Prophet’s ﷺ own ruqyah for himself (Sahih al-Bukhari 5016) and the usual close of a ruqyah.",
            "استعاذة برب الناس ملك الناس إله الناس من شر الوسواس الخناس، من الجنة والناس. وهي مع الفلق رقية النبي ﷺ لنفسه (صحيح البخاري ٥٠١٦)، وبها تُختم الرقية عادة."
        ),
    ]

    // MARK: Sunnah

    /// Prophetic ruqyah already in the library, in reading order.
    private static let libraryIDs = [
        "healing-jibril-ruqyah", "healing-lord-of-people", "healing-hand-on-the-pain",
        "healing-visiting-the-sick", "healing-no-harm-purification", "healing-wellbeing-in-body",
    ]

    static let sunnah: [GuidanceSupplication] = libraryIDs.compactMap(DuaCollection.dua) + added

    /// New Sunnah entries not in DuaLibrary; DuaCollection merges these so they can be saved and searched.
    static let added: [GuidanceSupplication] = [
        GuidanceSupplication(
            id: "ruqyah-sunnah-bukhari-3371",
            titleEnglish: "The words Ibrahim used for his sons",
            titleArabic: "تعويذ إبراهيم لابنيه",
            arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ، وَمِنْ كُلِّ عَيْنٍ لاَمَّةٍ",
            transliteration: "A‘udhu bi-kalimati-llahi-t-tammati min kulli shaytanin wa hammah, wa min kulli ‘aynin lammah.",
            meaningEnglish: "I seek refuge in the perfect words of Allah from every devil and every poisonous creature, and from every harmful envious eye.",
            meaningArabic: "أستجير بكلمات الله الكاملة من كل شيطان وكل دابة سامة، ومن كل عين تصيب بسوء.",
            contextEnglish: "Ibn ‘Abbas reports that the Prophet ﷺ would seek protection for al-Hasan and al-Husayn with these words, saying that Ibrahim had used them for Isma‘il and Ishaq. Say them over children and over anyone you fear for from the evil eye.",
            contextArabic: "يروي ابن عباس أن النبي ﷺ كان يعوّذ الحسن والحسين بهذه الكلمات ويقول إن إبراهيم كان يعوّذ بها إسماعيل وإسحاق. تُقال على الأطفال وعلى من تخشى عليه العين.",
            kind: .prophetic,
            applicability: .init(level: .direct,
                                 explanationEnglish: "The narration itself describes the Prophet ﷺ using these words as protection for children.",
                                 explanationArabic: "تصف الرواية نفسها استعمال النبي ﷺ لهذه الكلمات تعويذًا للأطفال."),
            source: .init(id: "ruqyah-sunnah-bukhari-3371", kind: .hadith, collectionEnglish: "Sahih al-Bukhari", collectionArabic: "صحيح البخاري",
                          number: "3371", gradeEnglish: "Sahih", gradeArabic: "صحيح",
                          canonicalURL: "https://sunnah.com/bukhari:3371", textForm: .excerpt),
            cautionEnglish: medicalCaution.english,
            cautionArabic: medicalCaution.arabic
        ),
        GuidanceSupplication(
            id: "ruqyah-sunnah-muslim-2708a",
            titleEnglish: "Refuge in the perfect words of Allah",
            titleArabic: "أعوذ بكلمات الله التامات",
            arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
            transliteration: "A‘udhu bi-kalimati-llahi-t-tammati min sharri ma khalaq.",
            meaningEnglish: "I seek refuge in the perfect words of Allah from the evil of what He has created.",
            meaningArabic: "أستجير بكلمات الله الكاملة من شر كل ما خلق.",
            contextEnglish: "Khawlah bint Hakim heard the Prophet ﷺ say that whoever stops at a place and says these words will not be harmed by anything until he leaves it. Read in ruqyah as a general protection; the narration states no repetition count.",
            contextArabic: "سمعت خولة بنت حكيم النبي ﷺ يقول: من نزل منزلًا ثم قال هذه الكلمات لم يضره شيء حتى يرتحل منه. تُقرأ في الرقية حماية عامة، ولم تذكر الرواية عددًا للتكرار.",
            kind: .prophetic,
            applicability: .init(level: .direct,
                                 explanationEnglish: "A protection the Prophet ﷺ taught in so many words; its subject is exactly seeking refuge from harm.",
                                 explanationArabic: "حماية علّمها النبي ﷺ بنصها، وموضوعها الاستعاذة من الأذى بعينه."),
            source: .init(id: "ruqyah-sunnah-muslim-2708a", kind: .hadith, collectionEnglish: "Sahih Muslim", collectionArabic: "صحيح مسلم",
                          number: "2708a", gradeEnglish: "Sahih", gradeArabic: "صحيح",
                          canonicalURL: "https://sunnah.com/muslim:2708a", textForm: .excerpt),
            cautionEnglish: medicalCaution.english,
            cautionArabic: medicalCaution.arabic
        ),
        GuidanceSupplication(
            id: "ruqyah-sunnah-bukhari-5745",
            titleEnglish: "The earth of our land",
            titleArabic: "تربة أرضنا",
            arabic: "بِسْمِ اللَّهِ، تُرْبَةُ أَرْضِنَا. بِرِيقَةِ بَعْضِنَا، يُشْفَى سَقِيمُنَا بِإِذْنِ رَبِّنَا",
            transliteration: "Bismillah, turbatu ardina, bi-riqati ba‘dina, yushfa saqimuna bi-idhni Rabbina.",
            meaningEnglish: "In the name of Allah. The dust of our land, with the saliva of some of us: our sick one is healed by the permission of our Lord.",
            meaningArabic: "باسم الله، تراب أرضنا مع ريق بعضنا، يُشفى مريضنا بإذن ربنا.",
            contextEnglish: "‘A’ishah reports that the Prophet ﷺ used to say this to the sick. Scholars describe the practice as touching a moistened fingertip to the ground and wiping the sore place while saying it; healing is attributed to Allah’s permission alone.",
            contextArabic: "تروي عائشة أن النبي ﷺ كان يقول هذا للمريض. وذكر العلماء أن صفته وضع الإصبع بالريق على التراب ثم مسح موضع الألم مع قوله؛ والشفاء منسوب إلى إذن الله وحده.",
            kind: .prophetic,
            applicability: .init(level: .direct,
                                 explanationEnglish: "The narration reports the Prophet ﷺ saying these very words to the sick.",
                                 explanationArabic: "تنقل الرواية أن النبي ﷺ كان يقول هذه الكلمات بعينها للمريض."),
            source: .init(id: "ruqyah-sunnah-bukhari-5745", kind: .hadith, collectionEnglish: "Sahih al-Bukhari", collectionArabic: "صحيح البخاري",
                          number: "5745", gradeEnglish: "Sahih", gradeArabic: "صحيح",
                          canonicalURL: "https://sunnah.com/bukhari:5745", textForm: .excerpt),
            cautionEnglish: medicalCaution.english,
            cautionArabic: medicalCaution.arabic
        ),
    ]

    // MARK: All

    static let all: [GuidanceSupplication] = quran + sunnah

    static func entry(_ id: String) -> GuidanceSupplication? {
        all.first { $0.id == id }
    }

    // MARK: Helpers

    private static func arabicDigits(_ value: Int) -> String {
        let digits = Array("٠١٢٣٤٥٦٧٨٩")
        return String(String(value).compactMap { $0.wholeNumberValue.map { digits[$0] } })
    }
}
