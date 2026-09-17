import LinkPresentation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// One invitation carries both the description and the App Store link. Some
/// sharing extensions discard ShareLink's optional `message` when given a URL.
struct AppSharePayload {
    let title: String
    let invitation: String
    let url: URL

    init(language: AppLanguage, url: URL) {
        title = language.pick("Haneen: Qur’an & daily remembrance", "حنين: القرآن والذكر كل يوم")
        invitation = Self.invitation(language)
        self.url = url
    }

    var text: String { invitation + "\n\n" + url.absoluteString }

    static func invitation(_ language: AppLanguage) -> String {
        language.pick(
            "Make time for Qur’an, du’a and daily remembrance with Haneen.\nFree in Arabic and English, with prayer times and morning and evening adhkar.",
            "حنين، رفيقك للقرآن والدعاء والذكر كل يوم.\nتطبيق مجاني بالعربية والإنجليزية، مع مواقيت الصلاة وأذكار الصباح والمساء."
        )
    }
}

/// The preview describes the app; it is not a second image attachment. Every
/// destination receives the complete invitation, including the unshortened URL.
@MainActor
final class AppShareItemSource: NSObject, @preconcurrency UIActivityItemSource {
    let payload: AppSharePayload
    private let artwork: UIImage?

    init(payload: AppSharePayload) {
        self.payload = payload
        artwork = UIImage(named: "YaqeenBrand")
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        payload.text
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        payload.text
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        payload.title
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        UTType.utf8PlainText.identifier
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = payload.title
        metadata.url = payload.url
        metadata.originalURL = payload.url
        if let artwork {
            metadata.iconProvider = NSItemProvider(object: artwork)
            metadata.imageProvider = NSItemProvider(object: artwork)
        }
        return metadata
    }
}

struct AppShareLink<Label: View>: View {
    let language: AppLanguage
    @ViewBuilder let label: () -> Label
    @State private var isPresented = false

    var body: some View {
        if let url = AppLinks.appStore {
            Button { isPresented = true } label: {
                label()
            }
            .buttonStyle(.yqPressSoft)
            .sheet(isPresented: $isPresented) {
                AppShareSheet(payload: AppSharePayload(language: language, url: url))
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct AppShareSheet: UIViewControllerRepresentable {
    let payload: AppSharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [AppShareItemSource(payload: payload)], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
