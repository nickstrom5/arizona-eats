import Foundation
import CoreLocation

/// The lists the app is built around. Each is a filter plus an order; none uses ratings (the app only publishes data it may).
enum Guide: String, CaseIterable, Identifiable, Hashable {
    case sonoranDog, sonoran, chimi, fryBread, route66, saloons, goldenPlate, honors, oldest, inspections, nearMe, all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sonoranDog: "Sonoran Hot Dogs"
        case .sonoran: "Sonoran Mexican"
        case .chimi: "Chimichangas"
        case .fryBread: "Fry Bread"
        case .route66: "Route 66 Diners"
        case .saloons: "Frontier Saloons"
        case .goldenPlate: "Golden Plate Awards"
        case .honors: "MICHELIN & James Beard"
        case .oldest: "Oldest Places"
        case .inspections: "Inspection Ratings"
        case .nearMe: "Near Me"
        case .all: "All Restaurants"
        }
    }

    var subtitle: String {
        switch self {
        case .sonoranDog: "Hand-checked bacon-wrapped dogs in a bolillo"
        case .sonoran: "Hand-checked Sonoran-style kitchens and taquerías"
        case .chimi: "Hand-checked chimichangas, including both places that claim them"
        case .fryBread: "Hand-checked fry bread and Native-owned kitchens"
        case .route66: "Hand-checked diners and drive-ins on the old road"
        case .saloons: "Hand-checked saloons from Whiskey Row to Tombstone"
        case .goldenPlate: "Yavapai County's award for a year without priority violations"
        case .honors: "MICHELIN Guide and James Beard honorees"
        case .oldest: "Founding years checked at the same address, oldest first"
        case .inspections: "Official ratings from Mohave and Pinal counties"
        case .nearMe: "Everything around you, closest first"
        case .all: "Restaurants, cafés, bars and bakeries statewide"
        }
    }

    var systemImage: String {
        switch self {
        case .sonoranDog: "flame"
        case .sonoran: "fork.knife.circle"
        case .chimi: "takeoutbag.and.cup.and.straw"
        case .fryBread: "circle.hexagongrid"
        case .route66: "car"
        case .saloons: "door.left.hand.open"
        case .goldenPlate: "rosette"
        case .honors: "star.circle"
        case .oldest: "clock.arrow.circlepath"
        case .inspections: "checkmark.seal"
        case .nearMe: "location"
        case .all: "fork.knife"
        }
    }

    /// The hand-checked Arizona guides get the copper card on Home.
    var isArizona: Bool { tag != nil }

    /// Guides whose order is a ranking worth numbering.
    var isRanked: Bool { [.oldest].contains(self) }

    var sortOptions: [SortOrder] {
        switch self {
        case .sonoranDog, .sonoran, .chimi, .fryBread, .route66, .saloons: [.featured, .nearest, .name]
        case .goldenPlate: [.name, .nearest]
        case .honors: [.iconic, .nearest]
        case .oldest: [.oldest]
        case .inspections: [.recent, .highestScore, .lowestScore, .nearest]
        case .nearMe: [.nearest]
        case .all: [.name, .nearest]
        }
    }

    var defaultSort: SortOrder { sortOptions[0] }

    /// The tag behind a hand-checked guide.
    var tag: PlaceTags? {
        switch self {
        case .sonoranDog: .sonoranDog
        case .sonoran: .sonoran
        case .chimi: .chimi
        case .fryBread: .fryBread
        case .route66: .route66
        case .saloons: .saloon
        default: nil
        }
    }

    func includes(_ p: Place) -> Bool {
        if let tag {   // the guides that promise "hand-checked" list only places checked open with a 2025–26 source
            return p.handChecked && p.tags.contains(tag)
        }
        switch self {
        case .goldenPlate: return p.goldenPlate != nil
        case .honors: return p.michelin != .none || p.jamesBeard != nil
        case .oldest: return p.founded != nil && p.tags.contains(.oldest)
        case .inspections: return p.inspection != nil
        default: return true
        }
    }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case featured, nearest, oldest, name, iconic, recent, highestScore, lowestScore
    var id: String { rawValue }
    var label: String {
        switch self {
        case .featured: "Featured first"
        case .nearest: "Nearest"
        case .oldest: "Oldest first"
        case .name: "A to Z"
        case .iconic: "MICHELIN, then James Beard"
        case .recent: "Latest inspection first"
        case .highestScore: "Best rating first"
        case .lowestScore: "Lowest rating first"
        }
    }
}

