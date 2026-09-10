import SwiftUI

// MARK: - My ayat

/// The reader's own layer over the mushaf: bookmarks, favourites,
/// highlights, notes and the categories they made themselves.
struct AyahLibraryView: View {
    let language: AppLanguage

    @ObservedObject private var library = AyahLibrary.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showNewCategory = false
    @State private var editingCategory: AyahCategory?
    @State private var deletingCategory: AyahCategory?

    init(language: AppLanguage) {
        self.language = language
    }

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(title: copy("My ayat", "آياتي"),
                           subtitle: copy("Highlights, bookmarks, notes and your own categories.",
                                          "تظليلاتك وعلاماتك وملاحظاتك وتصنيفاتك الخاصة."))
                collections
                categories
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationTitle(copy("My ayat", "آياتي"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showNewCategory) {
            CategoryEditorSheet(language: language)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(language: language, editing: category)
        }
        .confirmationDialog(
            deletingCategory.map { copy("Delete “\($0.name)”?", "حذف «\($0.name)»؟") } ?? "",
            isPresented: Binding(get: { deletingCategory != nil }, set: { if !$0 { deletingCategory = nil } }),
            titleVisibility: .visible,
            presenting: deletingCategory
        ) { category in
            Button(copy("Delete category", "حذف التصنيف"), role: .destructive) {
                library.deleteCategory(category)
                Haptics.thud()
            }
            Button(copy("Cancel", "إلغاء"), role: .cancel) {}
        } message: { category in
            Text(copy("The ayat stay in the mushaf with their highlights and notes; only the “\(category.name)” label is removed.",
                      "تبقى الآيات في المصحف مع تظليلاتها وملاحظاتها؛ يُزال فقط تصنيف «\(category.name)»."))
        }
    }

    // MARK: Collections

    private var collections: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isAccessibilitySize ? 1 : 2)
        return LazyVGrid(columns: columns, spacing: 10) {
            tile(symbol: "bookmark.fill", tint: .yqAccent,
                 title: copy("Bookmarks", "العلامات"), keys: library.bookmarkedKeys, removal: .bookmark)
            tile(symbol: "suit.heart.fill", tint: HighlightColor.pink.color,
                 title: copy("Favourites", "المفضلة"), keys: library.favouriteKeys, removal: .favourite)
            tile(symbol: "highlighter", tint: HighlightColor.orange.color,
                 title: copy("Highlights", "التظليلات"), keys: library.highlightedKeys, removal: .highlight)
            tile(symbol: "note.text", tint: HighlightColor.blue.color,
                 title: copy("Notes", "الملاحظات"), keys: library.notedKeys, removal: .none)
        }
    }

    private func tile(symbol: String, tint: Color, title: String, keys: [String], removal: AyahListRemoval) -> some View {
        NavigationLink {
            AyahListView(title: title, keys: keys, language: language, removal: removal)
        } label: {
            BadgeTile(symbol: symbol, tint: tint, title: title, detail: AyahLibraryCopy.ayatCount(keys.count, language))
        }
        .buttonStyle(.yqPress)
    }

    // MARK: Categories

    private var categories: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Categories", "التصنيفات")) {
                Button { showNewCategory = true } label: { TextAction(title: copy("New", "جديد")) }
                    .buttonStyle(.yqPressSoft)
                    .accessibilityLabel(copy("New category", "تصنيف جديد"))
            }
            if library.categories.isEmpty {
                EmptyGuidanceState(
                    title: copy("Make a category for what you're going through", "أنشئ تصنيفًا لما تمرّ به"),
                    detail: copy("Sad, hopeful, grateful. Save ayat under it from the mushaf.",
                                 "حزين، متفائل، ممتن. احفظ الآيات تحته من المصحف."),
                    symbol: "folder.badge.plus",
                    artwork: .saved
                )
                .yqCard()
            } else {
                RowGroup {
                    ForEach(Array(library.categories.enumerated()), id: \.element.id) { position, category in
                        NavigationLink {
                            AyahListView(title: category.name, keys: library.keys(in: category), language: language, removal: .category(category))
                        } label: {
                            CategoryRow(category: category, subtitle: AyahLibraryCopy.ayatCount(library.count(in: category), language))
                        }
                        .buttonStyle(.yqPressSoft)
                        .contextMenu {
                            Button { editingCategory = category } label: {
                                Label(copy("Rename", "إعادة تسمية"), systemImage: "pencil")
                            }
                            Button(role: .destructive) { deletingCategory = category } label: {
                                Label(copy("Delete", "حذف"), systemImage: "trash")
                            }
                        }
                        if position < library.categories.count - 1 { RowDivider() }
                    }
                }
            }
        }
    }
}

