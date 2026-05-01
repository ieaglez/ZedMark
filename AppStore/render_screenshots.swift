import AppKit

struct Theme {
    static let bg = NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.94, alpha: 1)
    static let window = NSColor(calibratedRed: 0.985, green: 0.985, blue: 0.975, alpha: 1)
    static let sidebar = NSColor(calibratedRed: 0.91, green: 0.93, blue: 0.92, alpha: 1)
    static let panel = NSColor(calibratedRed: 0.975, green: 0.975, blue: 0.955, alpha: 1)
    static let line = NSColor(calibratedRed: 0.82, green: 0.84, blue: 0.82, alpha: 1)
    static let text = NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.17, alpha: 1)
    static let muted = NSColor(calibratedRed: 0.35, green: 0.40, blue: 0.43, alpha: 1)
    static let faint = NSColor(calibratedRed: 0.56, green: 0.60, blue: 0.62, alpha: 1)
    static let accent = NSColor(calibratedRed: 0.03, green: 0.54, blue: 0.62, alpha: 1)
    static let accentSoft = NSColor(calibratedRed: 0.84, green: 0.97, blue: 0.98, alpha: 1)
    static let amber = NSColor(calibratedRed: 0.92, green: 0.62, blue: 0.12, alpha: 1)
}

let outDir = URL(fileURLWithPath: "AppStore/Screenshots", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let canvasHeight: CGFloat = 900

func topRect(_ rect: NSRect) -> NSRect {
    NSRect(x: rect.origin.x, y: canvasHeight - rect.origin.y - rect.height, width: rect.width, height: rect.height)
}

func topPoint(_ point: NSPoint) -> NSPoint {
    NSPoint(x: point.x, y: canvasHeight - point.y)
}

func paragraphStyle(_ alignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    if let lineHeight {
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
    }
    return style
}

func drawText(_ text: String, _ rect: NSRect, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = Theme.text, align: NSTextAlignment = .left, mono: Bool = false, lineHeight: CGFloat? = nil) {
    let font: NSFont
    if mono {
        font = NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    } else {
        font = NSFont.systemFont(ofSize: size, weight: weight)
    }
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraphStyle(align, lineHeight: lineHeight)
    ]
    NSString(string: text).draw(in: topRect(rect), withAttributes: attrs)
}

func fill(_ rect: NSRect, _ color: NSColor, radius: CGFloat = 0) {
    color.setFill()
    let rect = topRect(rect)
    if radius == 0 {
        rect.fill()
    } else {
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }
}

func stroke(_ rect: NSRect, _ color: NSColor, radius: CGFloat = 0, width: CGFloat = 1) {
    color.setStroke()
    let rect = topRect(rect)
    let path = radius == 0 ? NSBezierPath(rect: rect) : NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    path.stroke()
}

func line(from a: NSPoint, to b: NSPoint, color: NSColor = Theme.line, width: CGFloat = 1) {
    color.setStroke()
    let path = NSBezierPath()
    path.move(to: topPoint(a))
    path.line(to: topPoint(b))
    path.lineWidth = width
    path.stroke()
}

func chip(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat, tint: NSColor = Theme.accent) {
    fill(NSRect(x: x, y: y, width: w, height: 28), tint.withAlphaComponent(0.11), radius: 6)
    stroke(NSRect(x: x, y: y, width: w, height: 28), tint.withAlphaComponent(0.35), radius: 6)
    drawText(text, NSRect(x: x + 12, y: y + 6, width: w - 24, height: 16), size: 11, weight: .medium, color: tint, mono: true)
}

func metric(_ title: String, _ value: String, x: CGFloat, y: CGFloat) {
    fill(NSRect(x: x, y: y, width: 112, height: 74), NSColor.white.withAlphaComponent(0.75), radius: 8)
    stroke(NSRect(x: x, y: y, width: 112, height: 74), Theme.line, radius: 8)
    drawText(value, NSRect(x: x + 12, y: y + 18, width: 88, height: 24), size: 22, weight: .semibold, mono: true)
    drawText(title.uppercased(), NSRect(x: x + 12, y: y + 48, width: 88, height: 14), size: 9.5, weight: .medium, color: Theme.faint, mono: true)
}

