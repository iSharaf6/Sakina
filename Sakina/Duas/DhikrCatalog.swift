import Foundation

// MARK: - Dhikr catalog
//
// Short, standard adhkar for the tap counter. Sources are cited only where
// the exact narration is certain; everything else carries a general label.

struct DhikrItem: Identifiable, Hashable {
    let id: String
    let arabic: String
    let transliteration: String
    let meaningEnglish: String
    let meaningArabic: String
    let defaultTarget: Int
    let sourceEnglish: String
    let sourceArabic: String
    let sourceURL: String?
    let artwork: CompanionArtwork

    func meaning(_ language: AppLanguage) -> String {
        language.pick(meaningEnglish, meaningArabic)
    }

    func source(_ language: AppLanguage) -> String {
        language.pick(sourceEnglish, sourceArabic)
    }
}

enum DhikrCatalog {
    static let all: [DhikrItem] = [
        DhikrItem(
            id: "subhanallah",
            arabic: "سُبْحَانَ اللَّهِ",
            transliteration: "SubhanAllah",
            meaningEnglish: "Glory be to Allah.",
            meaningArabic: "تنزيه الله عن كل نقص.",
            defaultTarget: 33,
            sourceEnglish: "Sahih Muslim 597",
            sourceArabic: "صحيح مسلم ٥٩٧",
            sourceURL: "https://sunnah.com/muslim:597",
            artwork: .praise
        ),
        DhikrItem(
            id: "alhamdulillah",
            arabic: "الْحَمْدُ لِلَّهِ",
            transliteration: "Alhamdulillah",
            meaningEnglish: "All praise is for Allah.",
            meaningArabic: "الثناء كله لله.",
            defaultTarget: 33,
            sourceEnglish: "Sahih Muslim 597",
            sourceArabic: "صحيح مسلم ٥٩٧",
            sourceURL: "https://sunnah.com/muslim:597",
            artwork: .praise
        ),
        DhikrItem(
            id: "allahuakbar",
            arabic: "اللَّهُ أَكْبَرُ",
            transliteration: "Allahu Akbar",
            meaningEnglish: "Allah is the Greatest.",
            meaningArabic: "الله أعظم من كل شيء.",
            defaultTarget: 34,
            sourceEnglish: "Sahih Muslim 597",
            sourceArabic: "صحيح مسلم ٥٩٧",
            sourceURL: "https://sunnah.com/muslim:597",
            artwork: .praise
        ),
        DhikrItem(
            id: "tahlil",
            arabic: "لَا إِلَٰهَ إِلَّا اللَّهُ",
            transliteration: "La ilaha illallah",
            meaningEnglish: "There is no god but Allah.",
            meaningArabic: "لا معبود بحق إلا الله.",
            defaultTarget: 100,
            sourceEnglish: "Established dhikr",
            sourceArabic: "ذكر ثابت",
            sourceURL: nil,
            artwork: .anytime
        ),
        DhikrItem(
            id: "astaghfirullah",
            arabic: "أَسْتَغْفِرُ اللَّهَ",
            transliteration: "Astaghfirullah",
            meaningEnglish: "I seek Allah’s forgiveness.",
            meaningArabic: "أطلب من الله المغفرة.",
            defaultTarget: 100,
            sourceEnglish: "Sahih Muslim 2702",
            sourceArabic: "صحيح مسلم ٢٧٠٢",
            sourceURL: "https://sunnah.com/muslim:2702",
            artwork: .istighfar
        ),
        DhikrItem(
            id: "subhanallahi-wa-bihamdihi",
            arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahi wa bihamdihi",
            meaningEnglish: "Glory be to Allah, and praise be to Him.",
            meaningArabic: "تنزيه لله مقرون بحمده.",
            defaultTarget: 100,
            sourceEnglish: "Sahih al-Bukhari 6405",
            sourceArabic: "صحيح البخاري ٦٤٠٥",
            sourceURL: "https://sunnah.com/bukhari:6405",
            artwork: .morning
        ),
        DhikrItem(
            id: "two-phrases",
            arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
            transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil-‘Azim",
            meaningEnglish: "Glory be to Allah and praise be to Him; glory be to Allah, the Magnificent.",
            meaningArabic: "تنزيه لله مع حمده، وتنزيه لله العظيم.",
            defaultTarget: 10,
            sourceEnglish: "Sahih al-Bukhari 6406",
            sourceArabic: "صحيح البخاري ٦٤٠٦",
            sourceURL: "https://sunnah.com/bukhari:6406",
            artwork: .praise
        ),
        DhikrItem(
            id: "hawqala",
            arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
            transliteration: "La hawla wa la quwwata illa billah",
            meaningEnglish: "There is no power and no strength except through Allah.",
            meaningArabic: "لا تحوّل ولا قدرة إلا بالله.",
            defaultTarget: 33,
            sourceEnglish: "Sahih al-Bukhari 6384",
            sourceArabic: "صحيح البخاري ٦٣٨٤",
            sourceURL: "https://sunnah.com/bukhari:6384",
            artwork: .anytime
        ),
        DhikrItem(
            id: "salawat",
            arabic: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
            transliteration: "Allahumma salli wa sallim ‘ala nabiyyina Muhammad",
            meaningEnglish: "O Allah, send blessings and peace upon our Prophet Muhammad.",
            meaningArabic: "اللهم صلّ وسلّم على نبينا محمد.",
            defaultTarget: 10,
            sourceEnglish: "Sahih Muslim 408",
            sourceArabic: "صحيح مسلم ٤٠٨",
            sourceURL: "https://sunnah.com/muslim:408",
            artwork: .salawat
        ),
        DhikrItem(
            id: "hasbunallah",
            arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
            transliteration: "HasbunAllahu wa ni‘mal-wakil",
            meaningEnglish: "Allah is sufficient for us, and He is the best Disposer of affairs.",
            meaningArabic: "الله كافينا، ونعم من يُوكَل إليه الأمر.",
            defaultTarget: 7,
            sourceEnglish: "Qur’an 3:173",
            sourceArabic: "القرآن ٣:١٧٣",
            sourceURL: "https://quran.com/3/173",
            artwork: .anytime
        ),
        DhikrItem(
            id: "yunus",
            arabic: "لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ",
            transliteration: "La ilaha illa anta subhanaka inni kuntu minaz-zalimin",
            meaningEnglish: "There is no god but You; glory be to You. Truly I have been among the wrongdoers.",
            meaningArabic: "لا معبود بحق إلا أنت، تنزّهت، إني كنت من الظالمين.",
            defaultTarget: 33,
            sourceEnglish: "Qur’an 21:87",
            sourceArabic: "القرآن ٢١:٨٧",
            sourceURL: "https://quran.com/21/87",
            artwork: .healing
        ),
        DhikrItem(
            id: "astaghfirullaha-wa-atubu-ilayh",
            arabic: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
            transliteration: "Astaghfirullaha wa atubu ilayh",
            meaningEnglish: "I seek Allah’s forgiveness and turn to Him in repentance.",
            meaningArabic: "أطلب مغفرة الله وأرجع إليه تائبًا.",
            defaultTarget: 100,
            sourceEnglish: "Sahih al-Bukhari 6307",
            sourceArabic: "صحيح البخاري ٦٣٠٧",
            sourceURL: "https://sunnah.com/bukhari:6307",
            artwork: .istighfar
        ),
        DhikrItem(
            id: "tahlil-full",
            arabic: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
            transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa ‘ala kulli shay’in qadir",
            meaningEnglish: "There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He is able to do all things.",
            meaningArabic: "لا معبود بحق إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير.",
            defaultTarget: 100,
            sourceEnglish: "Sahih al-Bukhari 6403",
            sourceArabic: "صحيح البخاري ٦٤٠٣",
            sourceURL: "https://sunnah.com/bukhari:6403",
            artwork: .anytime
        ),
    ]

