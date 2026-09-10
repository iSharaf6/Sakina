import SwiftUI

// MARK: - Surah picker

/// All 114 surahs with search by number, Arabic name or English name.
struct SurahPickerSheet: View {
    let language: AppLanguage
    let current: Int
    let onPick: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var copy: AppCopy { AppCopy(language: language) }

    private var filtered: [QuranSurah] {
        let store = QuranStore.shared
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return store.surahs }
        let number = Self.number(from: trimmed)
        let folded = Self.fold(trimmed)
        return store.surahs.filter { surah in
            if let number, surah.number == number { return true }
            if let number, String(surah.number).hasPrefix(String(number)) { return true }
            return Self.fold(surah.nameSimple).contains(folded)
                || Self.fold(surah.nameTranslated).contains(folded)
                || Self.fold(surah.nameArabic).contains(folded)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { surah in
                    Button {
                        Haptics.selection()
                        onPick(surah.number)
                        dismiss()
                    } label: {
                        row(surah)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.yqHairline)
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .accessibilityLabel(accessibilityLabel(for: surah))
                    .accessibilityAddTraits(surah.number == current ? .isSelected : [])
                }
                if filtered.isEmpty {
                    Text(copy("No surah matches.", "لا توجد سورة مطابقة."))
                        .font(.yqSubhead)
                        .foregroundStyle(Color.yqSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchField(prompt: copy("Number or name", "الرقم أو الاسم"), text: $query)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
                    .background(Color.yqCanvas)
            }
            .yqScreen()
            .navigationTitle(copy("Surahs", "السور"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
        }
        .yaqeenLanguage(language)
    }

    private func row(_ surah: QuranSurah) -> some View {
        let isCurrent = surah.number == current
        let count = language == .arabic
            ? "\(QuranAyah.arabicDigits(surah.versesCount)) آية"
            : "\(surah.versesCount) ayat"
        let detail = "\(count) · \(surah.placeName(language))"
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(isCurrent ? Color.yqAccent : Color.yqFill)
                Text(language == .arabic ? QuranAyah.arabicDigits(surah.number) : "\(surah.number)")
                    .font(.yqCaptionBold)
                    .foregroundStyle(isCurrent ? Color.yqOnAccent : Color.yqInk)
            }
            .frame(width: 36, height: 36)

            if language == .arabic {
                VStack(alignment: .leading, spacing: 2) {
                    Text(surah.nameArabic)
                        .font(.arabicProse(20))
                        .foregroundStyle(Color.yqInk)
                    Text(detail)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
                Spacer(minLength: 8)
                Text(surah.nameSimple)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(surah.nameSimple)
                        .font(.yqBodyMedium)
                        .foregroundStyle(Color.yqInk)
                    Text(surah.nameTranslated)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(surah.nameArabic)
                        .font(.arabicProse(20))
                        .foregroundStyle(Color.yqInk)
                    Text(detail)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
            }

            if isCurrent {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.yqAccent)
            }
        }
        .lineLimit(1)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private func accessibilityLabel(for surah: QuranSurah) -> String {
        "\(surah.number). \(surah.name(language)), \(surah.versesCount) \(copy("ayat", "آية")), \(surah.placeName(language))"
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "ٱ", with: "ا")
    }

    private static func number(from text: String) -> Int? {
        pickerNumber(from: text)
    }
}

/// Reads a whole number typed in Western or Arabic-Indic digits.
private func pickerNumber(from text: String) -> Int? {
    let western = text.trimmingCharacters(in: .whitespacesAndNewlines).map { character -> Character in
        switch character {
        case "٠": return "0"
        case "١": return "1"
        case "٢": return "2"
        case "٣": return "3"
        case "٤": return "4"
        case "٥": return "5"
        case "٦": return "6"
        case "٧": return "7"
        case "٨": return "8"
        case "٩": return "9"
        default: return character
        }
    }
    return Int(String(western))
}

// MARK: - Juz picker

/// Thirty rows; picking one hands back the key of the juz's first ayah.
struct JuzPickerSheet: View {
    let language: AppLanguage
    let current: Int
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var copy: AppCopy { AppCopy(language: language) }

    static let ordinals = [
        "الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس", "السابع", "الثامن", "التاسع", "العاشر",
        "الحادي عشر", "الثاني عشر", "الثالث عشر", "الرابع عشر", "الخامس عشر", "السادس عشر", "السابع عشر",
        "الثامن عشر", "التاسع عشر", "العشرون", "الحادي والعشرون", "الثاني والعشرون", "الثالث والعشرون",
        "الرابع والعشرون", "الخامس والعشرون", "السادس والعشرون", "السابع والعشرون", "الثامن والعشرون",
        "التاسع والعشرون", "الثلاثون",
    ]

