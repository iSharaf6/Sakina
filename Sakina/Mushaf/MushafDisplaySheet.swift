import SwiftUI

/// The reader's display controls: layout, reading direction, script,
/// translation, font size and ayah-marker colour. Everything lives in
/// UserDefaults under the `MushafPreferences` keys, so the reader updates
/// live while the sheet is open.
struct MushafDisplaySheet: View {
    let language: AppLanguage

    @AppStorage(MushafPreferences.layoutKey) private var layout: MushafPreferences.Layout = .page
    @AppStorage(MushafPreferences.directionKey) private var direction: MushafPreferences.Direction = .horizontal
    @AppStorage(MushafPreferences.scriptKey) private var script: QuranScript = .uthmani
    @AppStorage(MushafPreferences.translationKey) private var translationEdition = QuranTranslationEdition.saheehInternational.id
    @AppStorage(MushafPreferences.showTranslationKey) private var showTranslation = false
    @AppStorage(MushafPreferences.fontScaleKey) private var fontScale = 1.0
    @AppStorage(MushafPreferences.fitKey) private var fitPage = true

    @ObservedObject private var library = AyahLibrary.shared
    @Environment(\.dismiss) private var dismiss

    private var copy: AppCopy { AppCopy(language: language) }
    private var editions: [QuranTranslationEdition] { QuranTranslationStore.shared.editions }
    /// Pages fitted to the screen: the slider is a ceiling and the
    /// translation stays out of the page.
    private var fitting: Bool { layout == .page && fitPage }