    static func item(id: String) -> DhikrItem? {
        all.first { $0.id == id }
    }
}

// MARK: - Dhikr log
//
// Per-day counts, kept for thirty days. Stored as `yyyy-MM-dd:itemID=count`
// pairs joined by `|`, mirroring `PracticeLog`.

enum DhikrLog {
    static let key = "yaqeen.dhikrLog"
    static let retainedDays = 30

    private struct Entry {
        let day: String
        let id: String
        let count: Int
    }

    private static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func entries(_ raw: String) -> [Entry] {
        raw.split(separator: "|").compactMap { piece -> Entry? in
            guard let colon = piece.firstIndex(of: ":"),
                  let equals = piece.lastIndex(of: "="),
                  colon < equals,
                  let count = Int(piece[piece.index(after: equals)...]) else { return nil }
            let day = String(piece[..<colon])
            let id = String(piece[piece.index(after: colon)..<equals])
            guard !day.isEmpty, !id.isEmpty else { return nil }
            return Entry(day: day, id: id, count: count)
        }
    }

    /// The count recorded for one item on one day.
    static func count(for id: String, on date: Date = .now, in raw: String) -> Int {
        let target = day(date)
        return entries(raw).first { $0.day == target && $0.id == id }?.count ?? 0
    }

    /// Every item counted on one day, keyed by item id.
    static func counts(on date: Date = .now, in raw: String) -> [String: Int] {
        let target = day(date)
        return entries(raw).filter { $0.day == target }.reduce(into: [:]) { $0[$1.id] = $1.count }
    }

    /// The sum of every item counted today.
    static func todayTotal(on date: Date = .now, in raw: String) -> Int {
        counts(on: date, in: raw).values.reduce(0, +)
    }

    /// Returns the log with `count` recorded for `id` on `date`, dropping
    /// anything older than thirty days.
    static func setting(_ count: Int, for id: String, on date: Date = .now, in raw: String) -> String {
        let today = day(date)
        let calendar = Calendar(identifier: .gregorian)
        let cutoff = day(calendar.date(byAdding: .day, value: -retainedDays, to: date) ?? date)
        var kept = entries(raw).filter { $0.day >= cutoff && !($0.day == today && $0.id == id) }
        if count > 0 {
            kept.append(Entry(day: today, id: id, count: count))
        }
        return kept.map { "\($0.day):\($0.id)=\($0.count)" }.joined(separator: "|")
    }
}