/// Filters shared by every list. Search text lives with each list.
struct Filters: Equatable, Codable {
    var town: String?
    var cuisine: String?
    var hideChains = false
    var confirmedOnly = false
    var includeNonRestaurants = false
    var bibGourmand = false          // MICHELIN Bib Gourmand only: a fact from the Guide, not a rating

    var activeCount: Int {
        [town != nil, cuisine != nil, hideChains, confirmedOnly, includeNonRestaurants, bibGourmand].filter { $0 }.count
    }

    func allows(_ p: Place) -> Bool {
        if !includeNonRestaurants && p.isVenue { return false }
        if let town, p.city != town { return false }
        if let cuisine, p.cuisine != cuisine { return false }
        if hideChains && p.isChain { return false }
        if confirmedOnly && p.tier == .listing { return false }
        if bibGourmand && p.michelin != .bib { return false }
        return true
    }
}

extension Filters {
    /// Filters saved by an older build have no bibGourmand key: read what's there instead of dropping them all.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(town: try c.decodeIfPresent(String.self, forKey: .town),
                  cuisine: try c.decodeIfPresent(String.self, forKey: .cuisine),
                  hideChains: try c.decodeIfPresent(Bool.self, forKey: .hideChains) ?? false,
                  confirmedOnly: try c.decodeIfPresent(Bool.self, forKey: .confirmedOnly) ?? false,
                  includeNonRestaurants: try c.decodeIfPresent(Bool.self, forKey: .includeNonRestaurants) ?? false,
                  bibGourmand: try c.decodeIfPresent(Bool.self, forKey: .bibGourmand) ?? false)
    }
}

enum Ranking {
    static func sort(_ places: [Place], by order: SortOrder, from here: CLLocation?) -> [Place] {
        // Keys come from fields made once at load: a localized compare, or a new CLLocation per comparison, made a 16,000-place
        // sort take most of a second (AR-13). sortKey is the normalized name, so case, accents and punctuation don't change the order.
        func name(_ a: Place, _ b: Place) -> Bool { a.sortKey != b.sortKey ? a.sortKey < b.sortKey : a.id < b.id }
        switch order {
        case .nearest where here != nil:
            // each distance once, not four times per comparison
            let from = here!
            return places.map { p in (p, p.location.map { $0.distance(from: from) } ?? .greatestFiniteMagnitude) }
                .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : name($0.0, $1.0) }
                .map(\.0)
        case .featured, .nearest:
            // honored places first, then verified founding year, then name
            return places.sorted {
                let a = $0.iconicPoints ?? -1, b = $1.iconicPoints ?? -1
                if a != b { return a > b }
                let fa = $0.founded ?? 9999, fb = $1.founded ?? 9999
                return fa != fb ? fa < fb : name($0, $1)
            }
        case .oldest:
            return places.sorted { ($0.founded ?? 9999) != ($1.founded ?? 9999) ? ($0.founded ?? 9999) < ($1.founded ?? 9999) : name($0, $1) }
        case .name:
            return places.sorted(by: name)
        case .iconic:
            // an order anyone can check: MICHELIN distinction, then the James Beard honor (America's Classic, winner, finalist, semifinalist), then name
            func jb(_ p: Place) -> Int { p.honorFlags & 1 != 0 ? 4 : p.honorFlags & 2 != 0 ? 3 : p.honorFlags & 4 != 0 ? 2 : p.honorFlags & 8 != 0 ? 1 : 0 }
            return places.sorted {
                if $0.michelin.rawValue != $1.michelin.rawValue { return $0.michelin.rawValue > $1.michelin.rawValue }
                if jb($0) != jb($1) { return jb($0) > jb($1) }
                return name($0, $1)
            }
        case .recent:
            return places.sorted {
                let a = $0.inspection?.d ?? "", b = $1.inspection?.d ?? ""
                return a != b ? a > b : name($0, $1)
            }
        case .highestScore, .lowestScore:
            // each county's own latest rating, in the county's order (Excellent first); places without one go last either way
            let best = order == .highestScore
            return places.sorted {
                let a = $0.inspection?.band, b = $1.inspection?.band
                if (a == nil) != (b == nil) { return a != nil }
                let x = a ?? 0, y = b ?? 0
                if x != y { return best ? x < y : x > y }
                let da = $0.inspection?.d ?? "", db = $1.inspection?.d ?? ""
                return da != db ? da > db : name($0, $1)
            }
        }
    }
}
