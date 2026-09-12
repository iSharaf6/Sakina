import SwiftUI

/// The same preferences surface is opened from the reader and app Settings.
struct MushafDisplaySheet: View {
    let language: AppLanguage
    @AppStorage(MushafPreferences.presentationKey) private var presentation: MushafPreferences.Presentation = .traditional
    @AppStorage(MushafPreferences.themeKey) private var theme: MushafPreferences.Theme = .system
    @AppStorage(MushafPreferences.layoutKey) private var layout: MushafPreferences.Layout = .page
    @AppStorage(MushafPreferences.directionKey) private var direction: MushafPreferences.Direction = .horizontal
    @AppStorage(MushafPreferences.scriptKey) private var script: QuranScript = .uthmani
    @AppStorage(MushafPreferences.translationKey) private var translationEdition = QuranTranslationEdition.saheehInternational.id
    @AppStorage(SettingsKeys.translationVisible) private var showTranslation = true
    @AppStorage(SettingsKeys.transliterationVisible) private var showTransliteration = true
    @AppStorage(SettingsKeys.arabicScale) private var fontScale = 1.0
    @ObservedObject private var library = AyahLibrary.shared
    @Environment(\.dismiss) private var dismiss
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    section(copy("Your reading view", "طريقة القراءة")) {
                        HStack(spacing: 12) {
                            modeCard(.traditional)
                            modeCard(.digital)
                        }
                    }
                    section(copy("Appearance", "المظهر")) {
                        Picker(copy("Appearance", "المظهر"), selection: $theme) {
                            ForEach(MushafPreferences.Theme.allCases) { Text($0.title(language)).tag($0) }
                        }.pickerStyle(.segmented)
                    }
                    section(copy("Arabic script", "الرسم القرآني")) {
                        VStack(spacing: 0) {
                            ForEach(QuranScript.allCases) { option in
                                scriptRow(option)
                                if option != .indopak { Divider().padding(.leading, 16) }
                            }
                        }.yqCard(cornerRadius: 18)
                        Text(copy("Tajweed and IndoPak use the flexible Digital view.", "يتوفر رسم التجويد والرسم الهندي في العرض الرقمي المرن."))
                            .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    }
                    section(copy("Text & meaning", "النص والمعنى")) {
                        VStack(spacing: 16) {
                            if let sample = QuranStore.shared.ayah("1:2") {
                                Text(QuranTextRenderer.swiftUI(sample, script: script, size: 25 * fontScale, includeMarker: false))
                                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            HStack {
                                Text(copy("Arabic size", "حجم الخط العربي")).font(.yqBodyMedium)
                                Spacer()
                                Text("\(Int((fontScale * 100).rounded()))%")
                                    .font(.yqCaption).monospacedDigit().foregroundStyle(Color.yqSecondary)
                            }
                            Slider(value: $fontScale, in: MushafPreferences.fontScaleRange, step: 0.05)
                                .accessibilityLabel(copy("Arabic text size", "حجم النص العربي"))
                            Divider()
                            Toggle(copy("English meaning", "المعنى بالإنجليزية"), isOn: $showTranslation)
                            Toggle(copy("Transliteration", "الكتابة بحروف لاتينية"), isOn: $showTransliteration)
                            if showTranslation {
                                Picker(copy("Translation", "الترجمة"), selection: $translationEdition) {
                                    ForEach(QuranTranslationStore.shared.editions) { Text($0.name).tag($0.id) }
                                }.font(.yqSubhead)
                            }
                        }
                        .font(.yqBodyMedium)
                        .padding(16).yqCard(cornerRadius: 18)
                        Text(copy("These settings are shared with the app. Changing size or reading aids opens Digital; Traditional keeps the printed page.",
                                  "تُطبَّق هذه الإعدادات في أنحاء التطبيق. يؤدي تغيير حجم النص أو تفعيل وسائل المساعدة على القراءة إلى فتح العرض الرقمي، بينما يحتفظ عرض المصحف بتنسيق الصفحة المطبوعة."))
                            .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    }
                    section(copy("Navigation", "التصفح")) {
                        VStack(spacing: 14) {
                            if presentation == .digital {
                                Picker(copy("Read by", "القراءة حسب"), selection: $layout) {
                                    ForEach(MushafPreferences.Layout.allCases) { Text($0.title(language)).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                            Picker(copy("Direction", "اتجاه التصفح"), selection: $direction) {
                                ForEach(MushafPreferences.Direction.allCases) { Text($0.title(language)).tag($0) }
                            }.pickerStyle(.segmented)
                            Toggle(copy("Coloured ayah markers", "تلوين علامات الآيات"), isOn: $library.colorReferenceMarks)
                                .font(.yqSubhead)
                        }
                    }
                }
                .padding(20).padding(.bottom, 24)
            }
            .background(Color.yqCanvas.ignoresSafeArea())
            .navigationTitle(copy("Reading appearance", "مظهر القراءة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(copy("Done", "تم")) { dismiss() } } }
        }
        .tint(.yqAccentDeep)
        .yaqeenLanguage(language)
        .preferredColorScheme(theme.colorScheme)
        .onChange(of: fontScale) { _, _ in useDigital() }
        .onChange(of: showTranslation) { _, _ in useDigital() }
        .onChange(of: showTransliteration) { _, _ in useDigital() }
    }
    private func scriptRow(_ option: QuranScript) -> some View {
                                Button {
                                    script = option
                                    if option != .uthmani { presentation = .digital }
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(option.title(language)).font(.yqBodyMedium).foregroundStyle(Color.yqInk)
                                            Text(option.detail(language)).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: script == option ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(script == option ? Color.yqAccentDeep : Color.yqTertiary)
                                    }
                                    .padding(16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(script == option ? [.isSelected] : [])
    }
    private func useDigital() { presentation = .digital; Haptics.selection() }
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(title).font(.yqHeadline); content() }
    }
    private func modeCard(_ option: MushafPreferences.Presentation) -> some View {
        Button {
            if option == .traditional { script = .uthmani; layout = .page }
            presentation = option
            Haptics.selection()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    if option == .traditional { PageFrame(fit: true) }
                    else { RoundedRectangle(cornerRadius: 5).fill(Color.yqSurface) }
                    VStack(spacing: 6) {
                        Text("بِسْمِ ٱللَّهِ").font(.custom(QuranTextRenderer.uthmaniFontName, fixedSize: 21)).foregroundStyle(Color.yqInk)
                        if option == .digital {
                            Text("In the name of Allah").font(.system(size: 8)).foregroundStyle(Color.yqSecondary)
                        }
                    }
                }.frame(height: 85)
                HStack {
                    Text(option.title(language)).font(.yqSubheadBold)
                    Spacer(minLength: 0)
                    if presentation == option { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.yqAccentDeep) }
                }
                Text(option == .traditional ? copy("The familiar printed page", "الصفحة المطبوعة المألوفة") : copy("Room to read your way", "قراءة تناسبك"))
                    .font(.system(size: 11)).foregroundStyle(Color.yqSecondary).lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .yqCard(cornerRadius: 18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(presentation == option ? Color.yqAccentDeep : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain).foregroundStyle(Color.yqInk)
        .accessibilityLabel(option.title(language))
        .accessibilityAddTraits(presentation == option ? [.isSelected] : [])
    }
}
