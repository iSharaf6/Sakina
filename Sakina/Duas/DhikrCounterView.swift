import SwiftUI

// MARK: - Dhikr list

/// Every dhikr in the catalog with today's count. Tapping a row opens the
/// full-screen counter.
struct DhikrListView: View {
    let language: AppLanguage
    @AppStorage(DhikrLog.key) private var dhikrLogRaw = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var copy: AppCopy { AppCopy(language: language) }
    private var items: [DhikrItem] { DhikrCatalog.all }
    private var todayCounts: [String: Int] { DhikrLog.counts(in: dhikrLogRaw) }
    private var todayTotal: Int { todayCounts.values.reduce(0, +) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: copy("Dhikr counter", "عداد الذكر"),
                           subtitle: copy("Tap to count. Your phone taps back.", "اضغط لتعدّ، وهاتفك يردّ عليك بنبضة."))
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                summary
                    .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                RowGroup {
                    ForEach(Array(items.enumerated()), id: \.element.id) { position, item in
                        NavigationLink {
                            DhikrCounterView(item: item, language: language)
                        } label: {
                            BadgeRow(symbol: "circle.dotted", title: item.arabic,
                                     subtitle: item.transliteration, artwork: item.artwork) {
                                trailing(for: item)
                            }
                        }
                        .buttonStyle(.yqPressSoft)
                        .accessibilityLabel(rowLabel(for: item))
                        if position < items.count - 1 { RowDivider() }
                    }
                }
                .revealed(2, appeared: appeared, reduceMotion: reduceMotion)
                RowGroup {
                    NavigationLink {
                        AdhkarBenefitsView(language: language)
                    } label: {
                        BadgeRow(symbol: "sparkles", title: copy("Benefits of adhkar", "فضائل الأذكار"),
                                 subtitle: copy("Eight reasons to keep counting.", "ثمانية أسباب تجعلك تواصل."),
                                 badgeStyle: .tinted)
                    }
                    .buttonStyle(.yqPressSoft)
                }
                .revealed(3, appeared: appeared, reduceMotion: reduceMotion)
                Text(copy("Counts are kept on this phone for thirty days.", "تُحفظ الأعداد على هذا الهاتف لثلاثين يومًا."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
                    .revealed(4, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { appeared = true }
    }

    private var summary: some View {
        HStack(spacing: 14) {
            IconBadge(symbol: "hand.tap.fill", tint: .yqAccent, size: 44, style: .tinted)
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: copy("Today", "اليوم"))
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(todayTotal.formatted(.number.locale(language.locale)))
                        .font(.yqNumber)
                        .foregroundStyle(Color.yqInk)
                        .contentTransition(.numericText())
                    Text(copy(todayTotal == 1 ? "count" : "counts", "عدّة"))
                        .font(.yqSubhead)
                        .foregroundStyle(Color.yqSecondary)
                }
            }
            Spacer(minLength: 0)
            Text(todayTotal == 0
                 ? copy("Begin with one.", "ابدأ بواحدة.")
                 : copy("Keep going.", "واصل."))
                .font(.yqSubheadMedium)
                .foregroundStyle(Color.yqAccentDeep)
        }
        .padding(16)
        .yqCard(cornerRadius: 20)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func trailing(for item: DhikrItem) -> some View {
        let count = todayCounts[item.id] ?? 0
        if count > 0 {
            Tag(text: count.formatted(.number.locale(language.locale)))
        } else {
            Chevron()
        }
    }

    private func rowLabel(for item: DhikrItem) -> String {
        let count = todayCounts[item.id] ?? 0
        let base = "\(item.transliteration), \(item.meaning(language))"
        return count > 0 ? copy("\(base), \(count) today", "\(base)، \(count) اليوم") : base
    }
}

// MARK: - Counter

/// A full-screen tasbih for one dhikr. The whole canvas is the button.
struct DhikrCounterView: View {
    let item: DhikrItem
    let language: AppLanguage

