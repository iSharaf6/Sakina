import SwiftUI

@MainActor
struct ScholarInsightCard: View {
    let insight: ScholarInsight
    let profile: ScholarProfile
    let language: AppLanguage
    @ObservedObject private var store: ScholarContentStore

    @State private var presentedInsight: ScholarInsight?

    init(
        insight: ScholarInsight,
        profile: ScholarProfile,
        language: AppLanguage,
        store: ScholarContentStore
    ) {
        self.insight = insight
        self.profile = profile
        self.language = language
        self.store = store
    }

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CapsLabel(
                text: copy("Scholar’s expanded insight", "إضاءة موسّعة من الشيخ"),
                color: .sakinaMuted,
                size: 9
            )

            NavigationLink {
                ScholarProfileView()
            } label: {
                HStack(spacing: 11) {
                    ScholarAvatarView(profile: profile, size: 46, language: language)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(profile.displayName(language))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sakinaInk)
                        Text(profileLine)
                            .font(.caption2)
                            .foregroundStyle(Color.sakinaMuted)
                    }

                    Spacer(minLength: 8)
                    Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.sakinaMuted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(copy("Opens the public profile", "يفتح صفحة الملف العام"))

            Divider().overlay(Color.sakinaHairline)

            Text(insight.body(language))
                .font(.reading(16))
                .lineSpacing(7)
                .foregroundStyle(Color.sakinaInk.opacity(0.95))
                .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: language == .arabic ? .trailing : .leading)
                .environment(\.layoutDirection, language.layoutDirection)
                .lineLimit(6)

            if language == .english, insight.hasReviewedEnglishTranslation {
                Label(
                    copy(
                        "Originally written in Arabic, English translation reviewed",
                        "كُتب أصلًا باللغة العربية، روجعت الترجمة الإنجليزية"
                    ),
                    systemImage: "character.book.closed"
                )
                .font(.caption2)
                .foregroundStyle(Color.sakinaMuted)
            }

            Button {
                presentedInsight = insight
            } label: {
                HStack {
                    Text(copy("Read full insight", "اقرأ الإضاءة كاملة"))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: language == .arabic ? "arrow.left" : "arrow.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Color.sakinaCanvas)
                .padding(.horizontal, 15)
                .frame(minHeight: 44)
                .background(Color.sakinaInk, in: Capsule())
            }
            .buttonStyle(.yaqeenPressable)
            .accessibilityLabel(copy("Read the full scholarly insight", "اقرأ الإضاءة الشرعية كاملة"))
        }
        .padding(18)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        }
        .sheet(item: $presentedInsight) { selected in
            ScholarInsightDetailView(
                insight: selected,
                profile: profile,
                language: language,
                store: store
            )
        }
    }

    private var profileLine: String {
        if store.hasVerifiedPublicProfile {
            return profile.title(language)
                ?? copy("Verified public profile", "ملف عام موثّق")
        }
        return copy(
            "Local placeholder, not verified online",
            "عنصر محلي مؤقت، غير موثّق عبر الإنترنت"
        )
    }
}

@MainActor
struct ScholarInsightDetailView: View {
    let insight: ScholarInsight
    let profile: ScholarProfile
    let language: AppLanguage
    @ObservedObject var store: ScholarContentStore

    @Environment(\.dismiss) private var dismiss

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        NavigationLink {
                            ScholarProfileView()
                        } label: {
                            HStack(spacing: 13) {
                                ScholarAvatarView(profile: profile, size: 58, language: language)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.displayName(language))
                                        .font(.headline)
                                    if let title = profile.title(language) {
                                        Text(title)
                                            .font(.caption)
                                            .foregroundStyle(Color.sakinaMuted)
                                    } else {
                                        Text(profileLine)
                                            .font(.caption)
                                            .foregroundStyle(Color.sakinaMuted)
                                    }
                                }
                                Spacer()
                                Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(Color.sakinaInk)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        insightSection(
                            title: copy("Arabic original", "النص العربي الأصلي"),
                            body: insight.bodyArabic,
                            direction: .rightToLeft,
                            alignment: .trailing
                        )

                        if insight.hasReviewedEnglishTranslation, let english = insight.bodyEnglish {
                            insightSection(
                                title: copy("Reviewed English translation", "الترجمة الإنجليزية المراجعة"),
                                body: english,
                                direction: .leftToRight,
                                alignment: .leading
                            )
                        }

                        if !insight.references.isEmpty {
                            referencesSection
                        }

                        Text(copy(
                            "This is a published scholarly insight, not a replacement for reading the ayah in its full context or seeking situation-specific advice.",
                            "هذه إضاءة شرعية منشورة، ولا تغني عن قراءة الآية في سياقها الكامل أو طلب المشورة المناسبة للحالة."
                        ))
                        .font(.caption)
                        .lineSpacing(4)
                        .foregroundStyle(Color.sakinaMuted)
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(copy("Scholarly insight", "الإضاءة الشرعية"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
        }
        .yaqeenLanguage(language)
    }

    private var profileLine: String {
        if store.hasVerifiedPublicProfile {
            return profile.title(language)
                ?? copy("Verified public profile", "ملف عام موثّق")
        }
        return copy(
            "Local placeholder, not verified online",
            "عنصر محلي مؤقت، غير موثّق عبر الإنترنت"
        )
    }

    private func insightSection(
        title: String,
        body: String,
        direction: LayoutDirection,
        alignment: Alignment
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            CapsLabel(text: title, color: .sakinaMuted, size: 9)
            Text(body)
                .font(.reading(17))
                .lineSpacing(8)
                .multilineTextAlignment(direction == .rightToLeft ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: alignment)
                .environment(\.layoutDirection, direction)
        }
        .foregroundStyle(Color.sakinaInk)
        .padding(18)
        .sakinaCard(cornerRadius: 22)
    }

    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(copy("Sources and references", "المصادر والمراجع"), systemImage: "books.vertical")
                .font(.headline)
                .foregroundStyle(Color.sakinaInk)

            ForEach(insight.references) { reference in
                if let url = reference.url {
                    Link(destination: url) {
                        referenceRow(reference, linked: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    referenceRow(reference, linked: false)
                }
            }
        }
        .padding(18)
        .sakinaCard(cornerRadius: 22)
    }

    private func referenceRow(_ reference: ScholarInsightReference, linked: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: linked ? "arrow.up.right.square" : "book.closed")
                .font(.caption.weight(.semibold))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(reference.title)
                    .font(.subheadline.weight(.semibold))
                if let detail = reference.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.sakinaMuted)
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.sakinaInk)
        .contentShape(Rectangle())
    }
}

#Preview("Insight card layout") {
    let store = ScholarContentStore(client: nil, cache: ScholarContentCache(fileURL: nil))
    ScrollView {
        ScholarInsightCard(
            insight: ScholarInsight(
                id: "preview-only",
                key: ScholarContentKey(situationID: "preview", verseKey: "0:0"),
                scholarID: ScholarProfile.bundledPlaceholder.id,
                situationTitleEnglish: nil,
                situationTitleArabic: nil,
                bodyArabic: "—",
                bodyEnglish: nil,
                isEnglishTranslationReviewed: false,
                references: [],
                publishedAt: nil,
                updatedAt: .now
            ),
            profile: .bundledPlaceholder,
            language: .english,
            store: store
        )
        .padding()
    }
    .background(Color.sakinaCanvas)
    .environmentObject(store)
}
