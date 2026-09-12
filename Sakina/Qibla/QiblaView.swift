import SwiftUI
import UIKit

struct QiblaView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @StateObject private var compass = QiblaCompassModel()

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ZStack {
            Color.yqSurface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    introduction
                    phaseContent
                    privacyNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 44)
            }
        }
        .navigationTitle(copy("Qibla", "القبلة"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { compass.start() }
        .onDisappear { compass.stop() }
        .sensoryFeedback(.success, trigger: compass.isAligned)
    }

    private var introduction: some View {
        VStack(spacing: 9) {
            CompanionIllustration(artwork: .qibla, size: 58)
                .accessibilityHidden(true)

            Text(copy("Face the Kaaba", "اتجه نحو الكعبة"))
                .font(.yqTitle2)
                .foregroundStyle(Color.sakinaInk)

            Text(copy(
                "Hold your iPhone flat, then turn slowly until the pointer rests at the top.",
                "أمسك هاتفك أفقيًا، ثم استدر ببطء حتى يشير السهم إلى أعلى الشاشة."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.sakinaMuted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch compass.phase {
        case .permissionRequired:
            QiblaStatusCard(
                symbol: "location.circle",
                title: copy("Use your location", "استخدم موقعك"),
                message: copy(
                    "Haneen needs your approximate location to calculate the Qibla direction. It stays on this device.",
                    "يحتاج حنين إلى موقعك التقريبي لحساب اتجاه القبلة، ويبقى موقعك على هذا الجهاز."
                ),
                buttonTitle: copy("Find Qibla", "حدد القبلة"),
                action: compass.requestPermission
            )

        case .locating:
            VStack(spacing: 20) {
                QiblaCompassDial(
                    turn: 0,
                    isAligned: false,
                    isLoading: true,
                    accessibilityLabel: copy("Qibla compass", "بوصلة القبلة"),
                    accessibilityValue: copy("Finding your direction", "جارٍ تحديد اتجاهك"),
                    reduceMotion: reduceMotion
                )
                Label(copy("Finding your direction…", "جارٍ تحديد اتجاهك…"), systemImage: "location.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.sakinaMuted)

                if compass.needsCalibration {
                    calibrationCard
                }
            }

        case .ready:
            readyContent

        case .permissionDenied:
            QiblaStatusCard(
                symbol: "location.slash",
                title: copy("Location access is off", "الوصول إلى الموقع متوقف"),
                message: copy(
                    "Allow location access in Settings to calculate Qibla from where you are.",
                    "اسمح بالوصول إلى الموقع في الإعدادات لحساب القبلة من مكانك."
                ),
                buttonTitle: copy("Open Settings", "افتح الإعدادات"),
                action: openSettings
            )

        case .permissionRestricted:
            QiblaStatusCard(
                symbol: "lock.trianglebadge.exclamationmark",
                title: copy("Location is restricted", "الموقع مقيّد"),
                message: copy(
                    "This device does not currently allow location access. Check Screen Time or device-management settings.",
                    "لا يسمح هذا الجهاز حاليًا بالوصول إلى الموقع. تحقق من إعدادات مدة استخدام الجهاز أو إدارة الجهاز."
                )
            )

        case .locationServicesDisabled:
            QiblaStatusCard(
                symbol: "location.slash.circle",
                title: copy("Location Services are off", "خدمات الموقع متوقفة"),
                message: copy(
                    "Turn on Location Services in Settings, then return to find Qibla.",
                    "فعّل خدمات الموقع في الإعدادات، ثم عد لتحديد القبلة."
                ),
                buttonTitle: copy("Open Settings", "افتح الإعدادات"),
                action: openSettings
            )

        case .headingUnavailable:
            QiblaStatusCard(
                symbol: "safari",
                title: copy("Compass unavailable", "البوصلة غير متاحة"),
                message: headingUnavailableMessage,
                buttonTitle: copy("Try again", "حاول مجددًا"),
                action: compass.retry
            )

        case let .failed(message):
            QiblaStatusCard(
                symbol: "exclamationmark.circle",
                title: copy("Direction unavailable", "تعذّر تحديد الاتجاه"),
                message: language == .arabic
                    ? "تعذّر تحديد موقعك. انتقل إلى مكان مفتوح وحاول مرة أخرى."
                    : message,
                buttonTitle: copy("Try again", "حاول مجددًا"),
                action: compass.retry
            )
        }
    }

    private var readyContent: some View {
        VStack(spacing: 18) {
            QiblaCompassDial(
                turn: compass.signedTurn ?? 0,
                heading: compass.heading ?? 0,
                isAligned: compass.isAligned,
                isLoading: false,
                accessibilityLabel: copy("Qibla compass", "بوصلة القبلة"),
                accessibilityValue: spokenDirection,
                reduceMotion: reduceMotion
            )

            VStack(spacing: 6) {
                Label(directionTitle, systemImage: directionSymbol)
                    .font(.yqHeadline)
                    .foregroundStyle(Color.sakinaInk)

                if let bearing = compass.qiblaBearing {
                    Text(copy(
                        "Qibla is \(Int(bearing.rounded()))° from true north",
                        "اتجاه القبلة \(Int(bearing.rounded()))° من الشمال الحقيقي"
                    ))
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
                }

                if !compass.isUsingTrueNorth {
                    Text(copy(
                        "Using magnetic north briefly while true north settles.",
                        "يُستخدم اتجاه الشمال المغناطيسي مؤقتًا حتى تتوفر قراءة مستقرة للشمال الحقيقي."
                    ))
                    .font(.caption2)
                    .foregroundStyle(Color.sakinaMuted)
                }
            }
            .multilineTextAlignment(.center)

            if compass.needsCalibration {
                calibrationCard
            }

            HStack(spacing: 8) {
                CompanionIllustration(artwork: .haptics, size: 32)
                Text(copy(
                    "Keep away from magnets, speakers, and magnetic cases.",
                    "ابتعد عن المغناطيس ومكبرات الصوت والأغطية المغناطيسية."
                ))
            }
            .font(.caption)
            .foregroundStyle(Color.sakinaMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    private var calibrationCard: some View {
        Label {
            Text(copy(
                "Compass accuracy is low. Move your iPhone in a figure eight, then keep it flat.",
                "دقة البوصلة منخفضة. حرّك هاتفك على شكل رقم ثمانية، ثم أبقه مستويًا."
            ))
        } icon: {
            Image(systemName: "move.3d")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Color.sakinaInk)
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yaqeenSand.opacity(0.68), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .accessibilityLabel(copy(
            "Compass calibration needed. Move your iPhone in a figure eight, then keep it flat.",
            "تحتاج البوصلة إلى المعايرة. حرّك هاتفك على شكل رقم ثمانية، ثم أبقه مستويًا."
        ))
    }

    private var privacyNote: some View {
        Label {
            Text(copy(
                "Your coordinates and compass readings are used only while this screen is open and are never saved.",
                "تُستخدم إحداثياتك وقراءات البوصلة فقط أثناء فتح هذه الشاشة ولا يتم حفظها."
            ))
        } icon: {
            CompanionIllustration(artwork: .privacy, size: 32)
        }
        .font(.caption)
        .foregroundStyle(Color.sakinaMuted)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var directionTitle: String {
        guard let turn = compass.signedTurn else {
            return copy("Hold still for a moment", "أبقِ الهاتف ثابتًا للحظة")
        }
        if compass.isAligned {
            return copy("You are facing Qibla", "أنت متجه نحو القبلة")
        }
        let degrees = Int(abs(turn).rounded())
        if turn > 0 {
            return copy("Turn \(degrees)° right", "استدر \(degrees)° يمينًا")
        }
        return copy("Turn \(degrees)° left", "استدر \(degrees)° يسارًا")
    }

    private var spokenDirection: String {
        var value = directionTitle
        if let accuracy = compass.headingAccuracy {
            value += copy(
                ". Compass accuracy within \(Int(accuracy.rounded())) degrees.",
                ". دقة البوصلة ضمن \(Int(accuracy.rounded())) درجة."
            )
        }
        return value
    }

    private var directionSymbol: String {
        if compass.isAligned { return "checkmark.circle.fill" }
        guard let turn = compass.signedTurn else { return "safari" }
        return turn >= 0 ? "arrow.triangle.turn.up.right.circle" : "arrow.triangle.turn.up.left.circle"
    }

    private var headingUnavailableMessage: String {
        if let bearing = compass.qiblaBearing {
            return copy(
                "This device cannot provide live heading. Using another compass, face \(Int(bearing.rounded()))° from true north.",
                "لا يستطيع هذا الجهاز تحديد الاتجاه لحظيًا. استخدم بوصلة أخرى واتجه بزاوية \(Int(bearing.rounded()))° من الشمال الحقيقي."
            )
        }
        return copy(
            "A live compass is not available on this device. Qibla works on an iPhone with a magnetometer.",
            "لا يستطيع هذا الجهاز عرض اتجاه البوصلة لحظيًا. تتطلب هذه الميزة هاتف آيفون مزوّدًا بمستشعر مغناطيسي."
        )
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

struct QiblaShortcutCard: View {
    let language: AppLanguage

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        HStack(spacing: 14) {
            CompanionIllustration(artwork: .qibla, size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(copy("Find Qibla", "حدد القبلة"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sakinaInk)
                Text(copy("A private, live compass", "بوصلة لحظية تحافظ على خصوصيتك"))
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
            }

            Spacer(minLength: 10)

            Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.sakinaMuted)
                .accessibilityHidden(true)
        }
        .padding(15)
        .sakinaCard(cornerRadius: 20)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(copy("Opens the Qibla compass", "يفتح بوصلة القبلة"))
    }
}

private struct QiblaStatusCard: View {
    let symbol: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            CompanionIllustration(artwork: CompanionArtwork.badge(for: symbol) ?? .qibla, size: 80)

            VStack(spacing: 7) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.sakinaInk)
                Text(message)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.sakinaMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sakinaCanvas)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(Color.sakinaInk, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(YaqeenPressStyle())
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .sakinaCard(cornerRadius: 26)
        .accessibilityElement(children: .contain)
    }
}

private struct QiblaCompassDial: View {
    let turn: Double
    var heading: Double = 0
    let isAligned: Bool
    let isLoading: Bool
    let accessibilityLabel: String
    let accessibilityValue: String
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2

            ZStack {
                Circle()
                    .fill(Color.yqFill)
                Circle()
                    .strokeBorder(isAligned ? Color.yqAccentDeep : Color.yqSecondary.opacity(0.4), lineWidth: isAligned ? 3 : 1)

                ForEach(0..<72, id: \.self) { index in
                    Capsule()
                        .fill(index.isMultiple(of: 18) ? Color.yqInk : Color.yqSecondary.opacity(0.45))
                        .frame(width: index.isMultiple(of: 18) ? 2.5 : 1, height: index.isMultiple(of: 6) ? 12 : 6)
                        .offset(y: -(radius - 15))
                        .rotationEffect(.degrees(Double(index) * 5))
                }

                cardinalLabels(radius: radius)
                    .rotationEffect(.degrees(-heading))

                ZStack {
                    Capsule()
                        .fill(Color.yqAccentDeep.opacity(0.2))
                        .frame(width: 8, height: size * 0.34)
                        .offset(y: -size * 0.12)

                    QiblaPointer()
                        .fill(Color.yqAccentDeep)
                        .frame(width: size * 0.12, height: size * 0.36)
                        .offset(y: -size * 0.15)


                    Circle()
                        .fill(Color.sakinaElevated)
                        .frame(width: size * 0.1, height: size * 0.1)
                        .overlay(Circle().strokeBorder(Color.yqAccentDeep, lineWidth: 3))
                }
                .rotationEffect(.degrees(turn))
                .animation(
                    reduceMotion ? nil : .interactiveSpring(response: 0.42, dampingFraction: 0.84),
                    value: turn
                )
                .opacity(isLoading ? 0.28 : 1)

                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color.yqAccentDeep)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 320)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    private func cardinalLabels(radius: CGFloat) -> some View {
        ZStack {
            Text("N").offset(y: -(radius - 40))
            Text("E").offset(x: radius - 40)
            Text("S").offset(y: radius - 40)
            Text("W").offset(x: -(radius - 40))
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(Color.sakinaMuted)
        .accessibilityHidden(true)
    }
}

private struct QiblaPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY * 0.78))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    NavigationStack {
        QiblaView()
    }
}
