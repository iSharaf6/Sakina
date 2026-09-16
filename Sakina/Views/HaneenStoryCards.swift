import SwiftUI

/// Personal credit belongs in About, alongside the purpose of the app.
struct HaneenCreatorCard: View {
    let language: AppLanguage
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                Image("CreatorPortrait")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 76, height: 76)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(copy("Made by Islam Sharaf", "من تطوير إسلام شرف"))
                        .font(.yqHeadline)
                        .foregroundStyle(Color.yqInk)
                    Text(copy("The person behind Haneen", "من وراء حنين"))
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            Text(copy(
                "I’m building Haneen to make the Qur’an and daily remembrance a little easier to return to. It’s a personal project, made with care and improved with your feedback.",
                "أطوّر حنين لأُيسّر الرجوع إلى القرآن والأذكار اليومية. إنه مشروع شخصي أعمل عليه بعناية، وتساعدني ملاحظاتكم على تحسينه."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.yqSecondary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)

            Text(copy(
                "Have an idea, want to support the project, or see a chance to work together? I’d be glad to connect.",
                "لديك فكرة، أو ترغب في دعم المشروع، أو ترى فرصة للتعاون أو العمل معًا؟ يسعدني أن نتواصل."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.yqSecondary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://www.linkedin.com/in/islamsharaf-/")!) {
                    connectionRow(copy("Connect on LinkedIn", "تواصل معي عبر LinkedIn"), symbol: "arrow.up.right")
                }
                Divider()
                NavigationLink { ContactSupportView(language: language) } label: {
                    connectionRow(copy("Send a message", "أرسل رسالة"), symbol: "envelope")
                }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .yqCard(cornerRadius: 20)
    }

    private func connectionRow(_ title: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.yqSubheadBold)
            Spacer(minLength: 12)
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .accessibilityHidden(true)
        }
        .foregroundStyle(Color.yqAccentDeep)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

struct HaneenDedicationCard: View {
    let language: AppLanguage
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(uiImage: CompanionImage.image(.dedication))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 200)
                .accessibilityHidden(true)

            Text(copy("In loving memory", "وفاءً لذكراهم"))
                .font(.yqHeadline)
                .foregroundStyle(Color.yqInk)

            Text(copy(
                "I created Haneen in memory of my late grandparents on both my mother’s and father’s sides, hoping it may be a sadaqah jariyah — a continuing charity — on their behalf.",
                "أنشأت حنين وفاءً لذكرى أجدادي وجدّاتي المتوفَّين من جهة أمي وأبي، راجيًا من الله أن يجعله صدقة جارية عنهم."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.yqSecondary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)

            Text(copy(
                "May Allah forgive them, have mercy on them, and make every benefit this app brings a lasting good for them. Ameen.",
                "اللهم اغفر لهم وارحمهم، واجعل كل نفع يأتي من هذا التطبيق في ميزان حسناتهم. آمين."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.yqInk)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .yqCard(cornerRadius: 20)
    }
}
