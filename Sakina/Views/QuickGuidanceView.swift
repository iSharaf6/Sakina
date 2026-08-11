import SwiftUI

/// A calm, source-aware version of the supplied “emergency numbers” list.
/// Each row routes into Yaqeen's full reviewed situation rather than presenting
/// a verse reference as a stand-alone answer.
struct QuickGuidanceView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    introduction

                    LazyVStack(spacing: 10) {
                        ForEach(EmergencyGuidanceCatalog.prompts) { prompt in
                            if let situation = prompt.situation {
                                NavigationLink(value: situation) {
                                    QuickGuidanceRow(
                                        prompt: prompt,
                                        situation: situation,
                                        language: language
                                    )
                                }
                                .buttonStyle(YaqeenPressStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle(copy("Quick guidance", "هداية سريعة"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(copy("Qur’an for the moment you’re in", "قرآن للحظة التي تعيشها"))
                    .font(.title2.weight(.semibold))
            } icon: {
                Image(systemName: "book.pages.fill")
                    .foregroundStyle(Color.yaqeenForest)
            }

            Text(copy(
                "Choose the words closest to what you are carrying. Each suggestion opens the ayah in context with its source notes, hadith, and du’a.",
                "اختر الكلمات الأقرب لما تحمله. يفتح كل اقتراح الآية في سياقها مع ملاحظات المصدر والحديث والدعاء."
            ))
            .font(.subheadline)
            .foregroundStyle(Color.sakinaMuted)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .sakinaCard(cornerRadius: 22)
    }
}

struct QuickGuidanceShortcutCard: View {
    let language: AppLanguage

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.sakinaCanvas.opacity(0.13))
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 21, weight: .medium))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(copy("When you need an ayah now", "عندما تحتاج إلى آية الآن"))
                    .font(.headline)
                Text(copy(
                    "Worry · feeling lost · setbacks · hope",
                    "القلق · الضياع · الانتكاسات · الأمل"
                ))
                .font(.caption)
                .foregroundStyle(Color.sakinaCanvas.opacity(0.74))
                .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: language == .arabic ? "arrow.left" : "arrow.right")
                .font(.subheadline.weight(.semibold))
                .accessibilityHidden(true)
        }
        .foregroundStyle(Color.sakinaCanvas)
        .padding(17)
        .background(Color.sakinaInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint(copy("Opens quick Qur’anic guidance", "يفتح الهداية القرآنية السريعة"))
    }
}

private struct QuickGuidanceRow: View {
    let prompt: EmergencyGuidancePrompt
    let situation: Situation
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            VStack(alignment: .leading, spacing: 7) {
                Text(prompt.title(language))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.sakinaInk)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(situation.referenceLabel)
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(Color.yaqeenForest)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint(language.pick(
            "Opens the full reading with context",
            "يفتح القراءة الكاملة مع السياق"
        ))
    }
}

#Preview {
    NavigationStack {
        QuickGuidanceView()
            .navigationDestination(for: Situation.self) { situation in
                SituationDetailView(situation: situation)
            }
    }
}
