import Combine
import CoreLocation
import Foundation
import MapKit

// MARK: - Kinds

/// The two "near me" searches. Each kind owns its query words, its symbol and
/// the honesty note shown above the results.
enum NearbyPlaceKind: String, CaseIterable, Identifiable {
    case mosques
    case halal

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .mosques: return language.pick("Mosques near me", "المساجد القريبة")
        case .halal: return language.pick("Halal food near me", "مطاعم حلال قريبة")
        }
    }

    func subtitle(_ language: AppLanguage) -> String {
        switch self {
        case .mosques:
            return language.pick("Cross-checked against Apple Maps and OpenStreetMap.",
                                 "نقارن النتائج بين خرائط Apple وOpenStreetMap.")
        case .halal:
            return language.pick("Cross-checked against Apple Maps and OpenStreetMap.",
                                 "نقارن النتائج بين خرائط Apple وOpenStreetMap.")
        }
    }

    var symbol: String {
        switch self {
        case .mosques: return "building.columns.fill"
        case .halal: return "fork.knife"
        }
    }

    /// Natural-language queries sent to Apple Maps. Every query runs and the
    /// results are unioned, then filtered by `matchesKind`.
    var searchQueries: [String] {
        switch self {
        case .mosques: return ["mosque", "masjid", "islamic center", "musalla"]
        case .halal: return ["halal restaurant", "halal food", "halal"]
        }
    }

    func accuracyNote(_ language: AppLanguage) -> String {
        switch self {
        case .mosques:
            return language.pick(
                "Results come from Apple Maps and OpenStreetMap. Places found in both are marked. Check prayer times and women’s facilities with the mosque.",
                "النتائج من خرائط Apple وOpenStreetMap، ونميّز الأماكن المذكورة في المصدرين معًا. تواصل مع المسجد للتأكد من مواقيت الصلاة وتوفّر مصلى للنساء."
            )
        case .halal:
            return language.pick(
                "Results come from Apple Maps and OpenStreetMap. Places found in both are marked. Always confirm halal certification with the restaurant before ordering.",
                "النتائج من خرائط Apple وOpenStreetMap، ونميّز الأماكن المذكورة في المصدرين معًا. اسأل المطعم عن شهادة الحلال قبل الطلب."
            )
        }
    }
}

// MARK: - Model

enum PlaceSource: String, Hashable, CaseIterable {
    case appleMaps
    case openStreetMap

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .appleMaps: return language.pick("Apple Maps", "خرائط Apple")
        case .openStreetMap: return "OpenStreetMap"
        }
    }
}

/// How the halal claim was established. Shown verbatim so nobody mistakes a
/// generic restaurant for a certified one.
enum HalalEvidence: Hashable {
    /// OpenStreetMap carries `diet:halal=yes|only` or a halal cuisine tag.
    case osmTag
    /// The place name itself says halal (either source).
    case name
    /// Apple returned it for a halal query but nothing in the record says halal.
    case unconfirmed

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .osmTag: return language.pick("Tagged halal on OpenStreetMap", "مصنَّف حلالًا في OpenStreetMap")
        case .name: return language.pick("Name says halal", "ترد كلمة حلال في الاسم")
        case .unconfirmed: return language.pick("Halal not confirmed — ask first", "لم يُؤكَّد أن الطعام حلال، اسأل أولًا")
        }
    }
}

