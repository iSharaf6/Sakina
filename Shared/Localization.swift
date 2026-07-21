import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
    var layoutDirection: LayoutDirection { self == .arabic ? .rightToLeft : .leftToRight }
    var nativeName: String { self == .arabic ? "العربية" : "English" }

    func pick(_ english: String, _ arabic: String) -> String {
        self == .arabic ? arabic : english
    }
}

struct AppCopy {
    let language: AppLanguage

    func callAsFunction(_ english: String, _ arabic: String) -> String {
        language.pick(english, arabic)
    }
}

extension View {
    func yaqeenLanguage(_ language: AppLanguage) -> some View {
        environment(\.locale, language.locale)
            .environment(\.layoutDirection, language.layoutDirection)
    }
}
