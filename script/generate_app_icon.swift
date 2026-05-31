#!/usr/bin/env swift

import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = rootURL.appendingPathComponent("Resources", isDirectory: true)
let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = resourcesURL.appendingPathComponent("AppIcon.icns")

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconsetURL)
try? FileManager.default.removeItem(at: icnsURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

struct IconColor {
    // Bright, light tile — white fading to a faint cool grey.
    static let topBackground = NSColor(srgbRed: 1.000, green: 1.000, blue: 1.000, alpha: 1)     // #ffffff
    static let bottomBackground = NSColor(srgbRed: 0.929, green: 0.945, blue: 0.965, alpha: 1)  // #edf1f6
    static let tileEdge = NSColor(srgbRed: 0.851, green: 0.875, blue: 0.902, alpha: 1)          // #d9dfe6
    // A single fresh teal accent — the app's one colour.
    static let glyph = NSColor(srgbRed: 0.055, green: 0.690, blue: 0.788, alpha: 1)             // #0eb0c9
}

func scaled(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
    value * scale
}

func point(_ x: CGFloat, _ y: CGFloat, _ scale: CGFloat) -> CGPoint {
    CGPoint(x: scaled(x, scale), y: scaled(y, scale))
}

func roundedRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat, scale: CGFloat) -> NSBezierPath {
    NSBezierPath(
        roundedRect: NSRect(
            x: scaled(x, scale),
            y: scaled(y, scale),
            width: scaled(width, scale),
            height: scaled(height, scale)
        ),
        xRadius: scaled(radius, scale),
        yRadius: scaled(radius, scale)
    )
}

func strokeLine(from start: CGPoint, to end: CGPoint, width: CGFloat, color: NSColor, scale: CGFloat) {
    let path = NSBezierPath()
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.lineWidth = scaled(width, scale)
    path.move(to: point(start.x, start.y, scale))
    path.line(to: point(end.x, end.y, scale))
    color.setStroke()
    path.stroke()
}

func fillRoundedRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat, color: NSColor, scale: CGFloat) {
    let path = roundedRect(x: x, y: y, width: width, height: height, radius: radius, scale: scale)
    color.setFill()
    path.fill()
}

func strokePolyline(_ pts: [CGPoint], width: CGFloat, color: NSColor, scale: CGFloat) {
    guard let first = pts.first else { return }
    let path = NSBezierPath()
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.lineWidth = scaled(width, scale)
    path.move(to: point(first.x, first.y, scale))
    for p in pts.dropFirst() {
        path.line(to: point(p.x, p.y, scale))
    }
    color.setStroke()
    path.stroke()
}

func drawIcon(size: CGFloat) -> NSImage {
    let scale = size / 1024
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSGraphicsContext.current?.shouldAntialias = true
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    // macOS-style squircle with a soft contact shadow.
    let appShape = roundedRect(x: 96, y: 96, width: 832, height: 832, radius: 186, scale: scale)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.16)
    shadow.shadowBlurRadius = scaled(26, scale)
    shadow.shadowOffset = NSSize(width: 0, height: scaled(-12, scale))
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    IconColor.topBackground.setFill()
    appShape.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Soft vertical light gradient fill (white → faint grey).
    NSGraphicsContext.saveGraphicsState()
    appShape.addClip()
    let gradient = NSGradient(starting: IconColor.bottomBackground, ending: IconColor.topBackground)
    gradient?.draw(in: appShape, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    // Crisp grey rim so the light tile reads on light backgrounds.
    IconColor.tileEdge.setStroke()
    appShape.lineWidth = scaled(3, scale)
    appShape.stroke()

    // A page of text — a clean "reader" mark.
    fillRoundedRect(x: 352, y: 286, width: 320, height: 452, radius: 54, color: IconColor.glyph, scale: scale)

    let lineColor = NSColor.white
    // Title line — a touch bolder and shorter.
    strokeLine(from: CGPoint(x: 410, y: 650), to: CGPoint(x: 592, y: 650), width: 42, color: lineColor, scale: scale)
    // Body lines.
    strokeLine(from: CGPoint(x: 410, y: 558), to: CGPoint(x: 614, y: 558), width: 32, color: lineColor, scale: scale)
    strokeLine(from: CGPoint(x: 410, y: 478), to: CGPoint(x: 614, y: 478), width: 32, color: lineColor, scale: scale)
    strokeLine(from: CGPoint(x: 410, y: 398), to: CGPoint(x: 540, y: 398), width: 32, color: lineColor, scale: scale)

    image.unlockFocus()
    return image
}

func writePNG(image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render PNG data"])
    }
    try data.write(to: url)
}

let iconSizes: [(name: String, points: CGFloat, scale: CGFloat)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

for iconSize in iconSizes {
    let pixelSize = iconSize.points * iconSize.scale
    let image = drawIcon(size: pixelSize)
    try writePNG(image: image, to: iconsetURL.appendingPathComponent(iconSize.name))
}

func appendOSType(_ type: String, to data: inout Data) {
    data.append(type.data(using: .ascii)!)
}

func appendUInt32BE(_ value: UInt32, to data: inout Data) {
    data.append(UInt8((value >> 24) & 0xff))
    data.append(UInt8((value >> 16) & 0xff))
    data.append(UInt8((value >> 8) & 0xff))
    data.append(UInt8(value & 0xff))
}

let icnsEntries: [(type: String, file: String)] = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_256x256.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png")
]

var payload = Data()
for entry in icnsEntries {
    let pngData = try Data(contentsOf: iconsetURL.appendingPathComponent(entry.file))
    appendOSType(entry.type, to: &payload)
    appendUInt32BE(UInt32(pngData.count + 8), to: &payload)
    payload.append(pngData)
}

var icnsData = Data()
appendOSType("icns", to: &icnsData)
appendUInt32BE(UInt32(payload.count + 8), to: &icnsData)
icnsData.append(payload)
try icnsData.write(to: icnsURL)

print("Generated \(icnsURL.path)")