struct NearbyPlace: Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let distanceMeters: Double
    let phone: String?
    let websiteURL: URL?
    let sources: Set<PlaceSource>
    let isHalalTagged: Bool
    let halalEvidence: HalalEvidence?
    let osmURL: URL?
    let appleMapsURL: URL?
    let googleMapsURL: URL?
    /// The live Apple record, kept so Directions opens the named place rather
    /// than a bare coordinate. Excluded from equality on purpose.
    let mapItem: MKMapItem?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isConfirmedByBothSources: Bool { sources.count >= 2 }

    static func == (lhs: NearbyPlace, rhs: NearbyPlace) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// "350 m" or "1.2 km", digits formatted for the app language.
    func distanceText(_ language: AppLanguage) -> String {
        NearbyPlace.formatDistance(distanceMeters, language: language)
    }

    static func formatDistance(_ meters: Double, language: AppLanguage) -> String {
        let locale = language.locale
        if meters < 1000 {
            let rounded = max(10, (meters / 10).rounded() * 10)
            let number = rounded.formatted(.number.precision(.fractionLength(0)).locale(locale))
            return "\(number) \(language.pick("m", "م"))"
        }
        let km = meters / 1000
        let number = km.formatted(.number.precision(.fractionLength(km < 10 ? 0...1 : 0...0)).locale(locale))
        return "\(number) \(language.pick("km", "كم"))"
    }
}

// MARK: - Service

