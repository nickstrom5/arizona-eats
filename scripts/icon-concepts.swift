// Arizona Eats icon concepts for Nick's pick, in the shared Eats Ranked icon style (state-prompts/ICON-STYLE.md v1):
// one flat, level, centred food on a plain background; no scenery, tilt, texture, gloss or gradients.
// Usage (from az-eats/): swift scripts/icon-concepts.swift   -> playbook/brand/concept-{a,b,c}-1024.png and -512, -180, -60 copies
//   A  Sonoran hot dog: a bacon-wrapped dog in a soft bolillo with a mayo zigzag, on copper (Chicago's icon is a hot dog on blue,
//      so this one stays off blue)
//   B  prickly pear: a magenta fruit standing on its green pad, on flag blue
//   C  chimichanga: a golden fried burrito with sour cream and guacamole on top, on flag blue
// Palette (the prompt's, Nick's call): flag blue #002868, copper #CE5C17 (#B54E12 deeper), sun #FFD100, sand #F3E3C3. Food-only
// tones are listed per concept.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let BLUE: UInt32 = 0x002868, COPPER: UInt32 = 0xB54E12, SAND: UInt32 = 0xF3E3C3

// MARK: A, Sonoran hot dog (long food: side elevation). CoreGraphics y-up; the box is 0.72 x 0.35, mass a little low.
func sonoranDog(_ c: CGContext, _ s: CGFloat) {
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * s, y: y * s, width: w * s, height: h * s) }
    // bolillo: a soft sand roll, 0.72 x 0.21, deep rounded corners
    let bun = CGPath(roundedRect: R(0.14, 0.31, 0.72, 0.21), cornerWidth: 0.09 * s, cornerHeight: 0.09 * s, transform: nil)
    // bacon-wrapped dog: a capsule 0.69 x 0.19 resting in the roll, its lower part hidden by the roll's front lip
    let dog = CGPath(roundedRect: R(0.155, 0.47, 0.69, 0.19), cornerWidth: 0.095 * s, cornerHeight: 0.095 * s, transform: nil)
    c.setFillColor(rgb(0x8C3418)); c.addPath(dog); c.fillPath()
    // the bacon's lighter fat bands: 4 slanted bands clipped to the dog (marks, one accent tone of the bacon)
    c.saveGState(); c.addPath(dog); c.clip()
    c.setFillColor(rgb(0xBF5A35))
    for k in 0..<4 {
        let x = 0.22 + CGFloat(k) * 0.165
        let band = CGMutablePath()
        band.move(to: CGPoint(x: x * s, y: 0.46 * s)); band.addLine(to: CGPoint(x: (x + 0.05) * s, y: 0.46 * s))
        band.addLine(to: CGPoint(x: (x + 0.11) * s, y: 0.67 * s)); band.addLine(to: CGPoint(x: (x + 0.06) * s, y: 0.67 * s)); band.closeSubpath()
        c.addPath(band); c.fillPath()
    }
    c.restoreGState()
    // the roll's front lip, drawn over the dog's lower edge
    c.setFillColor(rgb(SAND)); c.addPath(bun); c.fillPath()
    // mayo zigzag along the top of the dog: one 34 px round-cap stroke, 5 half-waves
    let mayo = CGMutablePath()
    let x0: CGFloat = 0.27, x1: CGFloat = 0.73, yMid: CGFloat = 0.595, amp: CGFloat = 0.024
    mayo.move(to: CGPoint(x: x0 * s, y: (yMid - amp) * s))
    for k in 1...5 {
        let x = x0 + (x1 - x0) * CGFloat(k) / 5
        mayo.addLine(to: CGPoint(x: x * s, y: (yMid + (k % 2 == 1 ? amp : -amp)) * s))
    }
    c.setStrokeColor(rgb(0xFFFFFF)); c.setLineWidth(0.034 * s); c.setLineCap(.round); c.setLineJoin(.round)
    c.addPath(mayo); c.strokePath()
}

