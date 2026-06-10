#!/usr/bin/env swift
//
// RenderAppIcon.swift — renders the Clay iOS app icon into the asset catalog.
//
// Run via `make icon`. Customize gradient and symbol to match the app's brand.
//
import AppKit

let size = 1024.0
let outDir = "Resources/Assets.xcassets/AppIcon.appiconset"
let outPath = "\(outDir)/icon-1024.png"

// Draw into an explicit 1024×1024-pixel bitmap rep — `lockFocus` on an NSImage
// picks up the display's 2x backing scale and emits a 2048px PNG, which actool
// rejects.
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)
else { fatalError("no bitmap rep") }
rep.size = NSSize(width: size, height: size)

NSGraphicsContext.saveGraphicsState()
guard let nsCtx = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("no graphics context")
}
NSGraphicsContext.current = nsCtx
let ctx = nsCtx.cgContext

// Full-bleed diagonal gradient — deep indigo wash over the family's dark-glass base.
let colors = [
    NSColor(srgbRed: 0x14 / 255.0, green: 0x12 / 255.0, blue: 0x2E / 255.0, alpha: 1).cgColor,
    NSColor(srgbRed: 0x3B / 255.0, green: 0x33 / 255.0, blue: 0x6E / 255.0, alpha: 1).cgColor,
]
let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: colors as CFArray,
    locations: [0, 1])!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: [])

// Centred white glyph at 50% of the canvas.
let glyphPt = size * 0.50
let config = NSImage.SymbolConfiguration(pointSize: glyphPt, weight: .medium)
if let symbol = NSImage(systemSymbolName: "square.grid.2x2.fill", accessibilityDescription: nil)?  // widget grid — the Clay mark
    .withSymbolConfiguration(config) {
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    NSColor.white.set()
    let r = NSRect(origin: .zero, size: symbol.size)
    symbol.draw(in: r)
    r.fill(using: .sourceAtop)
    tinted.unlockFocus()

    let gs = tinted.size
    let origin = NSPoint(x: (size - gs.width) / 2, y: (size - gs.height) / 2)
    tinted.draw(
        at: origin, from: NSRect(origin: .zero, size: gs),
        operation: .sourceOver, fraction: 1.0)
}

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("failed to encode PNG")
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("→ \(outPath)")