    static func arabicName(_ juz: Int) -> String {
        guard juz >= 1, juz <= ordinals.count else { return "الجزء \(QuranAyah.arabicDigits(juz))" }
        return "الجزء \(ordinals[juz - 1])"
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(1...QuranStore.juzCount, id: \.self) { juz in
                    let first = QuranStore.shared.firstAyah(ofJuz: juz)
                    Button {
                        guard let first else { return }
                        Haptics.selection()
                        onPick(first.key)
                        dismiss()
                    } label: {
                        row(juz: juz, first: first)
                    }
                    .buttonStyle(.plain)
                    .disabled(first == nil)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.yqHairline)
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .accessibilityAddTraits(juz == current ? .isSelected : [])
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .yqScreen()
            .navigationTitle(copy("Juz", "الأجزاء"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
        }
        .yaqeenLanguage(language)
    }

    private func row(juz: Int, first: QuranAyah?) -> some View {
        let isCurrent = juz == current
        let title = language == .arabic
            ? Self.arabicName(juz)
            : "Juz \(juz) · \(Self.arabicName(juz))"
        let subtitle: String = {
            guard let first else { return "" }
            let start = copy("Starts at", "يبدأ من")
            return "\(start) \(first.reference(language))"
        }()
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(isCurrent ? Color.yqAccent : Color.yqFill)
                Text(language == .arabic ? QuranAyah.arabicDigits(juz) : "\(juz)")
                    .font(.yqCaptionBold)
                    .foregroundStyle(isCurrent ? Color.yqOnAccent : Color.yqInk)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
            }
            Spacer(minLength: 8)
            if isCurrent {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.yqAccent)
            }
        }
        .lineLimit(1)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

// MARK: - Page picker

/// Type a page number (1…604, Western or Arabic-Indic digits) or pick the
/// first page of a juz. Hands back the page number.
struct PagePickerSheet: View {
    let language: AppLanguage
    let current: Int
    let onPick: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @State private var invalidAttempt = false
    @FocusState private var fieldFocused: Bool

    private var copy: AppCopy { AppCopy(language: language) }

    /// The typed page when it is a real Madani page number.
    private var typedPage: Int? {
        guard let number = pickerNumber(from: input), (1...QuranStore.pageCount).contains(number) else { return nil }
        return number
    }

    private var currentLabel: String {
        language == .arabic
            ? "أنت الآن في صفحة \(QuranAyah.arabicDigits(current))"
            : "You are on page \(current)"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            TextField(language == .arabic ? "١ – ٦٠٤" : "1 – 604", text: $input)
                                .font(.yqBody)
                                .keyboardType(.numberPad)
                                .focused($fieldFocused)
                                .submitLabel(.go)
                                .onSubmit(go)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 46)
                                .background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(invalidAttempt ? Color.yqAccent : Color.clear, lineWidth: 1)
                                )
                                .accessibilityLabel(copy("Page number", "رقم الصفحة"))
                            Button(action: go) {
                                Text(copy("Go", "انتقال"))
                                    .font(.yqSubheadBold)
                                    .foregroundStyle(Color.yqOnAccent)
                                    .padding(.horizontal, 18)
                                    .frame(minHeight: 46)
                                    .background(Color.yqAccent, in: Capsule(style: .continuous))
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.yqPress)
                            .disabled(typedPage == nil)
                            .opacity(typedPage == nil ? 0.5 : 1)
                            .accessibilityLabel(copy("Go to page", "الانتقال إلى الصفحة"))
                        }
                        Text(invalidAttempt ? copy("Enter a page from 1 to 604.", "أدخل رقم صفحة من ١ إلى ٦٠٤.") : currentLabel)
                            .font(.yqCaption)
                            .foregroundStyle(Color.yqSecondary)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                }

                Section {
                    ForEach(1...QuranStore.juzCount, id: \.self) { juz in
                        let first = QuranStore.shared.firstAyah(ofJuz: juz)
                        Button {
                            guard let first else { return }
                            Haptics.selection()
                            onPick(first.page)
                            dismiss()
                        } label: {
                            row(juz: juz, first: first)
                        }
                        .buttonStyle(.plain)
                        .disabled(first == nil)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.yqHairline)
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        .accessibilityAddTraits(isCurrent(juz: juz, first: first) ? .isSelected : [])
                    }
                } header: {
                    CapsLabel(text: copy("Juz", "الأجزاء"))
                        .padding(.horizontal, 4)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .yqScreen()
            .navigationTitle(copy("Go to page", "الانتقال إلى صفحة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
            .onChange(of: input) { _, _ in invalidAttempt = false }
        }
        .yaqeenLanguage(language)
    }

    private func go() {
        guard let page = typedPage else {
            invalidAttempt = !input.isEmpty
            Haptics.warning()
            return
        }
        Haptics.selection()
        onPick(page)
        dismiss()
    }

    /// The juz whose page span holds the current page.
    private func isCurrent(juz: Int, first: QuranAyah?) -> Bool {
        guard let first else { return false }
        let nextStart = QuranStore.shared.firstAyah(ofJuz: juz + 1)?.page ?? QuranStore.pageCount + 1
        return current >= first.page && current < nextStart
    }

    private func row(juz: Int, first: QuranAyah?) -> some View {
        let isCurrent = isCurrent(juz: juz, first: first)
        let title = language == .arabic ? JuzPickerSheet.arabicName(juz) : "Juz \(juz)"
        let subtitle: String = {
            guard let first else { return "" }
            let surahName = QuranStore.shared.surah(first.surah)?.name(language) ?? ""
            return language == .arabic
                ? "صفحة \(QuranAyah.arabicDigits(first.page)) · \(surahName)"
                : "Page \(first.page) · \(surahName)"
        }()
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(isCurrent ? Color.yqAccent : Color.yqFill)
                Text(language == .arabic ? QuranAyah.arabicDigits(juz) : "\(juz)")
                    .font(.yqCaptionBold)
                    .foregroundStyle(isCurrent ? Color.yqOnAccent : Color.yqInk)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
            }
            Spacer(minLength: 8)
            if isCurrent {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.yqAccent)
            }
        }
        .lineLimit(1)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