func drawChrome(title: String) {
    fill(NSRect(x: 44, y: 44, width: 1352, height: 812), Theme.window, radius: 18)
    stroke(NSRect(x: 44, y: 44, width: 1352, height: 812), NSColor.black.withAlphaComponent(0.12), radius: 18, width: 1.5)
    fill(NSRect(x: 44, y: 44, width: 1352, height: 52), NSColor(calibratedWhite: 0.98, alpha: 1), radius: 18)
    line(from: NSPoint(x: 44, y: 96), to: NSPoint(x: 1396, y: 96))
    fill(NSRect(x: 70, y: 63, width: 13, height: 13), NSColor(calibratedRed: 1, green: 0.36, blue: 0.32, alpha: 1), radius: 6.5)
    fill(NSRect(x: 93, y: 63, width: 13, height: 13), NSColor(calibratedRed: 1, green: 0.75, blue: 0.22, alpha: 1), radius: 6.5)
    fill(NSRect(x: 116, y: 63, width: 13, height: 13), NSColor(calibratedRed: 0.22, green: 0.80, blue: 0.38, alpha: 1), radius: 6.5)
    drawText(title, NSRect(x: 154, y: 58, width: 340, height: 24), size: 15, weight: .semibold)
}

func drawAppShell(title: String = "ZedMark Demo Note") {
    drawChrome(title: title)
    fill(NSRect(x: 44, y: 96, width: 235, height: 760), Theme.sidebar)
    line(from: NSPoint(x: 279, y: 96), to: NSPoint(x: 279, y: 856))
    fill(NSRect(x: 279, y: 96, width: 858, height: 760), NSColor(calibratedRed: 0.98, green: 0.985, blue: 0.98, alpha: 1))
    fill(NSRect(x: 1137, y: 96, width: 259, height: 760), Theme.panel)
    line(from: NSPoint(x: 1137, y: 96), to: NSPoint(x: 1137, y: 856))
}

func drawSidebar() {
    drawText("ZM", NSRect(x: 70, y: 128, width: 30, height: 22), size: 13, weight: .semibold, color: Theme.accent, mono: true)
    drawText("ZedMark", NSRect(x: 105, y: 123, width: 120, height: 18), size: 14, weight: .medium)
    drawText("markdown reader", NSRect(x: 105, y: 145, width: 140, height: 16), size: 11, color: Theme.muted, mono: true)
    line(from: NSPoint(x: 44, y: 180), to: NSPoint(x: 279, y: 180))
    drawText("RECENT", NSRect(x: 70, y: 205, width: 130, height: 14), size: 10, weight: .medium, color: Theme.faint, mono: true)
    drawText("ZedMarkDemo.md", NSRect(x: 70, y: 232, width: 170, height: 16), size: 12, weight: .medium)
    drawText("AppStore", NSRect(x: 70, y: 251, width: 150, height: 14), size: 10, color: Theme.faint, mono: true)
    line(from: NSPoint(x: 70, y: 292), to: NSPoint(x: 253, y: 292))
    drawText("OUTLINE", NSRect(x: 70, y: 318, width: 130, height: 14), size: 10, weight: .medium, color: Theme.faint, mono: true)
    let items = [
        "Read Local Markdown",
        "Navigate With Outline",
        "Quick Review",
        "Pick A Reading Style",
        "Export"
    ]
    for (index, item) in items.enumerated() {
        let y = CGFloat(348 + index * 34)
        fill(NSRect(x: 64, y: y - 4, width: 190, height: 26), index == 1 ? Theme.accentSoft : .clear, radius: 6)
        drawText(item, NSRect(x: 76, y: y, width: 166, height: 18), size: 11.5, weight: index == 1 ? .semibold : .regular, color: index == 1 ? Theme.accent : Theme.muted)
    }
}

