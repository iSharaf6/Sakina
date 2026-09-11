import Foundation
import GoogleSignIn
import SwiftData
import UIKit

struct YaqeenBackup: Codable {
    struct SavedMoment: Codable {
        let situationID: String
        let createdAt: Date
    }

    struct Reflection: Codable {
        let id: UUID
        let situationID: String
        let text: String
        let createdAt: Date
        let updatedAt: Date
    }

    let schemaVersion: Int
    let exportedAt: Date
    let savedMoments: [SavedMoment]
    let reflections: [Reflection]

    init(savedMoments: [SavedMoment], reflections: [Reflection]) {
        schemaVersion = 1
        exportedAt = .now
        self.savedMoments = savedMoments
        self.reflections = reflections
    }

    /// Captures the current local-first library after SwiftData has committed a
    /// change. The snapshot contains no prayer location or app preferences.
    @MainActor
    static func snapshot(from context: ModelContext) -> YaqeenBackup? {
        guard let bookmarks = try? context.fetch(FetchDescriptor<Bookmark>()),
              let entries = try? context.fetch(FetchDescriptor<JournalEntry>()) else {
            return nil
        }

        return YaqeenBackup(
            savedMoments: bookmarks.map {
                .init(situationID: $0.situationID, createdAt: $0.createdAt)
            },
            reflections: entries.map {
                .init(
                    id: $0.syncID,
                    situationID: $0.situationID,
                    text: $0.text,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            }
        )
    }
}

@MainActor
final class GoogleAccountManager: ObservableObject {
    static let shared = GoogleAccountManager()
    static let driveScope = "https://www.googleapis.com/auth/drive.appdata"

    enum SyncState: Equatable {
        case idle
        case working(String)
        case success(String)
        case failure(String)
    }

    @Published private(set) var user: GIDGoogleUser?
    @Published private(set) var syncState: SyncState = .idle
    @Published var showConfigurationHelp = false

    private let drive = GoogleDriveAppDataService()

    var isSignedIn: Bool { user != nil }
    var displayName: String { user?.profile?.name ?? "Google account" }
    var email: String { user?.profile?.email ?? "" }
    var imageURL: URL? { user?.profile?.imageURL(withDimension: 160) }

