import SwiftUI

/// A name of Allah with a short meaning and, where the content library
/// supplies one, a one-line reflection and a Qur'anic reference.
struct DivineName: Identifiable, Hashable {
    let id: String
    let arabic: String
    let transliteration: String
    let meaning: String
    let verse: String
    var meaningArabic: String? = nil
    var reflectionEnglish: String? = nil
    var reflectionArabic: String? = nil

    func meaning(_ language: AppLanguage) -> String {
        language == .arabic ? (meaningArabic ?? Self.fallbackArabicMeanings[id] ?? arabic) : meaning
    }

    func reflection(_ language: AppLanguage) -> String? {
        language == .arabic ? reflectionArabic : reflectionEnglish
    }

    private static let fallbackArabicMeanings = ["rahman": "واسع الرحمة", "rahim": "الرحيم بعباده", "malik": "المالك لكل شيء", "quddus": "المنزّه عن كل نقص", "salam": "السالم من كل عيب", "mumin": "واهب الأمن", "muhaymin": "الرقيب الحافظ", "aziz": "الغالب الذي لا يُغلب", "jabbar": "العلي القاهر", "mutakabbir": "المتعالي عن صفات الخلق", "khaliq": "خالق كل شيء", "bari": "موجد الخلق", "musawwir": "الذي أعطى كل شيء صورته", "hakim": "صاحب الحكمة التامة"]

    /// The library. Replaced by the full ninety-nine when `DivineNameLibrary` is present.
    static var all: [Self] { DivineNameLibrary.names.isEmpty ? attested : DivineNameLibrary.names }

    /// Names directly attested in Qur'an 59:22–24.
    static let attested: [Self] = [
        .init(id: "rahman", arabic: "الرَّحْمَٰن", transliteration: "Ar-Rahman", meaning: "The Most Merciful", verse: "59:22"),
        .init(id: "rahim", arabic: "الرَّحِيم", transliteration: "Ar-Rahim", meaning: "The Especially Merciful", verse: "59:22"),
        .init(id: "malik", arabic: "الْمَلِك", transliteration: "Al-Malik", meaning: "The King", verse: "59:23"),
        .init(id: "quddus", arabic: "الْقُدُّوس", transliteration: "Al-Quddus", meaning: "The Most Holy", verse: "59:23"),
        .init(id: "salam", arabic: "السَّلَام", transliteration: "As-Salam", meaning: "The Source of Peace", verse: "59:23"),
        .init(id: "mumin", arabic: "الْمُؤْمِن", transliteration: "Al-Mu’min", meaning: "The Giver of Security", verse: "59:23"),
        .init(id: "muhaymin", arabic: "الْمُهَيْمِن", transliteration: "Al-Muhaymin", meaning: "The Guardian", verse: "59:23"),
        .init(id: "aziz", arabic: "الْعَزِيز", transliteration: "Al-‘Aziz", meaning: "The Almighty", verse: "59:23"),
        .init(id: "jabbar", arabic: "الْجَبَّار", transliteration: "Al-Jabbar", meaning: "The Compeller", verse: "59:23"),
        .init(id: "mutakabbir", arabic: "الْمُتَكَبِّر", transliteration: "Al-Mutakabbir", meaning: "The Supremely Great", verse: "59:23"),
        .init(id: "khaliq", arabic: "الْخَالِق", transliteration: "Al-Khaliq", meaning: "The Creator", verse: "59:24"),
        .init(id: "bari", arabic: "الْبَارِئ", transliteration: "Al-Bari’", meaning: "The Originator", verse: "59:24"),
        .init(id: "musawwir", arabic: "الْمُصَوِّر", transliteration: "Al-Musawwir", meaning: "The Fashioner", verse: "59:24"),
        .init(id: "hakim", arabic: "الْحَكِيم", transliteration: "Al-Hakim", meaning: "The All-Wise", verse: "59:24")
    ]
}

/// The generated content library.
enum DivineNameLibrary {
    static var names: [DivineName] = DuaLibrary.names
    static func note(_ language: AppLanguage) -> String? {
        names.count == 99 ? language.pick(DuaLibrary.namesNoteEnglish, DuaLibrary.namesNoteArabic) : nil
    }
}

