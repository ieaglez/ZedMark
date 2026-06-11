import AppKit
import SwiftUI
import WebKit

struct PreviewFindRequest: Equatable {
    enum Action: Equatable {
        case update
        case next
        case previous
        case clear
    }

    var query: String
    var action: Action
    var generation: Int
}

struct WebPreview: NSViewRepresentable {
    var html: String
    var documentPath: String?
    var scrollTarget: String?
    var zoom: Double
    var restoreScrollY: Double
    var findRequest: PreviewFindRequest?
    var onState: ((Double, String?) -> Void)?
    var onFindResult: ((Int, Int) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController.add(
            WeakScriptMessageHandler(delegate: context.coordinator),
            name: "zmState"
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.pageZoom = zoom
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        context.coordinator.onState = onState
        context.coordinator.onFindResult = onFindResult
        context.coordinator.update(
            html: html,
            documentPath: documentPath,
            scrollTarget: scrollTarget,
            restoreScrollY: restoreScrollY,
            in: webView
        )
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.pageZoom != zoom {
            webView.pageZoom = zoom
        }
        context.coordinator.onState = onState
        context.coordinator.onFindResult = onFindResult
        context.coordinator.update(
            html: html,
            documentPath: documentPath,
            scrollTarget: scrollTarget,
            restoreScrollY: restoreScrollY,
            in: webView
        )
        context.coordinator.applyFind(findRequest, in: webView)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "zmState")
        webView.navigationDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onState: ((Double, String?) -> Void)?
        var onFindResult: ((Int, Int) -> Void)?

        private var loadedHTML = ""
        private var loadedDocumentPath: String?
        private var pendingScrollTarget: String?
        private var lastScrollTarget: String?
        private var pendingRestoreY: Double?
        private var lastKnownScrollY: Double = 0
        private var activeFindQuery = ""
        private var lastFindGeneration = -1

        func update(
            html: String,
            documentPath: String?,
            scrollTarget: String?,
            restoreScrollY: Double,
            in webView: WKWebView
        ) {
            if loadedHTML != html {
                let isSameDocument = documentPath != nil && documentPath == loadedDocumentPath
                // Live reloads keep the reading position; a newly opened
                // document restores its last saved position.
                pendingRestoreY = isSameDocument ? lastKnownScrollY : restoreScrollY
                if !isSameDocument {
                    lastKnownScrollY = restoreScrollY
                }
                loadedHTML = html
                loadedDocumentPath = documentPath
                pendingScrollTarget = scrollTarget
                // TestFlight/App Store sandboxing can leave WebKit blank when a
                // user-selected file URL is used as the HTML base URL, so local
                // images are inlined as data URIs at render time instead.
                webView.loadHTMLString(html, baseURL: nil)
                return
            }

            if let scrollTarget, scrollTarget != lastScrollTarget {
                scroll(to: scrollTarget, in: webView)
            }
        }

        func applyFind(_ request: PreviewFindRequest?, in webView: WKWebView) {
            guard let request, request.generation != lastFindGeneration else { return }
            lastFindGeneration = request.generation

            let script: String
            switch request.action {
            case .update:
                activeFindQuery = request.query
                script = "window.__zmFind(\(Self.jsStringLiteral(request.query)))"
            case .next:
                script = "window.__zmFindNav(1)"
            case .previous:
                script = "window.__zmFindNav(-1)"
            case .clear:
                activeFindQuery = ""
                script = "window.__zmFindClear()"
            }
            runFindScript(script, in: webView)
        }

        private func runFindScript(_ script: String, in webView: WKWebView) {
            webView.evaluateJavaScript(script) { [weak self] result, _ in
                guard let self, let values = result as? [Any], values.count == 2,
                      let current = (values[0] as? NSNumber)?.intValue,
                      let total = (values[1] as? NSNumber)?.intValue
                else { return }
                self.onFindResult?(current, total)
            }
        }

        // MARK: WKScriptMessageHandler

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "zmState",
                  let payload = message.body as? [String: Any]
            else { return }
            let y = (payload["y"] as? NSNumber)?.doubleValue ?? 0
            let heading = payload["h"] as? String
            lastKnownScrollY = y
            onState?(y, (heading?.isEmpty ?? true) ? nil : heading)
        }

        // MARK: WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let target = pendingScrollTarget {
                scroll(to: target, in: webView)
                pendingScrollTarget = nil
                pendingRestoreY = nil
            } else if let y = pendingRestoreY, y > 0 {
                webView.evaluateJavaScript("window.scrollTo({ top: \(y), behavior: 'instant' });")
                pendingRestoreY = nil
            }

            if !activeFindQuery.isEmpty {
                runFindScript("window.__zmFind(\(Self.jsStringLiteral(activeFindQuery)))", in: webView)
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url
            else {
                decisionHandler(.allow)
                return
            }

            let scheme = url.scheme?.lowercased()

            // In-page anchors (the document is loaded as about:blank).
            if url.fragment != nil, scheme == "about" || scheme == "file" {
                decisionHandler(.allow)
                return
            }

            if ["http", "https", "mailto"].contains(scheme) {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            // Never launch local files from document links — reveal them instead.
            if scheme == "file" {
                NSWorkspace.shared.activateFileViewerSelecting([url])
                decisionHandler(.cancel)
                return
            }

            // Unknown schemes (javascript:, custom protocols, ...) are dropped.
            decisionHandler(.cancel)
        }

        private func scroll(to id: String, in webView: WKWebView) {
            lastScrollTarget = id
            let escaped = id
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let script = "document.getElementById('\(escaped)')?.scrollIntoView({ behavior: 'smooth', block: 'start' });"
            webView.evaluateJavaScript(script)
        }

        private static func jsStringLiteral(_ value: String) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: [value]),
                  let json = String(data: data, encoding: .utf8),
                  json.count >= 2
            else {
                return "\"\""
            }
            return String(json.dropFirst().dropLast())
        }
    }
}

/// Breaks the retain cycle between WKUserContentController and its handler.
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