// MARK: B, prickly pear (upright: front elevation). Pad 0.44 x 0.56, fruit on its rim; total height 0.72.
func pricklyPear(_ c: CGContext, _ s: CGFloat) {
    func E(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: (x - w / 2) * s, y: (y - h / 2) * s, width: w * s, height: h * s) }
    c.setFillColor(rgb(0x5E9B45)); c.fillEllipse(in: E(0.5, 0.415, 0.46, 0.55))            // pad
    // fruit: a magenta pear shape (egg wider at the top), sitting on the pad's top rim with a 13 px blue gap ring
    let fruit = CGMutablePath()
    let cx: CGFloat = 0.5, bot: CGFloat = 0.6, top: CGFloat = 0.875, hw: CGFloat = 0.105
    fruit.move(to: CGPoint(x: cx * s, y: bot * s))
    fruit.addCurve(to: CGPoint(x: (cx + hw) * s, y: (top - 0.07) * s), control1: CGPoint(x: (cx + hw * 0.7) * s, y: bot * s), control2: CGPoint(x: (cx + hw) * s, y: (top - 0.17) * s))
    fruit.addCurve(to: CGPoint(x: cx * s, y: top * s), control1: CGPoint(x: (cx + hw) * s, y: (top - 0.01) * s), control2: CGPoint(x: (cx + hw * 0.5) * s, y: top * s))
    fruit.addCurve(to: CGPoint(x: (cx - hw) * s, y: (top - 0.07) * s), control1: CGPoint(x: (cx - hw * 0.5) * s, y: top * s), control2: CGPoint(x: (cx - hw) * s, y: (top - 0.01) * s))
    fruit.addCurve(to: CGPoint(x: cx * s, y: bot * s), control1: CGPoint(x: (cx - hw) * s, y: (top - 0.17) * s), control2: CGPoint(x: (cx - hw * 0.7) * s, y: bot * s))
    fruit.closeSubpath()
    c.setStrokeColor(rgb(BLUE)); c.setLineWidth(0.026 * s); c.setLineJoin(.round); c.addPath(fruit); c.strokePath()   // R7 ring
    c.setFillColor(rgb(0xC2185B)); c.addPath(fruit); c.fillPath()
    // areoles: 7 sand dots on the pad (40 px), one kind, one colour
    c.setFillColor(rgb(SAND))
    for (x, y) in [(0.40, 0.50), (0.60, 0.50), (0.33, 0.38), (0.5, 0.40), (0.67, 0.38), (0.42, 0.26), (0.58, 0.26)] as [(CGFloat, CGFloat)] {
        c.fillEllipse(in: E(x, y, 0.04, 0.04))
    }
}

// MARK: C, chimichanga (long food: side elevation). Body 0.72 x 0.27 with a lighter top plane; sour cream and guacamole on top.
func chimichanga(_ c: CGContext, _ s: CGFloat) {
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * s, y: y * s, width: w * s, height: h * s) }
    func E(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: (x - w / 2) * s, y: (y - h / 2) * s, width: w * s, height: h * s) }
    let body = CGPath(roundedRect: R(0.14, 0.30, 0.72, 0.27), cornerWidth: 0.11 * s, cornerHeight: 0.11 * s, transform: nil)
    c.saveGState(); c.addPath(body); c.clip()
    c.setFillColor(rgb(0xD48A2E)); c.fill(R(0, 0, 1, 1))                 // fried tortilla
    c.setFillColor(rgb(0xEAB15A)); c.fill(R(0, 0.47, 1, 1))              // lighter top plane
    c.restoreGState()
    // toppings: a dollop of guacamole and one of sour cream, side by side on the top, left of centre so the box stays centred
    c.setFillColor(rgb(0x6E9E3A)); c.fillEllipse(in: E(0.40, 0.585, 0.22, 0.11))
    c.setFillColor(rgb(SAND)); c.fillEllipse(in: E(0.58, 0.595, 0.20, 0.13))
}

// MARK: - main
let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent().path
let out = root + "/playbook/brand"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
func canvas(_ n: Int) -> CGContext {
    let c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.setAllowsAntialiasing(true); c.setShouldAntialias(true); c.interpolationQuality = .high
    return c
}
func save(_ img: CGImage, _ name: String) {
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out + "/" + name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("could not write \(name)") }
}
for (key, bg, draw) in [("a", COPPER, sonoranDog), ("b", BLUE, pricklyPear), ("c", BLUE, chimichanga)] as [(String, UInt32, (CGContext, CGFloat) -> Void)] {
    let c = canvas(1024)
    c.setFillColor(rgb(bg)); c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    draw(c, 1024)
    let full = c.makeImage()!
    save(full, "concept-\(key)-1024.png")
    for n in [512, 180, 60] {
        let sm = canvas(n); sm.draw(full, in: CGRect(x: 0, y: 0, width: n, height: n)); save(sm.makeImage()!, "concept-\(key)-\(n).png")
    }
    print("wrote concept-\(key)")
}
