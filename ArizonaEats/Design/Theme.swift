import SwiftUI
import UIKit
import CoreText

/// Arizona flag and landscape palette (Nick's pick, 2026-10-22), light only: flag blue #002868 (14.6:1 on white) for titles, tint and
/// accents; copper #B54E12 (5.2:1 on white) for the hand-checked Arizona guide cards under white text; sun yellow #FFD100 only as a
/// fill under dark text (1.5:1 on white, never text); sand #F3E3C3 behind the Home cards. No team colors (Cardinals, Suns, Diamondbacks,
/// ASU, UA). The names `green`/`gold` are kept from Wisconsin Eats so the shared views read the same; here `green` is the flag blue
/// and `gold` the copper.
enum Theme {
    static let green = Color(hex: 0x002868)      // flag blue: titles, tint, primary text accents
    static let green2 = Color(hex: 0x1C3F86)
    static let gold = Color(hex: 0xB54E12)       // copper: card fills under white text, chips
    static let goldSoft = Color(hex: 0xF3E3C3)   // sand
    static let lime = Color(hex: 0xFFD100)       // sun yellow, fills only, under dark text
    static let limeSoft = Color(hex: 0xFFF3B8)
    static let sand = Color(hex: 0xF8F1E4)
    static let red = Color(hex: 0xBF0A30)        // MICHELIN chips and the counties' low ratings only
    static let ink = Color(hex: 0x0E1A30)
    static let ink2 = Color(hex: 0x28385A)
    static let muted = Color(hex: 0x55627A)
    static let surface = Color.white
    static let surface2 = Color(hex: 0xF2F4F8)
    static let surface3 = Color(hex: 0xE1E6EF)
    static let rule = Color(hex: 0xDCE2EC)
    static let rule2 = Color(hex: 0xB5C0D3)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A small uppercase label: "STONE CRAB", "1 MICHELIN STAR".
struct Chip: View {
    enum Style { case gold, green, red, plain, dashed }
    let text: String
    var style: Style = .plain

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .foregroundStyle(style == .green || style == .red ? Color.white : style == .dashed ? Theme.muted : style == .gold ? Theme.ink : Theme.green)
            .background {
                RoundedRectangle(cornerRadius: 5).fill(style == .gold ? Theme.goldSoft : style == .green ? Theme.green : style == .red ? Theme.red
                                                       : style == .dashed ? .clear : Theme.surface2)
            }
            .overlay {
                if style == .dashed { RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.rule2, style: StrokeStyle(lineWidth: 1, dash: [3, 2])) }
            }
            .accessibilityLabel(text)
    }
}

/// A county's own inspection rating, as published: "Mohave County · Excellent", "Pinal County · Needs Improvement". Arizona has
/// no statewide grade and the app computes none.
struct BandBadge: View {
    let county: InspectionCounty
    let band: InspectionBand
    var large = false

    var body: some View {
        Text([county.name, band.label].joined(separator: " · ").uppercased())
            .font(large ? .footnote.weight(.heavy) : .caption2.weight(.heavy))
            .tracking(0.4)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, large ? 10 : 7).padding(.vertical, large ? 6 : 3)
            .foregroundStyle(band.ink)
            .background(RoundedRectangle(cornerRadius: 6).fill(band.fill))
            .accessibilityLabel("\(county.name) inspection: \(band.label)")
    }
}

/// Arizona Eats' lettering: the system face drawn compressed and heavy for titles and guide names (like a Route 66 sign), and the
/// system monospaced face for numbers, dates and small labels. No bundled fonts.
struct DisplayFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .black
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight).width(.compressed))
    }
}

/// Numbers, dates and small labels in the system monospaced face, scaled like DisplayFont.
struct MonoFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .semibold
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight, design: .monospaced))
    }
}

extension View {
    func displayFont(_ size: CGFloat, weight: Font.Weight = .black) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }

    func monoFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> some View {
        modifier(MonoFont(size: size, weight: weight))
    }
}

/// The band under the Home title: the flag's 13 sunset rays, red and yellow, rising from a copper star over the blue field.
struct Stripes: View {
    var height: CGFloat = 6

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, blue = h * 0.28
            let apex = CGPoint(x: w / 2, y: h - blue)
            for k in 0..<13 {
                var ray = Path()
                ray.move(to: apex)
                ray.addLine(to: CGPoint(x: w * CGFloat(k) / 13, y: 0))
                ray.addLine(to: CGPoint(x: w * CGFloat(k + 1) / 13, y: 0))
                ray.closeSubpath()
                ctx.fill(ray, with: .color(k % 2 == 0 ? Theme.red : Theme.lime))
            }
            ctx.fill(Path(CGRect(x: 0, y: h - blue, width: w, height: blue)), with: .color(Theme.green))
            ctx.fill(Path(CGRect(x: w / 2 - h * 0.45, y: h - blue - h * 0.2, width: h * 0.9, height: blue + h * 0.2)), with: .color(Color(hex: 0xCE5C17)))
        }
        .frame(height: height * 3.4)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .accessibilityHidden(true)
    }
}

extension View {
    /// An inline navigation title in the display type. UINavigationBar.appearance() didn't reach every SwiftUI bar on iOS 27
    /// (the Map title went from compressed blue to plain black after a push and pop; place titles were always plain), so the
    /// title is our own view in the bar. The navigation title is still set, for the back button and VoiceOver.
    func inlineTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).displayFont(19, weight: .heavy).foregroundStyle(Theme.green)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}
