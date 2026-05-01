import SwiftUI
#if canImport(JZMDReaderCore)
import JZMDReaderCore
#endif

struct SidebarView: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        VStack(spacing: 0) {
            SidebarHeader(store: store)

            Rectangle()
                .fill(ReaderDesign.line)
                .frame(height: 1)

            RecentSection(store: store)
                .padding(.horizontal, 10)
                .padding(.top, 11)
                .padding(.bottom, 7)

            SidebarSectionDivider()
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            ScrollView {
                OutlineSection(store: store)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
            }
        }
        .background(ReaderDesign.sidebarBackground)
    }
}

private struct SidebarHeader: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        let copy = store.copy

        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(ReaderDesign.elevatedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(ReaderDesign.softLine, lineWidth: 1)
                    )
                Text("ZM")
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ReaderDesign.cool)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(AppCopy.appName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ReaderDesign.primaryText)
                Text(copy.sidebarSubtitle)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(ReaderDesign.secondaryText)
            }

            Spacer(minLength: 8)

            ReaderChromeButton(systemName: "plus", help: copy.openMarkdown) {
                store.showOpenPanel()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ReaderDesign.panelBackground)
    }
}

private struct RecentSection: View {
    @ObservedObject var store: ReaderStore
    @State private var showingAllRecent = false

    var body: some View {
        let copy = store.copy

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(ReaderDesign.tertiaryText)
                Text(copy.recent.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(ReaderDesign.secondaryText)
                Spacer(minLength: 0)

                if store.recentFiles.count > 3 {
                    Button(copy.all) {
                        showingAllRecent = true
                    }
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(ReaderDesign.cool)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ReaderDesign.accentSoft.opacity(0.55), in: Capsule())
                    .buttonStyle(.plain)
                    .help(copy.recentFiles)
                    .popover(isPresented: $showingAllRecent, arrowEdge: .trailing) {
                        AllRecentFilesPopover(store: store, isPresented: $showingAllRecent)
                            .frame(width: 360, height: 360)
                    }
                }
            }

            if store.recentFiles.isEmpty {
                EmptySidebarText(copy.noFilesYet)
            } else {
                VStack(spacing: 3) {
                    ForEach(Array(store.recentFiles.prefix(3))) { file in
                        RecentFileRow(file: file) {
                            store.openRecent(file)
                        }
                    }
                }
            }
        }
    }
}

private struct AllRecentFilesPopover: View {
    @ObservedObject var store: ReaderStore
    @Binding var isPresented: Bool

    var body: some View {
        let copy = store.copy

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(copy.recentFiles)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ReaderDesign.primaryText)
                Spacer(minLength: 0)
                ReaderChromeButton(systemName: "xmark", help: copy.close) {
                    isPresented = false
                }
            }

            if store.recentFiles.isEmpty {
                EmptySidebarText(copy.noFilesYet)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.recentFiles) { file in
                            RecentFileRow(file: file) {
                                store.openRecent(file)
                                isPresented = false
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        }
        .padding(12)
        .background(ReaderDesign.panelBackground)
    }
}

private struct RecentFileRow: View {
    var file: RecentFile
    var action: () -> Void

    var body: some View {
        SidebarRowButton(action: action) {
            Image(systemName: "doc.text")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(ReaderDesign.tertiaryText)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(ReaderDesign.primaryText)
                    .lineLimit(1)

                Text(file.folder)
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(ReaderDesign.tertiaryText)
                    .lineLimit(1)
            }
        }
    }
}

private struct SidebarSectionDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(ReaderDesign.line)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ReaderDesign.elevatedBackground.opacity(0.38))
                .frame(height: 1)
                .offset(y: -1)
        }
    }
}

private struct OutlineSection: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        let copy = store.copy

        VStack(alignment: .leading, spacing: 8) {
            ReaderSectionHeader(title: copy.outline, systemName: "list.bullet.indent")

            if store.renderResult.headings.isEmpty {
                EmptySidebarText(copy.noHeadings)
            } else {
                VStack(spacing: 3) {
                    ForEach(store.renderResult.headings) { heading in
                        SidebarRowButton(
                            isSelected: store.selectedHeadingID == heading.id,
                            action: { store.selectHeading(heading) }
                        ) {
                            Text("H\(heading.level)")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundStyle(ReaderDesign.secondaryText)
                                .frame(width: 22)
                                .padding(.leading, CGFloat(max(heading.level - 1, 0)) * 8)

                            Text(heading.title)
                                .font(.system(size: 11.5, weight: .regular))
                                .foregroundStyle(ReaderDesign.primaryText)
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            Text("L\(heading.line)")
                                .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                                .foregroundStyle(ReaderDesign.tertiaryText)
                        }
                    }
                }
            }
        }
    }
}

private struct SidebarRowButton<Content: View>: View {
    var isSelected = false
    var action: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                content()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: ReaderDesign.smallRadius))
            .overlay(
                RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                    .stroke(isSelected ? ReaderDesign.accent.opacity(0.16) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var background: Color {
        if isSelected { return ReaderDesign.accentSoft.opacity(0.42) }
        if isHovering { return ReaderDesign.elevatedBackground.opacity(0.62) }
        return .clear
    }
}

private struct EmptySidebarText: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(ReaderDesign.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
    }
}
