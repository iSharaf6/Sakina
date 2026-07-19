import SwiftUI
import SwiftData

// MARK: - Library

struct LibraryView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case saved = "Saved verses"
        case reflections = "Reflections"
        var id: String { rawValue }
    }

    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Environment(\.modelContext) private var context
    @State private var mode: Mode = .saved
    @Namespace private var pill

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        VStack(alignment: .leading, spacing: 10) {
                            CapsLabel(text: "Your first aid shelf", color: .sakinaGold)
                            Text("Library")
                                .font(.display(40))
                                .foregroundStyle(Color.sakinaInk)
                        }
                        modeToggle
                        content
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(for: Situation.self) { situation in
                SituationDetailView(situation: situation)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases) { m in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        mode = m
                    }
                } label: {
                    Text(m.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(mode == m ? Color.black.opacity(0.82) : Color.sakinaMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background {
                            if mode == m {
                                Capsule()
                                    .fill(Color.sakinaGold)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.sakinaElevated))
        .overlay(Capsule().strokeBorder(Color.sakinaHairline, lineWidth: 1))
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .saved:
            if bookmarks.isEmpty {
                emptyState(
                    line: "Verses you save will gather here,",
                    detail: "your personal first aid kit for the heart."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(bookmarks) { bookmark in
                        if let situation = bookmark.situation {
                            NavigationLink(value: situation) {
                                SituationRow(
                                    situation: situation,
                                    hue: .chapterHue(situation.chapter)
                                )
                            }
                            .buttonStyle(PressableCard())
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(bookmark)
                                } label: {
                                    Label("Remove from library", systemImage: "heart.slash")
                                }
                            }
                        }
                    }
                }
            }
        case .reflections:
            if entries.isEmpty {
                emptyState(
                    line: "Your written reflections and du'as",
                    detail: "will be kept here — private, on this device."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        reflectionCard(entry)
                    }
                }
            }
        }
    }

    private func reflectionCard(_ entry: JournalEntry) -> some View {
        let situation = entry.situation
        let hue: Color = situation.map { .chapterHue($0.chapter) } ?? .sakinaGold
        return Group {
            if let situation {
                NavigationLink(value: situation) {
                    reflectionBody(entry, situation: situation, hue: hue)
                }
                .buttonStyle(PressableCard())
            } else {
                reflectionBody(entry, situation: nil, hue: hue)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                context.delete(entry)
            } label: {
                Label("Delete reflection", systemImage: "trash")
            }
        }
    }

    private func reflectionBody(_ entry: JournalEntry, situation: Situation?, hue: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                CapsLabel(text: situation?.title ?? "Reflection", color: hue, size: 10)
                Spacer()
                CapsLabel(
                    text: entry.createdAt.formatted(date: .abbreviated, time: .omitted),
                    size: 9
                )
            }
            Text(entry.text)
                .font(.reading(15))
                .lineSpacing(5)
                .lineLimit(4)
                .foregroundStyle(Color.sakinaInk.opacity(0.92))
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard(tint: hue, cornerRadius: 20)
    }

    // MARK: Empty state

    private func emptyState(line: String, detail: String) -> some View {
        VStack(spacing: 16) {
            EightPointStar()
                .stroke(Color.sakinaGold.opacity(0.6), lineWidth: 1)
                .frame(width: 30, height: 30)
            VStack(spacing: 5) {
                Text(line)
                    .font(.reading(16))
                    .italic()
                    .foregroundStyle(Color.sakinaInk.opacity(0.9))
                Text(detail)
                    .font(.reading(16))
                    .italic()
                    .foregroundStyle(Color.sakinaMuted)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
    }
}
