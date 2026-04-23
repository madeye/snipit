#!/usr/bin/env swift
/// Run: swift scripts/generate_icon.swift
/// Generates AppIcon PNG files for all required sizes in the asset catalog.

import AppKit
import CoreGraphics

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setFillColor(NSColor.white.cgColor)
    let roundedPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
                              cornerWidth: size * 0.18, cornerHeight: size * 0.18, transform: nil)
    ctx.addPath(roundedPath)
    ctx.fillPath()

    // Blue rectangle (selection indicator) — 55% of icon, centered
    let margin = size * 0.15
    let rectInset = size * 0.22
    let selRect = CGRect(x: rectInset, y: rectInset,
                         width: size - rectInset * 2,
                         height: size - rectInset * 2)
    ctx.setStrokeColor(NSColor.systemBlue.cgColor)
    ctx.setLineWidth(size * 0.055)
    ctx.stroke(selRect)

    // Corner handles (small squares at the corners)
    let handleSize = size * 0.08
    let handleColor = NSColor.systemBlue.cgColor
    let corners: [CGPoint] = [
        CGPoint(x: selRect.minX, y: selRect.minY),
        CGPoint(x: selRect.maxX, y: selRect.minY),
        CGPoint(x: selRect.minX, y: selRect.maxY),
        CGPoint(x: selRect.maxX, y: selRect.maxY),
    ]
    ctx.setFillColor(handleColor)
    for corner in corners {
        let hr = CGRect(x: corner.x - handleSize / 2, y: corner.y - handleSize / 2,
                        width: handleSize, height: handleSize)
        ctx.fill(hr)
    }

    // Mouse cursor arrow (top-left of the selection rect)
    let cursorOrigin = CGPoint(x: selRect.minX - size * 0.04, y: selRect.maxY - size * 0.04)
    let cursorScale = size * 0.30
    let arrowPath = CGMutablePath()
    arrowPath.move(to: CGPoint(x: cursorOrigin.x, y: cursorOrigin.y))
    arrowPath.addLine(to: CGPoint(x: cursorOrigin.x, y: cursorOrigin.y - cursorScale))
    arrowPath.addLine(to: CGPoint(x: cursorOrigin.x + cursorScale * 0.35, y: cursorOrigin.y - cursorScale * 0.70))
    arrowPath.addLine(to: CGPoint(x: cursorOrigin.x + cursorScale * 0.20, y: cursorOrigin.y - cursorScale * 0.65))
    arrowPath.addLine(to: CGPoint(x: cursorOrigin.x + cursorScale * 0.40, y: cursorOrigin.y - cursorScale))
    arrowPath.addLine(to: CGPoint(x: cursorOrigin.x + cursorScale * 0.30, y: cursorOrigin.y - cursorScale))
    arrowPath.addLine(to: CGPoint(x: cursorOrigin.x + cursorScale * 0.12, y: cursorOrigin.y - cursorScale * 0.70))
    arrowPath.closeSubpath()

    ctx.setFillColor(NSColor.black.cgColor)
    ctx.addPath(arrowPath)
    ctx.fillPath()
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(size * 0.018)
    ctx.addPath(arrowPath)
    ctx.strokePath()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to render \(path)")
        return
    }
    do {
        try data.write(to: URL(fileURLWithPath: path))
        print("Wrote \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

let assetDir = "Snipit/Resources/Assets.xcassets/AppIcon.appiconset"

let sizes: [(name: String, px: CGFloat)] = [
    ("AppIcon_16",   16),
    ("AppIcon_32",   32),
    ("AppIcon_64",   64),
    ("AppIcon_128",  128),
    ("AppIcon_256",  256),
    ("AppIcon_512",  512),
    ("AppIcon_1024", 1024),
]

for (name, px) in sizes {
    let img = drawIcon(size: px)
    savePNG(img, to: "\(assetDir)/\(name).png")
}

print("Done. All icon sizes generated.")
