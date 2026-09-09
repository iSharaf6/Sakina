import Foundation

/// Source-linked additions for daily practice. Arabic is an explicitly labelled
/// excerpt of the cited narration; the English and Arabic meanings are paraphrases.
/// Sequence order is editorial. It does not establish a new prescribed ritual.
enum DailyDuaCatalog {
    private static func entry(_ id: String, _ title: String, _ titleAR: String,
                              arabic: String, transliteration: String, meaning: String, meaningAR: String,
                              context: String, contextAR: String,
                              collection: String = "bukhari", number: String,
                              caution: String? = nil, cautionAR: String? = nil) -> GuidanceSupplication {
        let isQuran = collection == "quran"
        let names: [String: (String, String)] = [
            "bukhari": ("Sahih al-Bukhari", "صحيح البخاري"),
            "muslim": ("Sahih Muslim", "صحيح مسلم"),
            "tirmidhi": ("Jami’ at-Tirmidhi", "جامع الترمذي"),
            "quran": ("The Qur’an", "القرآن الكريم")
        ]
        let name = names[collection]!
        return GuidanceSupplication(id: id, titleEnglish: title, titleArabic: titleAR,
            arabic: arabic, transliteration: transliteration, meaningEnglish: meaning, meaningArabic: meaningAR,
            contextEnglish: context, contextArabic: contextAR, kind: isQuran ? .quranic : .prophetic,
            applicability: .init(level: .direct, explanationEnglish: context, explanationArabic: contextAR),
            source: .init(id: "\(collection)-\(number)-\(id)", kind: isQuran ? .quran : .hadith,
                          collectionEnglish: name.0, collectionArabic: name.1, number: number,
                          gradeEnglish: isQuran ? "Qur’an" : (collection == "tirmidhi" ? "Sahih (Darussalam); al-Tirmidhi: hasan" : "Sahih"),
                          gradeArabic: isQuran ? "قرآن" : (collection == "tirmidhi" ? "صحيح (دار السلام)، وقال الترمذي: حسن" : "صحيح"),
                          canonicalURL: isQuran ? "https://quran.com/\(number.replacingOccurrences(of: ":", with: "/"))" : "https://sunnah.com/\(collection):\(number)",
                          textForm: .excerpt), cautionEnglish: caution, cautionArabic: cautionAR)
    }

