import SwiftUI

struct ReaderWorkspaceView: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        ZStack {
            ReaderDesign.appBackground
                .ignoresSafeArea()

            if store.document == nil {
                EmptyReaderView(store: store)
            } else {
                WebPreview(
                    html: store.renderResult.html,
                    documentPath: store.document?.url.standardizedFileURL.path,
                    scrollTarget: store.selectedHeadingID,
                    zoom: store.effectiveZoom,
                    restoreScrollY: store.restoreScrollY,
                    findRequest: store.findRequest,
                    onState: { [weak store] y, heading in
                        store?.handlePreviewState(scrollY: y, headingID: heading)
                    },
                    onFindResult: { [weak store] current, total in
                        store?.handleFindResult(current: current, total: total)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: ReaderDesign.panelRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: ReaderDesign.panelRadius)
                        .stroke(ReaderDesign.line, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.035), radius: 18, x: 0, y: 12)
                .padding(14)
            }

            if store.isDropTargeted {
                RoundedRectangle(cornerRadius: ReaderDesign.panelRadius)
                    .stroke(ReaderDesign.accent, style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                    .background(ReaderDesign.accentSoft.opacity(0.18), in: RoundedRectangle(cornerRadius: ReaderDesign.panelRadius))
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            if store.isFindBarVisible, store.document != nil {
                FindBar(store: store)
                    .padding(.top, 24)
                    .padding(.trailing, 28)
            }
        }
    }
}

private struct FindBar: View {
    @ObservedObject var store: ReaderStore
    @FocusState private var isFocused: Bool

    var body: some View {
        let copy = store.copy

        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(ReaderDesign.tertiaryText)

            TextField(copy.findPlaceholder, text: Binding(
                get: { store.findQuery },
                set: { store.findQuery = $0 }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .frame(width: 168)
            .focused($isFocused)
            .onSubmit { store.findNext() }
            .onExitCommand { store.hideFindBar() }

            Text(store.findTotal > 0 ? "\(store.findCurrent)/\(store.findTotal)" : "0/0")
                .font(.system(size: 10.5, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(ReaderDesign.tertiaryText)
                .frame(minWidth: 38)

            ReaderChromeButton(
                systemName: "chevron.up",
                help: copy.findPrevious,
                isDisabled: store.findTotal == 0
            ) {
                store.findPrevious()
            }

            ReaderChromeButton(
                systemName: "chevron.down",
                help: copy.findNext,
                isDisabled: store.findTotal == 0
            ) {
                store.findNext()
            }

            ReaderChromeButton(systemName: "xmark", help: copy.close) {
                store.hideFindBar()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(ReaderDesign.panelBackground, in: RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(ReaderDesign.line, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
        .onAppear { isFocused = true }
    }
}

private struct EmptyReaderView: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        let copy = store.copy

        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ReaderDesign.elevatedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ReaderDesign.softLine, lineWidth: 1)
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "doc.richtext")
                    .font(.system(size: 27, weight: .regular))
                    .foregroundStyle(ReaderDesign.accent)
            }

            VStack(spacing: 5) {
                Text(AppCopy.appName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ReaderDesign.primaryText)
                Text(copy.emptySubtitle)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(ReaderDesign.secondaryText)
            }

            Button {
                store.showOpenPanel()
            } label: {
                Label(copy.openMarkdown, systemImage: "folder")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(ReaderDesign.primaryText)
            .background(ReaderDesign.accent, in: RoundedRectangle(cornerRadius: ReaderDesign.smallRadius))
        }
        .padding(22)
        .readerPanel()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
