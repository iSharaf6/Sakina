import SwiftUI

/// Human-language ways into the reviewed guidance. One list, no pages.
struct QuickGuidanceView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var query = ""
    @State private var appeared = false
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var matches: [EmergencyGuidancePrompt] {
        EmergencyGuidanceCatalog.prompts.filter { prompt in
            query.isEmpty || prompt.searchablePhrases.contains { $0.localizedStandardContains(query) }
                || title(prompt).localizedStandardContains(query)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: copy("An ayah for right now", "آية لهذه اللحظة"),
                           subtitle: copy("What’s taking up space in your mind?", "ما الذي يشغل بالك؟"))
                SearchField(prompt: copy("Find your words", "ابحث عمّا تشعر به"), text: $query)
                if matches.isEmpty {
                    EmptyGuidanceState(title: copy("Nothing matched", "لا توجد نتائج"),
                                       detail: copy("Try a feeling, like worry or hope.", "جرّب شعورًا مثل القلق أو الأمل."),
                                       symbol: "text.magnifyingglass")
                } else {
                    RowGroup {
                        ForEach(Array(matches.enumerated()), id: \.element.id) { index, prompt in
                            if let situation = prompt.situation {
                                NavigationLink { SituationDetailView(situation: situation) } label: {
                                    HStack(spacing: 12) {
                                        IconBadge(symbol: "quote.opening", tint: GuidanceCatalog.group(containing: situation).tint, size: 34, style: .tinted)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(title(prompt)).font(.yqBodyMedium).foregroundStyle(Color.yqInk)
                                            Text(situation.referenceLabel).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                                        }
                                        Spacer(minLength: 8)
                                        Chevron()
                                    }
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 14)
                                    .frame(minHeight: 58)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.yqPressSoft)
                                if index < matches.count - 1 { RowDivider(inset: 60) }
                            }
                        }
                    }
                    .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                }
                Text(copy("Each opens a reading, its meaning, and room to reflect.", "يفتح كل منها قراءة ومعنى وفسحة للتأمل."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
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

    private func title(_ prompt: EmergencyGuidancePrompt) -> String {
        let titles: [String: (String, String)] = [
            "overwhelmed-responsibilities": ("Too much to carry", "أعباء كثيرة"),
            "worry-will-not-settle": ("Overthinking", "تفكير لا يهدأ"),
            "doubting-ability": ("Doubting myself", "أشك في نفسي"),
            "comparing-progress": ("Falling behind", "أشعر بالتأخر"),
            "struggling-to-continue": ("Running out of strength", "نفدت قوتي"),
            "lost-next-step": ("What comes next?", "ما الخطوة التالية؟"),
            "setback-after-effort": ("Facing a setback", "أواجه انتكاسة"),
            "effort-feels-unseen": ("Feeling unseen", "لا يلاحظون جهدي"),
            "alone-or-misunderstood": ("Feeling alone", "أشعر بالوحدة"),
            "distant-from-faith": ("Far from my faith", "بعيد عن إيماني"),
            "repeating-mistake": ("The same mistake", "أكرر الخطأ"),
            "fear-too-late-to-return": ("Is it too late?", "هل فات الأوان؟"),
            "outcome-beyond-control": ("Letting go", "أفوّض أمري"),
            "fear-of-judgment": ("What people think", "نظرة الناس"),
            "hurt-or-wronged": ("Someone hurt me", "آذاني أحدهم"),
            "hope-feels-far": ("Looking for hope", "أبحث عن الأمل"),
            "beginning-again": ("Starting again", "أبدأ من جديد")
        ]
        guard let title = titles[prompt.id] else { return prompt.title(language) }
        return copy(title.0, title.1)
    }
}
