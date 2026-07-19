import Foundation

// MARK: Verse

/// One ayah, loaded from the bundled `verses.json`.
/// Arabic text is the Uthmani script and the translation is Saheeh International,
/// both fetched verbatim from the Quran.com API (v4). Do not edit by hand.
struct Verse: Codable, Identifiable, Hashable {
    let key: String            // e.g. "4:35"
    let surah: Int
    let ayah: Int
    let surahName: String      // e.g. "An Nisa"
    let surahNameArabic: String
    let surahNameTranslated: String
    let arabic: String
    let translation: String
    let audioFile: String      // zero padded "004035" for the recitation CDN

    var id: String { key }

    var reference: String { "\(surahName) \(key)" }
}

// MARK: Verse store

final class VerseStore {
    static let shared = VerseStore()

    private struct File: Codable {
        let source: String
        let verses: [Verse]
    }

    private(set) var byKey: [String: Verse] = [:]
    private(set) var all: [Verse] = []

    private init() {
        guard let url = Bundle.main.url(forResource: "verses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            assertionFailure("verses.json missing from bundle")
            return
        }
        all = file.verses
        byKey = Dictionary(uniqueKeysWithValues: file.verses.map { ($0.key, $0) })
    }

    func verses(for keys: [String]) -> [Verse] {
        keys.compactMap { byKey[$0] }
    }
}

// MARK: Chapters

enum ChapterID: String, Codable, CaseIterable {
    case search, bond, storm, family, heart, trials, provision
}

struct Chapter: Identifiable, Hashable {
    let id: ChapterID
    let numeral: String
    let title: String
    let arabicWord: String
    let subtitle: String

    static let all: [Chapter] = [
        Chapter(id: .search, numeral: "I", title: "The Search",
                arabicWord: "دُعَاء",
                subtitle: "Seeking, waiting, and trusting before marriage"),
        Chapter(id: .bond, numeral: "II", title: "The Bond",
                arabicWord: "مَوَدَّة",
                subtitle: "Tenderness, counsel, and growing together"),
        Chapter(id: .storm, numeral: "III", title: "The Storm",
                arabicWord: "صَبْر",
                subtitle: "Conflict, forgiveness, and holding fast"),
        Chapter(id: .family, numeral: "IV", title: "The Family and The Decree",
                arabicWord: "رَحْمَة",
                subtitle: "Children, absence, loss, and what Allah writes"),
        Chapter(id: .heart, numeral: "V", title: "The Heart",
                arabicWord: "قَلْب",
                subtitle: "Iman, prayer, repentance, and the inner life"),
        Chapter(id: .trials, numeral: "VI", title: "The Trials",
                arabicWord: "اِبْتِلَاء",
                subtitle: "Fear, loneliness, hurt, and hard seasons"),
        Chapter(id: .provision, numeral: "VII", title: "The Provision",
                arabicWord: "رِزْق",
                subtitle: "Money, work, and trusting the Provider"),
    ]

    static func by(_ id: ChapterID) -> Chapter {
        all.first { $0.id == id }!
    }
}

// MARK: Situation

/// A life situation mapped to one or more ayat.
/// `whyNote` is a brief reflection on the verse's plain meaning. It is deliberately
/// conservative, citing only well established sources. It is not tafsir.
struct Situation: Identifiable, Hashable {
    let id: String
    let chapter: ChapterID
    let title: String
    let verseKeys: [String]
    let referenceLabel: String
    let whyNote: String

    var verses: [Verse] { VerseStore.shared.verses(for: verseKeys) }
    var primaryVerse: Verse? { verses.first }
}

// MARK: Catalog

enum SituationCatalog {

    static func situations(in chapter: ChapterID) -> [Situation] {
        all.filter { $0.chapter == chapter }
    }

    static func by(id: String) -> Situation? {
        all.first { $0.id == id }
    }

