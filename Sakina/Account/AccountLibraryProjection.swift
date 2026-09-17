import Foundation
import SwiftData

/// Only the reader's library is synchronized. Location, reminders, preferences,
/// daily goals and counters stay on the device. Each item has its own merge key.
@MainActor
struct AccountLibraryProjection {
    let context: ModelContext
    let library: AyahLibrary
    let defaults: UserDefaults

    init(context: ModelContext, library: AyahLibrary? = nil, defaults: UserDefaults = .standard) {
        self.context = context
        self.library = library ?? .shared
        self.defaults = defaults
    }

    private struct Moment: Codable { var situationID: String; var createdAt: Date }
    private struct Reflection: Codable {
        var id: UUID
        var situationID: String
        var text: String
        var createdAt: Date
        var updatedAt: Date
    }
    private struct Records {
        var marks: [AyahMark]
        var categories: [AyahCategory]
        var moments: [Moment]
        var reflections: [Reflection]
        var duas: [String]
        var places: String
    }

    func capture() throws -> [String: String] {
        try context.save()
        var values: [String: String] = [:]
        for mark in library.marks.values { values["ayah/\(mark.key)"] = try Self.encode(mark) }
        for category in library.categories { values["category/\(category.id)"] = try Self.encode(category) }
        for bookmark in try context.fetch(FetchDescriptor<Bookmark>()) {
            values["moment/\(bookmark.situationID)"] = try Self.encode(Moment(situationID: bookmark.situationID, createdAt: bookmark.createdAt))
        }
        for entry in try context.fetch(FetchDescriptor<JournalEntry>()) {
            values["reflection/\(entry.syncID.uuidString)"] = try Self.encode(Reflection(id: entry.syncID, situationID: entry.situationID, text: entry.text, createdAt: entry.createdAt, updatedAt: entry.updatedAt))
        }
        for id in DuaCollection.savedIDs(defaults.string(forKey: DuaCollection.savedKey) ?? "") {
            values["dua/\(id)"] = "true"
        }
        if let key = library.lastReadKey { values["reading/quran"] = key }
        if let id = defaults.string(forKey: DuaCollection.lastReadKey), !id.isEmpty { values["reading/dua"] = id }
        let places = defaults.string(forKey: ReadingPlace.key) ?? ""
        for practice in DuaPractice.allCases {
            if let entry = ReadingPlace.entry(for: practice, in: places) { values["reading/practice/\(practice.rawValue)"] = entry }
        }
        return values
    }

    /// Decode and validate everything before mutating any local store. Unknown
    /// fields are retained in the cloud envelope for forward compatibility.
    func validate(_ values: [String: String]) throws { _ = try decoded(values) }

    private func decoded(_ values: [String: String]) throws -> Records {
        var marks: [AyahMark] = []
        var categories: [AyahCategory] = []
        var moments: [Moment] = []
        var reflections: [Reflection] = []
        var duas: [String] = []
        var places = ""
        for (key, value) in values.sorted(by: { $0.key < $1.key }) {
            if key.hasPrefix("ayah/") {
                let mark = try Self.decode(AyahMark.self, value)
                guard key == "ayah/\(mark.key)" else { throw ProjectionError.invalidRecord }
                marks.append(mark)
            } else if key.hasPrefix("category/") {
                let category = try Self.decode(AyahCategory.self, value)
                guard key == "category/\(category.id)" else { throw ProjectionError.invalidRecord }
                categories.append(category)
            } else if key.hasPrefix("moment/") {
                let moment = try Self.decode(Moment.self, value)
                guard key == "moment/\(moment.situationID)" else { throw ProjectionError.invalidRecord }
                moments.append(moment)
            } else if key.hasPrefix("reflection/") {
                let reflection = try Self.decode(Reflection.self, value)
                guard key == "reflection/\(reflection.id.uuidString)" else { throw ProjectionError.invalidRecord }
                reflections.append(reflection)
            } else if key.hasPrefix("dua/") {
                duas.append(String(key.dropFirst(4)))
            } else if key.hasPrefix("reading/practice/"), let practice = DuaPractice(rawValue: String(key.dropFirst(17))) {
                places = ReadingPlace.updating(practice, entryID: value, in: places)
            }
        }
        return Records(marks: marks, categories: categories, moments: moments, reflections: reflections, duas: duas, places: places)
    }

    func apply(_ values: [String: String]) throws {
        let records = try decoded(values)
        let moments = records.moments
        let reflections = records.reflections
        let oldMoments = try context.fetch(FetchDescriptor<Bookmark>())
        let oldEntries = try context.fetch(FetchDescriptor<JournalEntry>())
        let momentIDs = Set(moments.map(\.situationID))
        let entryIDs = Set(reflections.map(\.id))
        for old in oldMoments where !momentIDs.contains(old.situationID) { context.delete(old) }
        for old in oldEntries where !entryIDs.contains(old.syncID) { context.delete(old) }
        for moment in moments {
            if let existing = oldMoments.first(where: { $0.situationID == moment.situationID }) { existing.createdAt = moment.createdAt }
            else { context.insert(Bookmark(situationID: moment.situationID, createdAt: moment.createdAt)) }
        }
        for reflection in reflections {
            if let existing = oldEntries.first(where: { $0.syncID == reflection.id }) {
                existing.situationID = reflection.situationID
                existing.text = reflection.text
                existing.createdAt = reflection.createdAt
                existing.updatedAt = reflection.updatedAt
            } else {
                context.insert(JournalEntry(syncID: reflection.id, situationID: reflection.situationID, text: reflection.text, createdAt: reflection.createdAt, updatedAt: reflection.updatedAt))
            }
        }
        do { try context.save() } catch { context.rollback(); throw error }
        try library.replaceAccountContent(categories: records.categories, marks: records.marks, lastReadKey: values["reading/quran"])
        defaults.set(records.duas.joined(separator: "|"), forKey: DuaCollection.savedKey)
        defaults.set(values["reading/dua"] ?? "", forKey: DuaCollection.lastReadKey)
        defaults.set(records.places, forKey: ReadingPlace.key)
        WidgetPracticeSync.refresh()
    }

    static func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    static func decode<T: Decodable>(_ type: T.Type, _ value: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(value.utf8))
    }

    enum ProjectionError: Error { case invalidRecord }
}