    @AppStorage(DhikrLog.key) private var dhikrLogRaw = ""
    @AppStorage private var target: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var count = 0
    @State private var pressing = false
    @State private var hasTapped = false
    @State private var showResetConfirm = false
    @State private var showCustomTarget = false
    @State private var customTarget = 100

    private let ringSize: CGFloat = 220
    private let presets = [33, 100, 1000]

    init(item: DhikrItem, language: AppLanguage) {
        self.item = item
        self.language = language
        _target = AppStorage(wrappedValue: item.defaultTarget, "yaqeen.dhikrTarget.\(item.id)")
    }

    private var copy: AppCopy { AppCopy(language: language) }
    private var reached: Bool { count >= target }
    private var laps: Int { target > 0 ? count / target : 0 }

    /// Progress of the current lap. A completed lap shows a full ring.
    private var fraction: Double {
        guard target > 0, count > 0 else { return 0 }
        let remainder = count % target
        return remainder == 0 ? 1 : Double(remainder) / Double(target)
    }

    /// The ring springs forward on every bead, but jumps rather than
    /// unwinding when a new lap begins.
    private var ringAnimation: Animation? {
        if reduceMotion { return nil }
        if count > target, count % target == 1 { return nil }
        return .spring(response: 0.4, dampingFraction: 0.8)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)
            tapArea
        }
        .safeAreaInset(edge: .bottom) { controls }
        .yqScreen()
        .navigationTitle(item.transliteration)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog(copy("Reset today’s count for this dhikr?", "إعادة عدّ اليوم لهذا الذكر؟"),
                            isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button(copy("Reset", "إعادة"), role: .destructive) { reset() }
            Button(copy("Cancel", "إلغاء"), role: .cancel) {}
        }
        .alert(copy("Custom target", "هدف مخصص"), isPresented: $showCustomTarget) {
            TextField(copy("Number", "العدد"), value: $customTarget, format: .number)
                .keyboardType(.numberPad)
            Button(copy("Set", "تعيين")) { setTarget(customTarget) }
            Button(copy("Cancel", "إلغاء"), role: .cancel) {}
        } message: {
            Text(copy("How many times do you want to count?", "كم مرة تريد أن تعدّ؟"))
        }
        .onAppear {
            count = DhikrLog.count(for: item.id, in: dhikrLogRaw)
            customTarget = target
            hasTapped = count > 0
            UIApplication.shared.isIdleTimerDisabled = true
            Haptics.prepare()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 8) {
            Text(item.arabic)
                .font(.arabicProse(30))
                .foregroundStyle(Color.yqInk)
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, .rightToLeft)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.transliteration)
                .font(.yqHeadline)
                .foregroundStyle(Color.yqInk)
                .multilineTextAlignment(.center)
            Text(item.meaning(language))
                .font(.yqSubhead)
                .foregroundStyle(Color.yqSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .yqCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }

    // MARK: Tap area

    private var tapArea: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)
            ring
            lapTag
            Text(hasTapped
                 ? copy("Tap anywhere to count", "اضغط في أي مكان لتعدّ")
                 : copy("Tap anywhere to begin", "اضغط في أي مكان لتبدأ"))
                .font(.yqCaption)
                .foregroundStyle(Color.yqTertiary)
                .opacity(hasTapped ? 0 : 1)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: hasTapped)
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressing else { return }
                    pressing = true
                    tap()
                }
                .onEnded { _ in pressing = false }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(copy("Count \(item.transliteration)", "عدّ \(item.transliteration)"))
        .accessibilityValue(copy("\(count) of \(target)", "\(count) من \(target)"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tap() }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(reached ? Color.yqAccent.opacity(0.32) : Color.yqAccent.opacity(0.14), lineWidth: 10)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: reached)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.yqAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(ringAnimation, value: count)
            VStack(spacing: 2) {
                Text(count.formatted(.number.locale(language.locale)))
                    .font(.system(size: 64, weight: .bold).monospacedDigit())
                    .foregroundStyle(reached ? Color.yqAccentDeep : Color.yqInk)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .keyframeAnimator(initialValue: 1.0, trigger: reduceMotion ? 0 : count) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(0.92, duration: 0.05)
                            SpringKeyframe(1.0, duration: 0.3, spring: Spring(response: 0.28, dampingRatio: 0.55))
                        }
                    }
                Text(copy("of \(target.formatted(.number.locale(language.locale)))",
                          "من \(target.formatted(.number.locale(language.locale)))"))
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            }
            .padding(.horizontal, 28)
            if reached {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.yqOnAccent, Color.yqAccent)
                    .background(Circle().fill(Color.yqSurface).padding(-3))
                    .offset(y: -ringSize / 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: ringSize, height: ringSize)
        .scaleEffect(pressing && !reduceMotion ? 0.97 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: pressing)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: reached)
    }

    @ViewBuilder
    private var lapTag: some View {
        if laps >= 2 {
            Tag(text: "\(laps.formatted(.number.locale(language.locale)))×", filled: true)
                .transition(.scale.combined(with: .opacity))
        } else if reached {
            Tag(text: copy("Target reached", "بلغت الهدف"))
                .transition(.scale.combined(with: .opacity))
        } else {
            Tag(text: item.source(language), tint: BadgeTint.slate.color)
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 12) {
            Button { showResetConfirm = true } label: {
                CircleButton(symbol: "arrow.counterclockwise", size: 48)
            }
            .buttonStyle(.yqPress)
            .disabled(count == 0)
            .opacity(count == 0 ? 0.45 : 1)
            .accessibilityLabel(copy("Reset today’s count", "إعادة عدّ اليوم"))

            Spacer(minLength: 0)

            Menu {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        setTarget(preset)
                    } label: {
                        if preset == target {
                            Label(preset.formatted(.number.locale(language.locale)), systemImage: "checkmark")
                        } else {
                            Text(preset.formatted(.number.locale(language.locale)))
                        }
                    }
                }
                Divider()
                Button {
                    customTarget = target
                    showCustomTarget = true
                } label: {
                    Label(copy("Custom…", "مخصص…"), systemImage: "slider.horizontal.3")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(copy("Target · \(target.formatted(.number.locale(language.locale)))",
                              "الهدف · \(target.formatted(.number.locale(language.locale)))"))
                        .font(.yqSubheadBold)
                        .monospacedDigit()
                }
                .foregroundStyle(Color.yqInk)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(Color.yqFill, in: Capsule(style: .continuous))
                .contentShape(Capsule())
            }
            .buttonStyle(.yqPress)
            .accessibilityLabel(copy("Target, \(target)", "الهدف، \(target)"))

            Spacer(minLength: 0)

            if let raw = item.sourceURL, let url = URL(string: raw) {
                Link(destination: url) {
                    CircleButton(symbol: "book.closed", size: 48)
                }
                .buttonStyle(.yqPress)
                .accessibilityLabel(copy("Open the source", "افتح المصدر"))
            } else {
                Color.clear.frame(width: 48, height: 48)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background {
            Rectangle().fill(.regularMaterial).ignoresSafeArea()
        }
    }

    // MARK: Actions

    private func tap() {
        let next = count + 1
        hasTapped = true
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
            count = next
        }
        dhikrLogRaw = DhikrLog.setting(next, for: item.id, in: dhikrLogRaw)

        if target > 0, next == target {
            Haptics.celebrate()
        } else if target > 0, next % target == 0 {
            Haptics.milestone()
        } else if next % 33 == 0 {
            Haptics.milestone()
        } else {
            Haptics.count()
        }
    }

    private func reset() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
            count = 0
        }
        hasTapped = false
        dhikrLogRaw = DhikrLog.setting(0, for: item.id, in: dhikrLogRaw)
        Haptics.thud()
    }

    private func setTarget(_ value: Int) {
        let clamped = min(max(value, 1), 10_000)
        guard clamped != target else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
            target = clamped
        }
        Haptics.selection()
    }
}
