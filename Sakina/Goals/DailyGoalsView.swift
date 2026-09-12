import SwiftUI

// MARK: - Daily goals

/// Today's small invitations. Progress is shown for the day only; there is
/// no streak, no score, and nothing carries over.
struct DailyGoalsView: View {
    let language: AppLanguage

    @AppStorage(GoalLog.key) private var goalLogRaw = ""
    @AppStorage(GoalPreferences.key) private var enabledRaw = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var showPicker = false

    private var copy: AppCopy { AppCopy(language: language) }
    private var enabled: [DailyGoal] { GoalPreferences.enabled(from: enabledRaw) }
    private var done: Set<String> { GoalLog.doneIDs(in: goalLogRaw) }
    private var doneCount: Int { enabled.filter { done.contains($0.id) }.count }
    private var progress: Double { GoalLog.progress(enabled: enabled, in: goalLogRaw) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: copy("Daily goals", "أهداف اليوم"),
                           subtitle: copy("Small, daily, yours.", "أهداف بسيطة تختارها ليومك."))
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                hero.revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                today.revealed(2, appeared: appeared, reduceMotion: reduceMotion)
                footer.revealed(3, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showPicker = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.yqInk)
                }
                .accessibilityLabel(copy("Customise goals", "تخصيص الأهداف"))
            }
        }
        .sheet(isPresented: $showPicker) {
            GoalPickerSheet(language: language)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { appeared = true }
    }

    // MARK: Hero

    private var headline: String {
        if enabled.isEmpty { return copy("Nothing chosen yet.", "لم تختر شيئًا بعد.") }
        if doneCount == 0 { return copy("A fresh page.", "صفحة جديدة.") }
        if doneCount == enabled.count { return copy("All done. Alhamdulillah.", "تم كل شيء. الحمد لله.") }
        return copy("Keep going, gently.", "أكمل على مهل.")
    }

    private var dateCaption: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(language.locale))
    }

    private var hero: some View {
        HStack(spacing: 18) {
            GoalRing(progress: progress, size: 96, lineWidth: 9, reduceMotion: reduceMotion) {
                Text("\(doneCount) / \(enabled.count)")
                    .font(.yqNumber)
                    .foregroundStyle(Color.yqInk)
                    .contentTransition(.numericText())
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(.yqTitle2)
                    .tracking(-0.3)
                    .foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                Text(dateCaption)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            }
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.leading)
        .padding(18)
        .yqCard(cornerRadius: 22)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85), value: doneCount)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(headline) \(copy("\(doneCount) of \(enabled.count) done.", "\(doneCount) من \(enabled.count).")) \(dateCaption)")
    }

    // MARK: Today

    private var today: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Today", "اليوم"))
            if enabled.isEmpty {
                Button {
                    Haptics.tap()
                    showPicker = true
                } label: {
                    EmptyGuidanceState(title: copy("Choose a few goals", "اختر بعض الأهداف"),
                                       detail: copy("Pick the ones that fit your day.", "اختر ما يناسب يومك."),
                                       symbol: "slider.horizontal.3")
                        .yqCard()
                }
                .buttonStyle(.yqPress)
            } else {
                RowGroup {
                    ForEach(Array(enabled.enumerated()), id: \.element.id) { index, goal in
                        GoalRow(goal: goal, language: language, isDone: done.contains(goal.id)) {
                            toggle(goal)
                        }
                        if index < enabled.count - 1 {
                            RowDivider(inset: 56)
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ goal: DailyGoal) {
        let wasDone = done.contains(goal.id)
        let next = GoalLog.toggling(goal.id, in: goalLogRaw)
        let completesAll = !wasDone && GoalLog.doneIDs(in: next).isSuperset(of: enabled.map(\.id))
        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
            goalLogRaw = next
        }
        if completesAll {
            Haptics.celebrate()
        } else {
            Haptics.thud()
        }
    }

    // MARK: Footer

    private var footer: some View {
        Text(copy("Goals reset every morning. No streaks, no scores.", "تتجدد الأهداف كل صباح. بلا نقاط أو حساب لأيام المواظبة."))
            .font(.yqCaption)
            .foregroundStyle(Color.yqTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}

// MARK: - Row

/// One goal: a check on the leading edge, then the goal itself. Goals with a
/// collection push into it; goals without one simply toggle.
private struct GoalRow: View {
    let goal: DailyGoal
    let language: AppLanguage
    let isDone: Bool
    let onToggle: () -> Void

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                GoalCheck(isDone: isDone)
                    .frame(width: 44, height: 58)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.yqPressSoft)
            .accessibilityLabel(goal.title(language))
            .accessibilityValue(isDone ? copy("Done", "تم") : copy("Not yet", "ليس بعد"))
            .accessibilityHint(isDone ? copy("Marks it as not done", "يلغي تحديد الهدف كمُنجز") : copy("Marks it as done", "يحدّد الهدف كمُنجز"))

            if let practice = goal.practice {
                NavigationLink(value: practice) { label(showsChevron: true) }
                    .buttonStyle(.yqPressSoft)
                    .accessibilityHint(copy("Opens \(practice.title(language))", "يفتح \(practice.title(language))"))
            } else {
                Button(action: onToggle) { label(showsChevron: false) }
                    .buttonStyle(.yqPressSoft)
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .frame(minHeight: 62)
    }

    private func label(showsChevron: Bool) -> some View {
        HStack(spacing: 12) {
            if let artwork = goal.artwork {
                CompanionIllustration(artwork: artwork, size: 40)
                    .opacity(isDone ? 0.7 : 1)
            } else {
                IconBadge(symbol: goal.symbol, tint: .yqAccent, size: 36, style: .tinted)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title(language))
                    .font(.yqBodyMedium)
                    .foregroundStyle(isDone ? Color.yqSecondary : Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(goal.detail(language))
                    .font(.yqSubhead)
                    .foregroundStyle(isDone ? Color.yqTertiary : Color.yqSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if showsChevron { Chevron() }
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }
}

/// The 28 pt check: an empty hairline ring, or a filled accent circle with a
/// white checkmark. The symbol swap animates in place.
private struct GoalCheck: View {
    let isDone: Bool

    var body: some View {
        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 28, weight: .regular))
            .symbolRenderingMode(.palette)
            .foregroundStyle(isDone ? Color.yqOnAccent : Color.yqHairline, isDone ? Color.yqAccent : Color.clear)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: isDone)
            .frame(width: 28, height: 28)
    }
}

// MARK: - Ring

/// A round-capped progress ring that springs to its new value.
struct GoalRing<Center: View>: View {
    let progress: Double
    var size: CGFloat = 96
    var lineWidth: CGFloat = 9
    var reduceMotion = false
    @ViewBuilder var center: () -> Center

    init(progress: Double, size: CGFloat = 96, lineWidth: CGFloat = 9, reduceMotion: Bool = false,
         @ViewBuilder center: @escaping () -> Center = { EmptyView() }) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.reduceMotion = reduceMotion
        self.center = center
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.yqAccent.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.yqAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.55, dampingFraction: 0.78), value: progress)
            center()
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Picker sheet

/// Choose which goals belong to your day. Everything is on by default.
private struct GoalPickerSheet: View {
    let language: AppLanguage

    @AppStorage(GoalPreferences.key) private var enabledRaw = ""
    @Environment(\.dismiss) private var dismiss

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(copy("Keep the goals that fit your day. You can change this any time.",
                              "اختر الأهداف التي تناسب يومك. يمكنك تغييرها في أي وقت."))
                        .font(.yqSubhead)
                        .foregroundStyle(Color.yqSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    RowGroup {
                        ForEach(Array(DailyGoalCatalog.defaults.enumerated()), id: \.element.id) { index, goal in
                            Toggle(isOn: binding(for: goal)) {
                                HStack(spacing: 12) {
                                    if let artwork = goal.artwork {
                                        CompanionIllustration(artwork: artwork, size: 40)
                                    } else {
                                        IconBadge(symbol: goal.symbol, tint: .yqAccent, size: 36, style: .tinted)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(goal.title(language))
                                            .font(.yqBodyMedium)
                                            .foregroundStyle(Color.yqInk)
                                        Text(goal.detail(language))
                                            .font(.yqSubhead)
                                            .foregroundStyle(Color.yqSecondary)
                                            .lineLimit(2)
                                    }
                                }
                                .multilineTextAlignment(.leading)
                            }
                            .tint(.yqAccentDeep)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .frame(minHeight: 58)
                            if index < DailyGoalCatalog.defaults.count - 1 {
                                RowDivider(inset: 66)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .yqScreen()
            .navigationTitle(copy("Customise", "تخصيص"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                        .font(.yqSubheadBold)
                        .tint(.yqAccentDeep)
                }
            }
        }
        .yaqeenLanguage(language)
    }

    private func binding(for goal: DailyGoal) -> Binding<Bool> {
        Binding(
            get: { GoalPreferences.isEnabled(goal.id, in: enabledRaw) },
            set: { _ in
                enabledRaw = GoalPreferences.toggling(goal.id, in: enabledRaw)
                Haptics.press()
            }
        )
    }
}

// MARK: - Home card

/// The compact Home entry. This is a label only; the coordinator wraps it in
/// a `NavigationLink` to `DailyGoalsView`.
struct DailyGoalsCard: View {
    let language: AppLanguage

    @AppStorage(GoalLog.key) private var goalLogRaw = ""
    @AppStorage(GoalPreferences.key) private var enabledRaw = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var copy: AppCopy { AppCopy(language: language) }
    private var enabled: [DailyGoal] { GoalPreferences.enabled(from: enabledRaw) }
    private var done: Set<String> { GoalLog.doneIDs(in: goalLogRaw) }
    private var doneCount: Int { enabled.filter { done.contains($0.id) }.count }
    private var next: DailyGoal? { enabled.first { !done.contains($0.id) } }

    private var subtitle: String {
        if enabled.isEmpty { return copy("Choose a few goals", "اختر بعض الأهداف") }
        guard let next else { return copy("All done today", "تم كل شيء اليوم") }
        if doneCount == 0 { return copy("Start with: \(next.title(language))", "هدفك الأول: \(next.title(language))") }
        return copy("\(doneCount) of \(enabled.count) done, next: \(next.title(language))",
                    "أُنجز \(doneCount) من \(enabled.count)، التالي: \(next.title(language))")
    }

    var body: some View {
        HStack(spacing: 14) {
            GoalRing(progress: GoalLog.progress(enabled: enabled, in: goalLogRaw), size: 44, lineWidth: 5, reduceMotion: reduceMotion) {
                if !enabled.isEmpty, doneCount == enabled.count {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.yqAccent)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(copy("Daily goals", "أهداف اليوم"))
                    .font(.yqHeadline)
                    .foregroundStyle(Color.yqInk)
                Text(subtitle)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Chevron()
        }
        .multilineTextAlignment(.leading)
        .padding(14)
        .yqCard(cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(copy("Daily goals", "أهداف اليوم")). \(subtitle)")
    }
}
