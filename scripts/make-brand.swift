// Arizona Eats brand: the app icon (Nick's pick 2026-10-22, "do the cactus": concept B of scripts/icon-concepts.swift, a magenta
// prickly pear fruit on its green pad, on flag blue; the shared Eats Ranked icon style, state-prompts/ICON-STYLE.md, no backing shape).
// Usage, from az-eats/: swift scripts/make-brand.swift   -> ArizonaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png,
// docs/ favicons and touch icons, docs/og.png. scripts/make-site.py draws the same mark as its inline SVG: change both together.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let BLUE: UInt32 = 0x002868, SAND: UInt32 = 0xF3E3C3

/// The prickly pear (upright, front elevation): pad 0.46 x 0.55, the magenta fruit on its rim with a flag-blue gap ring; height 0.72.
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

func render(_ n: Int, _ path: String, background: Bool) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: background ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setShouldAntialias(true)
    if background { ctx.setFillColor(rgb(BLUE)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n)) }
    pricklyPear(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
render(1024, "ArizonaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png", background: true)
try? FileManager.default.createDirectory(atPath: "docs", withIntermediateDirectories: true)
for (n, name) in [(512, "icon-512.png"), (192, "icon-192.png"), (180, "apple-touch-icon.png"), (32, "favicon-32.png")] {
    render(n, "docs/" + name, background: true)
}

/// The share image (1200 x 630): flag blue, the prickly pear at the left, the name and tagline at the right, a copper and sun-yellow
/// band along the bottom (the flag's colours).
func og(_ path: String) {
    let W = 1200, H = 630
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(BLUE)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    ctx.setFillColor(rgb(0xFFD100)); ctx.fill(CGRect(x: 0, y: 28, width: W, height: 14))
    ctx.setFillColor(rgb(0xCE5C17)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 28))
    ctx.saveGState(); ctx.translateBy(x: 30, y: 60); pricklyPear(ctx, 540); ctx.restoreGState()
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
    let title = NSFont(name: "AvenirNextCondensed-Heavy", size: 92) ?? NSFont.boldSystemFont(ofSize: 86)
    let sub = NSFont(name: "AvenirNextCondensed-DemiBold", size: 38) ?? NSFont.boldSystemFont(ofSize: 34)
    NSAttributedString(string: "ARIZONA EATS", attributes: [.font: title, .foregroundColor: NSColor.white]).draw(at: NSPoint(x: 560, y: 330))
    NSAttributedString(string: "SONORAN DOGS, TACOS & FRY BREAD", attributes: [.font: sub, .foregroundColor: NSColor(srgbRed: 0.953, green: 0.890, blue: 0.765, alpha: 1)]).draw(at: NSPoint(x: 564, y: 272))
    NSGraphicsContext.restoreGraphicsState()
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
og("docs/og.png")