/// Finds mosques or halal food near the user by asking Apple Maps and
/// OpenStreetMap independently, then merging the two answers. Constructing
/// the service never prompts for location; `search(_:)` does.
@MainActor
final class NearbyPlacesService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    enum State: Equatable {
        case idle
        case locating
        case searching
        case results([NearbyPlace])
        case failed(String)
        case denied
    }

    static let defaultRadiusMeters: Double = 8_000
    static let maximumRadiusMeters: Double = 16_000
    static let resultCap = 40

    @Published private(set) var state: State = .idle
    @Published private(set) var kind: NearbyPlaceKind?
    @Published private(set) var userCoordinate: CLLocationCoordinate2D?
    @Published private(set) var radiusMeters: Double = NearbyPlacesService.defaultRadiusMeters
    /// Sources that failed on the last search. Shown so the user knows the
    /// list may be incomplete rather than silently trusting a partial answer.
    @Published private(set) var unavailableSources: Set<PlaceSource> = []
    @Published private(set) var lastUpdated: Date?

    var language: AppLanguage

    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var cachedLocation: CLLocation?
    private var searchTask: Task<Void, Never>?
    private var locationTimeout: Task<Void, Never>?
    @Published private(set) var updating = false

    var canWiden: Bool { radiusMeters < Self.maximumRadiusMeters }

    init(language: AppLanguage = .english) {
        self.language = language
        let manager = CLLocationManager()
        self.manager = manager
        super.init()
        manager.delegate = self
        // Walking distances matter here, but street-level precision does not.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: Public API

    /// Locates the user (prompting once for When-In-Use if needed), then
    /// searches both sources. Safe to call repeatedly; earlier searches cancel.
    func search(_ kind: NearbyPlaceKind) {
        self.kind = kind
        radiusMeters = Self.defaultRadiusMeters
        run(kind)
    }

    /// Re-runs the current search with a fresh location fix.
    func refresh() {
        guard let kind else { return }
        cachedLocation = nil
        run(kind)
    }

    /// Doubles the radius once (8 km → 16 km) and searches again.
    func widenSearch() {
        guard let kind, canWiden else { return }
        radiusMeters = min(Self.maximumRadiusMeters, radiusMeters * 2)
        run(kind)
    }

    private func run(_ kind: NearbyPlaceKind) {
        cancel()
        searchTask = Task { [weak self] in
            await self?.perform(kind)
        }
    }

    private func perform(_ kind: NearbyPlaceKind) async {
        unavailableSources = []
        state = .locating

        let location: CLLocation
        do {
            location = try await currentLocation()
        } catch let error as NearbyPlacesError {
            if Task.isCancelled { return }
            switch error {
            case .permissionDenied, .permissionRestricted:
                state = .denied
            default:
                state = .failed(error.message(language))
            }
            return
        } catch {
            if Task.isCancelled { return }
            state = .failed(NearbyPlacesError.locationUnavailable.message(language))
            return
        }

        if Task.isCancelled { return }
        userCoordinate = location.coordinate
        state = .searching

        let radius = radiusMeters
        let language = language

        updating = true
        defer { if !Task.isCancelled { updating = false } }
        await withTaskGroup(of: (PlaceSource, Result<[Candidate], Error>).self) { group in
            group.addTask { (.appleMaps, await Self.searchApple(kind: kind, around: location, radius: radius)) }
            group.addTask { (.openStreetMap, await Self.searchOverpass(kind: kind, around: location, radius: radius, language: language)) }
            var candidates: [Candidate] = []
            var successes = 0
            for await (source, result) in group {
                guard !Task.isCancelled else { group.cancelAll(); return }
                switch result {
                case .success(let items): candidates += items; successes += 1
                case .failure: unavailableSources.insert(source)
                }
                // Show useful results immediately; the slower source enriches them later.
                if !candidates.isEmpty {
                    lastUpdated = .now
                    state = .results(Array(Self.merge(candidates, around: location).prefix(Self.resultCap)))
                }
            }
            guard !Task.isCancelled else { return }
            if successes == 0 { state = .failed(NearbyPlacesError.allSourcesFailed.message(language)) }
            else {
                lastUpdated = .now
                state = .results(Array(Self.merge(candidates, around: location).prefix(Self.resultCap)))
            }
        }
    }

    func cancel() {
        searchTask?.cancel()
        searchTask = nil
        locationTimeout?.cancel()
        finish(with: .failure(CancellationError()))
        updating = false
    }

    // MARK: Location

    private func currentLocation() async throws -> CLLocation {
        if let cachedLocation, Date.now.timeIntervalSince(cachedLocation.timestamp) < 120 {
            return cachedLocation
        }
        if let recent = manager.location, recent.horizontalAccuracy >= 0,
           abs(recent.timestamp.timeIntervalSinceNow) < 120 { return recent }
        guard continuation == nil else { throw NearbyPlacesError.requestAlreadyInProgress }

        let location = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            self.continuation = continuation
            beginRequest(for: manager.authorizationStatus)
        }
        cachedLocation = location
        return location
    }

    private func beginRequest(for status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
            locationTimeout?.cancel()
            locationTimeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(12)) } catch { return }
                self?.finish(with: .failure(NearbyPlacesError.locationUnavailable))
            }
        case .denied:
            finish(with: .failure(NearbyPlacesError.permissionDenied))
        case .restricted:
            finish(with: .failure(NearbyPlacesError.permissionRestricted))
        @unknown default:
            finish(with: .failure(NearbyPlacesError.locationUnavailable))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        beginRequest(for: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations
            .filter({ $0.horizontalAccuracy >= 0 })
            .max(by: { $0.timestamp < $1.timestamp }) else {
            finish(with: .failure(NearbyPlacesError.locationUnavailable))
            return
        }
        finish(with: .success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            finish(with: .failure(NearbyPlacesError.permissionDenied))
        } else {
            finish(with: .failure(NearbyPlacesError.locationUnavailable))
        }
    }

    private func finish(with result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        locationTimeout?.cancel()
        locationTimeout = nil
        continuation.resume(with: result)
    }

    // MARK: Apple Maps

    /// One raw hit from either source, before merging.
    struct Candidate {
        let source: PlaceSource
        let name: String
        let coordinate: CLLocationCoordinate2D
        let address: String?
        let phone: String?
        let websiteURL: URL?
        let halalEvidence: HalalEvidence?
        let osmURL: URL?
        let mapItem: MKMapItem?
        /// True when the source had no name and we substituted a placeholder.
        var isUnnamed: Bool = false
    }

    private nonisolated static func searchApple(kind: NearbyPlaceKind, around location: CLLocation,
                                                radius: Double) async -> Result<[Candidate], Error> {
        let region = MKCoordinateRegion(center: location.coordinate,
                                        latitudinalMeters: radius * 2,
                                        longitudinalMeters: radius * 2)
        var collected: [Candidate] = []
        var succeeded = 0
        var lastError: Error?

        await withTaskGroup(of: Result<[Candidate], Error>.self) { group in
            for query in kind.searchQueries.prefix(1) {
                group.addTask {
                    do {
                        let request = MKLocalSearch.Request()
                        request.naturalLanguageQuery = query
                        request.region = region
                        request.resultTypes = .pointOfInterest
                        let search = MKLocalSearch(request: request)
                        let timeout = Task {
                            do { try await Task.sleep(for: .seconds(10)) } catch { return }
                            search.cancel()
                        }
                        defer { timeout.cancel() }
                        let response = try await withTaskCancellationHandler {
                            try await search.start()
                        } onCancel: { search.cancel() }
                        let hits = response.mapItems.compactMap { item in
                            Self.candidate(from: item, query: query, kind: kind, origin: location, radius: radius)
                        }
                        return .success(hits)
                    } catch let error as MKError where error.code == .placemarkNotFound {
                        // "Nothing matched" is an answer, not a failure.
                        return .success([])
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case let .success(hits):
                    succeeded += 1
                    collected += hits
                case let .failure(error):
                    lastError = error
                }
            }
        }

        if succeeded == 0, let lastError { return .failure(lastError) }
        return .success(collected)
    }

    private nonisolated static func candidate(from item: MKMapItem, query: String, kind: NearbyPlaceKind,
                                              origin: CLLocation, radius: Double) -> Candidate? {
        guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
        let placemark = item.placemark
        let coordinate = placemark.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }

        // Apple treats the region as a hint and happily returns places far away.
        let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: origin)
        guard distance <= radius * 1.25 else { return nil }

        let category = item.pointOfInterestCategory
        let lowered = name.lowercased()

        var halalEvidence: HalalEvidence?
        switch kind {
        case .mosques:
            // Apple rarely categorises places of worship, so an uncategorised hit
            // for "mosque" is usually right; obvious non-mosques are dropped.
            let named = Self.containsAny(lowered, Self.mosqueKeywords)
            let plausible = category == nil && !Self.containsAny(lowered, Self.nonMosqueKeywords)
            guard named || plausible else { return nil }
        case .halal:
            if Self.containsAny(lowered, Self.halalKeywords) {
                halalEvidence = .name
            } else if query == "halal restaurant", let category, Self.foodCategories.contains(category) {
                halalEvidence = .unconfirmed
            } else {
                return nil
            }
        }

        var address = placemark.title
        if address == nil || address == name {
            let parts = [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            address = parts.isEmpty ? nil : parts.joined(separator: " ")
        }
        if let address, address.hasPrefix(name) {
            // MKPlacemark.title sometimes repeats the name before the street.
            let trimmed = address.dropFirst(name.count).trimmingCharacters(in: CharacterSet(charactersIn: ", "))
            return Candidate(source: .appleMaps, name: name, coordinate: coordinate,
                             address: trimmed.isEmpty ? nil : trimmed,
                             phone: item.phoneNumber, websiteURL: item.url,
                             halalEvidence: halalEvidence, osmURL: nil, mapItem: item)
        }
        return Candidate(source: .appleMaps, name: name, coordinate: coordinate, address: address,
                         phone: item.phoneNumber, websiteURL: item.url,
                         halalEvidence: halalEvidence, osmURL: nil, mapItem: item)
    }

    private nonisolated static let foodCategories: Set<MKPointOfInterestCategory> = [
        .restaurant, .cafe, .foodMarket, .bakery
    ]

    private nonisolated static let mosqueKeywords: [String] = [
        "mosque", "masjid", "masjed", "mesjid", "musalla", "musallah", "musollah", "prayer room",
        "islamic", "islam", "muslim", "jamia", "jami", "jame", "jamek", "jamaat", "jamaah",
        "cami", "camii", "mescit", "mezquita", "moschee", "mosquée", "mosquee", "moskee", "moské", "meczet",
        "masjid", "مسجد", "جامع", "مصلى", "مصلّى", "الإسلامي", "الاسلامي", "إسلامي", "اسلامي"
    ]

    private nonisolated static let nonMosqueKeywords: [String] = [
        "church", "cathedral", "chapel", "synagogue", "temple", "gurdwara", "parish", "kirche", "iglesia", "basilica",
        "كنيسة", "معبد", "كنيس"
    ]

    private nonisolated static let halalKeywords: [String] = [
        "halal", "halaal", "helal", "zabiha", "zabihah", "dhabiha", "حلال"
    ]

    private nonisolated static func containsAny(_ haystack: String, _ needles: [String]) -> Bool {
        needles.contains { haystack.contains($0) }
    }

    // MARK: OpenStreetMap (Overpass)

    private struct OverpassResponse: Decodable {
        let elements: [OverpassElement]
    }

    private struct OverpassElement: Decodable {
        struct Center: Decodable {
            let lat: Double
            let lon: Double
        }
        let type: String
        let id: Int
        let lat: Double?
        let lon: Double?
        let center: Center?
        let tags: [String: String]?
    }

    /// Tried in order; the public instances rate-limit independently.
    private nonisolated static let overpassEndpoints = [
        URL(string: "https://overpass-api.de/api/interpreter")!,
        URL(string: "https://overpass.kumi.systems/api/interpreter")!,
        URL(string: "https://overpass.private.coffee/api/interpreter")!,
    ]

    private nonisolated static func overpassQuery(kind: NearbyPlaceKind, around coordinate: CLLocationCoordinate2D,
                                                  radius: Double) -> String {
        let around = "(around:\(Int(radius)),\(coordinate.latitude),\(coordinate.longitude))"
        switch kind {
        case .mosques:
            return """
            [out:json][timeout:10];
            (
              nwr["amenity"="place_of_worship"]["religion"="muslim"]\(around);
              nwr["building"="mosque"]\(around);
            );
            out center tags;
            """
        case .halal:
            let food = "[\"amenity\"~\"^(restaurant|cafe|fast_food|food_court)$\"]"
            return """
            [out:json][timeout:10];
            (
              nwr["diet:halal"~"^(yes|only)$"]\(food)\(around);
              nwr["cuisine"~"halal"]\(food)\(around);
            );
            out center tags;
            """
        }
    }

    private nonisolated static func searchOverpass(kind: NearbyPlaceKind, around location: CLLocation,
                                                   radius: Double, language: AppLanguage) async -> Result<[Candidate], Error> {
        let query = overpassQuery(kind: kind, around: location.coordinate, radius: radius)
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return .failure(NearbyPlacesError.overpassUnavailable)
        }
        for endpoint in overpassEndpoints.prefix(1) {
            if Task.isCancelled { return .failure(CancellationError()) }
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.timeoutInterval = 12
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.setValue("Haneen iOS (nearby places)", forHTTPHeaderField: "User-Agent")
            request.httpBody = Data("data=\(encoded)".utf8)

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { continue }
                let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
                let hits = decoded.elements.compactMap { element in
                    candidate(from: element, kind: kind, origin: location, radius: radius, language: language)
                }
                return .success(hits)
            } catch {
                continue
            }
        }
        return .failure(NearbyPlacesError.overpassUnavailable)
    }

    private nonisolated static func candidate(from element: OverpassElement, kind: NearbyPlaceKind, origin: CLLocation,
                                              radius: Double, language: AppLanguage) -> Candidate? {
        let latitude = element.lat ?? element.center?.lat
        let longitude = element.lon ?? element.center?.lon
        guard let latitude, let longitude else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        let distance = CLLocation(latitude: latitude, longitude: longitude).distance(from: origin)
        guard distance <= radius * 1.25 else { return nil }

        let tags = element.tags ?? [:]
        let localizedName = language == .arabic ? tags["name:ar"] : tags["name:en"]
        var name = (localizedName ?? tags["name"] ?? tags["name:en"] ?? tags["name:ar"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var halalEvidence: HalalEvidence?
        var isUnnamed = false
        switch kind {
        case .mosques:
            if name.isEmpty {
                // Many small masjids are mapped without a name. The tag itself is the evidence.
                name = language.pick("Mosque (unnamed on the map)", "مسجد (بدون اسم على الخريطة)")
                isUnnamed = true
            }
        case .halal:
            // A halal place with no name cannot be verified by anyone; leave it out.
            guard !name.isEmpty else { return nil }
            let diet = (tags["diet:halal"] ?? "").lowercased()
            let cuisine = (tags["cuisine"] ?? "").lowercased()
            if diet == "yes" || diet == "only" || cuisine.contains("halal") {
                halalEvidence = .osmTag
            } else if containsAny(name.lowercased(), halalKeywords) {
                halalEvidence = .name
            } else {
                return nil
            }
        }

        let street = [tags["addr:housenumber"], tags["addr:street"]].compactMap { $0 }.joined(separator: " ")
        let addressParts = [street, tags["addr:city"] ?? ""].filter { !$0.isEmpty }
        let address = addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")

        let phone = tags["phone"] ?? tags["contact:phone"]
        let website = (tags["website"] ?? tags["contact:website"]).flatMap { URL(string: $0) }
        let osmURL = URL(string: "https://www.openstreetmap.org/\(element.type)/\(element.id)")

        return Candidate(source: .openStreetMap, name: name, coordinate: coordinate, address: address,
                         phone: phone, websiteURL: website, halalEvidence: halalEvidence,
                         osmURL: osmURL, mapItem: nil, isUnnamed: isUnnamed)
    }

    // MARK: Merge

    /// Collapses duplicates within and across sources. Two hits are the same
    /// place when their names agree and they sit within 80 m (300 m for an
    /// exact name match, since the two maps pin large buildings differently).
    /// Names are never ignored: two different restaurants ten metres apart must
    /// stay two rows. The one exception is an unnamed OpenStreetMap mosque
    /// sitting within 30 m of a named hit from the other source.
    nonisolated static func merge(_ candidates: [Candidate], around origin: CLLocation) -> [NearbyPlace] {
        var groups: [[Candidate]] = []

        for candidate in candidates {
            if let index = groups.firstIndex(where: { group in
                group.contains { isSamePlace($0, candidate) }
            }) {
                groups[index].append(candidate)
            } else {
                groups.append([candidate])
            }
        }

        let places = groups.map { group -> NearbyPlace in
            let apple = group.first { $0.source == .appleMaps }
            let osm = group.first { $0.source == .openStreetMap }
            let primary = apple ?? group[0]
            let sources = Set(group.map(\.source))
            let coordinate = primary.coordinate
            let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: origin)

            let evidence: HalalEvidence? = {
                let all = group.compactMap(\.halalEvidence)
                if all.contains(.osmTag) { return .osmTag }
                if all.contains(.name) { return .name }
                return all.first
            }()

            let name = primary.name
            let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
            let ll = "\(coordinate.latitude),\(coordinate.longitude)"
            let id: String
            if let osmURL = osm?.osmURL {
                id = "osm:" + osmURL.lastPathComponent + ":" + osmURL.deletingLastPathComponent().lastPathComponent
            } else {
                id = "apple:\(normalised(name)):\(String(format: "%.4f,%.4f", coordinate.latitude, coordinate.longitude))"
            }

            return NearbyPlace(
                id: id,
                name: name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: apple?.address ?? osm?.address,
                distanceMeters: distance,
                phone: apple?.phone ?? osm?.phone,
                websiteURL: apple?.websiteURL ?? osm?.websiteURL,
                sources: sources,
                isHalalTagged: evidence == .osmTag || evidence == .name,
                halalEvidence: evidence,
                osmURL: osm?.osmURL,
                appleMapsURL: URL(string: "https://maps.apple.com/?ll=\(ll)&q=\(encodedName)"),
                googleMapsURL: URL(string: "https://www.google.com/maps/search/?api=1&query=\(ll)"),
                mapItem: apple?.mapItem
            )
        }

        // Two independent sources first, then a real halal tag, then nearest.
        return places.sorted { lhs, rhs in
            if lhs.sources.count != rhs.sources.count { return lhs.sources.count > rhs.sources.count }
            if lhs.isHalalTagged != rhs.isHalalTagged { return lhs.isHalalTagged }
            return lhs.distanceMeters < rhs.distanceMeters
        }
    }

    private nonisolated static func isSamePlace(_ a: Candidate, _ b: Candidate) -> Bool {
        let separation = CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
            .distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
        if (a.isUnnamed || b.isUnnamed) {
            return separation <= 30 && a.source != b.source
        }
        let nameA = normalised(a.name)
        let nameB = normalised(b.name)
        if nameA == nameB { return separation <= 300 }
        guard separation <= 80 else { return false }
        return nameSimilarity(nameA, nameB) >= 0.5
    }

    /// Lowercased, punctuation stripped, whitespace collapsed.
    nonisolated static func normalised(_ name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil)
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            return " "
        }
        return String(scalars).split(separator: " ").joined(separator: " ")
    }

    private nonisolated static let genericTokens: Set<String> = [
        "the", "of", "and", "al", "el", "a", "an",
        "mosque", "masjid", "islamic", "center", "centre", "society", "community", "musalla",
        "halal", "restaurant", "grill", "kitchen", "cafe", "food", "kebab", "house",
        "مسجد", "جامع", "مطعم", "حلال"
    ]

    private nonisolated static func nameSimilarity(_ a: String, _ b: String) -> Double {
        let tokensA = Set(a.split(separator: " ").map(String.init)).subtracting(genericTokens)
        let tokensB = Set(b.split(separator: " ").map(String.init)).subtracting(genericTokens)
        if tokensA.isEmpty || tokensB.isEmpty {
            // Only generic words on one side: fall back to containment.
            return a.contains(b) || b.contains(a) ? 1 : 0
        }
        // "Al Noor" against "Al Noor Islamic Society": the shorter name is contained.
        if tokensA.isSubset(of: tokensB) || tokensB.isSubset(of: tokensA) { return 1 }
        let intersection = tokensA.intersection(tokensB).count
        let union = tokensA.union(tokensB).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }
}

