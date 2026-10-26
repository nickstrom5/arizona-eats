import SwiftUI

struct AboutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ARIZONA EATS").displayFont(32).foregroundStyle(Theme.green)
                    Text("A free guide to \(model.restaurantCount.formatted()) Arizona restaurants, with MICHELIN and James Beard honors, Yavapai County's Golden Plate Awards, the inspection ratings Mohave and Pinal counties publish, and hand-checked lists of Arizona's own food as they're checked. No account, no ads, no tracking.")
                        .font(.subheadline).foregroundStyle(Theme.ink2)
                    Text("Arizona Eats is an independent app by Nicholas Soderstrom. It is not affiliated with, endorsed by or operated by the State of Arizona, the Arizona Department of Health Services, Maricopa County, Pima County, Pinal County, Mohave County, Yavapai County, the City of Tucson, any tribal nation, the MICHELIN Guide, the James Beard Foundation, Apple, or any restaurant or chain. Other names are trademarks of their owners.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 4)
            }
            Section("How the lists are built") {
                Text("Hand-checked lists (Sonoran hot dogs, Sonoran Mexican, chimichangas, fry bread, Route 66 diners, frontier saloons, oldest places) include only places checked against a 2025 or 2026 source (the place's own website or menu, local news or an official tourism listing), with the address checked. Founding years mean the year it opened at this address.")
                Text("Honors are the MICHELIN Guide American Southwest's Arizona selection (Bib Gourmand and Recommended; Arizona has no stars), James Beard Foundation awards from 2022 on, 2026 semifinalists, and America's Classics.")
                Text("Arizona has no statewide list of restaurants: each county keeps its own. This app starts from open map listings (Overture Maps) and keeps the kinds that proved reliable: checked against Maricopa County's permit list, high-confidence listings matched a permitted business \(rate("meta_high")) of the time. Maricopa County's permits, City of Tucson business licenses and the Mohave and Pinal inspection lists confirm places and add ones the map data missed. Adult clubs are left out. Website links are checked, and any that no longer belong to the place are left out.")
                Text("Inspection ratings are each county's own: Mohave's Excellent, Satisfactory or Needs Improvement, and Pinal's Excellent, Satisfactory, Needs Improvement or Unacceptable. Maricopa's grades are only on per-place pages, Pima's search sits behind a CAPTCHA, and the other counties publish search pages or nothing. Arizona has no statewide grade, so this app computes none. Tribal lands are outside county inspection.")
                Text("Ratings, reviews, hours and photos are Apple Maps' own, shown live in Apple's place card. This app doesn't store or rank by them.")
            }
            .font(.subheadline).foregroundStyle(Theme.ink2)
            Section("Sources") {
                source("Maricopa County Environmental Services", "Restaurant (External) permit list (ArcGIS), updated \(DayFormat.text(model.permitsUpdated) ?? model.permitsUpdated), modified for use in this app. The county's terms: \u{201C}Maricopa County has made every reasonable effort to obtain and maintain this data as accurately as possible, however, human or mechanical error remain a possibility. Maricopa County assumes no responsibility arising from the use of this information. The data and maps are provided without warranty of any kind, either expressed or implied.\u{201D}", Links.maricopaPermits.absoluteString)
                source("City of Tucson", "Business Licenses (Open Data), active licenses with a restaurant or bar industry code. The city provides the data \u{201C}as is\u{201D} and doesn't guarantee it is accurate, correct or complete.", Links.tucsonLicenses.absoluteString)
                source("Mohave County Department of Public Health", "Monthly Food Safety Inspections lists, January 2025 through \(DayFormat.text(model.inspectionsThrough["moh"]) ?? "").", InspectionCounty.mohave.sourceURL.absoluteString)
                source("Pinal County Environmental Health", "Food Inspection Search, the county's rating classes, through \(DayFormat.text(model.inspectionsThrough["pin"]) ?? "").", InspectionCounty.pinal.sourceURL.absoluteString)
                source("Yavapai County Community Health Services", "Golden Plate Awards \(model.goldenPlateYear.map(String.init) ?? ""), the county's announcement and list.", model.goldenPlateURL?.absoluteString)
                source("Overture Maps Foundation", "Restaurant listings and websites come from Overture Maps Foundation places data (overturemaps.org)\(model.overtureRelease.map { ", release \($0)" } ?? ""), filtered and reformatted for this app.\n• Data from Meta, Microsoft, DAC and BrightQuery. Available under CDLA Permissive 2.0.\n• Data from Foursquare. \(foursquareCopyright) Available under Apache 2.0. Foursquare data was transformed to the Overture schema; this app further filtered and reformatted it. See the NOTICE below.\n• Data from AllThePlaces. Available under CC0 1.0.\nCounty records are placed on the map with Overture Maps addresses data (open address sources under permissive licenses, docs.overturemaps.org/attribution).", "https://overturemaps.org")
                source("U.S. Census Bureau Geocoder", "Puts records on the map where Overture's address points don't reach. Public domain.", "https://geocoding.geo.census.gov")
                source("Honors", "The MICHELIN Guide American Southwest selection and James Beard Foundation awards, semifinalists and America's Classics are reported as facts and checked by hand against the official announcements. MICHELIN and the MICHELIN Guide are trademarks of Michelin. James Beard Foundation and James Beard Award are trademarks of the James Beard Foundation. Other names belong to their owners.", "https://guide.michelin.com/us/en/arizona/restaurants")
                source("Maps", "Maps, place cards and directions by Apple Maps.", nil)
            }
            Section("Licenses") {
                NavigationLink("Community Data License Agreement – Permissive 2.0") { LicenseText(file: "CDLA-Permissive-2.0", title: "CDLA Permissive 2.0") }
                NavigationLink("Apache License 2.0") { LicenseText(file: "Apache-2.0", title: "Apache License 2.0") }
                NavigationLink("Foursquare OS Places NOTICE") { LicenseText(file: "Foursquare-NOTICE", title: "Foursquare NOTICE") }
            }
            Section("Privacy") {
                Text("The app collects nothing. Your location, if you allow it, only sorts lists by distance and shows where you are on the map, on this device. Saved places stay on this device.")
                    .font(.subheadline).foregroundStyle(Theme.ink2)
                DataUpdatesNote()
                    .font(.footnote).foregroundStyle(Theme.muted)
                Link("Privacy policy", destination: Links.privacy)
                Link("Terms of use", destination: Links.terms)
            }
            Section("Help") {
                Link("Report a missing or closed place", destination: Links.correctionEmail)
                Link("Email \(Links.supportEmail)", destination: URL(string: "mailto:\(Links.supportEmail)")!)
                Link("Website", destination: Links.site)
                Text("Data as of \(DayFormat.text(model.generated) ?? model.generated). Places open and close; check before you go. Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .navigationTitle("About")
        .tint(Theme.green)
    }

    /// the copyright line exactly as the bundled Foursquare NOTICE has it, so the two can't disagree
    private var foursquareCopyright: String {
        guard let url = Bundle.main.url(forResource: "Foursquare-NOTICE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              let line = text.split(separator: "\n").first(where: { $0.hasPrefix("©") }) else { return "© Foursquare Labs, Inc. All rights reserved." }
        return line.trimmingCharacters(in: .whitespaces)
    }

    private func rate(_ group: String) -> String {
        let v = model.calibration.areas.values.compactMap { $0.groups[group]?.official }.map { Int(($0 * 100).rounded()) }.sorted()
        guard let lo = v.first, let hi = v.last else { return "most" }
        return lo == hi ? "\(lo)%" : "\(lo)–\(hi)%"
    }

    @ViewBuilder
    private func source(_ name: String, _ detail: String, _ url: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let url, let u = URL(string: url) { Link(name, destination: u).font(.subheadline.weight(.semibold)) }
            else { Text(name).font(.subheadline.weight(.semibold)) }
            Text(detail).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

/// A bundled license text (Resources/Licenses), reflowed rather than shown as raw 80-column lines.
struct LicenseText: View {
    let file: String
    let title: String

    var body: some View {
        ScrollView {
            Text(text).font(.footnote).foregroundStyle(Theme.ink).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .inlineTitle(title)
    }

    private var text: String {
        guard let url = Bundle.main.url(forResource: file, withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return "License text missing." }
        // join hard-wrapped lines into paragraphs; keep blank lines and list items as breaks
        var out: [String] = []
        for para in raw.components(separatedBy: "\n\n") {
            let lines = para.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            var joined = ""
            for l in lines where !l.isEmpty {
                let startsItem = l.hasPrefix("–") || l.hasPrefix("-") || l.range(of: #"^\(?[a-z0-9]{1,3}[.)]\s"#, options: .regularExpression) != nil
                joined += joined.isEmpty ? l : (startsItem ? "\n" + l : " " + l)
            }
            if !joined.isEmpty { out.append(joined) }
        }
        return out.joined(separator: "\n\n")
    }
}