    static let entries: [GuidanceSupplication] = [
        entry("daily-waking", "A new day", "يوم جديد",
              arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا، وَإِلَيْهِ النُّشُورُ",
              transliteration: "Al-hamdu lillahi-lladhi ahyana ba‘da ma amatana, wa ilayhi-n-nushur.",
              meaning: "Praise belongs to Allah, who brought us back to life after sleep. To Him we will be raised.",
              meaningAR: "الحمد لله الذي رد إلينا الحياة بعد النوم، وإليه البعث.",
              context: "Said on waking from sleep in this narration.", contextAR: "ورد هذا الذكر عند الاستيقاظ من النوم.", number: "6324"),
        entry("daily-morning", "Begin with Allah", "ابدأ يومك بذكر الله",
              arabic: "اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ",
              transliteration: "Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namutu wa ilayka-l-masir.",
              meaning: "O Allah, through You we reach morning and evening; through You we live and die. Our return is to You.",
              meaningAR: "يا الله، بقدرتك ندرك الصباح والمساء ونحيا ونموت، وإليك مرجعنا.",
              context: "The morning wording in al-Tirmidhi 3391. Other sound narrations contain wording variants.",
              contextAR: "صيغة الصباح في الترمذي ٣٣٩١، ووردت صيغ أخرى في روايات صحيحة.", collection: "tirmidhi", number: "3391"),
        entry("daily-evening", "As evening arrives", "حين يأتي المساء",
              arabic: "اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ",
              transliteration: "Allahumma bika amsayna wa bika asbahna wa bika nahya wa bika namutu wa ilayka-n-nushur.",
              meaning: "O Allah, through You we reach evening and morning; through You we live and die. To You we will be raised.",
              meaningAR: "يا الله، بقدرتك ندرك المساء والصباح ونحيا ونموت، وإليك البعث.",
              context: "The evening wording in al-Tirmidhi 3391. This preserves the wording of this particular narration.",
              contextAR: "صيغة المساء كما جاءت في هذه الرواية من الترمذي ٣٣٩١.", collection: "tirmidhi", number: "3391"),
        entry("daily-sleep", "Entrust your night", "سلّم ليلتك لله",
              arabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
              transliteration: "Bismika Allahumma amutu wa ahya.",
              meaning: "In Your name, O Allah, I die and I live.", meaningAR: "باسمك يا الله أموت وأحيا.",
              context: "A supplication the Prophet ﷺ said when going to sleep.", contextAR: "دعاء كان النبي ﷺ يقوله عند النوم.", number: "6324"),
        entry("daily-salah", "In bowing and sujud", "في الركوع والسجود",
              arabic: "سُبْحَانَكَ اللَّهُمَّ رَبَّنَا وَبِحَمْدِكَ، اللَّهُمَّ اغْفِرْ لِي",
              transliteration: "Subhanaka Allahumma Rabbana wa bihamdika, Allahumma-ghfir li.",
              meaning: "Glory and praise to You, O Allah, our Lord. O Allah, forgive me.",
              meaningAR: "أنزهك يا الله ربنا وأحمدك، وأسألك أن تغفر لي.",
              context: "‘A’ishah reports that the Prophet ﷺ often said these words in bowing and prostration.",
              contextAR: "تخبر عائشة أن النبي ﷺ كان يكثر من هذا الدعاء في الركوع والسجود.", number: "817"),
        entry("daily-after-forgiveness", "Ask forgiveness", "استغفر الله",
              arabic: "أَسْتَغْفِرُ اللَّهَ",
              transliteration: "Astaghfirullah.", meaning: "I ask Allah to forgive me.", meaningAR: "أطلب المغفرة من الله.",
              context: "After finishing the prayer, the Prophet ﷺ sought forgiveness three times, then said the next supplication of peace (Muslim 591).",
              contextAR: "كان النبي ﷺ يستغفر ثلاثًا بعد الصلاة، ثم يقول دعاء السلام التالي (مسلم ٥٩١).", collection: "muslim", number: "591"),
        entry("daily-after-peace", "From You comes peace", "منك السلام",
              arabic: "اللَّهُمَّ أَنْتَ السَّلاَمُ وَمِنْكَ السَّلاَمُ تَبَارَكْتَ ذَا الْجَلاَلِ وَالإِكْرَامِ",
              transliteration: "Allahumma Anta-s-Salamu wa minka-s-salam, tabarakta dha-l-jalali wa-l-ikram.",
              meaning: "O Allah, You are Peace and peace comes from You. Blessed are You, Possessor of majesty and honour.",
              meaningAR: "يا الله، أنت السلام ومنك السلام، تعاظمت وتقدست يا ذا الجلال والإكرام.",
              context: "Said after the prayer, following the request for forgiveness three times.",
              contextAR: "يقال بعد الصلاة عقب الاستغفار ثلاثًا.", collection: "muslim", number: "591"),
        entry("daily-healing", "Ask for healing", "اسأل الله الشفاء",
              arabic: "اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَاسَ، اشْفِهِ وَأَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا",
              transliteration: "Allahumma Rabba-n-nasi adhhibi-l-ba’s, ishfihi wa Anta-sh-Shafi, la shifa’a illa shifa’uka, shifa’an la yughadiru saqama.",
              meaning: "O Allah, Lord of people, take away the suffering. Heal him; You are the Healer. Only Your healing truly heals. Grant healing that leaves no illness.",
              meaningAR: "يا الله رب الناس، أزل المرض واشفِ المريض؛ فأنت الشافي، ولا شفاء إلا منك، شفاءً لا يبقي مرضًا.",
              context: "A ruqyah the Prophet ﷺ recited for an ill family member. The pronoun follows the cited Arabic wording.",
              contextAR: "رقية كان النبي ﷺ يدعو بها لبعض أهله عند المرض، والضمير كما ورد في الرواية.", number: "5743",
              caution: "Du’a can accompany medical care. Do not delay urgent care or stop prescribed treatment.",
              cautionAR: "الدعاء يصاحب التداوي؛ لا تؤخر الرعاية العاجلة ولا توقف علاجًا موصوفًا."),
        entry("daily-salawat", "Blessings upon the Prophet ﷺ", "الصلاة على النبي ﷺ",
              arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ",
              transliteration: "Allahumma salli ‘ala Muhammadin wa ‘ala ali Muhammad, kama sallayta ‘ala Ibrahima wa ‘ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik ‘ala Muhammadin wa ‘ala ali Muhammad, kama barakta ‘ala Ibrahima wa ‘ala ali Ibrahim, innaka Hamidun Majid.",
              meaning: "O Allah, honour Muhammad and the family of Muhammad as You honoured Ibrahim and his family. You are worthy of praise, full of glory. O Allah, bless Muhammad and his family as You blessed Ibrahim and his family. You are worthy of praise, full of glory.",
              meaningAR: "اللهم أثنِ على محمد وآله وبارك عليهم، كما صليت وباركت على إبراهيم وآله، إنك محمود مجيد.",
              context: "A transmitted form of salawat taught when the Companions asked how to send blessings upon the Prophet ﷺ.",
              contextAR: "صيغة مأثورة علّمها النبي ﷺ لأصحابه حين سألوه عن كيفية الصلاة عليه.", number: "3370"),
        entry("daily-praise", "Light on the tongue", "خفيفتان على اللسان",
              arabic: "سُبْحَانَ اللَّهِ الْعَظِيمِ، سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
              transliteration: "Subhana-llahi-l-‘Azim, subhana-llahi wa bihamdih.",
              meaning: "Glory to Allah, the Magnificent. Glory and praise to Allah.",
              meaningAR: "أنزه الله العظيم عن كل نقص، وأنزهه مع حمده.",
              context: "Two expressions praised in this hadith. No repetition target is specified here.",
              contextAR: "كلمتان ورد فضلهما في هذا الحديث دون تحديد عدد للتكرار فيه.", number: "6406"),
        entry("daily-ummah", "For our fellow believers", "لإخواننا المؤمنين",
              arabic: "رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ",
              transliteration: "Rabbana-ghfir lana wa li-ikhwanina-lladhina sabaquna bi-l-iman, wa la taj‘al fi qulubina ghillan lilladhina amanu, Rabbana innaka Ra’ufun Rahim.",
              meaning: "Our Lord, forgive us and our brothers and sisters who came before us in faith. Keep resentment towards believers out of our hearts. Our Lord, You are compassionate and merciful.",
              meaningAR: "ربنا اغفر لنا ولمن سبقنا بالإيمان، وطهّر قلوبنا من الحقد على المؤمنين، إنك رؤوف رحيم.",
              context: "The prayer within Qur’an 59:10, for the believers and hearts free of resentment.",
              contextAR: "الدعاء الوارد في الحشر ١٠ للمؤمنين ولسلامة القلب من الغل.", collection: "quran", number: "59:10"),
        entry("daily-tahajjud", "In the quiet of the night", "في سكون الليل",
              arabic: "اللَّهُمَّ لَكَ أَسْلَمْتُ، وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ، وَإِلَيْكَ أَنَبْتُ، وَبِكَ خَاصَمْتُ، وَإِلَيْكَ حَاكَمْتُ، فَاغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ، وَمَا أَسْرَرْتُ وَمَا أَعْلَنْتُ، أَنْتَ الْمُقَدِّمُ وَأَنْتَ الْمُؤَخِّرُ، لَا إِلَهَ إِلَّا أَنْتَ",
              transliteration: "Allahumma laka aslamtu, wa bika amantu wa ‘alayka tawakkaltu, wa ilayka anabtu, wa bika khasamtu, wa ilayka hakamtu. Faghfir li ma qaddamtu wa ma akhkhartu, wa ma asrartu wa ma a‘lantu. Anta-l-Muqaddimu wa Anta-l-Mu’akhkhir, la ilaha illa Ant.",
              meaning: "O Allah, I submit to You, believe in You, trust You and turn back to You. With Your help I contend, and to You I refer judgement. Forgive what I have done and what I have yet to do, what I hide and what I reveal. You bring forward and You hold back. There is no god but You.",
              meaningAR: "يا الله، أسلمت لك وآمنت بك وتوكلت عليك ورجعت إليك، وبحجتك أخاصم وإلى حكمك أرجع. اغفر لي ما مضى وما يأتي، وما أخفيت وما أظهرت. أنت المقدم والمؤخر، لا إله إلا أنت.",
              context: "An excerpt from the longer opening supplication for night prayer in Bukhari 1120. Open the source for the preceding praise and the full narration.",
              contextAR: "مقتطف من دعاء استفتاح قيام الليل في البخاري ١١٢٠؛ افتح المصدر لقراءة الثناء السابق والرواية كاملة.", number: "1120")
    ]
}