    var isConfigured: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            return false
        }
        return value.hasSuffix(".apps.googleusercontent.com") && !value.contains("YOUR_IOS_CLIENT_ID")
    }

    private init() {}

    func restorePreviousSignIn() {
        guard isConfigured else { return }
        Task {
            do {
                let restored = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                user = restored
            } catch {
                user = nil
            }
        }
    }

    func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    func signIn() {
        guard isConfigured else {
            showConfigurationHelp = true
            return
        }

        Task {
            do {
                guard let presenter = UIApplication.shared.yaqeenTopViewController else {
                    throw GoogleBackupError.noPresentationContext
                }

                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
                var signedInUser = result.user

                if signedInUser.grantedScopes?.contains(Self.driveScope) != true {
                    let scoped = try await signedInUser.addScopes([Self.driveScope], presenting: presenter)
                    signedInUser = scoped.user
                }

                user = signedInUser
                syncState = .success("Connected. Your private backup space is ready.")
            } catch {
                if (error as NSError).code != GIDSignInError.canceled.rawValue {
                    syncState = .failure(error.localizedDescription)
                }
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
        syncState = .idle
    }

    func disconnect() {
        Task {
            do {
                try await GIDSignIn.sharedInstance.disconnect()
            } catch {
                // Local sign-out still removes the account from this app even if
                // Google's revoke endpoint is temporarily unavailable.
            }
            user = nil
            syncState = .idle
        }
    }

    func upload(_ backup: YaqeenBackup) async -> Bool {
        guard let token = await freshAccessToken() else { return false }
        syncState = .working("Backing up your library…")

        do {
            try await drive.upload(backup, accessToken: token)
            UserDefaults.standard.set(Date.now, forKey: "googleBackupLastSync")
            syncState = .success("Your saved moments and reflections are backed up.")
            return true
        } catch {
            syncState = .failure(error.localizedDescription)
            return false
        }
    }

    func download() async -> YaqeenBackup? {
        guard let token = await freshAccessToken() else { return nil }
        syncState = .working("Restoring your library…")

        do {
            guard let backup = try await drive.download(accessToken: token) else {
                syncState = .failure("No Haneen backup was found in this Google account.")
                return nil
            }
            UserDefaults.standard.set(Date.now, forKey: "googleBackupLastSync")
            syncState = .success("Your Google backup was merged with this device.")
            return backup
        } catch {
            syncState = .failure(error.localizedDescription)
            return nil
        }
    }

    private func freshAccessToken() async -> String? {
        guard let current = user ?? GIDSignIn.sharedInstance.currentUser else {
            syncState = .failure("Sign in with Google first.")
            return nil
        }

        do {
            var refreshed = try await current.refreshTokensIfNeeded()
            if refreshed.grantedScopes?.contains(Self.driveScope) != true {
                guard let presenter = UIApplication.shared.yaqeenTopViewController else {
                    throw GoogleBackupError.noPresentationContext
                }
                refreshed = try await refreshed.addScopes([Self.driveScope], presenting: presenter).user
            }
            user = refreshed
            return refreshed.accessToken.tokenString
        } catch {
            syncState = .failure(error.localizedDescription)
            return nil
        }
    }
}

private actor GoogleDriveAppDataService {
    private let fileName = "yaqeen-private-backup.json"
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func upload(_ backup: YaqeenBackup, accessToken: String) async throws {
        let data = try encoder.encode(backup)

        if let existingID = try await existingFileID(accessToken: accessToken) {
            var request = URLRequest(
                url: URL(string: "https://www.googleapis.com/upload/drive/v3/files/\(existingID)?uploadType=media")!
            )
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            _ = try await perform(request)
        } else {
            let boundary = "yaqeen-\(UUID().uuidString)"
            let metadata = try JSONSerialization.data(withJSONObject: [
                "name": fileName,
                "parents": ["appDataFolder"],
            ])
            var body = Data()
            body.append("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
            body.append(metadata)
            body.append("\r\n--\(boundary)\r\nContent-Type: application/json\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            var request = URLRequest(
                url: URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!
            )
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            _ = try await perform(request)
        }
    }

    func download(accessToken: String) async throws -> YaqeenBackup? {
        guard let id = try await existingFileID(accessToken: accessToken) else { return nil }
        var request = URLRequest(
            url: URL(string: "https://www.googleapis.com/drive/v3/files/\(id)?alt=media")!
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let data = try await perform(request)
        return try decoder.decode(YaqeenBackup.self, from: data)
    }

    private func existingFileID(accessToken: String) async throws -> String? {
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "spaces", value: "appDataFolder"),
            URLQueryItem(name: "q", value: "name = '\(fileName)' and trashed = false"),
            URLQueryItem(name: "fields", value: "files(id,modifiedTime)"),
            URLQueryItem(name: "orderBy", value: "modifiedTime desc"),
            URLQueryItem(name: "pageSize", value: "1"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let data = try await perform(request)
        return try JSONDecoder().decode(FileList.self, from: data).files.first?.id
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleBackupError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            if let envelope = try? JSONDecoder().decode(GoogleErrorEnvelope.self, from: data) {
                throw GoogleBackupError.api(envelope.error.message)
            }
            throw GoogleBackupError.api("Google Drive returned status \(http.statusCode).")
        }
        return data
    }

    private struct FileList: Decodable {
        struct File: Decodable { let id: String }
        let files: [File]
    }

    private struct GoogleErrorEnvelope: Decodable {
        struct APIError: Decodable { let message: String }
        let error: APIError
    }
}

private enum GoogleBackupError: LocalizedError {
    case noPresentationContext
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .noPresentationContext:
            return "Haneen could not open Google's sign-in screen. Please try again."
        case .invalidResponse:
            return "Google Drive returned an unreadable response."
        case .api(let message):
            return message
        }
    }
}

private extension UIApplication {
    var yaqeenTopViewController: UIViewController? {
        let root = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        func top(from controller: UIViewController?) -> UIViewController? {
            if let navigation = controller as? UINavigationController {
                return top(from: navigation.visibleViewController)
            }
            if let tab = controller as? UITabBarController {
                return top(from: tab.selectedViewController)
            }
            if let presented = controller?.presentedViewController {
                return top(from: presented)
            }
            return controller
        }

        return top(from: root)
    }
}
