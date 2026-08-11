import SwiftUI

struct ScholarAvatarView: View {
    let profile: ScholarProfile
    var size: CGFloat = 54
    var showsVerifiedBadge = true
    var language: AppLanguage = .english

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatar
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.sakinaElevated.opacity(0.9), lineWidth: max(2, size * 0.035))
                }

            if showsVerifiedBadge, profile.verified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: size * 0.25, weight: .semibold))
                    .foregroundStyle(Color.sakinaCanvas, Color.sakinaInk)
                    .padding(size * 0.025)
                    .background(Color.sakinaInk, in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var avatar: some View {
        if let remoteURL = profile.avatarURL {
            AsyncImage(url: remoteURL, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                switch phase {
                case .success(let image):
                    fitted(image)
                case .empty, .failure:
                    bundledAvatar
                @unknown default:
                    bundledAvatar
                }
            }
        } else {
            bundledAvatar
        }
    }

    @ViewBuilder
    private var bundledAvatar: some View {
        if let assetName = profile.avatarAssetName {
            fitted(Image(assetName))
        } else {
            ZStack {
                Color.sakinaInk.opacity(0.09)
                Text(initials)
                    .font(.system(size: size * 0.28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.sakinaInk)
            }
        }
    }

    private func fitted(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipped()
    }

    private var initials: String {
        profile.displayNameEnglish
            .split(separator: " ")
            .filter { !$0.hasSuffix(".") }
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }

    private var accessibilityLabel: String {
        if profile.verified {
            return language.pick(
                "\(profile.displayNameEnglish), verified public profile",
                "\(profile.displayNameArabic)، ملف عام موثّق"
            )
        }
        return language.pick(
            "\(profile.displayNameEnglish), local placeholder, not verified online",
            "\(profile.displayNameArabic)، عنصر محلي مؤقت غير موثّق عبر الإنترنت"
        )
    }
}

#Preview("Local scholar placeholder") {
    ScholarAvatarView(profile: .bundledPlaceholder, size: 112)
        .padding()
        .background(Color.sakinaCanvas)
}
