import SwiftUI

enum ReaderDesign {
    // Bright, clean, cool-neutral canvas — white panels floating on a faint grey.
    static let appBackground = Color(red: 0.972, green: 0.976, blue: 0.984)      // #f8f9fb
    static let sidebarBackground = Color(red: 0.961, green: 0.965, blue: 0.973)  // #f5f6f8
    static let panelBackground = Color.white                                     // #ffffff
    static let elevatedBackground = Color.white
    static let line = Color(red: 0.898, green: 0.910, blue: 0.925)               // #e5e8ec
    static let softLine = Color(red: 0.937, green: 0.945, blue: 0.957)           // #eff1f4
    static let primaryText = Color(red: 0.106, green: 0.122, blue: 0.149)        // #1b1f26
    static let secondaryText = Color(red: 0.353, green: 0.388, blue: 0.439)      // #5a6370
    static let tertiaryText = Color(red: 0.561, green: 0.596, blue: 0.647)       // #8f98a5
    static let accent = Color(red: 0.055, green: 0.690, blue: 0.788)             // #0eb0c9 brand teal
    static let accentSoft = Color(red: 0.886, green: 0.969, blue: 0.984)         // #e2f7fb
    static let good = Color(red: 0.133, green: 0.545, blue: 0.333)               // #228b55
    static let cool = Color(red: 0.043, green: 0.510, blue: 0.588)               // #0b8296 deep teal

    // Neutral fills for toolbar buttons — kept grey so colour stays meaningful.
    static let hoverFill = Color(red: 0.945, green: 0.953, blue: 0.965)          // #f1f3f6
    static let activeFill = Color(red: 0.910, green: 0.922, blue: 0.937)         // #e8ebef

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
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                        .stroke(ReaderDesign.line.opacity(0.8), lineWidth: isHovering || isActive ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(help)
        .onHover { isHovering = $0 }
    }

    private var iconColor: Color {
        if isDisabled { return ReaderDesign.tertiaryText }
        if isActive { return ReaderDesign.primaryText }
        return ReaderDesign.secondaryText
    }

    private var background: Color {
        if isActive { return ReaderDesign.activeFill }
        if isHovering { return ReaderDesign.hoverFill }
        return .clear
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
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
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
