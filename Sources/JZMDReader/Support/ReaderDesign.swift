import SwiftUI

enum ReaderDesign {
    static let appBackground = Color(red: 0.980, green: 0.980, blue: 0.961)
    static let sidebarBackground = Color(red: 0.949, green: 0.949, blue: 0.925)
    static let panelBackground = Color(red: 0.988, green: 0.988, blue: 0.969)
    static let elevatedBackground = Color.white
    static let line = Color(red: 0.890, green: 0.882, blue: 0.843)
    static let softLine = Color(red: 0.929, green: 0.922, blue: 0.890)
    static let primaryText = Color(red: 0.122, green: 0.161, blue: 0.216)
    static let secondaryText = Color(red: 0.373, green: 0.400, blue: 0.451)
    static let tertiaryText = Color(red: 0.541, green: 0.569, blue: 0.612)
    static let accent = Color(red: 0.055, green: 0.690, blue: 0.788)
    static let accentSoft = Color(red: 0.902, green: 0.984, blue: 0.992)
    static let good = Color(red: 0.180, green: 0.490, blue: 0.196)
    static let cool = Color(red: 0.000, green: 0.337, blue: 0.400)

    static let smallRadius: CGFloat = 7
    static let panelRadius: CGFloat = 10
}

struct ReaderChromeButton: View {
    var systemName: String
    var help: String
    var isActive = false
    var isDisabled = false
    var action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(isDisabled ? ReaderDesign.tertiaryText : (isActive ? ReaderDesign.cool : ReaderDesign.cool.opacity(0.82)))
                .frame(width: 24, height: 24)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                        .stroke(isActive ? ReaderDesign.accent.opacity(0.22) : ReaderDesign.softLine.opacity(0.75), lineWidth: isHovering || isActive ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(help)
        .onHover { isHovering = $0 }
    }

    private var background: Color {
        if isActive { return ReaderDesign.accentSoft.opacity(0.46) }
        if isHovering { return ReaderDesign.elevatedBackground.opacity(0.82) }
        return .clear
    }
}

struct ReaderStatusPill: View {
    var text: String
    var systemName: String
    var tint: Color = ReaderDesign.good

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 7, weight: .regular))
            Text(text)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 999))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
    }
}

struct ReaderSectionHeader: View {
    var title: String
    var systemName: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(ReaderDesign.tertiaryText)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(ReaderDesign.secondaryText)
            Spacer(minLength: 0)
        }
    }
}

struct ReaderPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ReaderDesign.elevatedBackground, in: RoundedRectangle(cornerRadius: ReaderDesign.panelRadius))
            .overlay(
                RoundedRectangle(cornerRadius: ReaderDesign.panelRadius)
                    .stroke(ReaderDesign.softLine, lineWidth: 1)
            )
    }
}

extension View {
    func readerPanel() -> some View {
        modifier(ReaderPanelModifier())
    }
}
