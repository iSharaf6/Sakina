import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
    var layoutDirection: LayoutDirection { self == .arabic ? .rightToLeft : .leftToRight }
    var nativeName: String { self == .arabic ? "العربية" : "English" }
    var listSeparator: String { self == .arabic ? "، " : ", " }

    func pick(_ english: String, _ arabic: String) -> String {
        self == .arabic ? arabic : english
    }
}

/// Arabic cardinal labels need distinct zero, singular, dual, few and many
/// forms. Callers supply the noun's grammatical forms, not English plurals.
enum ArabicCount {
    static func label(_ count: Int, zero: String, one: String, two: String,
                      few: String, many: String, other: String) -> String {
        switch count {
        case 0: return zero
        case 1: return one
        case 2: return two
        default:
            let remainder = count % 100
            let noun = (3...10).contains(remainder) ? few
                : (11...99).contains(remainder) ? many : other
            return "\(count.formatted(.number.locale(Locale(identifier: "ar@numbers=arab")))) \(noun)"
        }
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
