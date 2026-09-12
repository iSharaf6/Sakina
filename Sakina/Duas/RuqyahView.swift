import SwiftUI

// MARK: - Ruqyah

/// Healing words from the Qur’an and the Sunnah, read in the shared du’a reader.
struct RuqyahView: View {
    let language: AppLanguage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(DuaCollection.savedKey) private var savedRaw = ""
    @State private var appeared = false

    private var copy: AppCopy { AppCopy(language: language) }
    private var quran: [GuidanceSupplication] { RuqyahCatalog.quran }
    private var sunnah: [GuidanceSupplication] { RuqyahCatalog.sunnah }
    private var quranTitle: String { copy("Ruqyah from the Qur’an", "الرقية من القرآن") }
    private var sunnahTitle: String { copy("Ruqyah from the Sunnah", "الرقية من السنة") }
    private var saved: [String] { DuaCollection.savedIDs(savedRaw) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: copy("Ruqyah", "الرقية"),
                           subtitle: copy("Healing words from the Qur’an and the Sunnah.", "آيات وأدعية للرقية من القرآن والسنة."))
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)

                VStack(spacing: 12) {
                    sectionCard(eyebrow: copy("From the Qur’an", "من القرآن"),
                                title: quranTitle,
                                detail: copy("\(quran.count) passages", ArabicCount.label(quran.count,
                                    zero: "لا مقاطع", one: "مقطع واحد", two: "مقطعان", few: "مقاطع", many: "مقطعًا", other: "مقطع")),
                                artwork: .healing, entries: quran)
                    sectionCard(eyebrow: copy("From the Sunnah", "من السنة"),
                                title: sunnahTitle,
                                detail: copy("\(sunnah.count) du’as", ArabicCount.label(sunnah.count,
                                    zero: "لا أدعية", one: "دعاء واحد", two: "دعاءان", few: "أدعية", many: "دعاءً", other: "دعاء")),
                                artwork: .sunnah, entries: sunnah)
                }
                .revealed(1, appeared: appeared, reduceMotion: reduceMotion)

                etiquette.revealed(2, appeared: appeared, reduceMotion: reduceMotion)

                list(header: copy("All passages", "كل المقاطع"), entries: quran, collectionTitle: quranTitle)
                    .revealed(3, appeared: appeared, reduceMotion: reduceMotion)
                list(header: copy("From the Sunnah", "من السنة"), entries: sunnah, collectionTitle: sunnahTitle)
                    .revealed(4, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { appeared = true }
    }

    // MARK: Section cards

    @ViewBuilder
    private func sectionCard(eyebrow: String, title: String, detail: String,
                             artwork: CompanionArtwork, entries: [GuidanceSupplication]) -> some View {
        if let first = entries.first {
            NavigationLink {
                DuaReaderView(dua: first, sequence: entries, collectionTitle: title)
            } label: {
                HStack(spacing: 16) {
                    CompanionIllustration(artwork: artwork, size: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        CapsLabel(text: eyebrow, color: .yqAccentDeep)
                        Text(title)
                            .font(.yqTitle2)
                            .foregroundStyle(Color.yqInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(detail)
                            .font(.yqSubhead)
                            .foregroundStyle(Color.yqSecondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: language == .arabic ? "arrow.left" : "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.yqOnAccent)
                        .frame(width: 36, height: 36)
                        .background(Color.yqAccent, in: Circle())
                }
                .multilineTextAlignment(.leading)
                .padding(16)
                .yqCard(cornerRadius: 22)
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.yqPress)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Etiquette

    private struct Etiquette: Identifiable {
        let symbol: String
        let title: String
        let detail: String
        var id: String { symbol }
    }

    private var etiquetteRows: [Etiquette] {
        [
            Etiquette(symbol: "text.book.closed",
                      title: copy("Read with conviction", "اقرأ بيقين"),
                      detail: copy("Clear Arabic, present heart, certain that healing is from Allah.", "اقرأ بوضوح، مع حضور القلب واليقين بأن الشفاء من الله.")),
            Etiquette(symbol: "wind",
                      title: copy("Blow lightly after reciting", "انفث بعد القراءة"),
                      detail: copy("A light breath over the hands or the painful place, as the Prophet ﷺ did.", "نفث خفيف على اليدين أو موضع الألم كما فعل النبي ﷺ.")),
            Etiquette(symbol: "drop",
                      title: copy("Water or oil is fine", "على ماء أو زيت"),
                      detail: copy("You may recite over water or oil to drink or apply.", "يجوز القراءة على ماء أو زيت للشرب أو الدهن.")),
            Etiquette(symbol: "cross.case",
                      title: copy("With medicine, not instead of it", "مع التداوي"),
                      detail: copy("Keep every appointment and prescription. Ruqyah sits beside them.", "واصل مراجعاتك الطبية وأخذ أدويتك مع الرقية.")),
            Etiquette(symbol: "hand.raised",
                      title: copy("Avoid anyone who asks odd things", "احذر من يطلب أمورًا غريبة"),
                      detail: copy("A mother’s name, an amulet, a sacrifice or a fee for secrets: walk away.", "ابتعد عمّن يطلب اسم الأم أو التمائم أو الذبائح أو مالًا مقابل أسرار مزعومة.")),
        ]
    }

    private var etiquette: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("How ruqyah is done", "كيف تكون الرقية"))
            RowGroup {
                ForEach(Array(etiquetteRows.enumerated()), id: \.element.id) { i, row in
                    BadgeRow(symbol: row.symbol, tint: .yqAccent, title: row.title, subtitle: row.detail, badgeStyle: .tinted) {
                        EmptyView()
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    if i < etiquetteRows.count - 1 { RowDivider() }
                }
            }
        }
    }

    // MARK: Lists

    private func list(header: String, entries: [GuidanceSupplication], collectionTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(header)
            RowGroup {
                ForEach(Array(entries.enumerated()), id: \.element.id) { i, dua in
                    NavigationLink {
                        DuaReaderView(dua: dua, sequence: entries, collectionTitle: collectionTitle)
                    } label: {
                        DuaListRow(dua: dua, index: i + 1, language: language, saved: saved.contains(dua.id))
                    }
                    .buttonStyle(.yqPressSoft)
                    if i < entries.count - 1 { RowDivider(inset: 54) }
                }
            }
        }
    }
}
