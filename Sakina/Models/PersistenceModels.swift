import Foundation
import SwiftData

// MARK: - Bookmark

/// A situation the user saved to their personal first-aid shelf.
@Model
final class Bookmark {
    @Attribute(.unique) var situationID: String
    var createdAt: Date

    init(situationID: String, createdAt: Date = .now) {
        self.situationID = situationID
        self.createdAt = createdAt
    }

    var situation: Situation? { SituationCatalog.by(id: situationID) }
}

// MARK: - Journal entry

/// A private reflection or du'a written beneath a specific ayah.
@Model
final class JournalEntry {
    @Attribute(.unique) var syncID: UUID = UUID()
    var situationID: String
    var text: String
    var createdAt: Date
    var updatedAt: Date = Date.now

    init(
        syncID: UUID = UUID(),
        situationID: String,
        text: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.syncID = syncID
        self.situationID = situationID
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var situation: Situation? { SituationCatalog.by(id: situationID) }
}
