import SwiftUI

// MARK: - Benefits of adhkar
//
// An editorial page: a definition card, eight woven benefit cards, and a
// door into the counter. References are limited to what is certain.

struct AdhkarBenefitsView: View {
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var appeared = false

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: copy("Benefits of adhkar", "فضائل الأذكار"),
                           subtitle: copy("Eight reasons the tongue should never rest.", "ثمانية أسباب تجعل لسانك لا يفتر."))
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                definition
                    .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                VStack(spacing: 12) {
                    ForEach(Array(AdhkarBenefit.all.enumerated()), id: \.element.id) { position, benefit in
                        BenefitCard(benefit: benefit, position: position, language: language, woven: !typeSize.isAccessibilitySize)
                            .revealed(position + 2, appeared: appeared, reduceMotion: reduceMotion)
                    }
                }
                closing
                    .revealed(AdhkarBenefit.all.count + 2, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { appeared = true }
    }

    // MARK: Definition

    private var definition: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            VStack(alignment: .leading, spacing: 10) {
                CapsLabel(text: copy("The word", "الكلمة"))
                Text(copy("Adhkar is the plural of dhikr: remembrance, or mention.",
                          "الأذكار جمع ذِكر، ومعناه التذكّر أو الإتيان على الشيء باللسان."))
                    .font(.yqHeadline)
                    .foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(copy("In practice it means keeping Allah close and often, with the words He and His Messenger ﷺ taught: SubhanAllah, Alhamdulillah, Allahu Akbar, and the rest.",
                          "وفي العمل: أن تُبقي الله قريبًا وكثيرًا على لسانك وفي قلبك، بالكلمات التي علّمها هو ورسوله ﷺ: سبحان الله، والحمد لله، والله أكبر، وما سواها."))
                    .font(.yqSubhead)
                    .lineSpacing(4)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text("ذِكْر")
                .font(.arabicProse(44))
                .foregroundStyle(Color.yqAccentDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityLabel(copy("Dhikr", "ذكر"))
        }
        .padding(20)
        .yqCard(cornerRadius: 22)
    }

    // MARK: Closing

    private var closing: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(copy("None of this needs a mat, a place or a time. It needs a tongue that moves and a heart that listens.",
                      "لا يحتاج شيء من هذا إلى سجادة أو مكان أو وقت. يحتاج لسانًا يتحرك وقلبًا يُنصت."))
                .font(.yqBody)
                .lineSpacing(5)
                .foregroundStyle(Color.yqInk)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                DhikrListView(language: language)
            } label: {
                PrimaryButton(title: copy("Start now", "ابدأ الآن"), symbol: language == .arabic ? "arrow.left" : "arrow.right")
            }
            .buttonStyle(.yqPress)
            Text(copy("Qur’an references link to quran.com; hadith references link to sunnah.com.",
                      "مراجع القرآن تفتح quran.com، ومراجع الحديث تفتح sunnah.com."))
                .font(.yqCaption)
                .foregroundStyle(Color.yqTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .yqCard(cornerRadius: 22)
    }
}

// MARK: - Benefit model

private struct AdhkarBenefit: Identifiable {
    let id: Int
    let symbol: String
    let titleEnglish: String
    let titleArabic: String
    let bodyEnglish: String
    let bodyArabic: String
    let sourceEnglish: String?
    let sourceArabic: String?
    let sourceURL: String?

    func title(_ language: AppLanguage) -> String { language.pick(titleEnglish, titleArabic) }
    func body(_ language: AppLanguage) -> String { language.pick(bodyEnglish, bodyArabic) }
    func source(_ language: AppLanguage) -> String? {
        guard let sourceEnglish, let sourceArabic else { return nil }
        return language.pick(sourceEnglish, sourceArabic)
    }

