import LinkPresentation
import UIKit
import UniformTypeIdentifiers
import XCTest
@testable import Sakina

@MainActor
final class AppSharePayloadTests: XCTestCase {
    func testLocalizedInvitationsContainOneDetectableCanonicalAppStoreLink() throws {
        let url = try XCTUnwrap(AppLinks.appStore)
        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

        for language in [AppLanguage.english, .arabic] {
            let payload = AppSharePayload(language: language, url: url)
            let links = detector.matches(in: payload.text, range: NSRange(payload.text.startIndex..., in: payload.text))
            XCTAssertEqual(links.compactMap(\.url), [url], "The full invitation must retain exactly one tappable App Store link")
            XCTAssertEqual(url.scheme, "https")
            XCTAssertEqual(url.host, "apps.apple.com")
            XCTAssertEqual(AppLinks.shareText(language), payload.text, "Other share entry points should use the same invitation")
            XCTAssertTrue(payload.text.hasPrefix(payload.invitation))
            XCTAssertTrue(payload.text.contains(language == .arabic ? "حنين" : "Haneen"))
            XCTAssertGreaterThan(payload.invitation.count, 60, "Sharing should include a useful description, not only the app name")
        }
    }

    func testMessagesMailCopyAndExtensionsReceiveTheCompleteInvitation() throws {
        let payload = AppSharePayload(language: .english, url: try XCTUnwrap(AppLinks.appStore))
        let source = AppShareItemSource(payload: payload)
        let controller = UIActivityViewController(activityItems: [source], applicationActivities: nil)
        let activities: [UIActivity.ActivityType?] = [nil, .message, .mail, .copyToPasteboard, .init(rawValue: "net.whatsapp.WhatsApp.ShareExtension")]

        XCTAssertEqual(source.activityViewControllerPlaceholderItem(controller) as? String, payload.text)
        for activity in activities {
            XCTAssertEqual(source.activityViewController(controller, itemForActivityType: activity) as? String, payload.text)
            XCTAssertEqual(source.activityViewController(controller, dataTypeIdentifierForActivityType: activity), UTType.utf8PlainText.identifier)
        }
        XCTAssertEqual(source.activityViewController(controller, subjectForActivityType: .mail), payload.title)
    }

    func testBrandedPreviewUsesDescriptiveTitleAndRealDestination() throws {
        for language in [AppLanguage.english, .arabic] {
            let payload = AppSharePayload(language: language, url: try XCTUnwrap(AppLinks.appStore))
            let source = AppShareItemSource(payload: payload)
            let controller = UIActivityViewController(activityItems: [source], applicationActivities: nil)
            let metadata = try XCTUnwrap(source.activityViewControllerLinkMetadata(controller))
            XCTAssertEqual(metadata.url, payload.url)
            XCTAssertEqual(metadata.originalURL, payload.url, "Do not fake a URL to display a subtitle")
            XCTAssertEqual(metadata.title, payload.title)
            XCTAssertGreaterThan(try XCTUnwrap(metadata.title).count, 12)
            XCTAssertNotNil(metadata.iconProvider, "The share preview must retain Haneen’s logo")
            XCTAssertNotNil(metadata.imageProvider)
        }
    }
}