struct NamesOfAllahView: View {
    let language: AppLanguage
    var initialNameID: String? = nil
    @AppStorage("yaqeen.lastDivineName") private var lastNameID = "rahman"
    @State private var index = 0
    @State private var query = ""
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var copy: AppCopy { AppCopy(language: language) }
    private var names: [DivineName] { DivineName.all }
    private var matching: [DivineName] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return names.filter { term.isEmpty || $0.transliteration.localizedStandardContains(term) || $0.arabic.localizedStandardContains(term) || $0.meaning(language).localizedStandardContains(term) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    PageHeader(title: copy("The beautiful names", "الأسماء الحسنى"),
                               subtitle: names.count == 99
                                   ? copy("Ninety-nine names. Swipe through them.", "تسعة وتسعون اسمًا، تصفّحها بالسحب.")
                                   : copy("A selection from Surah Al-Hashr.", "مختارات من سورة الحشر."))
                    deck.id("deck")
                    HStack {
                        Text(copy("\(index + 1) of \(names.count)", "\(index + 1) من \(names.count)"))
                            .font(.system(.caption, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Color.yqSecondary)
                        Spacer()
                        if !names[index].verse.isEmpty,
                           let url = URL(string: "https://quran.com/\(names[index].verse.replacingOccurrences(of: ":", with: "/"))") {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Text(copy("Qur’an \(names[index].verse)", "القرآن \(names[index].verse)"))
                                    Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .bold))
                                }
                                .font(.yqCaptionBold)
                                .foregroundStyle(Color.yqAccentDeep)
                                .frame(minHeight: 32)
                            }
                        }
                    }
                    SearchField(prompt: copy("Find a name or a meaning", "ابحث عن اسم أو معنى"), text: $query)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: typeSize.isAccessibilitySize ? 2 : 3), spacing: 8) {
                        ForEach(matching) { name in
                            let position = names.firstIndex(of: name) ?? 0
                            Button {
                                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) { index = position }
                                proxy.scrollTo("deck", anchor: .top)
                            } label: {
                                NameTile(name: name, selected: position == index)
                            }
                            .buttonStyle(.yqPress)
                        }
                    }
                    if matching.isEmpty {
                        EmptyGuidanceState(title: copy("No names found", "لا توجد نتائج"),
                                           detail: copy("Try a meaning, like mercy or peace.", "جرّب معنى مثل الرحمة أو السلام."),
                                           symbol: "magnifyingglass")
                    }
                    if let note = DivineNameLibrary.note(language) {
                        Text(note).font(.yqCaption).foregroundStyle(Color.yqTertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            let wanted = initialNameID ?? lastNameID
            index = names.firstIndex { $0.id == wanted } ?? 0
        }
        .onChange(of: index) { _, value in
            guard names.indices.contains(value) else { return }
            lastNameID = names[value].id
        }
        .sensoryFeedback(.selection, trigger: index)
    }

    private var deck: some View {
        TabView(selection: $index) {
            ForEach(Array(names.enumerated()), id: \.element.id) { position, name in
                NameCard(name: name, language: language)
                    .padding(.vertical, 6)
                    .tag(position)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: typeSize.isAccessibilitySize ? 360 : 262)
    }
}

private struct NameCard: View {
    let name: DivineName
    let language: AppLanguage

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 10) {
                Text(name.arabic)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Color.yqAccentDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, .rightToLeft)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(name.transliteration)
                    .font(.yqTitle2)
                    .foregroundStyle(Color.yqInk)
                Text(name.meaning(language))
                    .font(.yqBody)
                    .foregroundStyle(Color.yqSecondary)
                if let reflection = name.reflection(language) {
                    Text(reflection)
                        .font(.yqSubhead)
                        .lineSpacing(4)
                        .foregroundStyle(Color.yqInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .padding(22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .yqCard(cornerRadius: 24)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct NameTile: View {
    let name: DivineName
    let selected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(name.arabic)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(selected ? Color.white : Color.yqInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(name.transliteration)
                .font(.yqCaptionBold)
                .foregroundStyle(selected ? Color.white.opacity(0.9) : Color.yqSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(.horizontal, 6)
        .background(selected ? Color.yqAccent : Color.yqSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(selected ? Color.clear : Color.yqHairline, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