func drawReader(themeName: String = "Claude") {
    fill(NSRect(x: 279, y: 96, width: 858, height: 48), NSColor.white.withAlphaComponent(0.8))
    drawText("ZedMarkDemo.md", NSRect(x: 308, y: 112, width: 230, height: 18), size: 13, weight: .medium)
    chip("LIVE", x: 844, y: 106, w: 64)
    chip(themeName, x: 919, y: 106, w: 86)
    chip("100%", x: 1016, y: 106, w: 68, tint: Theme.muted)
    line(from: NSPoint(x: 279, y: 144), to: NSPoint(x: 1137, y: 144))
    fill(NSRect(x: 390, y: 185, width: 636, height: 618), NSColor.white, radius: 7)
    stroke(NSRect(x: 390, y: 185, width: 636, height: 618), Theme.line, radius: 7)
    drawText("ZedMark Demo Note", NSRect(x: 443, y: 232, width: 520, height: 36), size: 28, weight: .semibold)
    line(from: NSPoint(x: 443, y: 286), to: NSPoint(x: 973, y: 286))
    drawText("ZedMark is a native Markdown reader for macOS. Use it to open a local note, review structure, preview styled Markdown, and export a polished copy to HTML or PDF.", NSRect(x: 443, y: 312, width: 520, height: 68), size: 14.5, color: Theme.muted, lineHeight: 22)
    drawText("Read Local Markdown", NSRect(x: 443, y: 395, width: 520, height: 28), size: 21, weight: .semibold)
    drawText("Open .md, .markdown, .mdown, and plain text files from Finder, the File menu, or drag and drop. ZedMark keeps the document local and reloads the preview when the source file changes on disk.", NSRect(x: 443, y: 432, width: 520, height: 70), size: 14.2, color: Theme.muted, lineHeight: 22)
    drawText("Navigate With Outline", NSRect(x: 443, y: 530, width: 520, height: 28), size: 21, weight: .semibold)
    drawText("The sidebar shows recent files and a heading outline, so long notes stay easy to scan.", NSRect(x: 443, y: 568, width: 520, height: 32), size: 14.2, color: Theme.muted, lineHeight: 22)
    fill(NSRect(x: 443, y: 623, width: 520, height: 104), Theme.accentSoft, radius: 8)
    stroke(NSRect(x: 443, y: 623, width: 520, height: 104), Theme.accent.withAlphaComponent(0.28), radius: 8)
    drawText("Quick Review", NSRect(x: 464, y: 642, width: 200, height: 18), size: 13, weight: .semibold, color: Theme.accent, mono: true)
    drawText("- Word, line, heading, and reading-time stats\n- Lightweight proofing checks\n- Export to HTML or PDF", NSRect(x: 464, y: 668, width: 450, height: 62), size: 13.2, color: Theme.muted, lineHeight: 20)
}

