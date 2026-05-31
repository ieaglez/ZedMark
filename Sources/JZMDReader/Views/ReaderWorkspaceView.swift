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
                    baseURL: store.baseURL,
                    scrollTarget: store.selectedHeadingID,
                    zoom: store.effectiveZoom
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
