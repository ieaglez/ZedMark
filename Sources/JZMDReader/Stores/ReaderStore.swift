import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers
#if canImport(JZMDReaderCore)
import JZMDReaderCore
#endif

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
    var bookmarkData: Data?
    var id: String { url.path }
    var title: String { url.lastPathComponent }
    var folder: String { url.deletingLastPathComponent().path }
}

private struct StoredRecentFile: Codable {
    var path: String
    var bookmarkData: Data?
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
    @Published var activeHeadingID: String?
    @Published var recentFiles: [RecentFile] = []
    @Published var statusMessage = AppCopy(language: .english).ready
    @Published var exportFeedback: ExportFeedback = .idle
    @Published var lastExport: ExportRecord?
    @Published var isDropTargeted = false
    @Published var imagesNeedFolderAccess = false

    @Published var isFindBarVisible = false
    @Published var findQuery = "" {
        didSet {
            guard oldValue != findQuery else { return }
            pushFind(.update)
        }
    }
    @Published private(set) var findRequest: PreviewFindRequest?
    @Published private(set) var findCurrent = 0
    @Published private(set) var findTotal = 0

    @Published var theme: ReaderTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme)
            applyThemeToCachedParse()
        }
    }

    @Published var showInspector: Bool {
        didSet { UserDefaults.standard.set(showInspector, forKey: Keys.showInspector) }
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
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
            statusMessage = document == nil ? copy.ready : copy.livePreviewOn
        }
    }

    var copy: AppCopy { AppCopy(language: language) }
    var zoomPercentText: String { "\(Int((previewZoom * 100).rounded()))%" }
    var canZoomIn: Bool { previewZoom < Self.maxZoom }
    var canZoomOut: Bool { previewZoom > Self.minZoom }

    // The on-screen 100% renders the page at this scale, so the comfortable
    // reading size is the default. Export keeps the document's native size.
    static let zoomDisplayBase = 0.80
    var effectiveZoom: Double { previewZoom * Self.zoomDisplayBase }

    private static let minZoom = 0.60
    private static let maxZoom = 2.00
    private static let zoomStep = 0.10

    private enum Keys {
        static let theme = "JZMDReader.theme"
        static let showInspector = "JZMDReader.showInspector"
        static let showSidebar = "ZedMark.showSidebar"
        static let previewZoom = "ZedMark.previewZoom"
        static let language = "ZedMark.language"
        static let recentFiles = "JZMDReader.recentFiles"
        static let scrollPositions = "ZedMark.scrollPositions"
        static let folderBookmarks = "ZedMark.imageFolderBookmarks"
    }

    private let renderer = MarkdownRenderer()
    private let renderQueue = DispatchQueue(label: "com.jeffzhang.ZedMark.render", qos: .userInitiated)
    private var parseGeneration = 0
    private var cachedParse: MarkdownParseResult?
    private var watcher: FileWatcher?
    private var pdfExporter: PDFExporter?
    private var activeSecurityScopedURL: URL?
    private var activeFolderScopeURL: URL?
    private var observers: [NSObjectProtocol] = []
    private var findGeneration = 0
    private var scrollPositions: [String: Double] = [:]
    private var persistScrollWork: DispatchWorkItem?
    private var folderBookmarks: [String: Data] = [:]

    /// Restore target for the most recently opened document.
    private(set) var restoreScrollY: Double = 0

    init() {
        let defaults = UserDefaults.standard
        theme = ReaderTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .claude
        showInspector = defaults.object(forKey: Keys.showInspector) as? Bool ?? true
        showSidebar = defaults.object(forKey: Keys.showSidebar) as? Bool ?? true
        previewZoom = Self.clampedZoom(defaults.object(forKey: Keys.previewZoom) as? Double ?? 1.0)
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .english
        statusMessage = copy.ready
        scrollPositions = defaults.dictionary(forKey: Keys.scrollPositions) as? [String: Double] ?? [:]
        folderBookmarks = defaults.dictionary(forKey: Keys.folderBookmarks) as? [String: Data] ?? [:]
        loadRecentFiles()
        pruneScrollPositions()
        observeAppEvents()
    }

    deinit {
        watcher?.stop()
        persistScrollWork?.cancel()
        persistScrollPositions()
        activeSecurityScopedURL?.stopAccessingSecurityScopedResource()
        activeFolderScopeURL?.stopAccessingSecurityScopedResource()
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
            activateSecurityScope(for: url)
            activateFolderScopeIfBookmarked(for: url)
            let text = try readText(url: url)
            let modified = modificationDate(for: url)
            document = MarkdownDocument(url: url, text: text, lastModified: modified)
            selectedHeadingID = nil
            activeHeadingID = nil
            restoreScrollY = scrollPositions[url.standardizedFileURL.path] ?? 0
            renderDocument()
            addRecentFile(url)
            configureWatcher(for: url)
            statusMessage = copy.livePreviewOn
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
        openURL(resolvedURL(for: file) ?? file.url)
    }


    func dismissExportFeedback() {
        exportFeedback = .idle
        statusMessage = document == nil ? copy.ready : copy.livePreviewOn
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

        let didStartAccessingDestination = destination.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessingDestination {
                destination.stopAccessingSecurityScopedResource()
            }
        }

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

        let didStartAccessingDestination = destination.startAccessingSecurityScopedResource()
        let exporter = PDFExporter()
        pdfExporter = exporter
        exporter.export(html: renderResult.html, baseURL: baseURL, to: destination) { [weak self] result in
            if didStartAccessingDestination {
                destination.stopAccessingSecurityScopedResource()
            }
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

    private func activateSecurityScope(for url: URL) {
        let standardizedURL = url.standardizedFileURL
        if activeSecurityScopedURL?.standardizedFileURL == standardizedURL {
            return
        }

        activeSecurityScopedURL?.stopAccessingSecurityScopedResource()
        activeSecurityScopedURL = nil

        if standardizedURL.startAccessingSecurityScopedResource() {
            activeSecurityScopedURL = standardizedURL
        }
    }

    private func bookmarkData(for url: URL) -> Data? {
        try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    private func resolvedURL(for file: RecentFile) -> URL? {
        guard let bookmarkData = file.bookmarkData else { return file.url }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return url
        } catch {
            return FileManager.default.fileExists(atPath: file.url.path) ? file.url : nil
        }
    }

    private func renderDocument() {
        guard let document else {
            cachedParse = nil
            imagesNeedFolderAccess = false
            renderResult = .empty
            return
        }

        parseGeneration += 1
        let generation = parseGeneration
        let text = document.text
        let theme = self.theme
        let base = baseURL
        let renderer = self.renderer

        // Parsing (and image inlining) runs off the main thread; a generation
        // counter drops stale results when the document changes mid-flight.
        renderQueue.async { [weak self] in
            let parsed = renderer.parse(markdown: text, baseURL: base)
            let html = MarkdownRenderer.documentHTML(body: parsed.body, theme: theme)
            DispatchQueue.main.async {
                guard let self, generation == self.parseGeneration else { return }
                self.cachedParse = parsed
                self.imagesNeedFolderAccess = parsed.needsFolderAccessForImages
                self.renderResult = MarkdownRenderResult(
                    html: html,
                    headings: parsed.headings,
                    stats: parsed.stats,
                    diagnostics: parsed.diagnostics
                )
                if parsed.needsFolderAccessForImages {
                    self.statusMessage = self.copy.imagesNeedAccess
                }
            }
        }
    }

    /// Theme switches restyle the cached parse instead of re-parsing.
    private func applyThemeToCachedParse() {
        guard let parsed = cachedParse else {
            renderDocument()
            return
        }
        renderResult = MarkdownRenderResult(
            html: MarkdownRenderer.documentHTML(body: parsed.body, theme: theme),
            headings: parsed.headings,
            stats: parsed.stats,
            diagnostics: parsed.diagnostics
        )
    }

    // MARK: - Preview state (scroll position + outline tracking)

    func handlePreviewState(scrollY: Double, headingID: String?) {
        if activeHeadingID != headingID {
            activeHeadingID = headingID
        }
        guard let path = document?.url.standardizedFileURL.path else { return }
        scrollPositions[path] = scrollY
        schedulePersistScrollPositions()
    }

    private func schedulePersistScrollPositions() {
        persistScrollWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.persistScrollPositions()
        }
        persistScrollWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func persistScrollPositions() {
        UserDefaults.standard.set(scrollPositions, forKey: Keys.scrollPositions)
    }

    private func pruneScrollPositions() {
        guard scrollPositions.count > 80 else { return }
        let keep = Set(recentFiles.map { $0.url.standardizedFileURL.path })
        scrollPositions = scrollPositions.filter { keep.contains($0.key) }
        persistScrollPositions()
    }

    // MARK: - Find in document

    func showFindBar() {
        guard document != nil else { return }
        isFindBarVisible = true
        if !findQuery.isEmpty {
            pushFind(.update)
        }
    }

    func hideFindBar() {
        isFindBarVisible = false
        if findQuery.isEmpty {
            pushFind(.clear)
        } else {
            findQuery = ""
        }
    }

    func findNext() {
        pushFind(.next)
    }

    func findPrevious() {
        pushFind(.previous)
    }

    func handleFindResult(current: Int, total: Int) {
        findCurrent = current
        findTotal = total
    }

    private func pushFind(_ action: PreviewFindRequest.Action) {
        findGeneration += 1
        let resolvedAction: PreviewFindRequest.Action = findQuery.isEmpty && action == .update ? .clear : action
        findRequest = PreviewFindRequest(query: findQuery, action: resolvedAction, generation: findGeneration)
        if resolvedAction == .clear {
            findCurrent = 0
            findTotal = 0
        }
    }

    // MARK: - Copy HTML

    func copyHTML() {
        guard document != nil else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(renderResult.html, forType: .html)
        pasteboard.setString(renderResult.html, forType: .string)
        statusMessage = copy.copiedHTML
    }

    // MARK: - Image folder access (sandbox)

    /// The sandbox only grants access to the opened file, so sibling images
    /// need a one-time folder grant, remembered via security-scoped bookmark.
    func grantImageFolderAccess() {
        guard let folder = baseURL else { return }
        let panel = NSOpenPanel()
        panel.title = copy.grantFolderAccess
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = folder

        guard panel.runModal() == .OK, let chosen = panel.url else { return }

        if let bookmark = try? chosen.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            folderBookmarks[chosen.standardizedFileURL.path] = bookmark
            UserDefaults.standard.set(folderBookmarks, forKey: Keys.folderBookmarks)
        }
        activateFolderScope(chosen)
        renderDocument()
    }

    private func activateFolderScope(_ url: URL) {
        activeFolderScopeURL?.stopAccessingSecurityScopedResource()
        activeFolderScopeURL = nil
        if url.startAccessingSecurityScopedResource() {
            activeFolderScopeURL = url
        }
    }

    private func activateFolderScopeIfBookmarked(for fileURL: URL) {
        let folderPath = fileURL.standardizedFileURL.deletingLastPathComponent().path
        for (path, bookmark) in folderBookmarks {
            guard folderPath == path || folderPath.hasPrefix(path + "/") else { continue }
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                activateFolderScope(url)
                return
            }
        }
    }

    private func configureWatcher(for url: URL) {
        watcher?.stop()
        watcher = FileWatcher(url: url) { [weak self] in
            // Preview always tracks the file on disk.
            self?.reloadFromDisk(silent: true)
        }
    }

    private func modificationDate(for url: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }

    private func addRecentFile(_ url: URL) {
        let current = RecentFile(url: url.standardizedFileURL, bookmarkData: bookmarkData(for: url))
        var files = [current] + recentFiles.filter { $0.url.standardizedFileURL != current.url.standardizedFileURL }
        files = Array(files.prefix(12))
        recentFiles = files
        persistRecentFiles()
    }

    private func persistRecentFiles() {
        let records = recentFiles.map { StoredRecentFile(path: $0.url.path, bookmarkData: $0.bookmarkData) }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Keys.recentFiles)
        }
    }

    private func loadRecentFiles() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.recentFiles),
           let records = try? JSONDecoder().decode([StoredRecentFile].self, from: data) {
            recentFiles = records.compactMap { record in
                let fallbackURL = URL(fileURLWithPath: record.path)
                let resolved = resolvedURL(for: RecentFile(url: fallbackURL, bookmarkData: record.bookmarkData)) ?? fallbackURL
                guard FileManager.default.fileExists(atPath: resolved.path) else { return nil }
                return RecentFile(url: resolved, bookmarkData: record.bookmarkData)
            }
            return
        }

        let paths = defaults.stringArray(forKey: Keys.recentFiles) ?? []
        recentFiles = paths
            .map(URL.init(fileURLWithPath:))
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map { RecentFile(url: $0, bookmarkData: bookmarkData(for: $0)) }
        persistRecentFiles()
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
