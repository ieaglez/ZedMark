import SwiftUI
import UniformTypeIdentifiers
#if canImport(JZMDReaderCore)
import JZMDReaderCore
#endif

struct ContentView: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        VStack(spacing: 0) {
            CommandBarView(store: store)

            Rectangle()
                .fill(ReaderDesign.line)
                .frame(height: 1)

            HStack(spacing: 0) {
                if store.showSidebar {
                    SidebarView(store: store)
                        .frame(minWidth: 230, idealWidth: 270, maxWidth: 320)

                    Rectangle()
                        .fill(ReaderDesign.line)
                        .frame(width: 1)
                }

                ReaderWorkspaceView(store: store)

                if store.showInspector {
                    Rectangle()
                        .fill(ReaderDesign.line)
                        .frame(width: 1)

                    InspectorView(store: store)
                        .frame(minWidth: 278, idealWidth: 310, maxWidth: 350)
                }
            }
        }
        .background(ReaderDesign.appBackground)
        .preferredColorScheme(.light)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $store.isDropTargeted) { providers in
            store.handleDrop(providers: providers)
        }
    }
}

private struct CommandBarView: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        let copy = store.copy

        HStack(spacing: 8) {
            ReaderChromeButton(
                systemName: "sidebar.left",
                help: copy.toggleSidebar,
                isActive: store.showSidebar
            ) {
                store.toggleSidebar()
            }

            ReaderChromeButton(
                systemName: "plus",
                help: copy.openMarkdown
            ) {
                store.showOpenPanel()
            }

            HStack(spacing: 7) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(ReaderDesign.secondaryText)

                Text(store.document?.title ?? AppCopy.appName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(ReaderDesign.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(ReaderDesign.elevatedBackground, in: RoundedRectangle(cornerRadius: ReaderDesign.smallRadius))
            .overlay(
                RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                    .stroke(ReaderDesign.softLine, lineWidth: 1)
            )

            Spacer(minLength: 12)

            ZoomControlView(store: store)

            Picker(copy.languageLabel, selection: Binding(
                get: { store.language },
                set: { store.language = $0 }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 92)
            .controlSize(.small)
            .help(copy.languageLabel)

            Picker(copy.previewStyle, selection: Binding(
                get: { store.theme },
                set: { store.theme = $0 }
            )) {
                ForEach(ReaderTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 132)
            .controlSize(.small)
            .help(copy.previewStyle)

            ReaderChromeButton(
                systemName: "pencil",
                help: copy.openInEditor,
                isDisabled: store.document == nil
            ) {
                store.openInExternalEditor()
            }

            ReaderChromeButton(
                systemName: "magnifyingglass",
                help: copy.revealInFinder,
                isDisabled: store.document == nil
            ) {
                store.revealInFinder()
            }

            ReaderChromeButton(
                systemName: "arrow.clockwise",
                help: copy.reload,
                isDisabled: store.document == nil
            ) {
                store.reloadFromDisk()
            }

            Menu {
                Button(copy.exportHTML) { store.exportHTML() }
                Button(copy.exportPDF) { store.exportPDF() }
                Divider()
                Button(copy.copyHTMLMenu) { store.copyHTML() }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(store.document == nil ? ReaderDesign.tertiaryText : ReaderDesign.secondaryText)
                    .frame(width: 24, height: 24)
                    .background(ReaderDesign.elevatedBackground, in: RoundedRectangle(cornerRadius: ReaderDesign.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                            .stroke(ReaderDesign.softLine, lineWidth: 1)
                    )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(store.document == nil)
            .help(copy.export)

            ReaderChromeButton(
                systemName: store.showInspector ? "sidebar.right" : "sidebar.trailing",
                help: copy.inspector,
                isActive: store.showInspector
            ) {
                store.showInspector.toggle()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ReaderDesign.panelBackground)
    }
}


private struct ZoomControlView: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        let copy = store.copy

        HStack(spacing: 2) {
            ReaderChromeButton(
                systemName: "minus.magnifyingglass",
                help: copy.zoomOut,
                isDisabled: !store.canZoomOut
            ) {
                store.decreaseZoom()
            }

            Button {
                store.resetZoom()
            } label: {
                Text(store.zoomPercentText)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(ReaderDesign.secondaryText)
                    .frame(width: 44, height: 24)
                    .background(ReaderDesign.elevatedBackground, in: RoundedRectangle(cornerRadius: ReaderDesign.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                            .stroke(ReaderDesign.softLine, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(copy.resetZoom)

            ReaderChromeButton(
                systemName: "plus.magnifyingglass",
                help: copy.zoomIn,
                isDisabled: !store.canZoomIn
            ) {
                store.increaseZoom()
            }
        }
        .help(copy.zoom)
    }
}
