import SwiftData
import SwiftUI

struct LibraryView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case saved
        case reflections
        var id: String { rawValue }
    }

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var account = GoogleAccountManager.shared
    @State private var mode: Mode = .saved
    @Namespace private var pill

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        header
                        modeToggle
                        content
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(for: Situation.self) { situation in
                SituationDetailView(situation: situation)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            YaqeenMark()
                .fill(Color.sakinaInk)
                .frame(width: 32, height: 43)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(copy("Saved", "المحفوظات"))
                    .font(.display(34))
                    .foregroundStyle(Color.sakinaInk)
                Text(copy("The guidance and words you want to return to.", "الهداية والكلمات التي تريد العودة إليها."))
                    .font(.subheadline)
                    .foregroundStyle(Color.sakinaMuted)
            }
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases) { item in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 1)) {
                        mode = item
                    }
                } label: {
                    Text(item == .saved
                         ? copy("Saved moments", "المواقف المحفوظة")
                         : copy("Reflections", "التأملات"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode == item ? Color.sakinaCanvas : Color.sakinaMuted)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background {
                            if mode == item {
                                Capsule()
                                    .fill(Color.sakinaInk)
                                    .matchedGeometryEffect(id: "saved-mode", in: pill)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.sakinaElevated, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.sakinaHairline, lineWidth: 1))
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .saved:
            if bookmarks.isEmpty {
                EmptyGuidanceState(
                    title: copy("Nothing saved yet", "لا توجد محفوظات بعد"),
                    detail: copy(
                        "Save a moment from any guidance screen and it will wait here for you.",
                        "احفظ أي موقف من شاشة الهداية وستجده هنا عند عودتك."
                    ),
                    symbol: "bookmark"
                )
            } else {
                LazyVStack(spacing: 11) {
                    ForEach(bookmarks) { bookmark in
                        if let situation = bookmark.situation {
                            NavigationLink(value: situation) {
                                SituationRow(situation: situation, language: language)
                            }
                            .buttonStyle(YaqeenPressStyle())
                            .contextMenu {
                                Button(role: .destructive) { deleteBookmark(bookmark) } label: {
                                    Label(copy("Remove", "إزالة"), systemImage: "bookmark.slash")
                                }
                            }
                        }
                    }
                }
            }

        case .reflections:
            if entries.isEmpty {
                EmptyGuidanceState(
                    title: copy("A quiet place for your words", "مكان هادئ لكلماتك"),
                    detail: copy(
                        "Your private reflections stay on this iPhone and are backed up when Google is connected.",
                        "تبقى تأملاتك الخاصة على هذا الهاتف وتُنسخ احتياطيًا عند ربط حساب Google."
                    ),
                    symbol: "square.and.pencil"
                )
            } else {
                LazyVStack(spacing: 11) {
                    ForEach(entries) { entry in
                        reflectionCard(entry)
                    }
                }
            }
        }
    }

    private func reflectionCard(_ entry: JournalEntry) -> some View {
        let situation = entry.situation
        return Group {
            if let situation {
                NavigationLink(value: situation) {
                    reflectionBody(entry, situation: situation)
                }
                .buttonStyle(YaqeenPressStyle())
            } else {
                reflectionBody(entry, situation: nil)
            }
        }
        .contextMenu {
            Button(role: .destructive) { deleteReflection(entry) } label: {
                Label(copy("Delete reflection", "حذف التأمل"), systemImage: "trash")
            }
        }
    }

    private func reflectionBody(_ entry: JournalEntry, situation: Situation?) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text(situation?.localizedTitle(language) ?? copy("Reflection", "تأمل"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.sakinaInk)
                    .lineLimit(1)
                Spacer()
                Text(entry.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Color.sakinaMuted)
            }

            Text(entry.text)
                .font(.body)
                .lineSpacing(4)
                .lineLimit(4)
                .foregroundStyle(Color.sakinaInk.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
    }

    private func deleteBookmark(_ bookmark: Bookmark) {
        context.delete(bookmark)
        persistAndBackUpIfConnected()
    }

    private func deleteReflection(_ entry: JournalEntry) {
        context.delete(entry)
        persistAndBackUpIfConnected()
    }

    private func persistAndBackUpIfConnected() {
        try? context.save()
        guard account.isSignedIn, let backup = YaqeenBackup.snapshot(from: context) else { return }
        Task { _ = await account.upload(backup) }
    }
}