/// Mirrors `BadgeRow` but keeps the reader's chosen symbol as a plain glyph
/// instead of swapping in companion artwork.
private struct CategoryRow: View {
    let category: AyahCategory
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            CategoryBadge(symbol: category.symbol, tint: category.color.color, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            }
            Spacer(minLength: 8)
            Chevron()
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }
}

/// A rounded square with the category's symbol in its colour.
struct CategoryBadge: View {
    let symbol: String
    var tint: Color = .yqAccent
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(tint.opacity(0.12))
            Image(systemName: symbol)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Ayah list

/// What "Remove from this list" does for the list being shown.
enum AyahListRemoval: Hashable {
    case none
    case bookmark
    case favourite
    case highlight
    case category(AyahCategory)
}

/// One list of ayat: a collection tile or a category.
struct AyahListView: View {
    let title: String
    let keys: [String]
    let language: AppLanguage
    var removal: AyahListRemoval = .none

    @ObservedObject private var library = AyahLibrary.shared
    @State private var removed: Set<String> = []

    init(title: String, keys: [String], language: AppLanguage, removal: AyahListRemoval = .none) {
        self.title = title
        self.keys = keys
        self.language = language
        self.removal = removal
    }

    private var copy: AppCopy { AppCopy(language: language) }
    private var visibleKeys: [String] { keys.filter { !removed.contains($0) } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if visibleKeys.isEmpty {
                    EmptyGuidanceState(
                        title: copy("Nothing here yet", "لا يوجد شيء بعد"),
                        detail: copy("Tap any ayah in the mushaf to save it here.", "اضغط على أي آية في المصحف لحفظها هنا."),
                        symbol: "text.book.closed.fill",
                        artwork: .quran
                    )
                    .yqCard()
                } else {
                    HStack {
                        Text(AyahLibraryCopy.ayatCount(visibleKeys.count, language))
                            .font(.yqCaptionBold)
                            .foregroundStyle(Color.yqSecondary)
                        Spacer()
                    }
                    RowGroup {
                        ForEach(Array(visibleKeys.enumerated()), id: \.element) { position, key in
                            if let ayah = QuranStore.shared.ayah(key) {
                                NavigationLink {
                                    MushafView(language: language, initialKey: key)
                                } label: {
                                    AyahLibraryRow(ayah: ayah, mark: library.mark(key), language: language)
                                }
                                .buttonStyle(.yqPressSoft)
                                .contextMenu {
                                    if removal != .none {
                                        Button(role: .destructive) { remove(key) } label: {
                                            Label(copy("Remove from this list", "إزالة من هذه القائمة"), systemImage: "minus.circle")
                                        }
                                    }
                                    ShareLink(item: AyahLibraryCopy.shareText(for: ayah, language: language)) {
                                        Label(copy("Share", "مشاركة"), systemImage: "square.and.arrow.up")
                                    }
                                }
                                if position < visibleKeys.count - 1 { RowDivider(inset: 16) }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func remove(_ key: String) {
        switch removal {
        case .none: return
        case .bookmark: if library.isBookmarked(key) { library.toggleBookmark(key) }
        case .favourite: if library.isFavourite(key) { library.toggleFavourite(key) }
        case .highlight: library.setHighlight(nil, for: key)
        case .category(let category): if library.isInCategory(category, key: key) { library.toggle(category: category, for: key) }
        }
        Haptics.press()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { _ = removed.insert(key) }
    }
}

private struct AyahLibraryRow: View {
    let ayah: QuranAyah
    let mark: AyahMark?
    let language: AppLanguage

    private var note: String { mark?.note.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(ayah.displayArabic) \(ayah.marker)")
                .font(.arabic(20))
                .lineSpacing(8)
                .lineLimit(2)
                .foregroundStyle(Color.yqInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .environment(\.layoutDirection, .rightToLeft)
            HStack(spacing: 8) {
                if let highlight = mark?.highlight {
                    Circle().fill(highlight.color).frame(width: 8, height: 8)
                        .accessibilityLabel(highlight.title(language))
                }
                Text(ayah.reference(language))
                    .font(.yqCaptionBold)
                    .foregroundStyle(Color.yqSecondary)
                if mark?.bookmarked == true {
                    Image(systemName: "bookmark.fill").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.yqTertiary)
                }
                if mark?.favourite == true {
                    Image(systemName: "heart.fill").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.yqTertiary)
                }
                Spacer(minLength: 8)
                Chevron()
            }
            if !note.isEmpty {
                Text(note)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Category editor

/// Name, symbol and colour for a new or existing category.
struct CategoryEditorSheet: View {
    let language: AppLanguage
    let editing: AyahCategory?
    let onSave: (AyahCategory) -> Void

    @ObservedObject private var library = AyahLibrary.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    @State private var name: String
    @State private var symbol: String
    @State private var color: HighlightColor

    init(language: AppLanguage, editing: AyahCategory? = nil, onSave: @escaping (AyahCategory) -> Void = { _ in }) {
        self.language = language
        self.editing = editing
        self.onSave = onSave
        _name = State(initialValue: editing?.name ?? "")
        _symbol = State(initialValue: editing?.symbol ?? AyahCategorySymbols.all[0])
        _color = State(initialValue: editing?.color ?? .green)
    }

    private var copy: AppCopy { AppCopy(language: language) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    preview
                    nameField
                    symbolPicker
                    colorPicker
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .yqScreen(pattern: .none)
            .navigationTitle(editing == nil ? copy("New category", "تصنيف جديد") : copy("Edit category", "تعديل التصنيف"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy("Cancel", "إلغاء")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Save", "حفظ")) { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear { if editing == nil { nameFocused = true } }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .yaqeenLanguage(language)
    }

    private var preview: some View {
        HStack(spacing: 14) {
            CategoryBadge(symbol: symbol, tint: color.color, size: 44)
            Text(trimmedName.isEmpty ? copy("Untitled", "بلا اسم") : trimmedName)
                .font(.yqHeadline)
                .foregroundStyle(trimmedName.isEmpty ? Color.yqTertiary : Color.yqInk)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(14)
        .yqCard()
        .animation(.easeOut(duration: 0.15), value: symbol)
        .animation(.easeOut(duration: 0.15), value: color)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(copy("Name", "الاسم"))
            TextField(copy("Sad, hope, gratitude…", "حزين، أمل، امتنان…"), text: $name)
                .font(.yqBody)
                .foregroundStyle(Color.yqInk)
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit { if canSave { save() } }
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var symbolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(copy("Symbol", "الرمز"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(AyahCategorySymbols.all, id: \.self) { candidate in
                    let selected = candidate == symbol
                    Button {
                        Haptics.press()
                        symbol = candidate
                    } label: {
                        Image(systemName: candidate)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selected ? Color.yqOnAccent : Color.yqInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(selected ? Color.yqAccent : Color.yqFill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(candidate.replacingOccurrences(of: ".", with: " "))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(copy("Colour", "اللون"))
            HStack(spacing: 12) {
                ForEach(HighlightColor.allCases) { candidate in
                    Button {
                        Haptics.press()
                        color = candidate
                    } label: {
                        HighlightSwatch(color: candidate, selected: candidate == color)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(candidate.title(language))
                    .accessibilityAddTraits(candidate == color ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let saved: AyahCategory
        if var category = editing {
            category.name = trimmedName
            category.symbol = symbol
            category.color = color
            library.updateCategory(category)
            saved = category
        } else {
            saved = library.addCategory(name: trimmedName, symbol: symbol, color: color)
        }
        Haptics.success()
        onSave(saved)
        dismiss()
    }
}

// MARK: - Shared pieces

/// The symbols a category can wear.
enum AyahCategorySymbols {
    static let all = [
        "folder.fill", "heart.fill", "cloud.rain.fill", "sun.max.fill", "leaf.fill", "moon.stars.fill",
        "sparkles", "hand.raised.fill", "drop.fill", "flame.fill", "star.fill", "bolt.heart.fill"
    ]
}

/// One highlight colour dot; `nil` is the "no highlight" dot.
struct HighlightSwatch: View {
    let color: HighlightColor?
    let selected: Bool
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            if let color {
                Circle().fill(color.color)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(color.onColor)
                }
            } else {
                Circle().fill(Color.yqFill)
                Circle().strokeBorder(Color.yqHairline, lineWidth: 1)
                Image(systemName: "circle.slash")
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(Color.yqSecondary)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if selected {
                Circle()
                    .strokeBorder(color?.color ?? Color.yqSecondary, lineWidth: 2)
                    .padding(-4)
            }
        }
        .padding(4)
        .contentShape(Circle())
        .animation(.easeOut(duration: 0.15), value: selected)
    }
}

extension HighlightColor {
    /// Text and glyph colour that stays legible on this colour.
    var onColor: Color {
        switch self {
        case .yellow: return Color(white: 0.1)
        default: return .white
        }
    }
}

enum AyahLibraryCopy {
    /// "3 ayat" with the Arabic plural forms.
    static func ayatCount(_ count: Int, _ language: AppLanguage) -> String {
        guard language == .arabic else { return count == 1 ? "1 ayah" : "\(count) ayat" }
        switch count {
        case 0: return "لا آيات"
        case 1: return "آية واحدة"
        case 2: return "آيتان"
        case 3...10: return "\(count) آيات"
        default: return "\(count) آية"
        }
    }

    /// Reference, Arabic, translation and the Quran.com link.
    static func shareText(for ayah: QuranAyah, language: AppLanguage) -> String {
        [ayah.reference(language), "\(ayah.displayArabic) \(ayah.marker)", ayah.translation, ayah.canonicalURL]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
