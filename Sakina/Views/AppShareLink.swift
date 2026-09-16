import SwiftUI

/// Shares a real App Store URL with a branded preview, so messaging apps can
/// offer a tappable destination instead of treating the whole invitation as text.
struct AppShareLink<Label: View>: View {
    let language: AppLanguage
    @ViewBuilder let label: () -> Label

    var body: some View {
        if let url = AppLinks.appStore {
            ShareLink(
                item: url,
                subject: Text(language.pick("Haneen — Qur’an, du’a & dhikr", "حنين — قرآن ودعاء وذكر")),
                message: Text(language.pick(
                    "A little room for Qur’an, du’a and dhikr each day. Free, in Arabic and English.",
                    "فسحة للقرآن والدعاء والذكر كل يوم. تطبيق مجاني بالعربية والإنجليزية."
                )),
                preview: SharePreview(
                    language.pick("Haneen", "حنين"),
                    image: Image("YaqeenBrand")
                )
            ) {
                label()
            }
            .buttonStyle(.yqPressSoft)
        }
    }
}