// MARK: - Errors

enum NearbyPlacesError: Error {
    case permissionDenied
    case permissionRestricted
    case requestAlreadyInProgress
    case locationUnavailable
    case overpassUnavailable
    case allSourcesFailed

    func message(_ language: AppLanguage) -> String {
        switch self {
        case .permissionDenied:
            return language.pick("Location access is off.", "الوصول إلى الموقع متوقف.")
        case .permissionRestricted:
            return language.pick("Location access is restricted on this device.", "الوصول إلى الموقع مقيَّد على هذا الجهاز.")
        case .requestAlreadyInProgress:
            return language.pick("Still finding your location.", "ما زلنا نحدد موقعك.")
        case .locationUnavailable:
            return language.pick("Your location couldn’t be determined. Try again in a moment.",
                                 "تعذر تحديد موقعك. حاول مرة أخرى بعد قليل.")
        case .overpassUnavailable:
            return language.pick("OpenStreetMap didn’t respond.", "لم يستجب OpenStreetMap.")
        case .allSourcesFailed:
            return language.pick("Neither Apple Maps nor OpenStreetMap responded. Check your connection and try again.",
                                 "لم تستجب خرائط Apple ولا OpenStreetMap. تحقق من الاتصال وحاول مرة أخرى.")
        }
    }
}
