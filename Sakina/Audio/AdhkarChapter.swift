import Foundation

/// A checked excerpt of the original file. Playback seeks within that file,
/// keeping the complete recitation intact and avoiding duplicate audio assets.
struct AdhkarChapter: Identifiable {
    let duaID: String
    let titleEnglish: String
    let titleArabic: String
    let start: TimeInterval
    let end: TimeInterval
    var id: String { duaID }

    func title(_ language: AppLanguage) -> String { language.pick(titleEnglish, titleArabic) }
}

extension AdhkarRecording {
    var chapters: [AdhkarChapter] {
        switch self {
        case .morning:
            return [
                .init(duaID: "morning-ayat-al-kursi",
                      titleEnglish: "The verse of the Throne", titleArabic: "آية الكرسي",
                      start: 5.3, end: 56.69),
                .init(duaID: "morning-surah-al-ikhlas",
                      titleEnglish: "Surah al-Ikhlas", titleArabic: "سورة الإخلاص",
                      start: 71.65, end: 87.15),
                .init(duaID: "morning-surah-al-falaq",
                      titleEnglish: "Surah al-Falaq", titleArabic: "سورة الفلق",
                      start: 87.15, end: 111.54),
                .init(duaID: "morning-surah-an-nas",
                      titleEnglish: "Surah an-Nas", titleArabic: "سورة الناس",
                      start: 111.54, end: 141.96),
                .init(duaID: "morning-afini-fi-badani",
                      titleEnglish: "Wellbeing in body, hearing and sight", titleArabic: "اللهم عافني في بدني",
                      start: 566.06, end: 582.26),
                .init(duaID: "morning-hasbiyallah",
                      titleEnglish: "Allah is enough for me", titleArabic: "حسبي الله لا إله إلا هو",
                      start: 658.86, end: 668.14),
                .init(duaID: "morning-ya-hayyu-ya-qayyum",
                      titleEnglish: "O Ever-Living, O Sustainer", titleArabic: "يا حي يا قيوم برحمتك أستغيث",
                      start: 916.68, end: 930.77),
            ]
        case .evening:
            return [
                .init(duaID: "morning-ayat-al-kursi",
                      titleEnglish: "The verse of the Throne", titleArabic: "آية الكرسي",
                      start: 7.7, end: 59.09),
                .init(duaID: "morning-surah-al-ikhlas",
                      titleEnglish: "Surah al-Ikhlas", titleArabic: "سورة الإخلاص",
                      start: 74.05, end: 89.55),
                .init(duaID: "morning-surah-al-falaq",
                      titleEnglish: "Surah al-Falaq", titleArabic: "سورة الفلق",
                      start: 89.55, end: 113.94),
                .init(duaID: "morning-surah-an-nas",
                      titleEnglish: "Surah an-Nas", titleArabic: "سورة الناس",
                      start: 113.94, end: 144.36),
                .init(duaID: "morning-afini-fi-badani",
                      titleEnglish: "Wellbeing in body, hearing and sight", titleArabic: "اللهم عافني في بدني",
                      start: 588.33, end: 604.53),
                .init(duaID: "morning-hasbiyallah",
                      titleEnglish: "Allah is enough for me", titleArabic: "حسبي الله لا إله إلا هو",
                      start: 681.13, end: 690.41),
                .init(duaID: "morning-ya-hayyu-ya-qayyum",
                      titleEnglish: "O Ever-Living, O Sustainer", titleArabic: "يا حي يا قيوم برحمتك أستغيث",
                      start: 938.68, end: 952.77),
                .init(duaID: "evening-kalimat-allah-tammat",
                      titleEnglish: "Refuge in Allah’s perfect words", titleArabic: "أعوذ بكلمات الله التامات",
                      start: 1194.22, end: 1200.75),
            ]
        }
    }

    func chapter(for duaID: String) -> AdhkarChapter? {
        chapters.first { $0.duaID == duaID }
    }
}
