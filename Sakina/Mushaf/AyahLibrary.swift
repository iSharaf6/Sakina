import Combine
import Foundation
import SwiftUI

// MARK: - Highlight colours

enum HighlightColor: String, Codable, CaseIterable, Identifiable, Hashable {
    case green, yellow, blue, pink, purple, orange
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .green: return .yqAccent
        case .yellow: return Color(uiColor: .systemYellow)
        case .blue: return Color(uiColor: .systemBlue)
        case .pink: return Color(uiColor: .systemPink)
        case .purple: return Color(uiColor: .systemPurple)
        case .orange: return Color(uiColor: .systemOrange)
        }
    }

    var uiColor: UIColor { UIColor(color) }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .green: return language.pick("Green", "أخضر")
        case .yellow: return language.pick("Yellow", "أصفر")
        case .blue: return language.pick("Blue", "أزرق")
        case .pink: return language.pick("Pink", "وردي")
        case .purple: return language.pick("Purple", "بنفسجي")
        case .orange: return language.pick("Orange", "برتقالي")
        }
    }
}

// MARK: - Categories and marks

/// A reader-made folder such as "Sad" or "Hope".
struct AyahCategory: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var symbol: String
    var color: HighlightColor
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, symbol: String = "folder.fill", color: HighlightColor = .green, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.color = color
        self.createdAt = createdAt
    }
}

/// Everything a reader has attached to one ayah. The Qur'an text itself is
/// never stored here; only the key.
struct AyahMark: Identifiable, Codable, Hashable {
    let key: String
    var highlight: HighlightColor?
    var bookmarked: Bool
    var favourite: Bool
    var note: String
    var categoryIDs: [String]
    var updatedAt: Date

    var id: String { key }

    init(key: String) {
        self.key = key
        highlight = nil
        bookmarked = false
        favourite = false
        note = ""
        categoryIDs = []
        updatedAt = .now
    }

    var isEmpty: Bool {
        highlight == nil && !bookmarked && !favourite && note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && categoryIDs.isEmpty
    }
}

// MARK: - Library

/// The reader's own layer over the mushaf: highlights, bookmarks,
/// favourites, notes and categories. Stored as one JSON file in
/// Application Support; writes are coalesced.
@MainActor
final class AyahLibrary: ObservableObject {
    static let shared = AyahLibrary()

    static let colorMarksKey = "yaqeen.mushaf.colorReferenceMarks"
    static let lastReadKey = "yaqeen.mushaf.lastReadKey"
    static let fileName = "ayah-library.json"

    @Published private(set) var categories: [AyahCategory] = []
    @Published private(set) var marks: [String: AyahMark] = [:]

    /// Whether ayah number markers are drawn in the highlight colour.
    @Published var colorReferenceMarks: Bool {
        didSet { UserDefaults.standard.set(colorReferenceMarks, forKey: Self.colorMarksKey) }
    }

    /// Where the reader last was, for "continue reading".
    @Published var lastReadKey: String? {
        didSet { UserDefaults.standard.set(lastReadKey, forKey: Self.lastReadKey) }
    }

    private struct File: Codable {
        var version: Int
        var categories: [AyahCategory]
        var marks: [AyahMark]
    }

    private var saveTask: Task<Void, Never>?
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.fileURL = fileURL ?? support.appendingPathComponent(Self.fileName)
        colorReferenceMarks = UserDefaults.standard.object(forKey: Self.colorMarksKey) as? Bool ?? true
        lastReadKey = UserDefaults.standard.string(forKey: Self.lastReadKey)
        load()
    }

    // MARK: Reading

    func mark(_ key: String) -> AyahMark? { marks[key] }

    func highlight(_ key: String) -> HighlightColor? { marks[key]?.highlight }
    func isBookmarked(_ key: String) -> Bool { marks[key]?.bookmarked ?? false }
    func isFavourite(_ key: String) -> Bool { marks[key]?.favourite ?? false }
    func note(_ key: String) -> String { marks[key]?.note ?? "" }
    func categories(for key: String) -> [AyahCategory] {
        let ids = Set(marks[key]?.categoryIDs ?? [])
        return categories.filter { ids.contains($0.id) }
    }

    var bookmarkedKeys: [String] { QuranStore.shared.sorted(marks.values.filter(\.bookmarked).map(\.key)) }
    var favouriteKeys: [String] { QuranStore.shared.sorted(marks.values.filter(\.favourite).map(\.key)) }
    var highlightedKeys: [String] { QuranStore.shared.sorted(marks.values.filter { $0.highlight != nil }.map(\.key)) }
    var notedKeys: [String] { QuranStore.shared.sorted(marks.values.filter { !$0.note.trimmingCharacters(in: .whitespaces).isEmpty }.map(\.key)) }
    func keys(in category: AyahCategory) -> [String] {
        QuranStore.shared.sorted(marks.values.filter { $0.categoryIDs.contains(category.id) }.map(\.key))
    }
    func count(in category: AyahCategory) -> Int {
        marks.values.filter { $0.categoryIDs.contains(category.id) }.count
    }

    // MARK: Writing

    private func update(_ key: String, _ change: (inout AyahMark) -> Void) {
        var mark = marks[key] ?? AyahMark(key: key)
        change(&mark)
        mark.updatedAt = .now
        if mark.isEmpty { marks.removeValue(forKey: key) } else { marks[key] = mark }
        scheduleSave()
    }

    func setHighlight(_ color: HighlightColor?, for key: String) {
        update(key) { $0.highlight = color }
    }

    func toggleBookmark(_ key: String) {
        update(key) { $0.bookmarked.toggle() }
    }

    func toggleFavourite(_ key: String) {
        update(key) { $0.favourite.toggle() }
    }

    func setNote(_ note: String, for key: String) {
        update(key) { $0.note = note }
    }

    func toggle(category: AyahCategory, for key: String) {
        update(key) { mark in
            if let index = mark.categoryIDs.firstIndex(of: category.id) {
                mark.categoryIDs.remove(at: index)
            } else {
                mark.categoryIDs.append(category.id)
            }
        }
    }

    func isInCategory(_ category: AyahCategory, key: String) -> Bool {
        marks[key]?.categoryIDs.contains(category.id) ?? false
    }

    @discardableResult
    func addCategory(name: String, symbol: String = "folder.fill", color: HighlightColor = .green) -> AyahCategory {
        let category = AyahCategory(name: name.trimmingCharacters(in: .whitespacesAndNewlines), symbol: symbol, color: color)
        categories.append(category)
        scheduleSave()
        return category
    }

    func updateCategory(_ category: AyahCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index] = category
        scheduleSave()
    }

    func deleteCategory(_ category: AyahCategory) {
        categories.removeAll { $0.id == category.id }
        for key in marks.keys where marks[key]?.categoryIDs.contains(category.id) == true {
            update(key) { $0.categoryIDs.removeAll { $0 == category.id } }
        }
        scheduleSave()
    }

    func removeAll(for key: String) {
        marks.removeValue(forKey: key)
        scheduleSave()
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(File.self, from: data) else { return }
        categories = file.categories
        marks = Dictionary(file.marks.map { ($0.key, $0) }, uniquingKeysWith: { _, new in new })
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        let file = File(version: 1, categories: categories, marks: Array(marks.values))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(file) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}