func drawInspector() {
    drawText("Inspector", NSRect(x: 1164, y: 127, width: 130, height: 18), size: 14, weight: .semibold)
    chip("LIGHT", x: 1290, y: 119, w: 72, tint: Theme.amber)
    drawText("STATS", NSRect(x: 1164, y: 180, width: 100, height: 14), size: 10, weight: .medium, color: Theme.faint, mono: true)
    metric("Words", "156", x: 1164, y: 208)
    metric("Read", "1m", x: 1280, y: 208)
    metric("Lines", "36", x: 1164, y: 292)
    metric("Heads", "5", x: 1280, y: 292)
    drawText("EXPORT", NSRect(x: 1164, y: 402, width: 100, height: 14), size: 10, weight: .medium, color: Theme.faint, mono: true)
    fill(NSRect(x: 1164, y: 428, width: 91, height: 34), Theme.accent, radius: 7)
    drawText("HTML", NSRect(x: 1194, y: 437, width: 45, height: 14), size: 11.5, weight: .semibold, color: .white, align: .center)
    fill(NSRect(x: 1266, y: 428, width: 91, height: 34), Theme.accent, radius: 7)
    drawText("PDF", NSRect(x: 1299, y: 437, width: 25, height: 14), size: 11.5, weight: .semibold, color: .white, align: .center)
    drawText("PROOFING", NSRect(x: 1164, y: 516, width: 100, height: 14), size: 10, weight: .medium, color: Theme.faint, mono: true)
    let proof = [
        ("Repeated word", "Line 14"),
        ("Task marker", "Line 15"),
        ("Long sentence", "Line 18")
    ]
    for (index, item) in proof.enumerated() {
        let y = CGFloat(544 + index * 58)
        fill(NSRect(x: 1164, y: y, width: 193, height: 44), NSColor.white.withAlphaComponent(0.72), radius: 7)
        stroke(NSRect(x: 1164, y: y, width: 193, height: 44), Theme.line, radius: 7)
        drawText(item.0, NSRect(x: 1176, y: y + 9, width: 154, height: 15), size: 11.5, weight: .medium)
        drawText(item.1, NSRect(x: 1176, y: y + 25, width: 120, height: 14), size: 9.5, color: Theme.faint, mono: true)
    }
}

func render(_ filename: String, draw: () -> Void) {
    let image = NSImage(size: NSSize(width: 1440, height: 900))
    image.lockFocus()
    fill(NSRect(x: 0, y: 0, width: 1440, height: 900), Theme.bg)
    draw()
    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        fatalError("Could not render \(filename)")
    }
    try! png.write(to: outDir.appendingPathComponent(filename))
}

render("01-main-reader.png") {
    drawAppShell()
    drawSidebar()
    drawReader()
    drawInspector()
}

render("02-themes-and-outline.png") {
    drawAppShell(title: "Reader Themes")
    drawSidebar()
    drawReader(themeName: "Themes")
    drawText("Preview Style", NSRect(x: 1164, y: 126, width: 170, height: 18), size: 14, weight: .semibold)
    let themes = ["Claude", "GitHub", "Notion", "Paper", "Solarized", "Nord", "Catppuccin", "Academic", "Carbon", "Mono"]
    for (index, theme) in themes.enumerated() {
        let row = index / 2
        let col = index % 2
        let x = CGFloat(1164 + col * 96)
        let y = CGFloat(178 + row * 52)
        fill(NSRect(x: x, y: y, width: 84, height: 34), index == 0 ? Theme.accentSoft : NSColor.white.withAlphaComponent(0.75), radius: 7)
        stroke(NSRect(x: x, y: y, width: 84, height: 34), index == 0 ? Theme.accent.withAlphaComponent(0.35) : Theme.line, radius: 7)
        drawText(theme, NSRect(x: x + 8, y: y + 10, width: 68, height: 14), size: 10.5, weight: index == 0 ? .semibold : .regular, color: index == 0 ? Theme.accent : Theme.muted, align: .center)
    }
    drawText("Pick a visual style that fits the document you are reading.", NSRect(x: 1164, y: 470, width: 190, height: 48), size: 13.5, color: Theme.muted, lineHeight: 20)
}

render("03-review-and-export.png") {
    drawAppShell(title: "Review and Export")
    drawSidebar()
    drawReader(themeName: "Academic")
    drawInspector()
    fill(NSRect(x: 442, y: 744, width: 523, height: 42), NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.86, alpha: 1), radius: 8)
    stroke(NSRect(x: 442, y: 744, width: 523, height: 42), Theme.amber.withAlphaComponent(0.35), radius: 8)
    drawText("Exported PDF and HTML keep the rendered reading style.", NSRect(x: 462, y: 757, width: 480, height: 16), size: 13.2, weight: .medium, color: NSColor(calibratedRed: 0.52, green: 0.34, blue: 0.07, alpha: 1))
}

print("Wrote screenshots to \(outDir.path)")
