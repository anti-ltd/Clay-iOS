#!/usr/bin/env swift
//
// RenderAppIcon.swift — renders the Clay iOS app icon into the asset catalog.
//
// Clay's mark joins the family: one **physical keycap** — the same chiclet key
// as Clink and Cling, viewed slightly from above so you read its thickness —
// with a 2×2 grid of little rounded tiles molded into its top face instead of
// Clink's "C". Four widgets laid out on a board: the Clay widget studio, but
// now built as ONE keycap so it sits beside Clink/Cling/Cluster as a sibling
// rather than four separate floating tiles.
//
// Built directly on Clink's renderer so the field, lighting, keycap material,
// and emboss pipeline are byte-for-byte the family look — only the legend on
// the top face differs (a grid glyph in place of the letter).
//
// iOS specifics, both required:
//   • the background is drawn full-bleed and fully opaque (no squircle clip,
//     no rim stroke) — iOS applies its own icon mask, and App Store icons must
//     not have an alpha channel.
//   • a single 1024px PNG (plus a 512px gallery copy) instead of an .iconset.
//
// Do NOT introduce a Liquid Glass `.icon` bundle here: the rest of the family
// ships a flat three-appearance appiconset, and an `.icon` makes iOS
// recolour/gloss Clay differently, so it stops matching the siblings.
//
import AppKit

let size = 1024.0
let outDir = "Resources/Assets.xcassets/AppIcon.appiconset"
let galleryPath = "Resources/icon-512.png"

// Appearance to render, matching the three iOS icon appearances:
//   • "light"  — white cap, indigo grid, on the luminous indigo field.
//   • "dark"   — graphite cap, cool-white grid, on a deepened near-black field.
//   • "tinted" — grayscale cap on a transparent field; iOS maps luminance to
//                the user's tint over its own dark backdrop.
let arg = CommandLine.arguments.dropFirst().first ?? "all"
let modes = (arg == "all") ? ["light", "dark", "tinted"] : [arg]

