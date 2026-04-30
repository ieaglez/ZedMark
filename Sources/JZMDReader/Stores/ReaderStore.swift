import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import JZMDReaderCore

struct MarkdownDocument: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    var text: String
    var lastModified: Date?

    var title: String {
        url.lastPathComponent.isEmpty ? "Untitled.md" : url.lastPathComponent
    }

    var folder: String {
        url.deletingLastPathComponent().path
    }
}

struct RecentFile: Identifiable, Hashable {
    var url: URL
    var id: String { url.path }
    var title: String { url.lastPathComponent }
    var folder: String { url.deletingLastPathComponent().path }
}


enum ExportKind: String, Hashable {
    case html = "HTML"
    case pdf = "PDF"

    var systemName: String {
        switch self {
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .pdf: return "doc.richtext"
        }
    }
}

struct ExportRecord: Identifiable, Equatable {
    let id = UUID()
    var kind: ExportKind
    var url: URL
    var date: Date
}

enum ExportFeedback: Equatable {
    case idle
    case exporting(ExportKind)
    case completed(ExportRecord)
    case failed(ExportKind, String)
    case cancelled
}

final class ReaderStore: ObservableObject {
    @Published var document: MarkdownDocument?
    @Published var renderResult: MarkdownRenderResult = .empty
    @Published var selectedHeadingID: String?
    @Published var recentFiles: [RecentFile] = []
    @Published var statusMessage = AppCopy(language: .english).ready
    @Published var exportFeedback: ExportFeedback = .idle
    @Published var lastExport: ExportRecord?
    @Published var isDropTargeted = false

