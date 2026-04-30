import AppKit
import SwiftUI
import WebKit

struct WebPreview: NSViewRepresentable {
    var html: String
    var baseURL: URL?
    var scrollTarget: String?
    var zoom: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.pageZoom = zoom
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.update(html: html, baseURL: baseURL, scrollTarget: scrollTarget, in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.pageZoom != zoom {
            webView.pageZoom = zoom
        }
        context.coordinator.update(html: html, baseURL: baseURL, scrollTarget: scrollTarget, in: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var loadedHTML = ""
        private var pendingScrollTarget: String?
        private var lastScrollTarget: String?

        func update(html: String, baseURL: URL?, scrollTarget: String?, in webView: WKWebView) {
            if loadedHTML != html {
                loadedHTML = html
                pendingScrollTarget = scrollTarget
                webView.loadHTMLString(html, baseURL: baseURL)
                return
            }

            if let scrollTarget, scrollTarget != lastScrollTarget {
                scroll(to: scrollTarget, in: webView)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let target = pendingScrollTarget {
                scroll(to: target, in: webView)
                pendingScrollTarget = nil
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
            if url.fragment != nil, scheme == "file" || scheme == "about" {
                decisionHandler(.allow)
                return
            }

            if ["http", "https", "mailto"].contains(scheme) || scheme == "file" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        private func scroll(to id: String, in webView: WKWebView) {
            lastScrollTarget = id
            let escaped = id
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let script = "document.getElementById('\(escaped)')?.scrollIntoView({ behavior: 'smooth', block: 'start' });"
            webView.evaluateJavaScript(script)
        }
    }
}
