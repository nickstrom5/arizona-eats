import Foundation
import CoreLocation
import UIKit

/// `-screenshot <name>` opens one screen with fixed state for App Store screenshots (scripts/capture-screenshots.sh).
/// Names: home, sonoran_dog, route66, saloon, honors, golden, inspections, detail, map, oldest, saved, about.
enum ScreenshotMode {
    /// Debug builds only: an App Store build ignores the launch argument, so no one can reach seeded screens or fake locations.
    static var name: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }
    static var isActive: Bool { name != nil }

    @MainActor
    static func apply(to model: AppModel) {
        guard let name, model.isLoaded else { return }
        model.filters = Filters()
        // downtown Phoenix (Central Ave at Washington St), so "nearest" lists have distances without a permission prompt
        model.screenshotLocation = CLLocation(latitude: 33.4484, longitude: -112.0740)
        // by name and town, ignoring case, so a rebuild with a slightly different casing still finds the place; the hand-checked one first
        let pick = { (n: String, town: String?) -> Place? in
            let hits = model.places.filter { $0.name.caseInsensitiveCompare(n) == .orderedSame && (town == nil || $0.city == town) }
            return hits.first(where: \.handChecked) ?? hits.first
        }
        for p in [pick("Pizzeria Bianco", "Phoenix"), pick("Fry Bread House", "Phoenix"), pick("Little Miss BBQ", "Phoenix")]
            .compactMap({ $0 }) where !model.isSaved(p) {
            model.toggleSaved(p)
        }
        let open = { (g: Guide) in model.tab = .guides; model.selectedGuide = g; model.guidesPath = [.guide(g)] }
        switch name {
        case "sonoran_dog":
            // from downtown Tucson, where the Sonoran hot dog stands are
            model.screenshotLocation = CLLocation(latitude: 32.2217, longitude: -110.9698)
            open(.sonoranDog)
        case "route66":
            // from Williams, on the old road
            model.screenshotLocation = CLLocation(latitude: 35.2495, longitude: -112.1910)
            open(.route66)
        case "saloon":
            // from Prescott's Whiskey Row
            model.screenshotLocation = CLLocation(latitude: 34.5418, longitude: -112.4685)
            open(.saloons)
        case "honors": open(.honors)
        case "oldest": open(.oldest)
        case "golden":
            // from Prescott's courthouse square, so the Golden Plate places are a short drive
            model.screenshotLocation = CLLocation(latitude: 34.5418, longitude: -112.4685)
            open(.goldenPlate)
        case "inspections":
            // from Casa Grande (Pinal County)
            model.screenshotLocation = CLLocation(latitude: 32.8795, longitude: -111.7574)
            open(.inspections)
        case "detail":
            // the original El Güero Canelo on S 12th Ave: hand-checked, an America's Classic, with its notes
            model.screenshotLocation = CLLocation(latitude: 32.2217, longitude: -110.9698)
            open(.sonoranDog)
            let guero = model.places.first { $0.name == "El Güero Canelo" && $0.address == "5201 S 12th Ave" }
            if let p = guero ?? pick("Huarachis Taqueria", "Phoenix") ?? model.places.first { model.selectedPlace = p; model.guidesPath.append(.place(p)) }
        case "map": model.tab = .map
        case "saved": model.tab = .saved
        case "about": model.tab = .about
        default: model.tab = .guides; model.selectedGuide = nil
        }
        // iPad shows the place column next to every list, so give each shot a place instead of "Pick a place": a different
        // honored or hand-checked one per shot.
        guard UIDevice.current.userInterfaceIdiom == .pad, model.selectedPlace == nil else { return }
        let place: Place? = switch name {
        case "home": pick("Fry Bread House", "Phoenix")
        case "sonoran_dog": model.places.first { $0.name == "El Güero Canelo" && $0.address == "5201 S 12th Ave" }
        case "route66": pick("Delgadillo's Snow Cap Drive-In", nil) ?? pick("Delgadillo's Snow Cap", nil)
        case "saloon": pick("The Palace Restaurant and Saloon", nil)
        case "map": pick("Lom Wong", "Phoenix")
        case "honors": pick("Pizzeria Bianco", "Phoenix")
        case "saved": pick("Little Miss BBQ", "Phoenix")
        case "about": nil
        default: pick("Pizzeria Bianco", "Phoenix")
        }
        model.selectedPlace = place
    }
}
