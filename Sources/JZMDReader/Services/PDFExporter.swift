import Foundation
import WebKit

final class PDFExporter: NSObject, WKNavigationDelegate {
    enum ExportError: LocalizedError {
        case missingWebView
        case noData

        var errorDescription: String? {
            switch self {
            case .missingWebView:
                return "The preview renderer was not available."
            case .noData:
                return "The PDF renderer returned no data."
            }
        }
    }

    private var webView: WKWebView?
    private var destination: URL?
    private var completion: ((Result<URL, Error>) -> Void)?

    func export(
        html: String,
        baseURL: URL?,
        to destination: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        self.destination = destination
        self.completion = completion

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 900, height: 1200))
        webView.navigationDelegate = self
        self.webView = webView
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)") { [weak self] result, _ in
            guard let self, let destination = self.destination else { return }
            let measuredHeight: CGFloat
            if let value = result as? Double {
                measuredHeight = CGFloat(value)
            } else if let value = result as? NSNumber {
                measuredHeight = CGFloat(truncating: value)
            } else {
                measuredHeight = 1200
            }
            let height = max(1200, measuredHeight)
            webView.frame = CGRect(x: 0, y: 0, width: 900, height: height)

            let configuration = WKPDFConfiguration()
            configuration.rect = CGRect(x: 0, y: 0, width: 900, height: height)
            webView.createPDF(configuration: configuration) { result in
                switch result {
                case .success(let data):
                    do {
                        guard !data.isEmpty else { throw ExportError.noData }
                        try data.write(to: destination, options: .atomic)
                        self.completion?(.success(destination))
                    } catch {
                        self.completion?(.failure(error))
                    }
                case .failure(let error):
                    self.completion?(.failure(error))
                }
                self.cleanup()
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completion?(.failure(error))
        cleanup()
    }

    private func cleanup() {
        webView?.navigationDelegate = nil
        webView = nil
        destination = nil
        completion = nil
    }
}