enum DuaPractice: String, CaseIterable, Identifiable, Hashable {
    case morning, evening, sleep, tahajjud, salah, afterSalah, ummah, healing, praise, salawat, quran, sunnah, istighfar, anytime, names
    var id: String { rawValue }
    static let daily: [Self] = [.morning, .evening, .sleep, .salah, .afterSalah, .tahajjud]
    func title(_ language: AppLanguage) -> String {
        let labels: [Self: (String, String)] = [
            .morning: ("Morning", "الصباح"), .evening: ("Evening", "المساء"), .sleep: ("Before sleep", "قبل النوم"),
            .tahajjud: ("Tahajjud", "التهجد"), .salah: ("Salah", "الصلاة"), .afterSalah: ("After salah", "بعد الصلاة"),
            .ummah: ("For the ummah", "للأمة"), .healing: ("Ruqyah & illness", "الرقية والمرض"), .praise: ("Praises of Allah", "الثناء على الله"),
            .salawat: ("Salawat", "الصلاة على النبي"), .quran: ("Qur’anic du’as", "أدعية قرآنية"), .sunnah: ("Sunnah du’as", "أدعية من السنة"),
            .istighfar: ("Istighfar", "الاستغفار"), .anytime: ("Dhikr for all times", "أذكار لكل وقت"), .names: ("Names of Allah", "أسماء الله الحسنى")
        ]
        return language.pick(labels[self]!.0, labels[self]!.1)
    }
    func invitation(_ language: AppLanguage) -> String {
        switch self {
        case .morning: return language.pick("Begin with remembrance.", "ابدأ بذكر الله.")
        case .evening: return language.pick("Return, as the day softens.", "عُد إلى الذكر مع المساء.")
        case .sleep: return language.pick("Leave the day with Allah.", "اختم يومك بذكر الله.")
        case .tahajjud: return language.pick("A quiet conversation with Allah.", "مناجاة في سكون الليل.")
        case .salah: return language.pick("Words for bowing and sujud.", "كلمات للركوع والسجود.")
        case .afterSalah: return language.pick("Stay a little after the salam.", "تمهّل بعد السلام.")
        case .ummah: return language.pick("Make room for others in your du’a.", "اجعل للآخرين نصيبًا من دعائك.")
        case .healing: return language.pick("Ask for healing and seek care.", "اسأل الشفاء وخذ بأسباب العلاج.")
        case .praise: return language.pick("Remember who you’re turning to.", "تذكّر من تدعوه.")
        case .salawat: return language.pick("Send blessings upon the Prophet ﷺ.", "صلِّ على النبي ﷺ.")
        case .quran: return language.pick("Prayers within Allah’s words.", "أدعية في كلام الله.")
        case .sunnah: return language.pick("Words the Prophet ﷺ taught.", "أدعية علّمنا إياها النبي ﷺ.")
        case .istighfar: return language.pick("There is room to return.", "باب التوبة مفتوح.")
        case .anytime: return language.pick("Little words. A place in your day.", "كلمات يسيرة في يومك.")
        case .names: return language.pick("Know Him by His beautiful names.", "تعرّف إليه بأسمائه الحسنى.")
        }
    }
    var entryIDs: [String] {
        if let ids = DuaLibrary.collections[rawValue], !ids.isEmpty { return ids }
        return legacyEntryIDs
    }
    private var legacyEntryIDs: [String] {
        switch self {
        case .morning: return ["daily-waking", "daily-morning", "prophetic-master-repentance"]
        case .evening: return ["daily-evening", "prophetic-master-repentance"]
        case .sleep: return ["daily-sleep"]
        case .tahajjud: return ["daily-tahajjud"]
        case .salah: return ["daily-salah", "daily-salawat"]
        case .afterSalah: return ["daily-after-forgiveness", "daily-after-peace", "prophetic-help-to-worship"]
        case .ummah: return ["daily-ummah", "quran-burdens-and-mercy"]
        case .healing: return ["daily-healing"]
        case .praise: return ["daily-praise", "daily-after-peace"]
        case .salawat: return ["daily-salawat"]
        case .quran: return DuaCollection.allEntries.filter { $0.kind == .quranic }.map(\.id)
        case .sunnah: return DuaCollection.allEntries.filter { $0.kind == .prophetic }.map(\.id)
        case .istighfar: return ["prophetic-master-repentance", "quran-repentance-adam", "quran-distress-yunus"]
        case .anytime: return ["daily-praise", "prophetic-anger-refuge", "quran-guidance"]
        case .names: return []
        }
    }
    var entries: [GuidanceSupplication] { entryIDs.compactMap(DuaCollection.dua) }
    /// This chooses a suggestion only, using the device clock. It is not a prayer-time calculation.
    static func suggested(at date: Date = .now, calendar: Calendar = .current) -> Self {
        switch calendar.component(.hour, from: date) {
        case 4..<12: return .morning
        case 12..<16: return .anytime
        case 16..<21: return .evening
        default: return .sleep
        }
    }
}