    @Published var theme: ReaderTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme)
            renderDocument()
        }
    }

    @Published var showInspector: Bool {
        didSet { UserDefaults.standard.set(showInspector, forKey: Keys.showInspector) }
    }

    @Published var livePreviewEnabled: Bool {
        didSet { UserDefaults.standard.set(livePreviewEnabled, forKey: Keys.livePreviewEnabled) }
    }

    @Published var showSidebar: Bool {
        didSet { UserDefaults.standard.set(showSidebar, forKey: Keys.showSidebar) }
    }

    @Published var previewZoom: Double {
        didSet {
            let clamped = Self.clampedZoom(previewZoom)
            if clamped != previewZoom {
                previewZoom = clamped
                return
            }
            UserDefaults.standard.set(previewZoom, forKey: Keys.previewZoom)
        }
    }

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    var copy: AppCopy { AppCopy(language: language) }
    var zoomPercentText: String { "\(Int((previewZoom * 100).rounded()))%" }
    var canZoomIn: Bool { previewZoom < Self.maxZoom }
    var canZoomOut: Bool { previewZoom > Self.minZoom }

    private static let minZoom = 0.60
    private static let maxZoom = 2.00
    private static let zoomStep = 0.10

    private enum Keys {
        static let theme = "JZMDReader.theme"
        static let showInspector = "JZMDReader.showInspector"
        static let livePreviewEnabled = "JZMDReader.livePreviewEnabled"
        static let showSidebar = "ZedMark.showSidebar"
        static let previewZoom = "ZedMark.previewZoom"
        static let language = "ZedMark.language"
        static let recentFiles = "JZMDReader.recentFiles"
    }

    private let renderer = MarkdownRenderer()
    private var watcher: FileWatcher?
    private var pdfExporter: PDFExporter?
    private var observers: [NSObjectProtocol] = []

    init() {
        let defaults = UserDefaults.standard
        theme = ReaderTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .claude
        showInspector = defaults.object(forKey: Keys.showInspector) as? Bool ?? true
        livePreviewEnabled = defaults.object(forKey: Keys.livePreviewEnabled) as? Bool ?? true
        showSidebar = defaults.object(forKey: Keys.showSidebar) as? Bool ?? true
        previewZoom = Self.clampedZoom(defaults.object(forKey: Keys.previewZoom) as? Double ?? 1.0)
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .english
        statusMessage = copy.ready
        loadRecentFiles()
        observeAppEvents()
    }

    deinit {
        watcher?.stop()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    var baseURL: URL? {
        document?.url.deletingLastPathComponent()
    }


    func toggleSidebar() {
        showSidebar.toggle()
    }

    func increaseZoom() {
        setPreviewZoom(previewZoom + Self.zoomStep)
    }

    func decreaseZoom() {
        setPreviewZoom(previewZoom - Self.zoomStep)
    }

    func resetZoom() {
        setPreviewZoom(1.0)
    }

    private func setPreviewZoom(_ value: Double) {
        previewZoom = Self.clampedZoom(value)
        statusMessage = "\(copy.zoom) \(zoomPercentText)"
    }

    private static func clampedZoom(_ value: Double) -> Double {
        min(max(value, minZoom), maxZoom)
    }

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = copy.openPanelTitle
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = markdownContentTypes

        if panel.runModal() == .OK, let url = panel.url {
            openURL(url)
        }
    }

    func openURL(_ url: URL) {
        guard markdownContentTypes.contains(where: { url.conforms(to: $0) }) || isMarkdownExtension(url.pathExtension) else {
            presentError(message: copy.unsupportedFile, detail: copy.unsupportedFileDetail)
            return
        }

        do {
            let text = try readText(url: url)
            let modified = modificationDate(for: url)
            document = MarkdownDocument(url: url, text: text, lastModified: modified)
            selectedHeadingID = nil
            renderDocument()
            addRecentFile(url)
            configureWatcher(for: url)
            statusMessage = livePreviewEnabled ? copy.livePreviewOn : copy.loaded
        } catch {
            presentError(message: copy.couldNotOpenFile, detail: error.localizedDescription)
        }
    }

    func reloadFromDisk() {
        reloadFromDisk(silent: false)
    }

    func reloadFromDisk(silent: Bool) {
        guard var current = document else { return }

        do {
            current.text = try readText(url: current.url)
            current.lastModified = modificationDate(for: current.url)
            document = current
            renderDocument()
            if !silent { statusMessage = copy.reloaded }
        } catch {
            presentError(message: copy.couldNotReloadFile, detail: error.localizedDescription)
        }
    }

    func selectHeading(_ heading: MarkdownHeading) {
        selectedHeadingID = nil
        DispatchQueue.main.async { [weak self] in
            self?.selectedHeadingID = heading.id
        }
    }

    func openRecent(_ file: RecentFile) {
        openURL(file.url)
    }


    func dismissExportFeedback() {
        exportFeedback = .idle
        statusMessage = document == nil ? copy.ready : (livePreviewEnabled ? copy.livePreviewOn : copy.loaded)
    }

    func revealInFinder() {
        guard let url = document?.url else { return }
        revealInFinder(url)
    }

    func revealLastExport() {
        guard let url = lastExport?.url else { return }
        revealInFinder(url)
    }

    private func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openInExternalEditor() {
        guard let url = document?.url else { return }
        NSWorkspace.shared.open(url)
    }

    func exportHTML() {
        guard let document else { return }
        let panel = NSSavePanel()
        panel.title = copy.exportHTML
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = document.url.deletingPathExtension().lastPathComponent + ".html"

        guard panel.runModal() == .OK, let destination = panel.url else {
            exportFeedback = .cancelled
            statusMessage = copy.exportCancelled
            return
        }

        exportFeedback = .exporting(.html)
        statusMessage = copy.exporting(.html)

        do {
            try renderResult.html.write(to: destination, atomically: true, encoding: .utf8)
            let record = ExportRecord(kind: .html, url: destination, date: Date())
            lastExport = record
            exportFeedback = .completed(record)
            statusMessage = copy.exported(.html)
        } catch {
            exportFeedback = .failed(.html, error.localizedDescription)
            presentError(message: copy.couldNotExportHTML, detail: error.localizedDescription)
        }
    }

    func exportPDF() {
        guard let document else { return }
        let panel = NSSavePanel()
        panel.title = copy.exportPDF
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = document.url.deletingPathExtension().lastPathComponent + ".pdf"

        guard panel.runModal() == .OK, let destination = panel.url else {
            exportFeedback = .cancelled
            statusMessage = copy.exportCancelled
            return
        }

        exportFeedback = .exporting(.pdf)
        statusMessage = copy.exporting(.pdf)

        let exporter = PDFExporter()
        pdfExporter = exporter
        exporter.export(html: renderResult.html, baseURL: baseURL, to: destination) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.pdfExporter = nil
                switch result {
                case .success:
                    let record = ExportRecord(kind: .pdf, url: destination, date: Date())
                    self.lastExport = record
                    self.exportFeedback = .completed(record)
                    self.statusMessage = self.copy.exported(.pdf)
                case .failure(let error):
                    self.exportFeedback = .failed(.pdf, error.localizedDescription)
                    self.presentError(message: self.copy.couldNotExportPDF, detail: error.localizedDescription)
                }
            }
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] data, _ in
            guard let data,
                  let value = String(data: data, encoding: .utf8),
                  let url = URL(string: value)
            else { return }

            DispatchQueue.main.async {
                self?.openURL(url)
            }
        }
        return true
    }

    private var markdownContentTypes: [UTType] {
        [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown"),
            UTType(filenameExtension: "mdown"),
            .plainText,
            .text
        ].compactMap { $0 }
    }

    private func isMarkdownExtension(_ pathExtension: String) -> Bool {
        ["md", "markdown", "mdown", "mkd", "txt"].contains(pathExtension.lowercased())
    }

    private func readText(url: URL) throws -> String {
        var encoding = String.Encoding.utf8
        return try String(contentsOf: url, usedEncoding: &encoding)
    }

    private func renderDocument() {
        guard let document else {
            renderResult = .empty
            return
        }
        renderResult = renderer.render(markdown: document.text, theme: theme)
    }

    private func configureWatcher(for url: URL) {
        watcher?.stop()
        watcher = FileWatcher(url: url) { [weak self] in
            guard let self else { return }
            if self.livePreviewEnabled {
                self.reloadFromDisk(silent: true)
            } else {
                self.statusMessage = self.copy.externalChangesAvailable
            }
        }
    }

    private func modificationDate(for url: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }

    private func addRecentFile(_ url: URL) {
        var urls = [url] + recentFiles.map(\.url).filter { $0 != url }
        urls = Array(urls.prefix(12))
        recentFiles = urls.map(RecentFile.init(url:))
        UserDefaults.standard.set(urls.map(\.path), forKey: Keys.recentFiles)
    }

    private func loadRecentFiles() {
        let paths = UserDefaults.standard.stringArray(forKey: Keys.recentFiles) ?? []
        recentFiles = paths
            .map(URL.init(fileURLWithPath:))
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map(RecentFile.init(url:))
    }

    private func observeAppEvents() {
        let observer = NotificationCenter.default.addObserver(
            forName: .jzOpenMarkdownURLs,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let urls = notification.object as? [URL], let first = urls.first else { return }
            self?.openURL(first)
        }
        observers.append(observer)
    }

    private func presentError(message: String, detail: String) {
        statusMessage = message
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.alertStyle = .warning
        alert.runModal()
    }
}

private extension URL {
    func conforms(to type: UTType) -> Bool {
        guard let ownType = UTType(filenameExtension: pathExtension) else { return false }
        return ownType.conforms(to: type)
    }
}
