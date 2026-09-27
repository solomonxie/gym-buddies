// Renders the opaque 1024x1024 app icon. Run: swift scripts/make_icon.swift
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let out = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
}
let navy = rgb(0.07, 0.07, 0.08)
let chrome = rgb(1.0, 0.42, 0.18)
let light = rgb(0.96, 0.96, 0.97)

let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

ctx.setFillColor(navy)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

func bar(_ x: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: CGColor) {
    let rect = CGRect(x: x, y: 512 - h / 2, width: w, height: h)
    ctx.setFillColor(color)
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: min(w, h) * 0.3, cornerHeight: min(w, h) * 0.3, transform: nil))
    ctx.fillPath()
}

// Symmetric dumbbell: handle, inner collars, big plates, small plates.
bar(262, 500, 64, light)
for mirrored in [false, true] {
    func place(_ x: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: CGColor) {
        bar(mirrored ? 1024 - x - w : x, w, h, c)
    }
    place(318, 34, 150, light)
    place(214, 96, 440, chrome)
    place(142, 64, 300, chrome)
    place(118, 26, 96, light)
}

let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
precondition(CGImageDestinationFinalize(dest))
print("wrote \(out.path)")