    static let all: [AdhkarBenefit] = [
        AdhkarBenefit(
            id: 1, symbol: "sparkles",
            titleEnglish: "It polishes the heart",
            titleArabic: "يجلو القلب",
            bodyEnglish: "Hearts tarnish quietly: through neglect, through the noise of a day. Remembrance is the cloth you run over them, and the shine returns with every pass.",
            bodyArabic: "تصدأ القلوب في صمت: بالغفلة، وبضجيج اليوم. والذكر هو الخرقة التي تمرّها عليها، فيعود اللمعان مع كل مسحة.",
            sourceEnglish: nil, sourceArabic: nil, sourceURL: nil
        ),
        AdhkarBenefit(
            id: 2, symbol: "heart.fill",
            titleEnglish: "It deepens your relationship with Allah",
            titleArabic: "يعمّق صلتك بالله",
            bodyEnglish: "Closeness grows the way any closeness does: by turning up often, and speaking. A few words at the sink, in the car, before sleep. Over months, that becomes a relationship.",
            bodyArabic: "تنمو القربى كما تنمو أي قربى: بكثرة الحضور والكلام. كلمات قليلة عند المغسلة، وفي السيارة، وقبل النوم. ومع الشهور تصير علاقة.",
            sourceEnglish: nil, sourceArabic: nil, sourceURL: nil
        ),
        AdhkarBenefit(
            id: 3, symbol: "person.2.fill",
            titleEnglish: "Allah remembers those who remember Him",
            titleArabic: "يذكرك الله إذا ذكرته",
            bodyEnglish: "It is a promise, not a hope: “So remember Me; I will remember you.” Every mention on your tongue is answered by a mention far above it.",
            bodyArabic: "وعد لا رجاء: «فاذكروني أذكركم». كل ذكر على لسانك يقابله ذكر أعلى منه بكثير.",
            sourceEnglish: "Qur’an 2:152", sourceArabic: "القرآن ٢:١٥٢", sourceURL: "https://quran.com/2/152"
        ),
        AdhkarBenefit(
            id: 4, symbol: "hands.and.sparkles.fill",
            titleEnglish: "Mindful dhikr is gratitude",
            titleArabic: "الذكر بوعي شكر",
            bodyEnglish: "The Prophet ﷺ told Mu‘adh to say after every prayer: “O Allah, help me to remember You, to thank You, and to worship You well.” Remembering and thanking sit in one breath.",
            bodyArabic: "أوصى النبي ﷺ معاذًا أن يقول دبر كل صلاة: «اللهم أعنّي على ذكرك وشكرك وحسن عبادتك». فالذكر والشكر في نَفَس واحد.",
            sourceEnglish: "Abu Dawud 1522", sourceArabic: "أبو داود ١٥٢٢", sourceURL: "https://sunnah.com/abudawud:1522"
        ),
        AdhkarBenefit(
            id: 5, symbol: "shield.fill",
            titleEnglish: "Daily adhkar are a protection",
            titleArabic: "الأذكار اليومية حماية",
            bodyEnglish: "Recite Ayat al-Kursi before sleep and, in the Prophet’s ﷺ words, “a guardian from Allah will remain with you” until morning. The morning and evening adhkar wrap the rest of the day.",
            bodyArabic: "اقرأ آية الكرسي قبل النوم، ففي قول النبي ﷺ: «لن يزال عليك من الله حافظ» حتى تصبح. وأذكار الصباح والمساء تلفّ ما بقي من اليوم.",
            sourceEnglish: "Bukhari 2311", sourceArabic: "البخاري ٢٣١١", sourceURL: "https://sunnah.com/bukhari:2311"
        ),
        AdhkarBenefit(
            id: 6, symbol: "leaf.fill",
            titleEnglish: "It is the lightest act of worship",
            titleArabic: "أخفّ العبادات",
            bodyEnglish: "“Two phrases light on the tongue, heavy on the scale, beloved to the Most Merciful.” No wudu, no direction, no set time. Just words, said anywhere.",
            bodyArabic: "«كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن». لا وضوء ولا قبلة ولا وقت. كلمات فقط، تُقال في أي مكان.",
            sourceEnglish: "Bukhari 6406", sourceArabic: "البخاري ٦٤٠٦", sourceURL: "https://sunnah.com/bukhari:6406"
        ),
        AdhkarBenefit(
            id: 7, symbol: "hand.raised.fill",
            titleEnglish: "It holds you back from sin",
            titleArabic: "يصدّك عن الذنب",
            bodyEnglish: "The Qur’an says prayer restrains from wrongdoing, then adds: “and the remembrance of Allah is greater.” A tongue busy with His name finds it harder to say, or do, what it shouldn’t.",
            bodyArabic: "يقول القرآن إن الصلاة تنهى عن الفحشاء والمنكر، ثم يضيف: «ولذكر الله أكبر». لسان مشغول باسمه يصعب عليه أن يقول أو يفعل ما لا ينبغي.",
            sourceEnglish: "Qur’an 29:45", sourceArabic: "القرآن ٢٩:٤٥", sourceURL: "https://quran.com/29/45"
        ),
        AdhkarBenefit(
            id: 8, symbol: "brain.head.profile",
            titleEnglish: "It calms the mind",
            titleArabic: "يهدّئ الذهن",
            bodyEnglish: "“Truly, in the remembrance of Allah do hearts find rest.” Not a technique, though it works like one: a steady rhythm, a single focus, and a Listener who never tires of you.",
            bodyArabic: "«ألا بذكر الله تطمئن القلوب». ليس أسلوبًا للاسترخاء، وإن كان يعمل كأسلوب: إيقاع ثابت، وتركيز واحد، ومستمع لا يملّ منك.",
            sourceEnglish: "Qur’an 13:28", sourceArabic: "القرآن ١٣:٢٨", sourceURL: "https://quran.com/13/28"
        ),
    ]
}

// MARK: - Benefit card

/// One benefit. Even cards carry the numeral on the leading side and sit
/// flush leading; odd cards mirror, so the column reads as woven.
private struct BenefitCard: View {
    let benefit: AdhkarBenefit
    let position: Int
    let language: AppLanguage
    var woven = true

    private var mirrored: Bool { woven && !position.isMultiple(of: 2) }
    private var numeral: String { String(format: "%02d", benefit.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if !mirrored { numeralView }
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    IconBadge(symbol: benefit.symbol, tint: .yqAccent, size: 32, style: .tinted)
                    Text(benefit.title(language))
                        .font(.yqHeadline)
                        .foregroundStyle(Color.yqInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(benefit.body(language))
                    .font(.yqSubhead)
                    .lineSpacing(4)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let source = benefit.source(language) {
                    if let raw = benefit.sourceURL, let url = URL(string: raw) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Tag(text: source)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.yqAccentDeep)
                            }
                            .frame(minHeight: 32)
                        }
                        .accessibilityLabel(language.pick("Source: \(source)", "المصدر: \(source)"))
                    } else {
                        Tag(text: source)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if mirrored { numeralView }
        }
        .multilineTextAlignment(.leading)
        .padding(18)
        .yqCard(cornerRadius: 20)
        .padding(.leading, mirrored ? 18 : 0)
        .padding(.trailing, woven && !mirrored ? 18 : 0)
        .accessibilityElement(children: .combine)
    }

    private var numeralView: some View {
        Text(numeral)
            .font(.system(size: 34, weight: .bold).monospacedDigit())
            .foregroundStyle(Color.yqSecondary.opacity(0.55))
            .frame(minWidth: 44, alignment: mirrored ? .trailing : .leading)
            .accessibilityHidden(true)
    }
}