func renderPNG(size: CGFloat, mode: String) -> Data? {
    let px = Int(size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    draw(in: ctx.cgContext, size: size, mode: mode)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

// Build a centred CGPath for the 2×2 grid legend (four rounded tiles), at the
// origin, so the caller can place + emboss it exactly like Clink's letter.
// `extent` is the total width/height of the grid square.
func gridGlyphPath(extent: CGFloat) -> (CGPath, CGRect) {
    let gap  = extent * 0.16
    let tile = (extent - gap) / 2
    let corner = tile * 0.30
    let path = CGMutablePath()
    for row in 0..<2 {
        for col in 0..<2 {
            let x = CGFloat(col) * (tile + gap)
            let y = CGFloat(row) * (tile + gap)
            path.addRoundedRect(in: CGRect(x: x, y: y, width: tile, height: tile),
                                cornerWidth: corner, cornerHeight: corner)
        }
    }
    return (path, path.boundingBoxOfPath)
}

func draw(in cg: CGContext, size: CGFloat, mode: String) {
    let isDark   = (mode == "dark")
    let isTinted = (mode == "tinted")
    let space = CGColorSpaceCreateDeviceRGB()
    func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }
    func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // ── Background ────────────────────────────────────────────────────────────
    // Tinted leaves the field transparent (iOS supplies its own dark backdrop
    // and tint); light and dark paint the indigo field, dark simply deepened.
    if !isTinted {
        let bgGrad = isDark
            ? CGGradient(colorsSpace: space, colors: [
                rgb(0.16, 0.13, 0.32),     // muted violet, top-left
                rgb(0.08, 0.10, 0.26),     // deep blue
                rgb(0.02, 0.03, 0.10),     // near-black, bottom-right
              ] as CFArray, locations: [0, 0.52, 1])!
            : CGGradient(colorsSpace: space, colors: [
                rgb(0.46, 0.36, 0.80),     // violet, top-left
                rgb(0.24, 0.30, 0.70),     // mid blue
                rgb(0.07, 0.09, 0.24),     // navy, bottom-right
              ] as CFArray, locations: [0, 0.52, 1])!
        cg.drawLinearGradient(bgGrad,
                              start: CGPoint(x: rect.minX, y: rect.maxY),
                              end: CGPoint(x: rect.maxX, y: rect.minY),
                              options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        // Soft overhead key-light bloom centred above the keycap.
        let bloomC = CGPoint(x: rect.midX, y: rect.midY + size * 0.16)
        let bloom = CGGradient(colorsSpace: space, colors: [
            rgb(0.78, 0.86, 1.00, isDark ? 0.20 : 0.40),
            rgb(0.60, 0.70, 1.00, 0.00),
        ] as CFArray, locations: [0, 1])!
        cg.drawRadialGradient(bloom, startCenter: bloomC, startRadius: 0,
                              endCenter: bloomC, endRadius: size * 0.55, options: [])
        // Warm magenta accent low-right, for depth in the field.
        let warmC = CGPoint(x: rect.maxX - size * 0.10, y: rect.minY + size * 0.12)
        let warm = CGGradient(colorsSpace: space, colors: [
            rgb(0.80, 0.34, 0.74, isDark ? 0.20 : 0.32),
            rgb(0.80, 0.34, 0.74, 0.00),
        ] as CFArray, locations: [0, 1])!
        cg.drawRadialGradient(warm, startCenter: warmC, startRadius: 0,
                              endCenter: warmC, endRadius: size * 0.5, options: [])
    }

    // ── Keycap geometry ───────────────────────────────────────────────────────
    // Top face is a rounded square; the body is extruded straight down from it
    // so we read thickness, with the whole thing nudged up to leave room for the
    // grounding shadow.
    let capSide = size * 0.66
    let depth   = capSide * 0.16            // extrusion height (the visible wall)
    let capX = (size - capSide) / 2
    let capY = (size - capSide) / 2 + depth * 0.55 + size * 0.01
    let radius = capSide * 0.30
    let topRect = CGRect(x: capX, y: capY, width: capSide, height: capSide)
    let topPath = CGPath(roundedRect: topRect, cornerWidth: radius,
                         cornerHeight: radius, transform: nil)

    // ── Contact shadow — grounds the key on the surface (skipped when tinted,
    //    where a blurred halo on transparency would read as grime). ────────────
    if !isTinted {
        cg.saveGState()
        cg.translateBy(x: 0, y: -depth)
        cg.addPath(topPath)
        cg.setShadow(offset: CGSize(width: 0, height: -size * 0.022),
                     blur: size * 0.06, color: rgb(0.01, 0.02, 0.06, 0.55))
        cg.setFillColor(rgb(0, 0, 0, 1))
        cg.fillPath()
        cg.restoreGState()
    }

    // ── Extruded body — fill the top-face path at descending offsets so the
    //    side wall reads as one solid bevel, shaded dark at the base. ──────────
    let stepCount = Int(depth)
    for i in stride(from: stepCount, through: 0, by: -1) {
        let t = Double(i) / Double(stepCount)          // 1 at base, 0 at top edge
        let r, g, b: Double
        if isTinted {
            r = lerp(0.62, 0.30, t); g = lerp(0.62, 0.30, t); b = lerp(0.62, 0.30, t)
        } else if isDark {
            r = lerp(0.26, 0.08, t); g = lerp(0.28, 0.09, t); b = lerp(0.34, 0.13, t)
        } else {
            r = lerp(0.74, 0.40, t); g = lerp(0.76, 0.42, t); b = lerp(0.82, 0.52, t)
        }
        cg.saveGState()
        cg.translateBy(x: 0, y: -CGFloat(i))
        cg.addPath(topPath)
        cg.setFillColor(rgb(r, g, b, 1))
        cg.fillPath()
        cg.restoreGState()
    }

    // Ambient occlusion pooled where the wall meets the surface.
    cg.saveGState()
    cg.translateBy(x: 0, y: -CGFloat(stepCount))
    cg.addPath(topPath)
    cg.clip()
    cg.addPath(topPath)
    cg.setLineWidth(size * 0.018)
    cg.replacePathWithStrokedPath()
    cg.clip()
    let occ = CGGradient(colorsSpace: space, colors: [
        rgb(0.18, 0.20, 0.30, 0.55),
        rgb(0.18, 0.20, 0.30, 0.00),
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(occ, start: CGPoint(x: 0, y: topRect.minY - depth),
                          end: CGPoint(x: 0, y: topRect.minY - depth + capSide * 0.18),
                          options: [])
    cg.restoreGState()

    // ════════════════════════════════════════════════════════════════════════
    //  TOP FACE — the lit, gently dished surface of the key.
    // ════════════════════════════════════════════════════════════════════════
    cg.saveGState()
    cg.addPath(topPath)
    cg.clip()
    let face: CGGradient
    if isTinted {
        face = CGGradient(colorsSpace: space, colors: [
            rgb(0.98, 0.98, 0.98), rgb(0.90, 0.90, 0.90), rgb(0.80, 0.80, 0.80),
        ] as CFArray, locations: [0, 0.55, 1])!
    } else if isDark {
        face = CGGradient(colorsSpace: space, colors: [
            rgb(0.30, 0.32, 0.40), rgb(0.22, 0.24, 0.32), rgb(0.15, 0.17, 0.24),
        ] as CFArray, locations: [0, 0.55, 1])!
    } else {
        face = CGGradient(colorsSpace: space, colors: [
            rgb(0.99, 1.00, 1.00), rgb(0.93, 0.95, 0.99), rgb(0.84, 0.88, 0.96),
        ] as CFArray, locations: [0, 0.55, 1])!
    }
    cg.drawLinearGradient(face, start: CGPoint(x: 0, y: topRect.maxY),
                          end: CGPoint(x: 0, y: topRect.minY), options: [])

    // Dish: soft darker vignette hugging the inner edge so the centre reads
    // as scooped, like a real keycap's concave top.
    let dishC = CGPoint(x: topRect.midX, y: topRect.midY)
    let dish: CGGradient
    if isTinted {
        dish = CGGradient(colorsSpace: space, colors: [
            rgb(0.55, 0.55, 0.55, 0.00), rgb(0.55, 0.55, 0.55, 0.00), rgb(0.45, 0.45, 0.45, 0.40),
        ] as CFArray, locations: [0, 0.62, 1])!
    } else if isDark {
        dish = CGGradient(colorsSpace: space, colors: [
            rgb(0.10, 0.11, 0.16, 0.00), rgb(0.10, 0.11, 0.16, 0.00), rgb(0.06, 0.07, 0.11, 0.55),
        ] as CFArray, locations: [0, 0.62, 1])!
    } else {
        dish = CGGradient(colorsSpace: space, colors: [
            rgb(0.80, 0.85, 0.94, 0.00), rgb(0.80, 0.85, 0.94, 0.00), rgb(0.62, 0.68, 0.82, 0.45),
        ] as CFArray, locations: [0, 0.62, 1])!
    }
    cg.drawRadialGradient(dish, startCenter: dishC, startRadius: 0,
                          endCenter: dishC, endRadius: capSide * 0.62, options: [])

    // Top specular: a broad soft sheen across the upper third.
    cg.saveGState()
    cg.translateBy(x: topRect.midX, y: topRect.maxY - capSide * 0.14)
    cg.scaleBy(x: 1.0, y: 0.45)
    let sheen = CGGradient(colorsSpace: space, colors: [
        rgb(1, 1, 1, isDark ? 0.35 : 0.85),
        rgb(1, 1, 1, 0.00),
    ] as CFArray, locations: [0, 1])!
    cg.drawRadialGradient(sheen, startCenter: .zero, startRadius: 0,
                          endCenter: .zero, endRadius: capSide * 0.5, options: [])
    cg.restoreGState()
    cg.restoreGState()  // end top-face clip

    // ── Molded 2×2 grid legend on the top face ────────────────────────────────
    let (rawGlyph, gBox) = gridGlyphPath(extent: capSide * 0.58)
    var place = CGAffineTransform(translationX: topRect.midX - gBox.midX,
                                  y: topRect.midY - gBox.midY)
    let glyph = rawGlyph.copy(using: &place)!

    // Engraved shadow under the tiles so they read as molded into the face.
    cg.saveGState()
    cg.addPath(glyph)
    let glyphShadow = isTinted ? rgb(0.20, 0.20, 0.20, 0.45)
                    : isDark   ? rgb(0, 0, 0, 0.55)
                               : rgb(0.10, 0.14, 0.30, 0.40)
    let glyphBase = isTinted ? rgb(0.34, 0.34, 0.34, 1)
                  : isDark   ? rgb(0.05, 0.06, 0.10, 1)
                             : rgb(0.20, 0.26, 0.52, 1)
    cg.setShadow(offset: CGSize(width: 0, height: -size * 0.004),
                 blur: size * 0.012, color: glyphShadow)
    cg.setFillColor(glyphBase)
    cg.fillPath()
    cg.restoreGState()

    // Tile body fill: light → indigo; dark → cool-white; tinted → mid-grey,
    // kept darker than the cap face so the tint keeps the grid legible.
    cg.saveGState()
    cg.addPath(glyph)
    cg.clip()
    let tileFill: CGGradient
    if isTinted {
        tileFill = CGGradient(colorsSpace: space, colors: [
            rgb(0.46, 0.46, 0.46), rgb(0.34, 0.34, 0.34),
        ] as CFArray, locations: [0, 1])!
    } else if isDark {
        tileFill = CGGradient(colorsSpace: space, colors: [
            rgb(0.98, 0.99, 1.00), rgb(0.82, 0.86, 0.96),
        ] as CFArray, locations: [0, 1])!
    } else {
        tileFill = CGGradient(colorsSpace: space, colors: [
            rgb(0.36, 0.34, 0.78), rgb(0.18, 0.22, 0.60),
        ] as CFArray, locations: [0, 1])!
    }
    cg.drawLinearGradient(tileFill, start: CGPoint(x: 0, y: gBox.maxY + place.ty),
                          end: CGPoint(x: 0, y: gBox.minY + place.ty), options: [])
    cg.restoreGState()

    // Top highlight on the tiles — a thin lit bevel, as if molded into plastic.
    var hiPlace = place.translatedBy(x: 0, y: size * 0.0045)
    let hiGlyph = rawGlyph.copy(using: &hiPlace)!
    cg.saveGState()
    cg.addPath(glyph)
    cg.clip()
    cg.addPath(hiGlyph)
    cg.setFillColor(rgb(1, 1, 1, isDark ? 0.16 : 0.30))
    cg.fillPath()
    cg.restoreGState()

    // ── Crisp top rim of the keycap — the lit leading edge of the top face. ───
    cg.saveGState()
    cg.addPath(topPath)
    cg.clip()
    cg.addPath(topPath)
    cg.setLineWidth(size * 0.012)
    cg.replacePathWithStrokedPath()
    cg.clip()
    let rim = CGGradient(colorsSpace: space, colors: [
        rgb(1, 1, 1, 0.95),
        rgb(1, 1, 1, 0.00),
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(rim, start: CGPoint(x: 0, y: topRect.maxY),
                          end: CGPoint(x: 0, y: topRect.midY), options: [])
    cg.restoreGState()
}

// Filenames for each appearance inside the appiconset.
let fileFor = ["light": "icon-1024.png",
               "dark": "icon-1024-dark.png",
               "tinted": "icon-1024-tinted.png"]

for mode in modes {
    guard let name = fileFor[mode] else { fatalError("unknown mode: \(mode)") }
    guard let png = renderPNG(size: size, mode: mode) else { fatalError("render failed: \(mode)") }
    try! png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("→ \(outDir)/\(name)")
    if mode == "light", let png512 = renderPNG(size: 512, mode: "light") {
        try! png512.write(to: URL(fileURLWithPath: galleryPath))
        print("→ \(galleryPath)")
    }
}
