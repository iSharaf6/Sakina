import CoreLocation
import MapKit
import SwiftUI
import UIKit

/// Mosques or halal food near the user. One screen for both kinds: an honesty
/// card about where the data comes from, a map, then the list, nearest first
/// with two-source matches on top.
struct NearbyPlacesView: View {
    let kind: NearbyPlaceKind
    let language: AppLanguage

    @StateObject private var service: NearbyPlacesService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var selectedPlace: NearbyPlace?
    @State private var selectedMarkerID: String?
    @State private var cameraPosition: MapCameraPosition = .automatic

    init(kind: NearbyPlaceKind, language: AppLanguage) {
        self.kind = kind
        self.language = language
        _service = StateObject(wrappedValue: NearbyPlacesService(language: language))
    }

    private var copy: AppCopy { AppCopy(language: language) }

    private var isBusy: Bool {
        switch service.state {
        case .idle, .locating, .searching: return true
        default: return false
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: kind.title(language), subtitle: kind.subtitle(language))
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                accuracyCard
                    .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                content
                    .revealed(2, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.press()
                    service.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isBusy ? Color.yqTertiary : Color.yqInk)
                }
                .disabled(isBusy)
                .accessibilityLabel(copy("Refresh", "تحديث"))
            }
        }
        .task { service.search(kind) }
        .onDisappear { service.cancel() }
        .onAppear { appeared = true }
        .onChange(of: service.state) { _, newState in
            switch newState {
            case let .results(places):
                if !places.isEmpty { Haptics.success() }
                fitCamera(to: places)
            case .failed:
                Haptics.warning()
            default:
                break
            }
        }
        .onChange(of: selectedMarkerID) { _, id in
            guard let id, case let .results(places) = service.state,
                  let place = places.first(where: { $0.id == id }) else { return }
            selectedPlace = place
        }
        .sheet(item: $selectedPlace, onDismiss: { selectedMarkerID = nil }) { place in
            NearbyPlaceDetailSheet(place: place, kind: kind, language: language)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Accuracy card

    private var accuracyCard: some View {
        HStack(alignment: .top, spacing: 14) {
            IconBadge(symbol: "checkmark.shield.fill", tint: .yqAccent, size: 40, style: .tinted)
            VStack(alignment: .leading, spacing: 4) {
                Text(copy("How to read these results", "كيف تقرأ هذه النتائج"))
                    .font(.yqSubheadBold)
                    .foregroundStyle(Color.yqInk)
                Text(kind.accuracyNote(language))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yqCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: State switch

    @ViewBuilder
    private var content: some View {
        switch service.state {
        case .idle, .locating:
            statusCard(copy("Finding you…", "نحدد موقعك…"))
        case .searching:
            statusCard(copy("Searching nearby…", "نبحث بالقرب منك…"))
        case .denied:
            deniedState
        case let .failed(message):
            failedState(message)
        case let .results(places):
            if places.isEmpty {
                emptyState
            } else {
                resultsSection(places)
            }
        }
    }

    private func statusCard(_ message: String) -> some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color.yqAccent)
            Text(message)
                .font(.yqSubheadMedium)
                .foregroundStyle(Color.yqSecondary)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .yqCard()
        .accessibilityElement(children: .combine)
    }

    private var deniedState: some View {
        VStack(spacing: 4) {
            EmptyGuidanceState(
                title: copy("Location is off", "الموقع متوقف"),
                detail: copy("Allow location for Haneen in Settings so we can search around you. Your location stays on this device.",
                             "اسمح بالوصول إلى الموقع لتطبيق حنين من الإعدادات لنبحث حولك. موقعك يبقى على هذا الجهاز."),
                symbol: "location.slash.fill"
            )
            Button {
                Haptics.tap()
                openSettings()
            } label: {
                PrimaryButton(title: copy("Open Settings", "فتح الإعدادات"), symbol: "gearshape.fill")
            }
            .buttonStyle(.yqPress)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .yqCard()
    }

    private func failedState(_ message: String) -> some View {
        VStack(spacing: 4) {
            EmptyGuidanceState(
                title: copy("Couldn’t search nearby", "تعذر البحث بالقرب منك"),
                detail: message,
                symbol: "wifi.exclamationmark"
            )
            Button {
                Haptics.tap()
                service.refresh()
            } label: {
                PrimaryButton(title: copy("Retry", "إعادة المحاولة"), symbol: "arrow.clockwise")
            }
            .buttonStyle(.yqPress)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .yqCard()
    }

    private var emptyState: some View {
        let radius = NearbyPlace.formatDistance(service.radiusMeters, language: language)
        let title: String
        switch kind {
        case .mosques: title = copy("No mosques within \(radius)", "لا مساجد ضمن \(radius)")
        case .halal: title = copy("No halal places within \(radius)", "لا أماكن حلال ضمن \(radius)")
        }
        return VStack(spacing: 4) {
            EmptyGuidanceState(
                title: title,
                detail: service.canWiden
                    ? copy("Neither Apple Maps nor OpenStreetMap lists one this close. You can widen the search once.",
                           "لا تذكر خرائط Apple ولا OpenStreetMap مكانًا بهذا القرب. يمكنك توسيع البحث مرة واحدة.")
                    : copy("Nothing is listed in either source. If you know a place, adding it to OpenStreetMap helps everyone.",
                           "لا يوجد شيء مدرج في أيٍّ من المصدرين. إن كنت تعرف مكانًا، فإضافته إلى OpenStreetMap تفيد الجميع."),
                symbol: kind.symbol
            )
            if service.canWiden {
                Button {
                    Haptics.tap()
                    service.widenSearch()
                } label: {
                    PrimaryButton(title: copy("Search a wider area", "توسيع نطاق البحث"), symbol: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.yqPress)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else {
                Button {
                    Haptics.tap()
                    service.refresh()
                } label: {
                    SecondaryButton(title: copy("Try again", "حاول مرة أخرى"), symbol: "arrow.clockwise")
                }
                .buttonStyle(.yqPress)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .yqCard()
    }

    // MARK: Results

    private func resultsSection(_ places: [NearbyPlace]) -> some View {
        let confirmed = places.filter(\.isConfirmedByBothSources).count
        return VStack(alignment: .leading, spacing: 12) {
            map(places)
            if !service.unavailableSources.isEmpty {
                sourceWarning
            }
            SectionHeader(confirmed > 0 ? copy("Confirmed first", "المؤكَّد أولًا") : copy("Nearest first", "الأقرب أولًا")) {
                Text(countText(places.count, confirmed: confirmed))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                    .multilineTextAlignment(.trailing)
            }
            RowGroup {
                ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                    Button {
                        Haptics.press()
                        selectedPlace = place
                    } label: {
                        NearbyPlaceRow(place: place, kind: kind, language: language)
                    }
                    .buttonStyle(.yqPressSoft)
                    if index < places.count - 1 { RowDivider() }
                }
            }
            if service.canWiden {
                Button {
                    Haptics.tap()
                    service.widenSearch()
                } label: {
                    SecondaryButton(title: copy("Search a wider area", "توسيع نطاق البحث"), symbol: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.yqPress)
                .padding(.top, 4)
            }
            footer
        }
    }

    private func map(_ places: [NearbyPlace]) -> some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom], selection: $selectedMarkerID) {
            UserAnnotation()
            ForEach(places) { place in
                Marker(place.name, systemImage: kind.symbol, coordinate: place.coordinate)
                    .tint(place.isConfirmedByBothSources ? Color.yqAccentDeep : Color.yqAccent)
                    .tag(place.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.yqHairline, lineWidth: 1))
        .accessibilityLabel(copy("Map of nearby results", "خريطة النتائج القريبة"))
    }

    private var sourceWarning: some View {
        let missing = service.unavailableSources.map { $0.title(language) }.sorted().joined(separator: ", ")
        let present = PlaceSource.allCases
            .filter { !service.unavailableSources.contains($0) }
            .map { $0.title(language) }
            .joined(separator: ", ")
        return HStack(alignment: .top, spacing: 12) {
            IconBadge(symbol: "exclamationmark.triangle.fill", tint: BadgeTint.slate.color, size: 32, style: .tinted)
            Text(copy("\(missing) didn’t respond, so this list comes from \(present) only and may be incomplete. Refresh to try again.",
                      "لم يستجب \(missing)، لذا هذه القائمة من \(present) فقط وقد تكون ناقصة. حدّث للمحاولة مجددًا."))
                .font(.yqCaption)
                .foregroundStyle(Color.yqSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yqCard()
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(copy("Search radius \(NearbyPlace.formatDistance(service.radiusMeters, language: language)). Map data from Apple Maps and © OpenStreetMap contributors.",
                      "نطاق البحث \(NearbyPlace.formatDistance(service.radiusMeters, language: language)). بيانات الخريطة من خرائط Apple ومساهمي © OpenStreetMap."))
            if service.updating { Text(copy("Checking the other map source…", "جارٍ التحقق من مصدر الخريطة الآخر…")) }
            if let updated = service.lastUpdated {
                let time = updated.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(language.locale))
                Text(copy("Updated \(time).", "حُدِّث في \(time)."))
            }
        }
        .font(.yqCaption)
        .foregroundStyle(Color.yqTertiary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
    }

    private func countText(_ count: Int, confirmed: Int) -> String {
        let places: String
        switch language {
        case .english:
            places = count == 1 ? "1 place" : "\(count) places"
        case .arabic:
            switch count {
            case 1: places = "مكان واحد"
            case 2: places = "مكانان"
            case 3...10: places = "\(count) أماكن"
            default: places = "\(count) مكانًا"
            }
        }
        guard confirmed > 0 else { return places }
        return copy("\(places) · \(confirmed) confirmed", "\(places) · \(confirmed) مؤكَّد")
    }

    // MARK: Camera

    private func fitCamera(to places: [NearbyPlace]) {
        var coordinates = places.prefix(8).map(\.coordinate)
        if let user = service.userCoordinate { coordinates.append(user) }
        guard let first = coordinates.first else { return }

        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max(0.012, (maxLat - minLat) * 1.5),
                                    longitudeDelta: max(0.012, (maxLon - minLon) * 1.5))
        let region = MKCoordinateRegion(center: center, span: span)
        if reduceMotion {
            cameraPosition = .region(region)
        } else {
            withAnimation(.easeInOut(duration: 0.35)) { cameraPosition = .region(region) }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Row

struct NearbyPlaceRow: View {
    let place: NearbyPlace
    let kind: NearbyPlaceKind
    let language: AppLanguage

    private var copy: AppCopy { AppCopy(language: language) }

    private var subtitle: String {
        var parts = [place.distanceText(language)]
        if let address = place.address, !address.isEmpty { parts.append(address) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(symbol: kind.symbol, tint: .yqAccent, size: 36,
                      style: place.isConfirmedByBothSources ? .tinted : .solid)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .lineLimit(2)
                if kind == .halal, let evidence = place.halalEvidence {
                    Text(evidence.title(language))
                        .font(.yqCaption)
                        .foregroundStyle(evidence == .unconfirmed ? Color.yqTertiary : Color.yqAccentDeep)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            sourceTag
            Chevron()
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var sourceTag: some View {
        if place.isConfirmedByBothSources {
            Tag(text: copy("2 sources", "مصدران"), tint: .yqAccentDeep, filled: true)
        } else if let source = place.sources.first {
            Tag(text: source.title(language), tint: BadgeTint.slate.color)
        }
    }
}

// MARK: - Detail sheet

struct NearbyPlaceDetailSheet: View {
    let place: NearbyPlace
    let kind: NearbyPlaceKind
    let language: AppLanguage

    @Environment(\.dismiss) private var dismiss

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                provenanceCard
                actions
                Text(kind.accuracyNote(language))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .yqScreen()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            IconBadge(symbol: kind.symbol, tint: .yqAccent, size: 48, style: .tinted)
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.yqTitle2)
                    .foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(place.distanceText(language) + (place.address.map { " · \($0)" } ?? ""))
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.leading)
    }

    private var provenanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapsLabel(text: copy("Where this comes from", "مصدر هذه المعلومة"))
            ForEach(PlaceSource.allCases, id: \.self) { source in
                let listed = place.sources.contains(source)
                HStack(spacing: 10) {
                    Image(systemName: listed ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(listed ? Color.yqAccent : Color.yqTertiary)
                    Text(source.title(language))
                        .font(.yqSubheadMedium)
                        .foregroundStyle(listed ? Color.yqInk : Color.yqSecondary)
                    Spacer(minLength: 8)
                    Text(listed ? copy("Listed", "مدرج") : copy("Not listed", "غير مدرج"))
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
                .accessibilityElement(children: .combine)
            }
            if place.isConfirmedByBothSources {
                Text(copy("Both sources list a place with this name at this spot.", "يذكر المصدران مكانًا بهذا الاسم في هذا الموضع."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqAccentDeep)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(copy("Only one source lists this place. Confirm before relying on it.", "مصدر واحد فقط يذكر هذا المكان. تأكد قبل الاعتماد عليه."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if kind == .halal, let evidence = place.halalEvidence {
                RowDivider(inset: 0)
                HStack(spacing: 10) {
                    Image(systemName: evidence == .unconfirmed ? "questionmark.circle.fill" : "checkmark.seal.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(evidence == .unconfirmed ? Color.yqTertiary : Color.yqAccent)
                    Text(evidence.title(language))
                        .font(.yqSubheadMedium)
                        .foregroundStyle(Color.yqInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yqCard()
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.tap()
                openDirections()
            } label: {
                PrimaryButton(title: copy("Directions", "الاتجاهات"), symbol: "arrow.triangle.turn.up.right.diamond.fill")
            }
            .buttonStyle(.yqPress)

            Button {
                Haptics.tap()
                openGoogleMaps()
            } label: {
                SecondaryButton(title: copy("Google Maps", "خرائط Google"), symbol: "map.fill")
            }
            .buttonStyle(.yqPress)

            if let telURL {
                Button {
                    Haptics.tap()
                    UIApplication.shared.open(telURL)
                } label: {
                    SecondaryButton(title: copy("Call", "اتصال"), symbol: "phone.fill")
                }
                .buttonStyle(.yqPress)
            }

            if let website = place.websiteURL {
                Button {
                    Haptics.tap()
                    UIApplication.shared.open(website)
                } label: {
                    SecondaryButton(title: copy("Website", "الموقع الإلكتروني"), symbol: "safari.fill")
                }
                .buttonStyle(.yqPress)
            }

            if let osmURL = place.osmURL {
                Button {
                    Haptics.tap()
                    UIApplication.shared.open(osmURL)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(copy("Report a problem on OpenStreetMap", "الإبلاغ عن مشكلة في OpenStreetMap"))
                            .font(.yqSubheadBold)
                    }
                    .foregroundStyle(Color.yqAccentDeep)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.yqPressSoft)
            }
        }
    }

    // MARK: Actions

    private var telURL: URL? {
        guard let phone = place.phone else { return nil }
        let digits = phone.filter { "+0123456789".contains($0) }
        guard digits.count >= 5 else { return nil }
        return URL(string: "tel:\(digits)")
    }

    private var encodedName: String {
        place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.name
    }

    private func openDirections() {
        if let item = place.mapItem {
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
            return
        }
        let ll = "\(place.latitude),\(place.longitude)"
        if let url = URL(string: "https://maps.apple.com/?daddr=\(ll)&q=\(encodedName)") {
            UIApplication.shared.open(url)
        } else if let fallback = place.appleMapsURL {
            UIApplication.shared.open(fallback)
        }
    }

    private func openGoogleMaps() {
        let ll = "\(place.latitude),\(place.longitude)"
        if let app = URL(string: "comgooglemaps://?q=\(ll)&center=\(ll)&zoom=16"),
           UIApplication.shared.canOpenURL(app) {
            UIApplication.shared.open(app)
        } else if let web = place.googleMapsURL {
            UIApplication.shared.open(web)
        }
    }
}
