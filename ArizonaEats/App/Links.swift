import Foundation

/// The app's web pages and support address, in one place.
/// The site is GitHub Pages at the project address until arizona.eatsranked.com resolves (Nick adds a Cloudflare CNAME
/// arizona -> nickstrom5.github.io, DNS only; then scripts/make-site.py sets CUSTOM_DOMAIN). GitHub forwards these github.io
/// links to the custom domain after the switch, so a shipped build keeps working; point them at the new domain in the next update.
enum Links {
    static let site = URL(string: "https://nickstrom5.github.io/arizona-eats/")!
    /// The app's data updates: scripts/publish_app_data.py writes docs/data/app/ (OTA-DATA.md).
    static let appData = URL(string: site.absoluteString + "data/app/")!
    static let privacy = URL(string: "https://nickstrom5.github.io/arizona-eats/privacy.html")!
    static let terms = URL(string: "https://nickstrom5.github.io/arizona-eats/terms.html")!
    /// Maricopa County's permit list (the ArcGIS item page, which opens and describes the data)
    static let maricopaPermits = URL(string: "https://www.arcgis.com/home/item.html?id=4f5bfeaefa0448a584b46cbc120397ea")!
    /// the City of Tucson's business license open data
    static let tucsonLicenses = URL(string: "https://gisdata.tucsonaz.gov/datasets/b0e8f873aaeb4375b481979be334fbf2")!
    static let supportEmail = "nick@eatsranked.com"

    static var correctionEmail: URL {
        URL(string: "mailto:\(supportEmail)?subject=Arizona%20Eats%20correction")!
    }
}
