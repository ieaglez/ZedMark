import SwiftUI
#if canImport(JZMDReaderCore)
import JZMDReaderCore
#endif

struct InspectorView: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        let copy = store.copy

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(copy.inspector)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ReaderDesign.primaryText)
                    Spacer()
                    ReaderStatusPill(text: copy.light, systemName: "sun.max.fill", tint: ReaderDesign.accent)
                }

                StatsSection(stats: store.renderResult.stats, copy: copy)
                ExportSection(store: store)
                ProofSection(diagnostics: store.renderResult.diagnostics, copy: copy)
            }
            .padding(16)
        }
        .background(ReaderDesign.panelBackground)
    }
}

private struct StatsSection: View {
    var stats: DocumentStats
    var copy: AppCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ReaderSectionHeader(title: copy.stats, systemName: "chart.bar")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                MetricView(title: copy.words, value: "\(stats.words)")
                MetricView(title: copy.read, value: stats.readingMinutes == 0 ? "0m" : "\(stats.readingMinutes)m")
                MetricView(title: copy.lines, value: "\(stats.lines)")
                MetricView(title: copy.heads, value: "\(stats.headings)")
            }
        }
    }
}

private struct MetricView: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .monospaced))
                .foregroundStyle(ReaderDesign.primaryText)
                .lineLimit(1)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(ReaderDesign.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .readerPanel()
    }
}

private struct ExportSection: View {
    @ObservedObject var store: ReaderStore

    var body: some View {
        let copy = store.copy

        VStack(alignment: .leading, spacing: 10) {
            ReaderSectionHeader(title: copy.export, systemName: "square.and.arrow.up")

            HStack(spacing: 8) {
                ExportButton(title: "HTML", systemName: "chevron.left.forwardslash.chevron.right") {
                    store.exportHTML()
                }

                ExportButton(title: "PDF", systemName: "doc.richtext") {
                    store.exportPDF()
                }
            }
            .disabled(store.document == nil)

            ExportFeedbackView(
                feedback: store.exportFeedback,
                hasDocument: store.document != nil,
                copy: copy,
                revealAction: { store.revealLastExport() },
                dismissAction: { store.dismissExportFeedback() }
            )
        }
    }
}

private struct ExportButton: View {
    var title: String
    var systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                Text(title)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ReaderDesign.cool)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(ReaderDesign.elevatedBackground, in: RoundedRectangle(cornerRadius: ReaderDesign.smallRadius))
            .overlay(
                RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                    .stroke(ReaderDesign.softLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ExportFeedbackView: View {
    var feedback: ExportFeedback
    var hasDocument: Bool
    var copy: AppCopy
    var revealAction: () -> Void
    var dismissAction: () -> Void

    var body: some View {
        Group {
            switch feedback {
            case .idle:
                ExportHintCard(
                    systemName: hasDocument ? "doc.badge.arrow.up" : "doc.badge.plus",
                    title: hasDocument ? copy.export : copy.openMarkdown,
                    detail: hasDocument ? copy.exportHint : copy.exportNeedsDocument,
                    tint: ReaderDesign.tertiaryText
                )
            case .exporting(let kind):
                HStack(spacing: 9) {
                    ProgressView()
                        .controlSize(.small)
                    Text(copy.exporting(kind))
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(ReaderDesign.secondaryText)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .readerPanel()
            case .completed(let record):
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ReaderDesign.good)
                        Text(copy.exported(record.kind))
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(ReaderDesign.primaryText)
                        Spacer(minLength: 6)
                        Text(record.date.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(ReaderDesign.tertiaryText)
                        FeedbackDismissButton(help: copy.dismiss, action: dismissAction)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(copy.savedTo)
                            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(ReaderDesign.tertiaryText)
                        Text(record.url.lastPathComponent)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ReaderDesign.primaryText)
                            .lineLimit(1)
                        Text(record.url.deletingLastPathComponent().path)
                            .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                            .foregroundStyle(ReaderDesign.tertiaryText)
                            .lineLimit(1)
                    }

                    Button(action: revealAction) {
                        Label(copy.showInFinder, systemImage: "folder")
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ReaderDesign.cool)
                    .background(ReaderDesign.accentSoft.opacity(0.60), in: RoundedRectangle(cornerRadius: ReaderDesign.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: ReaderDesign.smallRadius)
                            .stroke(ReaderDesign.accent.opacity(0.18), lineWidth: 1)
                    )
                }
                .padding(10)
                .readerPanel()
            case .failed(_, let message):
                ExportHintCard(
                    systemName: "exclamationmark.triangle.fill",
                    title: copy.exportFailed,
                    detail: message,
                    tint: Color(red: 0.710, green: 0.139, blue: 0.094),
                    dismissHelp: copy.dismiss,
                    dismissAction: dismissAction
                )
            case .cancelled:
                ExportHintCard(
                    systemName: "xmark.circle",
                    title: copy.exportCancelled,
                    detail: hasDocument ? copy.exportHint : copy.exportNeedsDocument,
                    tint: ReaderDesign.tertiaryText,
                    dismissHelp: copy.dismiss,
                    dismissAction: dismissAction
                )
            }
        }
    }
}

private struct ExportHintCard: View {
    var systemName: String
    var title: String
    var detail: String
    var tint: Color
    var dismissHelp: String?
    var dismissAction: (() -> Void)?

    init(systemName: String, title: String, detail: String, tint: Color, dismissHelp: String? = nil, dismissAction: (() -> Void)? = nil) {
        self.systemName = systemName
        self.title = title
        self.detail = detail
        self.tint = tint
        self.dismissHelp = dismissHelp
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(ReaderDesign.primaryText)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundStyle(ReaderDesign.secondaryText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if let dismissAction {
                FeedbackDismissButton(help: dismissHelp ?? "Dismiss", action: dismissAction)
            }
        }
        .padding(10)
        .readerPanel()
    }
}

private struct FeedbackDismissButton: View {
    var help: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(ReaderDesign.tertiaryText)
                .frame(width: 20, height: 20)
                .background(ReaderDesign.elevatedBackground.opacity(0.001), in: Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct ProofSection: View {
    var diagnostics: [ProofDiagnostic]
    var copy: AppCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ReaderSectionHeader(title: copy.proofing, systemName: "text.magnifyingglass")

            if diagnostics.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ReaderDesign.good)
                    Text(copy.noObviousIssues)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ReaderDesign.secondaryText)
                }
                .padding(10)
                .readerPanel()
            } else {
                VStack(spacing: 8) {
                    ForEach(diagnostics) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(item.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ReaderDesign.primaryText)
                                Spacer(minLength: 8)
                                if let line = item.line {
                                    Text("L\(line)")
                                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                                        .foregroundStyle(ReaderDesign.tertiaryText)
                                }
                            }
                            Text(item.detail)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(ReaderDesign.secondaryText)
                                .lineLimit(2)
                        }
                        .padding(10)
                        .readerPanel()
                    }
                }
            }
        }
    }
}
