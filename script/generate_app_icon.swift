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
    static let peacock = NSColor(calibratedRed: 0.020, green: 0.420, blue: 0.455, alpha: 1)
    static let peacockLight = NSColor(calibratedRed: 0.055, green: 0.690, blue: 0.788, alpha: 1)
    static let ink = NSColor(calibratedRed: 0.035, green: 0.173, blue: 0.204, alpha: 1)
    static let paper = NSColor(calibratedRed: 0.975, green: 0.972, blue: 0.948, alpha: 1)
    static let paperEdge = NSColor(calibratedRed: 0.790, green: 0.850, blue: 0.840, alpha: 1)
    static let paperFold = NSColor(calibratedRed: 0.800, green: 0.965, blue: 0.952, alpha: 1)
    static let paperLine = NSColor(calibratedRed: 0.685, green: 0.755, blue: 0.748, alpha: 1)
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

func zMarkPath(scale: CGFloat, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: point(298 + offsetX, 700 + offsetY, scale))
    path.line(to: point(670 + offsetX, 700 + offsetY, scale))
    path.line(to: point(600 + offsetX, 614 + offsetY, scale))
    path.line(to: point(458 + offsetX, 614 + offsetY, scale))
    path.line(to: point(300 + offsetX, 404 + offsetY, scale))
    path.line(to: point(560 + offsetX, 404 + offsetY, scale))
    path.line(to: point(486 + offsetX, 312 + offsetY, scale))
    path.line(to: point(214 + offsetX, 312 + offsetY, scale))
    path.line(to: point(286 + offsetX, 404 + offsetY, scale))
    path.line(to: point(430 + offsetX, 404 + offsetY, scale))
    path.line(to: point(588 + offsetX, 614 + offsetY, scale))
    path.line(to: point(226 + offsetX, 614 + offsetY, scale))
    path.close()
    path.lineJoinStyle = .round
    return path
}

func drawIcon(size: CGFloat) -> NSImage {
    let scale = size / 1024
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSGraphicsContext.current?.shouldAntialias = true
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.22)
    shadow.shadowBlurRadius = scaled(34, scale)
    shadow.shadowOffset = NSSize(width: 0, height: scaled(-16, scale))

    let appShape = roundedRect(x: 72, y: 68, width: 880, height: 880, radius: 198, scale: scale)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    IconColor.peacock.setFill()
    appShape.fill()
    NSGraphicsContext.restoreGraphicsState()

    IconColor.peacock.setFill()
    appShape.fill()
    NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
    appShape.lineWidth = scaled(3, scale)
    appShape.stroke()

    let pageShadow = NSShadow()
    pageShadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.24)
    pageShadow.shadowBlurRadius = scaled(24, scale)
    pageShadow.shadowOffset = NSSize(width: scaled(5, scale), height: scaled(-12, scale))

    let page = roundedRect(x: 372, y: 226, width: 420, height: 558, radius: 48, scale: scale)
    NSGraphicsContext.saveGraphicsState()
    pageShadow.set()
    IconColor.paper.setFill()
    page.fill()
    NSGraphicsContext.restoreGraphicsState()

    IconColor.paper.setFill()
    page.fill()

    let fold = NSBezierPath()
    fold.move(to: point(650, 784, scale))
    fold.line(to: point(792, 642, scale))
    fold.line(to: point(792, 784, scale))
    fold.close()
    IconColor.paperFold.setFill()
    fold.fill()
    IconColor.peacock.withAlphaComponent(0.42).setStroke()
    fold.lineWidth = scaled(7, scale)
    fold.stroke()

    strokeLine(from: CGPoint(x: 548, y: 430), to: CGPoint(x: 710, y: 430), width: 22, color: IconColor.paperLine, scale: scale)
    strokeLine(from: CGPoint(x: 548, y: 374), to: CGPoint(x: 686, y: 374), width: 22, color: IconColor.paperLine.withAlphaComponent(0.86), scale: scale)
    strokeLine(from: CGPoint(x: 548, y: 318), to: CGPoint(x: 646, y: 318), width: 22, color: IconColor.peacockLight.withAlphaComponent(0.72), scale: scale)

    let zDropShadow = NSShadow()
    zDropShadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.28)
    zDropShadow.shadowBlurRadius = scaled(18, scale)
    zDropShadow.shadowOffset = NSSize(width: scaled(5, scale), height: scaled(-10, scale))

    let zEdge = zMarkPath(scale: scale, offsetX: 16, offsetY: -16)
    IconColor.paperEdge.setFill()
    zEdge.fill()

    let z = zMarkPath(scale: scale)
    NSGraphicsContext.saveGraphicsState()
    zDropShadow.set()
    IconColor.paper.setFill()
    z.fill()
    NSGraphicsContext.restoreGraphicsState()

    IconColor.paper.setFill()
    z.fill()
    NSColor(calibratedWhite: 1, alpha: 0.74).setStroke()
    z.lineWidth = scaled(4, scale)
    z.stroke()

    strokeLine(from: CGPoint(x: 282, y: 652), to: CGPoint(x: 622, y: 652), width: 3, color: NSColor(calibratedWhite: 1, alpha: 0.54), scale: scale)

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
