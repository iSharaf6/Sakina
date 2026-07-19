import SwiftUI

// MARK: Home

struct HomeView: View {
    @Binding var path: NavigationPath
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var showAbout = false
    @State private var searchText = ""

    private let today = SharedStore.situationOfTheDay()

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var results: [Situation] { SituationCatalog.search(searchText) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AtmosphereBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        header
                            .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                        searchField
                            .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                        if isSearching {
                            searchResults
                        } else {
                            todayCard
                                .revealed(2, appeared: appeared, reduceMotion: reduceMotion)
                            chapterList
                                .revealed(3, appeared: appeared, reduceMotion: reduceMotion)
                            credits
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(for: Situation.self) { situation in
                SituationDetailView(situation: situation)
            }
            .navigationDestination(for: Chapter.self) { chapter in
                ChapterView(chapter: chapter)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAbout) { AboutView() }
            .onAppear { appeared = true }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                CapsLabel(text: "Quranic first aid", color: .sakinaGold)
                Text("Sakina")
                    .font(.display(44))
                    .foregroundStyle(Color.sakinaInk)
                Text(dateLine)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.sakinaMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 12) {
                Button {
                    showAbout = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.sakinaMuted)
                }
                .accessibilityLabel("Settings and about")
                Text("سَكِينَة")
                    .font(.arabic(22))
                    .foregroundStyle(Color.sakinaGold.opacity(0.9))
            }
        }
    }

    private var dateLine: String {
        let gregorian = Date.now.formatted(date: .abbreviated, time: .omitted)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "d MMMM yyyy"
        return "\(gregorian), \(formatter.string(from: .now)) AH"
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.sakinaMuted)
            TextField("How is your heart today?", text: $searchText)
                .font(.reading(15))
                .foregroundStyle(Color.sakinaInk)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if isSearching {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.sakinaMuted.opacity(0.8))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Capsule().fill(Color.sakinaElevated))
        .overlay(Capsule().strokeBorder(Color.sakinaHairline, lineWidth: 1))
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 14) {
            CapsLabel(
                text: results.isEmpty
                    ? "Nothing found"
                    : (results.count == 1 ? "1 verse" : "\(results.count) verses"),
                color: .sakinaGold
            )
            if results.isEmpty {
                VStack(spacing: 12) {
                    EightPointStar()
                        .stroke(Color.sakinaGold.opacity(0.6), lineWidth: 1)
                        .frame(width: 26, height: 26)
                    Text("Try a feeling, a word like debt or alone,\nor a surah name.")
                        .font(.reading(15))
                        .italic()
                        .foregroundStyle(Color.sakinaMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(results) { situation in
                        NavigationLink(value: situation) {
                            SituationRow(
                                situation: situation,
                                hue: .chapterHue(situation.chapter)
                            )
                        }
                        .buttonStyle(PressableCard())
                    }
                }
            }
        }
    }

    // MARK: Ayah of the day

    private var todayCard: some View {
        NavigationLink(value: today) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    CapsLabel(text: "Ayah of the day", color: .sakinaGold)
                    Spacer()
                    EightPointStar()
                        .fill(Color.sakinaGold.opacity(0.85))
                        .frame(width: 12, height: 12)
                }
                if let verse = today.primaryVerse {
                    Text(verse.arabic)
                        .font(.arabic(22))
                        .lineSpacing(10)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .foregroundStyle(Color.sakinaInk)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(today.title)
                        .font(.display(17, weight: .medium))
                        .foregroundStyle(Color.sakinaInk)
                        .multilineTextAlignment(.leading)
                    CapsLabel(text: today.referenceLabel, size: 10)
                }
            }
            .padding(22)
            .sakinaCard(tint: .sakinaGold, cornerRadius: 26)
        }
        .buttonStyle(PressableCard())
    }

    // MARK: Chapters

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 14) {
            CapsLabel(text: "Browse by chapter", color: .sakinaGold)
            VStack(spacing: 12) {
                ForEach(Chapter.all) { chapter in
                    NavigationLink(value: chapter) {
                        ChapterCard(chapter: chapter)
                    }
                    .buttonStyle(PressableCard())
                }
            }
        }
    }

    private var credits: some View {
        VStack(spacing: 12) {
            StarDivider()
            Text("Arabic: Uthmani script. Translation: Saheeh International.\nVia the Quran.com API")
                .font(.system(size: 11))
                .foregroundStyle(Color.sakinaMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: Chapter card

struct ChapterCard: View {
    let chapter: Chapter

    var body: some View {
        let hue = Color.chapterHue(chapter.id)
        let count = SituationCatalog.situations(in: chapter.id).count
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                CapsLabel(text: "Chapter \(chapter.numeral)", color: hue, size: 10)
                Text(chapter.title)
                    .font(.display(21))
                    .foregroundStyle(Color.sakinaInk)
                Text(count == 1 ? "1 situation" : "\(count) situations")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.sakinaMuted)
            }
            Spacer(minLength: 12)
            Text(chapter.arabicWord)
                .font(.arabic(28))
                .foregroundStyle(hue.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .sakinaCard(tint: hue, cornerRadius: 24)
    }
}

// MARK: Chapter page

struct ChapterView: View {
    let chapter: Chapter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        let hue = Color.chapterHue(chapter.id)
        let situations = SituationCatalog.situations(in: chapter.id)
        ZStack {
            AtmosphereBackground(hue: hue)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            CapsLabel(text: "Chapter \(chapter.numeral)", color: hue)
                            Rectangle()
                                .fill(Color.sakinaHairline)
                                .frame(height: 1)
                            Text(chapter.arabicWord)
                                .font(.arabic(18))
                                .foregroundStyle(hue)
                        }
                        Text(chapter.title)
                            .font(.display(32))
                            .foregroundStyle(Color.sakinaInk)
                        Text(chapter.subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.sakinaMuted)
                    }
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)

                    VStack(spacing: 12) {
                        ForEach(situations) { situation in
                            NavigationLink(value: situation) {
                                SituationRow(situation: situation, hue: hue)
                            }
                            .buttonStyle(PressableCard())
                        }
                    }
                    .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { appeared = true }
    }
}

// MARK: Situation row

struct SituationRow: View {
    let situation: Situation
    let hue: Color

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(hue.opacity(0.85))
                .frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 5) {
                Text(situation.title)
                    .font(.display(16, weight: .medium))
                    .foregroundStyle(Color.sakinaInk)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                CapsLabel(text: situation.referenceLabel, size: 10)
            }
            Spacer(minLength: 12)
            EightPointStar()
                .stroke(hue.opacity(0.55), lineWidth: 1)
                .frame(width: 11, height: 11)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .sakinaCard(tint: hue, cornerRadius: 20)
    }
}

// MARK: Motion

struct PressableCard: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct Revealed: ViewModifier {
    let index: Int
    let appeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 18)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.25)
                    : .spring(response: 0.6, dampingFraction: 0.85).delay(Double(index) * 0.07),
                value: appeared
            )
    }
}

extension View {
    func revealed(_ index: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        modifier(Revealed(index: index, appeared: appeared, reduceMotion: reduceMotion))
    }
}