    init(language: AppLanguage) {
        self.language = language
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section(copy("Layout", "التخطيط")) {
                        layoutChips
                        if layout == .page { fitCard }
                    }
                    section(copy("Direction", "اتجاه التصفح")) { directionChips }
                    section(copy("Script", "الرسم")) { scriptCards }
                    section(copy("Translation", "الترجمة")) { translationCard }
                    if fitting && script == .uthmani {
                        Text(copy("Printed pages keep their original lines. For larger, adjustable text, turn off Fit page to screen or choose Surah.",
                                  "تحافظ الصفحات المطبوعة على سطورها. لتكبير النص، أوقف ملاءمة الصفحة للشاشة أو اختر عرض السورة."))
                            .font(.yqCaption)
                            .foregroundStyle(Color.yqSecondary)
                    } else {
                        section(fitting ? copy("Maximum font size", "الحد الأقصى لحجم الخط") : copy("Font size", "حجم الخط")) { fontCard }
                    }
                    section(copy("Markers", "علامات الآيات")) { markersCard }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .yqScreen()
            .navigationTitle(copy("Display", "العرض"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
        }
        .yaqeenLanguage(language)
        .onChange(of: layout) { _, _ in Haptics.selection() }
        .onChange(of: fitPage) { _, _ in Haptics.press() }
        .onChange(of: direction) { _, _ in Haptics.selection() }
        .onChange(of: script) { _, _ in Haptics.selection() }
        .onChange(of: translationEdition) { _, _ in Haptics.selection() }
        .onChange(of: showTranslation) { _, _ in Haptics.press() }
        .onChange(of: library.colorReferenceMarks) { _, _ in Haptics.press() }
        .onChange(of: fontScale) { _, _ in Haptics.selection() }
    }

    // MARK: Sections

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            CapsLabel(text: title)
            content()
        }
    }

    // MARK: Layout and direction

    private var layoutChips: some View {
        HStack(spacing: 8) {
            ForEach(MushafPreferences.Layout.allCases) { option in
                chip(option.title(language), symbol: option == .page ? "book.closed" : "text.alignright",
                     selected: layout == option) {
                    layout = option
                }
            }
        }
    }

    /// Fit the whole page to the screen, as a printed mushaf page.
    private var fitCard: some View {
        Toggle(isOn: $fitPage) {
            VStack(alignment: .leading, spacing: 2) {
                Text(copy("Fit page to screen", "ملاءمة الصفحة للشاشة"))
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                Text(copy("The whole page on one screen, as in a printed mushaf.", "الصفحة كاملة على شاشة واحدة، كما في المصحف المطبوع."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
            }
        }
        .tint(.yqAccent)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 58)
        .yqCard(cornerRadius: 16)
    }

    private var directionChips: some View {
        HStack(spacing: 8) {
            ForEach(MushafPreferences.Direction.allCases) { option in
                chip(option.title(language), symbol: option == .horizontal ? "arrow.left.arrow.right" : "arrow.down",
                     selected: direction == option) {
                    direction = option
                }
            }
        }
    }

    private func chip(_ title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.yqCaptionBold)
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? Color.white : Color.yqAccentDeep)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(selected ? Color.yqAccentDeep : Color.yqAccentDeep.opacity(0.13), in: Capsule(style: .continuous))
            .contentShape(Capsule())
        }
        .buttonStyle(.yqPressSoft)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    // MARK: Script

    private var scriptCards: some View {
        VStack(spacing: 8) {
            ForEach(QuranScript.allCases) { option in
                let selected = script == option
                Button {
                    script = option
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.title(language))
                                .font(.yqBodyMedium)
                                .foregroundStyle(Color.yqInk)
                            Text(option.detail(language))
                                .font(.yqCaption)
                                .foregroundStyle(Color.yqSecondary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selected ? Color.yqAccent : Color.yqTertiary)
                    }
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 58)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .yqCard(cornerRadius: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(selected ? Color.yqAccent : Color.clear, lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.yqPressSoft)
                .accessibilityLabel("\(option.title(language)), \(option.detail(language))")
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }

    // MARK: Translation

    private var currentEdition: QuranTranslationEdition {
        QuranTranslationStore.shared.edition(translationEdition) ?? .saheehInternational
    }

    private var translationCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $showTranslation) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(copy("Show translation", "إظهار الترجمة"))
                        .font(.yqBodyMedium)
                        .foregroundStyle(Color.yqInk)
                    if fitting {
                        Text(copy("Not shown on fitted pages; turn off Fit page to screen or use the Surah layout.",
                                  "لا تظهر في الصفحات الملاءمة للشاشة؛ أوقف ملاءمة الصفحة أو استخدم تخطيط السورة."))
                            .font(.yqCaption)
                            .foregroundStyle(Color.yqSecondary)
                    }
                }
            }
            .tint(.yqAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 54)

            ForEach(editions) { edition in
                RowDivider(inset: 14)
                editionRow(edition)
            }
        }
        .yqCard(cornerRadius: 16)
    }

    /// One translation, name over author, with a check on the chosen one.
    private func editionRow(_ edition: QuranTranslationEdition) -> some View {
        let selected = edition.id == currentEdition.id
        return Button {
            translationEdition = edition.id
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(edition.name)
                        .font(.yqBodyMedium)
                        .foregroundStyle(Color.yqInk)
                    if edition.author != edition.name {
                        Text(edition.author)
                            .font(.yqCaption)
                            .foregroundStyle(Color.yqSecondary)
                    }
                }
                Spacer(minLength: 8)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.yqAccent)
                }
            }
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.yqPressSoft)
        .disabled(!showTranslation)
        .opacity(showTranslation ? 1 : 0.45)
        .accessibilityLabel(editionLabel(edition))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func editionLabel(_ edition: QuranTranslationEdition) -> String {
        edition.author == edition.name ? edition.name : "\(edition.name) · \(edition.author)"
    }

    // MARK: Font size

    private var fontCard: some View {
        VStack(spacing: 14) {
            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(.arabic(24 * fontScale))
                .foregroundStyle(Color.yqInk)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 64)
                .accessibilityHidden(true)

            Slider(
                value: $fontScale,
                in: MushafPreferences.fontScaleRange,
                step: 0.05
            ) {
                Text(copy("Font size", "حجم الخط"))
            } minimumValueLabel: {
                Text("A")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.yqSecondary)
            } maximumValueLabel: {
                Text("A")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.yqSecondary)
            }
            .tint(.yqAccent)
            .accessibilityValue("\(Int((fontScale * 100).rounded()))%")

            if fitting {
                Text(copy("Fitted pages use this as a ceiling and shrink only as far as the page needs.",
                          "تستخدم الصفحات الملاءمة هذا الحجم حدًا أقصى وتصغر بقدر ما تحتاج الصفحة فقط."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .yqCard(cornerRadius: 16)
    }

    // MARK: Markers

    private var markersCard: some View {
        Toggle(isOn: $library.colorReferenceMarks) {
            VStack(alignment: .leading, spacing: 2) {
                Text(copy("Colour ayah markers", "تلوين أرقام الآيات"))
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                Text(copy("Numbers take the highlight colour", "تأخذ الأرقام لون التظليل"))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
            }
        }
        .tint(.yqAccent)
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
        .yqCard(cornerRadius: 16)
    }
}
