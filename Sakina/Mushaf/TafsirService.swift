import Combine
import Foundation

/// Fetches tafsir for one ayah from Quran.com and keeps it, as plain text,
/// in memory and under Caches/tafsir. The Qur'an text itself never passes
/// through here; only the commentary.
@MainActor
final class TafsirService: ObservableObject {
    static let shared = TafsirService()

    /// The two editions the sheet offers. Resource ids were verified against
    /// `https://api.quran.com/api/v4/resources/tafsirs` on 10 Sep 2026.
    enum Edition: String, CaseIterable, Identifiable, Hashable {
        case ibnKathirEnglish
        case muyassarArabic

        var id: String { rawValue }

        /// Quran.com tafsir resource id.
        var resourceID: Int {
            switch self {
            case .ibnKathirEnglish: return 169
            case .muyassarArabic: return 16
            }
        }

        /// `name` exactly as the resources endpoint returns it.
        var resourceName: String {
            switch self {
            case .ibnKathirEnglish: return "Ibn Kathir (Abridged)"
            case .muyassarArabic: return "Tafsir Muyassar"
            }
        }

        var slug: String {
            switch self {
            case .ibnKathirEnglish: return "en-tafisr-ibn-kathir"
            case .muyassarArabic: return "ar-tafsir-muyassar"
            }
        }

        var isArabic: Bool { self == .muyassarArabic }

        /// Short label for the picker. The Arabic edition keeps its Arabic
        /// name in both app languages, as the owner asked.
        func title(_ language: AppLanguage) -> String {
            switch self {
            case .ibnKathirEnglish: return language.pick("Ibn Kathir (English)", "ابن كثير (بالإنجليزية)")
            case .muyassarArabic: return language.pick("الميسر (بالعربية)", "الميسر (بالعربية)")
            }
        }

        /// Sensible default for the app language.
        static func preferred(for language: AppLanguage) -> Edition {
            language == .arabic ? .muyassarArabic : .ibnKathirEnglish
        }
    }

    enum Failure: LocalizedError {
        case offline
        case timedOut
        case badResponse
        case empty

        func message(_ language: AppLanguage) -> String {
            switch self {
            case .offline:
                return language.pick("You're offline. Tafsir needs a connection the first time.",
                                     "لا يوجد اتصال. يحتاج التفسير إلى الإنترنت في المرة الأولى.")
            case .timedOut:
                return language.pick("Quran.com took too long to answer.", "استغرق Quran.com وقتًا طويلًا للرد.")
            case .badResponse:
                return language.pick("Quran.com sent something unexpected.", "وصل رد غير متوقع من Quran.com.")
            case .empty:
                return language.pick("No tafsir is available for this ayah in this edition.",
                                     "لا يتوفر تفسير لهذه الآية في هذه الطبعة.")
            }
        }

        var errorDescription: String? { message(.english) }
    }

    static let timeout: TimeInterval = 15

    private var memory: [String: String] = [:]
    private var inFlight: [String: Task<String, Error>] = [:]
    private let session: URLSession
    private let cacheRoot: URL

    init(session: URLSession? = nil, cacheRoot: URL? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = Self.timeout
            configuration.timeoutIntervalForResource = Self.timeout
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheRoot = cacheRoot ?? caches.appendingPathComponent("tafsir", isDirectory: true)
    }

    // MARK: Reading

    /// Whatever is already cached, without touching the network.
    func cached(for key: String, edition: Edition) -> String? {
        let id = cacheKey(key, edition)
        if let text = memory[id] { return text }
        guard let text = try? String(contentsOf: fileURL(key, edition), encoding: .utf8), !text.isEmpty else { return nil }
        memory[id] = text
        return text
    }

