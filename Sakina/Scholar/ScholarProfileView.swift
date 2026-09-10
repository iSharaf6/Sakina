import SwiftUI

@MainActor
struct ScholarProfileView: View {
    @EnvironmentObject private var store: ScholarContentStore
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @State private var presentedInsight: ScholarInsight?

    private let languageOverride: AppLanguage?

    init(languageOverride: AppLanguage? = nil) {
        self.languageOverride = languageOverride
    }

    private var language: AppLanguage {
        languageOverride ?? AppLanguage(rawValue: languageRaw) ?? .english
    }
    private var copy: AppCopy { AppCopy(language: language) }
    private var profile: ScholarProfile { store.profile }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    socialLinks
                    insightsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 42)
            }
        }
        .navigationTitle(copy("Scholarly review", "المراجعة الشرعية"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadProfileAndPublishedInsights()
        }
        .sheet(item: $presentedInsight) { insight in
            ScholarInsightDetailView(
                insight: insight,
                profile: profile,
                language: language,
                store: store
            )
            .presentationDetents([.large])
            .presentationBackground(Color.sakinaCanvas)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 15) {
            ScholarAvatarView(profile: profile, size: 126, language: language)

            VStack(spacing: 5) {
                HStack(spacing: 6) {
                    Text(profile.displayName(language))
                        .font(.title2.weight(.semibold))
                    if profile.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.sakinaInk)
                            .accessibilityLabel(copy("Verified profile", "ملف موثّق"))
                    }
                }
                .foregroundStyle(Color.sakinaInk)

                if profile.secondaryDisplayName(language) != profile.displayName(language) {
                    Text(profile.secondaryDisplayName(language))
                        .font(language == .arabic ? .subheadline : .system(.body, design: .default))
                        .foregroundStyle(Color.sakinaMuted)
                        .environment(\.layoutDirection, language == .arabic ? .leftToRight : .rightToLeft)
                }

                if let title = profile.title(language) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.sakinaInk)
                }

                Label(profileTrustText, systemImage: profileTrustSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        store.isShowingLocalPlaceholder ? Color.sakinaMuted : Color.sakinaInk
                    )
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        (store.isShowingLocalPlaceholder
                            ? Color.sakinaMuted.opacity(0.09)
                            : Color.sakinaInk.opacity(0.08)),
                        in: Capsule()
                    )
            }
            .multilineTextAlignment(.center)

            if let biography = profile.biography(language) {
                Text(biography)
                    .font(.reading(15))
                    .lineSpacing(6)
                    .foregroundStyle(Color.sakinaMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .sakinaCard(tint: .yaqeenForest, cornerRadius: 26)
        .accessibilityElement(children: .contain)
    }

    private var socialLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionEyebrow(
                title: copy("Links", "الروابط"),
                detail: store.isShowingLocalPlaceholder
                    ? copy("Supplied local links", "روابط محلية مُقدَّمة")
                    : copy("Public profile links", "روابط الملف العام")
            )

            VStack(spacing: 0) {
                if let facebookURL = profile.facebookURL {
                    socialRow(
                        title: "Facebook",
                        url: facebookURL,
                        symbol: "person.2.fill"
                    )
                }

                if profile.facebookURL != nil, profile.instagramURL != nil {
                    Divider().padding(.leading, 54)
                }

                if let instagramURL = profile.instagramURL {
                    socialRow(
                        title: "Instagram",
                        url: instagramURL,
                        symbol: "camera.fill"
                    )
                }
            }
            .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.sakinaHairline, lineWidth: 1)
            }
        }
    }

    private func socialRow(title: String, url: URL, symbol: String) -> some View {
        Link(destination: url) {
            HStack(spacing: 13) {
                CompanionIllustration(artwork: CompanionArtwork.badge(for: symbol) ?? .social, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(url.absoluteString.replacingOccurrences(of: "https://", with: ""))
                        .font(.caption)
                        .foregroundStyle(Color.sakinaMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.sakinaMuted)
            }
            .foregroundStyle(Color.sakinaInk)
            .padding(13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(url.absoluteString)")
        .accessibilityHint(copy("Opens in your browser", "يفتح في المتصفح"))
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionEyebrow(
                title: copy("Published insights", "الإضاءات المنشورة"),
                detail: publishedCount
            )

            switch store.allInsightsState {
            case .idle where store.allPublishedInsights.isEmpty,
                 .loading where store.allPublishedInsights.isEmpty:
                insightLoadingPlaceholders
            case .failed where store.allPublishedInsights.isEmpty:
                statusCard(
                    title: store.isShowingLocalPlaceholder
                        ? copy("Couldn’t verify a public scholar profile", "تعذّر التحقق من ملف عام للمراجع")
                        : copy("Couldn’t refresh published insights", "تعذّر تحديث الإضاءات المنشورة"),
                    detail: store.isShowingLocalPlaceholder
                        ? copy(
                            "Only the clearly marked local placeholder is shown. No public verification or insight is claimed.",
                            "لا يظهر إلا العنصر المحلي المعلَّم بوضوح، ولا يُدّعى توثيق عام أو إضاءة منشورة."
                        )
                        : copy("Please try again when you have a connection.", "أعد المحاولة عند توفر الاتصال."),
                    symbol: "exclamationmark.arrow.triangle.2.circlepath",
                    offersRetry: true
                )
            case .offline where store.allPublishedInsights.isEmpty:
                statusCard(
                    title: store.isShowingLocalPlaceholder
                        ? copy("Online verification is unavailable", "التحقق عبر الإنترنت غير متاح")
                        : copy("Published insights aren’t available offline yet", "الإضاءات المنشورة غير متاحة دون اتصال بعد"),
                    detail: store.isShowingLocalPlaceholder
                        ? copy(
                            "Showing local placeholder details only; they are not verified online.",
                            "تُعرض بيانات محلية مؤقتة فقط، ولم يتم توثيقها عبر الإنترنت."
                        )
                        : copy(
                            "A previously verified public profile remains saved on this device.",
                            "يبقى ملف عام سبق توثيقه محفوظًا على هذا الجهاز."
                        ),
                    symbol: "wifi.slash",
                    offersRetry: true
                )
            case .unconfigured where store.allPublishedInsights.isEmpty:
                statusCard(
                    title: store.isShowingLocalPlaceholder
                        ? copy("Online scholar content isn’t configured", "محتوى المراجع عبر الإنترنت غير مهيأ")
                        : copy("No published insights saved", "لا توجد إضاءات منشورة محفوظة"),
                    detail: store.isShowingLocalPlaceholder
                        ? copy(
                            "The identity, portrait, and links above are a local placeholder and are not verified online.",
                            "الاسم والصورة والروابط أعلاه عنصر محلي مؤقت، ولم يتم توثيقه عبر الإنترنت."
                        )
                        : copy(
                            "This previously verified public profile is available offline.",
                            "هذا الملف العام الذي سبق توثيقه متاح دون اتصال."
                        ),
                    symbol: "network.slash",
                    offersRetry: false
                )
            case .loaded where store.allPublishedInsights.isEmpty:
                statusCard(
                    title: store.isShowingLocalPlaceholder
                        ? copy("No public scholar profile is currently published", "لا يوجد ملف عام منشور للمراجع حاليًا")
                        : copy("No published insights yet", "لا توجد إضاءات منشورة بعد"),
                    detail: store.isShowingLocalPlaceholder
                        ? copy(
                            "Only the local, unverified placeholder remains visible.",
                            "لا يظهر الآن إلا العنصر المحلي غير الموثّق."
                        )
                        : copy(
                            "Published insights will appear here after publication.",
                            "ستظهر الإضاءات هنا بعد نشرها."
                        ),
                    symbol: "text.book.closed",
                    offersRetry: false
                )
            default:
                if [.offline, .failed].contains(store.allInsightsState) {
                    Label(
                        copy("Showing saved public content", "يُعرض المحتوى العام المحفوظ"),
                        systemImage: "arrow.down.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
                }

                ForEach(store.allPublishedInsights) { insight in
                    insightRow(insight)
                }
            }
        }
    }

    private var publishedCount: String {
        let count = store.allPublishedInsights.count
        return language.pick(
            "\(count) published",
            count == 0 ? "لم يُنشر شيء" : "\(count) منشورة"
        )
    }

    private var profileTrustText: String {
        switch store.profileSource {
        case .localPlaceholder:
            return copy("Local placeholder · not verified online", "عنصر محلي مؤقت · غير موثّق عبر الإنترنت")
        case .cachedVerified:
            return copy("Previously verified · saved offline", "سبق توثيقه · محفوظ دون اتصال")
        case .liveVerified:
            return copy("Verified public profile", "ملف عام موثّق")
        }
    }

    private var profileTrustSymbol: String {
        store.isShowingLocalPlaceholder ? "exclamationmark.circle" : "checkmark.seal.fill"
    }

    private var insightLoadingPlaceholders: some View {
        VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 4).frame(width: 150, height: 14)
                    RoundedRectangle(cornerRadius: 4).frame(height: 12)
                    RoundedRectangle(cornerRadius: 4).frame(width: 210, height: 12)
                }
                .foregroundStyle(Color.sakinaMuted.opacity(0.16))
                .padding(17)
                .sakinaCard(cornerRadius: 19)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(copy("Loading published insights", "جارٍ تحميل الإضاءات المنشورة"))
    }

    private func insightRow(_ insight: ScholarInsight) -> some View {
        Button {
            presentedInsight = insight
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline) {
                    Text(insight.situationTitle(language) ?? copy("Published insight", "إضاءة منشورة"))
                        .font(.headline)
                        .foregroundStyle(Color.sakinaInk)
                    Spacer(minLength: 8)
                    Text(insight.key.verseKey)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.sakinaMuted)
                }

                Text(insight.body(language))
                    .font(.reading(14))
                    .lineSpacing(4)
                    .foregroundStyle(Color.sakinaMuted)
                    .lineLimit(3)
                    .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: language == .arabic ? .trailing : .leading)

                Text(insight.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Color.sakinaMuted)
            }
            .padding(17)
            .sakinaCard(cornerRadius: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(copy("Opens the full insight", "يفتح الإضاءة كاملة"))
    }

    private func statusCard(
        title: String,
        detail: String,
        symbol: String,
        offersRetry: Bool
    ) -> some View {
        VStack(spacing: 11) {
            CompanionIllustration(artwork: CompanionArtwork.badge(for: symbol) ?? .help, size: 64)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Color.sakinaMuted)
                .multilineTextAlignment(.center)

            if offersRetry {
                Button(copy("Try again", "أعد المحاولة")) {
                    Task { await store.loadProfileAndPublishedInsights(force: true) }
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
            }
        }
        .foregroundStyle(Color.sakinaInk)
        .frame(maxWidth: .infinity)
        .padding(22)
        .sakinaCard(cornerRadius: 20)
    }
}

#Preview("Scholar profile — English") {
    NavigationStack {
        ScholarProfileView(languageOverride: .english)
            .environmentObject(
                ScholarContentStore(
                    client: nil,
                    cache: ScholarContentCache(fileURL: nil)
                )
            )
    }
}

#Preview("Scholar profile — Arabic") {
    NavigationStack {
        ScholarProfileView(languageOverride: .arabic)
            .environmentObject(
                ScholarContentStore(
                    client: nil,
                    cache: ScholarContentCache(fileURL: nil)
                )
            )
    }
    .environment(\.layoutDirection, .rightToLeft)
}