    static func search(_ query: String) -> [Situation] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(q)
            || $0.referenceLabel.localizedCaseInsensitiveContains(q)
            || Chapter.by($0.chapter).title.localizedCaseInsensitiveContains(q)
        }
    }

    static let all: [Situation] = [

        // I. THE SEARCH

        Situation(
            id: "beforeMarriage", chapter: .search,
            title: "Before getting married",
            verseKeys: ["25:74"], referenceLabel: "25:74, Surah Al Furqan",
            whyNote: "This is the du'a of the servants of the Most Merciful: “Our Lord, grant us from among our wives and offspring comfort to our eyes.” Before marriage even begins, the Qur'an teaches us to ask Allah for a spouse and family that bring coolness to the eyes."
        ),
        Situation(
            id: "lookingForSpouse", chapter: .search,
            title: "When you're looking for a righteous spouse",
            verseKeys: ["24:32"], referenceLabel: "24:32, Surah An Nur",
            whyNote: "Allah commands the community to help the unmarried among them marry, and attaches a promise: “If they should be poor, Allah will enrich them from His bounty.” Seeking marriage to guard one's chastity invites Allah's own provision."
        ),
        Situation(
            id: "choosingSpouse", chapter: .search,
            title: "When you're choosing someone to marry",
            verseKeys: ["2:221"], referenceLabel: "2:221, Surah Al Baqarah",
            whyNote: "This verse places faith above every worldly credential. A believing servant is declared better “even though he might please you.” Beauty, wealth, and status may impress, but the Qur'an directs the choice toward iman."
        ),
        Situation(
            id: "waitingForTiming", chapter: .search,
            title: "When you're waiting for Allah's timing",
            verseKeys: ["2:216"], referenceLabel: "2:216, Surah Al Baqarah",
            whyNote: "“perhaps you hate a thing and it is good for you; and perhaps you love a thing and it is bad for you. And Allah knows, while you know not.” The delay you grieve over may itself be protection, and a gift arriving on a wiser schedule than yours."
        ),
        Situation(
            id: "worriedNeverMarry", chapter: .search,
            title: "When you're worried you'll never get married",
            verseKeys: ["65:2", "65:3"], referenceLabel: "65:2 and 3, Surah At Talaq",
            whyNote: "Whoever fears Allah, the verse promises, “He will make for him a way out” and “will provide for him from where he does not expect.” The promise is tied to taqwa, not to circumstances: the way out arrives from directions you could not have planned."
        ),
        Situation(
            id: "strugglingPatience", chapter: .search,
            title: "When you're struggling to stay patient",
            verseKeys: ["2:153"], referenceLabel: "2:153, Surah Al Baqarah",
            whyNote: "Patience here is not passive waiting. The verse pairs it with prayer as an active means of seeking help, and ends with a promise of companionship: “Indeed, Allah is with the patient.”"
        ),

        // II. THE BOND

        Situation(
            id: "peaceInMarriage", chapter: .bond,
            title: "When you want peace in your marriage",
            verseKeys: ["30:21"], referenceLabel: "30:21, Surah Ar Rum",
            whyNote: "Allah names the marriage bond among His signs and describes its purpose in three words: sukun (tranquility), mawaddah (affection), and rahmah (mercy). Peace in marriage is not an accident. It is the very design Allah placed within it."
        ),
        Situation(
            id: "treatSpouseKindly", chapter: .bond,
            title: "When you need to treat your spouse kindly",
            verseKeys: ["4:19"], referenceLabel: "4:19, Surah An Nisa",
            whyNote: "“And live with them in kindness.” The verse then goes further: even if you dislike them, “perhaps you dislike a thing and Allah makes therein much good.” Kindness is commanded, not conditional on feelings."
        ),
        Situation(
            id: "becomeBetterSpouse", chapter: .bond,
            title: "When you want to become a better spouse",
            verseKeys: ["4:19"], referenceLabel: "4:19, Surah An Nisa",
            whyNote: "The command to “live with them in kindness” covers speech, provision, patience, and companionship. The Prophet ﷺ said: “The best of you are the best to their families” (Tirmidhi), and this verse is where that standard begins."
        ),
        Situation(
            id: "speakKindly", chapter: .bond,
            title: "When you need to speak kindly to your spouse",
            verseKeys: ["17:53"], referenceLabel: "17:53, Surah Al Isra",
            whyNote: "“And tell My servants to say that which is best,” for Shaytan sows discord between people. The verse names the stakes plainly: harsh words are an opening for Shaytan, and the best words close it."
        ),
        Situation(
            id: "decidingTogether", chapter: .bond,
            title: "When you're making decisions together",
            verseKeys: ["3:159"], referenceLabel: "3:159, Surah Ali 'Imran",
            whyNote: "Addressed to the Prophet ﷺ himself: had he been harsh in heart, people “would have disbanded from about you,” and he is commanded to consult them in the matter. Gentleness and shura (consultation) are the Qur'an's model of leadership, including at home."
        ),
        Situation(
            id: "fairnessInMarriage", chapter: .bond,
            title: "When you need fairness in your marriage",
            verseKeys: ["4:135"], referenceLabel: "4:135, Surah An Nisa",
            whyNote: "“be persistently standing firm in justice, witnesses for Allah, even if it be against yourselves or parents and relatives.” Justice in the Qur'an does not bend for love or self interest, even within the walls of your own home."
        ),
        Situation(
            id: "rebuildingTrust", chapter: .bond,
            title: "When you're trying to rebuild trust",
            verseKeys: ["23:8"], referenceLabel: "23:8, Surah Al Mu'minun",
            whyNote: "Among the qualities of the successful believers: “they who are to their trusts and their promises attentive.” Trust is rebuilt the way this verse describes it, by guarding every amanah and keeping every promise, consistently."
        ),
        Situation(
            id: "duaForFamily", chapter: .bond,
            title: "When you're making du'a for your family",
            verseKeys: ["25:74"], referenceLabel: "25:74, Surah Al Furqan",
            whyNote: "The servants of the Most Merciful ask: “Our Lord, grant us from among our wives and offspring comfort to our eyes and make us a leader [i.e., example] for the righteous.” A du'a for the family you have, and for the legacy it leaves."
        ),
        Situation(
            id: "feelingDistant", chapter: .bond,
            title: "When you feel distant from your spouse",
            verseKeys: ["30:21"], referenceLabel: "30:21, Surah Ar Rum",
            whyNote: "The affection and mercy between spouses are described as Allah's own placing: “He placed between you affection and mercy.” What He placed once, He can revive. The verse ends by calling this a sign “for a people who give thought.”"
        ),

        // III. THE STORM

        Situation(
            id: "marriageProblems", chapter: .storm,
            title: "When you're having marriage problems",
            verseKeys: ["4:35"], referenceLabel: "4:35, Surah An Nisa",
            whyNote: "The Qur'an's own protocol for marital rift: an arbitrator from his family and an arbitrator from her family. Then the promise: “If they both desire reconciliation, Allah will cause it between them.” A sincere intention to mend is itself the key Allah responds to."
        ),
        Situation(
            id: "constantlyArguing", chapter: .storm,
            title: "When you're constantly arguing",
            verseKeys: ["49:10"], referenceLabel: "49:10, Surah Al Hujurat",
            whyNote: "“The believers are but brothers, so make settlement between your brothers.” Before anything else, a believing couple are two believers, and settlement between believers is a command, followed by “And fear Allah that you may receive mercy.”"
        ),
        Situation(
            id: "spouseWrongedYou", chapter: .storm,
            title: "When your spouse has wronged you",
            verseKeys: ["42:40"], referenceLabel: "42:40, Surah Ash Shura",
            whyNote: "The verse permits a proportionate response, then immediately raises the ceiling: whoever pardons and makes reconciliation, “his reward is [due] from Allah.” Forgiving a spouse is not weakness. The Qur'an records its reward with Allah Himself."
        ),
        Situation(
            id: "loweringAnger", chapter: .storm,
            title: "When you're struggling to lower your anger",
            verseKeys: ["3:134"], referenceLabel: "3:134, Surah Ali 'Imran",
            whyNote: "Describing the people of Paradise: “who restrain anger and who pardon the people,” and the verse continues, “and Allah loves the doers of good.” Restraining anger is listed among the traits to which Allah attaches His love."
        ),
        Situation(
            id: "forgivingSpouse", chapter: .storm,
            title: "When you need to forgive your spouse",
            verseKeys: ["24:22"], referenceLabel: "24:22, Surah An Nur",
            whyNote: "Revealed when Abu Bakr swore to cut off support from a relative who had wronged his family (Sahih al Bukhari). Allah responded: “let them pardon and overlook. Would you not like that Allah should forgive you?” Abu Bakr said that he loved for Allah to forgive him, and restored it."
        ),
        Situation(
            id: "temptedToDivorce", chapter: .storm,
            title: "When you're tempted to divorce over disagreement",
            verseKeys: ["4:128"], referenceLabel: "4:128, Surah An Nisa",
            whyNote: "Aisha (may Allah be pleased with her) explained that this verse concerns a wife who, fearing separation, offers terms to keep the marriage (Sahih al Bukhari), and Allah rules on it: “and settlement is best.” An imperfect peace both choose is better, in Allah's words, than a separation neither truly wants."
        ),
        Situation(
            id: "marriageTested", chapter: .storm,
            title: "When your marriage is being tested",
            verseKeys: ["2:155", "2:156", "2:157"], referenceLabel: "2:155 to 157, Surah Al Baqarah",
            whyNote: "Allah promises that tests will come, “with something of fear and hunger and a loss,” then names the response that earns His blessings and mercy: “Indeed we belong to Allah, and indeed to Him we will return.”"
        ),
        Situation(
            id: "afraidWontLast", chapter: .storm,
            title: "When you're afraid your marriage won't last",
            verseKeys: ["2:155", "2:156", "2:157"], referenceLabel: "2:155 to 157, Surah Al Baqarah",
            whyNote: "Fear of loss is itself named in the verse: “We will surely test you with something of fear.” The glad tidings are given not to those who feel no fear, but to the patient who anchor themselves in inna lillahi wa inna ilayhi raji'un."
        ),
        Situation(
            id: "questioningChoice", chapter: .storm,
            title: "When you're questioning your choice",
            verseKeys: ["2:216"], referenceLabel: "2:216, Surah Al Baqarah",
            whyNote: "“perhaps you hate a thing and it is good for you,” the verse says. Regret reads only the present. Allah's knowledge encompasses the end of every path: “And Allah knows, while you know not.”"
        ),
        Situation(
            id: "trustingPlan", chapter: .storm,
            title: "When you're struggling to trust Allah's plan",
            verseKeys: ["2:216"], referenceLabel: "2:216, Surah Al Baqarah",
            whyNote: "The verse does not deny that some decreed things feel heavy. It openly describes what is “hateful to you.” It anchors trust not in how things feel, but in the One who decreed them."
        ),
        Situation(
            id: "trustingTiming", chapter: .storm,
            title: "When you're trusting Allah's timing",
            verseKeys: ["2:216"], referenceLabel: "2:216, Surah Al Baqarah",
            whyNote: "What is written for you arrives by decree, not by schedule. “Allah knows, while you know not” is the verse's final word, and the heart's resting place."
        ),
        Situation(
            id: "stayOrLeave", chapter: .storm,
            title: "When you're deciding whether to stay or leave",
            verseKeys: ["4:35"], referenceLabel: "4:35, Surah An Nisa",
            whyNote: "Before any final decision, the Qur'an prescribes a step: bring in a just arbitrator from each side. This verse is a reason to pause, involve wise family, and seek counsel. A weight this heavy is not meant to be carried alone. For practical rulings, consult a qualified scholar."
        ),

        // IV. THE FAMILY AND THE DECREE

        Situation(
            id: "raisingChildren", chapter: .family,
            title: "When you're raising children together",
            verseKeys: ["66:6"], referenceLabel: "66:6, Surah At Tahrim",
            whyNote: "“O you who have believed, protect yourselves and your families from a Fire.” Parenting in the Qur'an is guardianship. The deen of the household is a trust carried by both spouses together."
        ),
        Situation(
            id: "prayingForChildren", chapter: .family,
            title: "When you're praying for righteous children",
            verseKeys: ["37:100"], referenceLabel: "37:100, Surah As Saffat",
            whyNote: "The du'a of Ibrahim (peace be upon him): “My Lord, grant me [a child] from among the righteous.” He asked not simply for a child, but for righteousness in the child, and Allah answered him with a forbearing boy."
        ),
        Situation(
            id: "infertility", chapter: .family,
            title: "When you're struggling with infertility",
            verseKeys: ["21:89", "21:90"], referenceLabel: "21:89 and 90, Surah Al Anbiya",
            whyNote: "Zakariyya (peace be upon him) called on his Lord in old age, “My Lord, do not leave me alone [with no heir], while You are the best of inheritors,” and Allah says: “So We responded to him, and We gave to him John, and amended for him his wife.” The verses then describe those He answers: “they used to hasten to good deeds and supplicate Us in hope and fear.”"
        ),
        Situation(
            id: "spouseAway", chapter: .family,
            title: "When your spouse is away from home",
            verseKeys: ["12:86"], referenceLabel: "12:86, Surah Yusuf",
            whyNote: "Ya'qub (peace be upon him), aching for those absent from him, said: “I only complain of my suffering and my grief to Allah.” Longing is not weakness of faith. The Qur'an shows a prophet carrying it, and shows where he carried it."
        ),
        Situation(
            id: "divorceUnavoidable", chapter: .family,
            title: "When divorce becomes unavoidable",
            verseKeys: ["65:1"], referenceLabel: "65:1, Surah At Talaq",
            whyNote: "Even here, the Qur'an legislates with precision and dignity: the waiting period, keeping count, and not driving her from the home. And it leaves a door open: “You know not; perhaps Allah will bring about after that a [different] matter.” For any actual proceedings, consult a qualified scholar."
        ),
        Situation(
            id: "afterDivorce", chapter: .family,
            title: "When you're struggling after divorce",
            verseKeys: ["65:2", "65:3"], referenceLabel: "65:2 and 3, Surah At Talaq",
            whyNote: "It is no accident that the Qur'an's most famous promise of relief, a way out and provision from where you do not expect, sits in Surah At Talaq, The Divorce. It was sent down around exactly this wound."
        ),
        Situation(
            id: "grievingSpouse", chapter: .family,
            title: "When you're grieving the loss of your spouse",
            verseKeys: ["2:156", "2:157"], referenceLabel: "2:156 and 157, Surah Al Baqarah",
            whyNote: "“Indeed we belong to Allah, and indeed to Him we will return.” Upon those who say this in loss, Allah sends blessings and mercy. Grief met with these words is grief that Allah Himself honors."
        ),

        // V. THE HEART

        Situation(
            id: "needGuidance", chapter: .heart,
            title: "When you need guidance",
            verseKeys: ["1:6"], referenceLabel: "1:6, Surah Al Fatihah",
            whyNote: "The central plea of Al Fatihah, “Guide us to the straight path,” is recited in every rak'ah of every prayer. Guidance is asked for daily because it is needed daily, and Allah Himself taught us the words to ask with."
        ),
        Situation(
            id: "imanLow", chapter: .heart,
            title: "When your iman feels low",
            verseKeys: ["57:16"], referenceLabel: "57:16, Surah Al Hadid",
            whyNote: "“Has the time not come for those who have believed that their hearts should become humbly submissive at the remembrance of Allah and what has come down of the truth?” A gentle call sent to believers whose hearts had begun to settle. It is an invitation back, not a rejection."
        ),
        Situation(
            id: "salahConnection", chapter: .heart,
            title: "When you don't feel connected in salah",
            verseKeys: ["23:1", "23:2"], referenceLabel: "23:1 and 2, Surah Al Mu'minun",
            whyNote: "The surah opens by tying success itself to prayer with presence: the believers who succeed are those who are humbly submissive in their salah. Khushu' is named first among their qualities, something to ask Allah for and grow into, prayer by prayer."
        ),
        Situation(
            id: "hardToPray", chapter: .heart,
            title: "When you're finding it hard to pray",
            verseKeys: ["2:45"], referenceLabel: "2:45, Surah Al Baqarah",
            whyNote: "The verse itself admits the difficulty: seek help through patience and prayer, “and indeed, it is difficult except for the humbly submissive.” The Qur'an does not pretend salah is effortless. It names the struggle and the way through it."
        ),
        Situation(
            id: "losingFocus", chapter: .heart,
            title: "When you're losing focus",
            verseKeys: ["103:1", "103:2", "103:3"], referenceLabel: "103:1 to 3, Surah Al 'Asr",
            whyNote: "Surah Al 'Asr measures life by time itself: all of mankind is in loss except those who believe, do righteous deeds, and remind one another of truth and of patience. Three short ayat that reset what a day is actually for."
        ),
        Situation(
            id: "forgettingBlessings", chapter: .heart,
            title: "When you're forgetting Allah's blessings",
            verseKeys: ["14:7"], referenceLabel: "14:7, Surah Ibrahim",
            whyNote: "Your Lord Himself proclaimed it: “If you are grateful, I will surely increase you.” Gratitude in the Qur'an is not politeness. It is the stated condition of increase."
        ),
        Situation(
            id: "strugglingGrateful", chapter: .heart,
            title: "When you're struggling to be grateful",
            verseKeys: ["14:7"], referenceLabel: "14:7, Surah Ibrahim",
            whyNote: "Shukr is a promise with a guarantee attached, announced by Allah: “If you are grateful, I will surely increase you.” Start by naming one blessing at a time. Increase follows gratitude, not the other way around."
        ),
        Situation(
            id: "fightingTemptation", chapter: .heart,
            title: "When you're fighting temptation",
            verseKeys: ["29:69"], referenceLabel: "29:69, Surah Al 'Ankabut",
            whyNote: "For those who strive for Him: “We will surely guide them to Our ways.” The promise belongs to the one in the middle of the struggle. Striving itself draws Allah's guidance closer, and the verse ends: “And indeed, Allah is with the doers of good.”"
        ),
        Situation(
            id: "madeAMistake", chapter: .heart,
            title: "When you've made a mistake",
            verseKeys: ["39:53"], referenceLabel: "39:53, Surah Az Zumar",
            whyNote: "Perhaps the widest door in the Qur'an: “O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah.” Spoken to those who went wrong, in the softest of addresses, “My servants.”"
        ),
        Situation(
            id: "forgiveYourself", chapter: .heart,
            title: "When you're struggling to forgive yourself",
            verseKeys: ["39:53"], referenceLabel: "39:53, Surah Az Zumar",
            whyNote: "Allah addresses those who wronged themselves and forbids them despair. If He has not closed the door on you, you are not permitted to close it on yourself."
        ),
        Situation(
            id: "sameSin", chapter: .heart,
            title: "When you keep falling into the same sin",
            verseKeys: ["39:53"], referenceLabel: "39:53, Surah Az Zumar",
            whyNote: "The verse says Allah forgives all sins, and it addresses those who fear their sins are too many or too repeated to be forgiven. Return every time. His mercy does not run out before your repentance does."
        ),
        Situation(
            id: "selfControl", chapter: .heart,
            title: "When you're struggling with self control",
            verseKeys: ["79:40", "79:41"], referenceLabel: "79:40 and 41, Surah An Nazi'at",
            whyNote: "Paradise is promised to the one who feared standing before his Lord “and prevented the soul from [unlawful] inclination.” Restraint is framed not as deprivation but as a trade: desire held back now, a refuge that lasts forever."
        ),

        // VI. THE TRIALS

        Situation(
            id: "scaredOfFuture", chapter: .trials,
            title: "When you're scared of the future",
            verseKeys: ["9:51"], referenceLabel: "9:51, Surah At Tawbah",
            whyNote: "“Never will we be struck except by what Allah has decreed for us; He is our protector.” The future holds nothing that was not already written by your Protector, “And upon Allah let the believers rely.”"
        ),
        Situation(
            id: "afraidOfFailure", chapter: .trials,
            title: "When you're afraid of failure",
            verseKeys: ["9:51"], referenceLabel: "9:51, Surah At Tawbah",
            whyNote: "What reaches you was never going to miss you. The believer works with full effort, then rests the outcome on the One who decreed it, for “He is our protector.”"
        ),
        Situation(
            id: "worriedTomorrow", chapter: .trials,
            title: "When you're worried about tomorrow",
            verseKeys: ["65:2", "65:3"], referenceLabel: "65:2 and 3, Surah At Talaq",
            whyNote: "Taqwa opens a way out where none was visible, and provision arrives “from where he does not expect.” And the passage seals it: whoever relies upon Allah, He is sufficient for him."
        ),
        Situation(
            id: "feelAlone", chapter: .trials,
            title: "When you feel alone",
            verseKeys: ["50:16"], referenceLabel: "50:16, Surah Qaf",
            whyNote: "Allah describes His nearness as “closer to him than [his] jugular vein,” nearer than the vein in your own neck, aware of what your soul whispers. You may feel unseen by people. You have never once been unseen by Him."
        ),
        Situation(
            id: "tooManyBurdens", chapter: .trials,
            title: "When you're carrying too many burdens",
            verseKeys: ["2:286"], referenceLabel: "2:286, Surah Al Baqarah",
            whyNote: "“Allah does not charge a soul except [with that within] its capacity.” The load you carry has already been measured against you by the One who made you, and the same verse teaches the du'a asking Him to lighten it."
        ),
        Situation(
            id: "disappointed", chapter: .trials,
            title: "When you're disappointed",
            verseKeys: ["12:87"], referenceLabel: "12:87, Surah Yusuf",
            whyNote: "Ya'qub (peace be upon him), after years of loss, still tells his sons to go and search, and to “despair not of relief from Allah.” In the Qur'an, hope is not naivety. It is an article of faith."
        ),
        Situation(
            id: "movingOn", chapter: .trials,
            title: "When you're trying to move on",
            verseKeys: ["94:5", "94:6", "94:7", "94:8"], referenceLabel: "94:5 to 8, Surah Ash Sharh",
            whyNote: "Twice in a row: “Indeed, with hardship [will be] ease.” Then the instruction for the day after hardship: when you have finished, stand up for what is next, “And to your Lord direct [your] longing.”"
        ),
        Situation(
            id: "everyoneAhead", chapter: .trials,
            title: "When everyone else seems ahead of you",
            verseKeys: ["4:32"], referenceLabel: "4:32, Surah An Nisa",
            whyNote: "“And do not wish for that by which Allah has made some of you exceed others.” Each person's share was portioned deliberately. The verse then redirects the ache: “And ask Allah of His bounty,” directly, for your own."
        ),
        Situation(
            id: "someoneHurtsYou", chapter: .trials,
            title: "When someone hurts you",
            verseKeys: ["42:43"], referenceLabel: "42:43, Surah Ash Shura",
            whyNote: "“And whoever is patient and forgives,” the verse says, that is among the matters requiring true resolve. Patience under hurt is not weakness. The Qur'an ranks it among the greatest strengths of will."
        ),
        Situation(
            id: "needToForgive", chapter: .trials,
            title: "When you need to forgive",
            verseKeys: ["24:22"], referenceLabel: "24:22, Surah An Nur",
            whyNote: "“let them pardon and overlook. Would you not like that Allah should forgive you?” The verse binds your forgiveness of people to your hope for Allah's forgiveness of you. Forgive the way you hope to be forgiven."
        ),
        Situation(
            id: "afraidPeopleThink", chapter: .trials,
            title: "When you're afraid of what people think",
            verseKeys: ["3:173"], referenceLabel: "3:173, Surah Ali 'Imran",
            whyNote: "When people tried to frighten the believers, it only increased them in faith, and they answered: “Sufficient for us is Allah, and [He is] the best Disposer of affairs.” Only one approval truly matters."
        ),
        Situation(
            id: "feelingInsecure", chapter: .trials,
            title: "When you're feeling insecure",
            verseKeys: ["3:139"], referenceLabel: "3:139, Surah Ali 'Imran",
            whyNote: "“So do not weaken and do not grieve, and you will be superior if you are [true] believers.” Revealed after the wound of Uhud, it rebuilds a shaken people on iman, not on circumstances."
        ),
        Situation(
            id: "facingRejection", chapter: .trials,
            title: "When you're facing rejection",
            verseKeys: ["2:214"], referenceLabel: "2:214, Surah Al Baqarah",
            whyNote: "The verse recalls those before you who were shaken until even the messenger asked when Allah's help would come. The answer stands over every closed door: “Unquestionably, the help of Allah is near.”"
        ),

        // VII. THE PROVISION

        Situation(
            id: "worriedAboutRizq", chapter: .provision,
            title: "When you're worried about rizq",
            verseKeys: ["65:2", "65:3"], referenceLabel: "65:2 and 3, Surah At Talaq",
            whyNote: "Provision is promised “from where he does not expect” to the one who fears Allah and relies on Him. “Allah has already set for everything a [decreed] extent.” Rizq follows taqwa down roads you cannot map."
        ),
        Situation(
            id: "strugglingFinancially", chapter: .provision,
            title: "When you're struggling financially",
            verseKeys: ["71:10", "71:11", "71:12"], referenceLabel: "71:10 to 12, Surah Nuh",
            whyNote: "Nuh (peace be upon him) told his people: ask forgiveness of your Lord, and He will send rain in showers and “give you increase in wealth and children.” Istighfar is named in the Qur'an as a door of provision."
        ),
        Situation(
            id: "hesitantCharity", chapter: .provision,
            title: "When you're hesitant to give charity",
            verseKeys: ["2:245"], referenceLabel: "2:245, Surah Al Baqarah",
            whyNote: "“Who is it that would loan Allah a goodly loan so He may multiply it for him many times over?” Charity in the Qur'an is never loss. It is a loan to the One who repays multiplied."
        ),
        Situation(
            id: "comparingFinances", chapter: .provision,
            title: "When you're comparing your finances to others",
            verseKeys: ["17:30"], referenceLabel: "17:30, Surah Al Isra",
            whyNote: "“Indeed, your Lord extends provision for whom He wills and restricts [it].” Portions differ by His knowledge of His servants, not by their worth, for the verse ends by naming Him Aware and Seeing of His servants."
        ),
        Situation(
            id: "financialBurdens", chapter: .provision,
            title: "When financial burdens feel too heavy",
            verseKeys: ["2:286"], referenceLabel: "2:286, Surah Al Baqarah",
            whyNote: "“Allah does not charge a soul except [with that within] its capacity.” This burden was measured to your strength, and the verse closes with the du'a to say under it: our Lord, burden us not beyond what we can bear."
        ),
        Situation(
            id: "moneyStress", chapter: .provision,
            title: "When money is stressing you out",
            verseKeys: ["29:60"], referenceLabel: "29:60, Surah Al 'Ankabut",
            whyNote: "“And how many a creature carries not its [own] provision. Allah provides for it and for you.” Countless creatures hold no savings at all and are fed every day by the same Provider who feeds you."
        ),
        Situation(
            id: "afraidToSpend", chapter: .provision,
            title: "When you're afraid to spend for Allah's sake",
            verseKeys: ["34:39"], referenceLabel: "34:39, Surah Saba",
            whyNote: "Whatever you spend in His cause, “He will compensate it; and He is the best of providers.” Spending for Allah is never subtraction. The replacement is promised by the Provider Himself."
        ),
        Situation(
            id: "tomorrowRizq", chapter: .provision,
            title: "When you're worried about tomorrow",
            verseKeys: ["42:27"], referenceLabel: "42:27, Surah Ash Shura",
            whyNote: "Allah says that if He extended provision without measure, people would transgress, “But He sends [it] down in an amount which He wills.” What you have today is measured with knowledge, not withheld in neglect."
        ),
        Situation(
            id: "workNoResults", chapter: .provision,
            title: "When you're working hard but see no results",
            verseKeys: ["53:39"], referenceLabel: "53:39, Surah An Najm",
            whyNote: "“And that there is not for man except that [good] for which he strives.” No sincere effort is lost in Allah's ledger, even in the seasons when the results have not yet surfaced."
        ),
        Situation(
            id: "heartAttachedMoney", chapter: .provision,
            title: "When your heart is attached to money",
            verseKeys: ["18:46"], referenceLabel: "18:46, Surah Al Kahf",
            whyNote: "“Wealth and children are [but] adornment of the worldly life. But the enduring good deeds are better to your Lord.” One sentence that reorders what the heart holds tightly and what it holds lightly."
        ),
        Situation(
            id: "barakahInWealth", chapter: .provision,
            title: "When you need barakah in your wealth",
            verseKeys: ["14:7"], referenceLabel: "14:7, Surah Ibrahim",
            whyNote: "“If you are grateful, I will surely increase you.” Barakah enters through shukr. Gratitude over what is small is the Qur'an's stated path to its increase."
        ),
        Situation(
            id: "provisionDelayed", chapter: .provision,
            title: "When you think your provision is delayed",
            verseKeys: ["51:58"], referenceLabel: "51:58, Surah Adh Dhariyat",
            whyNote: "“Indeed, it is Allah who is the [continual] Provider, the firm possessor of strength.” What is written for you sits with Ar Razzaq Himself, whose strength never lapses and whose treasury never thins."
        ),
        Situation(
            id: "salaryNotEnough", chapter: .provision,
            title: "When your salary isn't enough",
            verseKeys: ["43:32"], referenceLabel: "43:32, Surah Az Zukhruf",
            whyNote: "“It is We who have apportioned among them their livelihood in the life of this world.” The numbers on a payslip are not the full account of what Allah moves toward you. Livelihood is administered by Him, not by the market alone."
        ),
        Situation(
            id: "scaredStartBusiness", chapter: .provision,
            title: "When you're scared to start a business",
            verseKeys: ["3:159"], referenceLabel: "3:159, Surah Ali 'Imran",
            whyNote: "“And when you have decided, then rely upon Allah. Indeed, Allah loves those who rely [upon Him].” The Qur'an's sequence for a venture: consult, deliberate, decide, then hand the outcome to Him."
        ),
        Situation(
            id: "stuckFinancially", chapter: .provision,
            title: "When you feel stuck in the same financial situation",
            verseKeys: ["13:11"], referenceLabel: "13:11, Surah Ar Ra'd",
            whyNote: "“Indeed, Allah will not change the condition of a people until they change what is in themselves.” Change begins inside, and Allah ties the changing of circumstances to it."
        ),
        Situation(
            id: "jealousOfSuccess", chapter: .provision,
            title: "When you're jealous of someone else's success",
            verseKeys: ["4:32"], referenceLabel: "4:32, Surah An Nisa",
            whyNote: "“And do not wish for that by which Allah has made some of you exceed others.” Then envy is redirected into du'a: “And ask Allah of His bounty.” His treasury is not diminished by what He gave them."
        ),
        Situation(
            id: "providingForFamily", chapter: .provision,
            title: "When you're worried about providing for your family",
            verseKeys: ["17:31"], referenceLabel: "17:31, Surah Al Isra",
            whyNote: "Revealed about those whose fear of poverty reached their own children, the verse answers the fear at its root: “We provide for them and for you.” Your dependents' provision does not come out of yours. Both come from Him."
        ),
        Situation(
            id: "afraidToRisk", chapter: .provision,
            title: "When you're afraid to take a risk",
            verseKeys: ["5:23"], referenceLabel: "5:23, Surah Al Ma'idah",
            whyNote: "Two men who feared Allah said: enter upon them through the gate, “And upon Allah rely, if you should be believers.” They spoke while the odds looked impossible. Tawakkul is trust that walks forward."
        ),
        Situation(
            id: "majorFinancialDecision", chapter: .provision,
            title: "When you're making a major financial decision",
            verseKeys: ["2:216"], referenceLabel: "2:216, Surah Al Baqarah",
            whyNote: "“perhaps you hate a thing and it is good for you; and perhaps you love a thing and it is bad for you.” Weigh it, seek counsel, pray istikharah, then trust that the outcome rests with the One who knows while you know not."
        ),
        Situation(
            id: "impatientForResults", chapter: .provision,
            title: "When you're impatient for results",
            verseKeys: ["2:153"], referenceLabel: "2:153, Surah Al Baqarah",
            whyNote: "“seek help through patience and prayer. Indeed, Allah is with the patient.” The promise is companionship during the waiting, not only reward at the end of it."
        ),
        Situation(
            id: "everyoneAheadDuha", chapter: .provision,
            title: "When you feel like everyone is ahead of you",
            verseKeys: ["93:4"], referenceLabel: "93:4, Surah Ad Duha",
            whyNote: "“And the Hereafter is better for you than the first [life].” Revealed to console the Prophet ﷺ himself. The timeline that actually matters ends better than it began."
        ),
        Situation(
            id: "payingBills", chapter: .provision,
            title: "When you're worried about paying bills",
            verseKeys: ["65:3"], referenceLabel: "65:3, Surah At Talaq",
            whyNote: "“And will provide for him from where he does not expect.” And whoever relies upon Allah, He is sufficient for him. The bill has a date. So does the provision, with the One who has set for everything an extent."
        ),
        Situation(
            id: "stressedAboutDebt", chapter: .provision,
            title: "When you're stressed about debt",
            verseKeys: ["2:286"], referenceLabel: "2:286, Surah Al Baqarah",
            whyNote: "“Allah does not charge a soul except [with that within] its capacity.” Carry it one payment at a time with the du'a this verse teaches: our Lord, burden us not beyond what we can bear."
        ),
        Situation(
            id: "losingJob", chapter: .provision,
            title: "When you're afraid of losing your job",
            verseKeys: ["57:22"], referenceLabel: "57:22, Surah Al Hadid",
            whyNote: "“No disaster strikes upon the earth or among yourselves except that it is in a register before We bring it into being.” Nothing about your provision is improvised. It was written, and so is what comes after it."
        ),
        Situation(
            id: "savingsLow", chapter: .provision,
            title: "When your savings are running low",
            verseKeys: ["29:60"], referenceLabel: "29:60, Surah Al 'Ankabut",
            whyNote: "“And how many a creature carries not its [own] provision. Allah provides for it and for you.” The account balance is not the source. The Provider is, and His providing has never depended on your reserves."
        ),
    ]
}