    /// Plain-text tafsir for `key` ("2:255") in `edition`, from cache when
    /// possible. Concurrent requests for the same ayah share one fetch.
    func tafsir(for key: String, edition: Edition) async throws -> String {
        if let text = cached(for: key, edition: edition) { return text }
        let id = cacheKey(key, edition)
        if let running = inFlight[id] { return try await running.value }
        let task = Task<String, Error> { [session, cacheRoot] in
            let url = URL(string: "https://api.quran.com/api/v4/tafsirs/\(edition.resourceID)/by_ayah/\(key)")!
            var request = URLRequest(url: url)
            request.timeoutInterval = Self.timeout
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch let error as URLError {
                switch error.code {
                case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                    throw Failure.offline
                case .timedOut:
                    throw Failure.timedOut
                default:
                    throw Failure.badResponse
                }
            }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw Failure.badResponse
            }
            guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
                throw Failure.badResponse
            }
            let text = Self.plainText(fromHTML: envelope.tafsir.text ?? "")
            guard !text.isEmpty else { throw Failure.empty }
            let file = Self.fileURL(root: cacheRoot, key: key, edition: edition)
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? text.write(to: file, atomically: true, encoding: .utf8)
            return text
        }
        inFlight[id] = task
        defer { inFlight[id] = nil }
        let text = try await task.value
        memory[id] = text
        return text
    }

    // MARK: Cache paths

    private func cacheKey(_ key: String, _ edition: Edition) -> String { "\(edition.resourceID)/\(key)" }

    private func fileURL(_ key: String, _ edition: Edition) -> URL {
        Self.fileURL(root: cacheRoot, key: key, edition: edition)
    }

    /// Caches/tafsir/{resource id}/{key}.txt. The colon in "2:255" is kept
    /// out of the file name.
    nonisolated private static func fileURL(root: URL, key: String, edition: Edition) -> URL {
        root.appendingPathComponent(String(edition.resourceID), isDirectory: true)
            .appendingPathComponent(key.replacingOccurrences(of: ":", with: "-"))
            .appendingPathExtension("txt")
    }

    // MARK: Decoding

    private struct Envelope: Decodable {
        struct Body: Decodable {
            let text: String?
            let resourceName: String?
            enum CodingKeys: String, CodingKey { case text, resourceName = "resource_name" }
        }
        let tafsir: Body
    }

    /// Strips Quran.com's HTML down to readable paragraphs.
    nonisolated static func plainText(fromHTML html: String) -> String {
        var text = html
        // Block boundaries become newlines before the tags are removed.
        let breaks = ["<br>", "<br/>", "<br />", "</p>", "</div>", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "</li>", "</blockquote>", "</tr>"]
        for tag in breaks {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        let openers = ["<p", "<div", "<h1", "<h2", "<h3", "<h4", "<h5", "<h6", "<li", "<blockquote", "<tr"]
        for tag in openers {
            text = text.replacingOccurrences(of: "\(tag)(?=[\\s>])", with: "\n\(tag)", options: [.regularExpression, .caseInsensitive])
        }
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = decodeEntities(text)
        text = text.replacingOccurrences(of: "\r\n", with: "\n")
        text = text.replacingOccurrences(of: "[ \\t\\u{00A0}]+\\n", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n[ \\t\\u{00A0}]+", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        let named: [String: String] = [
            "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "#39": "'", "nbsp": "\u{00A0}",
            "hellip": "…", "mdash": "—", "ndash": "–", "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”",
            "laquo": "«", "raquo": "»", "copy": "©", "middot": "·", "bull": "•"
        ]
        var result = ""
        result.reserveCapacity(text.count)
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            guard character == "&",
                  let semicolon = text[index...].firstIndex(of: ";"),
                  text.distance(from: index, to: semicolon) <= 10 else {
                result.append(character)
                index = text.index(after: index)
                continue
            }
            let name = String(text[text.index(after: index)..<semicolon])
            var replacement: String?
            if let value = named[name] {
                replacement = value
            } else if name.hasPrefix("#x") || name.hasPrefix("#X"), let code = UInt32(name.dropFirst(2), radix: 16), let scalar = Unicode.Scalar(code) {
                replacement = String(Character(scalar))
            } else if name.hasPrefix("#"), let code = UInt32(name.dropFirst()), let scalar = Unicode.Scalar(code) {
                replacement = String(Character(scalar))
            }
            if let replacement {
                result.append(replacement)
                index = text.index(after: semicolon)
            } else {
                result.append(character)
                index = text.index(after: index)
            }
        }
        return result
    }
}
