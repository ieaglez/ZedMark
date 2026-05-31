import Foundation

public struct MarkdownRenderer {
    public init() {}

    public func render(markdown: String, theme: ReaderTheme) -> MarkdownRenderResult {
        let parser = Parser(markdown: markdown)
        let body = parser.renderBody()
        let stats = makeStats(markdown: markdown, headings: parser.headings.count)
        let diagnostics = makeDiagnostics(markdown: markdown)

        return MarkdownRenderResult(
            html: Self.documentHTML(body: body, theme: theme),
            headings: parser.headings,
            stats: stats,
            diagnostics: diagnostics
        )
    }

    public static func emptyHTML(theme: ReaderTheme) -> String {
        documentHTML(body: "", theme: theme)
    }

    public static func documentHTML(body: String, theme: ReaderTheme) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
          :root {
            \(theme.cssVariables)
          }

          html {
            background: var(--bg);
            color: var(--text);
            scroll-behavior: smooth;
          }

          * { box-sizing: border-box; }

          body {
            margin: 0;
            max-width: none;
            min-height: 100vh;
            padding: 52px 60px 96px;
            background: var(--page);
            color: var(--text);
            font-family: \(theme.bodyFont);
            font-size: 16px;
            line-height: 1.72;
            -webkit-font-smoothing: antialiased;
            text-rendering: optimizeLegibility;
            font-feature-settings: "kern", "liga", "calt";
            font-variant-ligatures: common-ligatures;
            word-wrap: break-word;
          }

          ::selection {
            background: var(--accent-soft);
            color: var(--text);
          }

          h1, h2, h3, h4, h5, h6 {
            margin: 1.7em 0 0.5em;
            line-height: 1.18;
            color: var(--text);
            letter-spacing: 0;
            font-weight: 680;
          }

          h1 {
            margin-top: 0;
            font-size: 2.08rem;
            padding-bottom: 0.38em;
            border-bottom: 1px solid var(--border);
          }
          h2 {
            font-size: 1.46rem;
            padding-bottom: 0.24em;
            border-bottom: 1px solid var(--border-soft);
          }
          h3 {
            font-size: 1.18rem;
            color: var(--heading-3, var(--accent-cool));
            font-weight: 650;
          }
          h4 { font-size: 1.02rem; }
          h5, h6 {
            font-size: 0.78rem;
            color: var(--muted);
            text-transform: uppercase;
            font-family: ui-monospace, "SF Mono", Menlo, Consolas, "PingFang SC", monospace;
          }

          p { margin: 0.86em 0; }
          a {
            color: var(--accent-cool);
            text-decoration-thickness: 0.08em;
            text-underline-offset: 0.18em;
          }
          strong { font-weight: 700; }
          em { font-style: italic; }
          del { color: var(--muted); }
          mark {
            padding: 0.08em 0.22em;
            border-radius: 4px;
            background: var(--amber-bg);
            color: var(--text);
            box-decoration-break: clone;
            -webkit-box-decoration-break: clone;
          }

          .heading-anchor {
            opacity: 0;
            margin-left: -1.15em;
            padding-right: 0.32em;
            color: var(--faint);
            text-decoration: none;
          }
          h1:hover .heading-anchor,
          h2:hover .heading-anchor,
          h3:hover .heading-anchor,
          h4:hover .heading-anchor,
          h5:hover .heading-anchor,
          h6:hover .heading-anchor { opacity: 1; }

          blockquote {
            margin: 1.22em 0;
            padding: 0.4em 1.05em;
            border-left: 3px solid var(--accent);
            color: var(--muted);
            background: var(--quote);
            border-radius: 0 7px 7px 0;
          }

          .callout {
            --callout-color: var(--accent-cool);
            --callout-bg: var(--accent-soft);
            --callout-border: var(--accent);
            margin: 1.3em 0;
            padding: 0.92em 1em;
            border: 1px solid var(--callout-border);
            border-left: 4px solid var(--callout-color);
            border-radius: 8px;
            background: var(--callout-bg);
            /* Callout backgrounds are always light tints, so keep text dark and legible on every theme. */
            color: #353b45;
          }
          .callout p { color: #353b45; }
          .callout-blue {
            --callout-color: var(--blue);
            --callout-bg: var(--blue-bg);
            --callout-border: var(--blue-border);
          }
          .callout-green {
            --callout-color: var(--green);
            --callout-bg: var(--green-bg);
            --callout-border: var(--green-border);
          }
          .callout-amber {
            --callout-color: var(--amber);
            --callout-bg: var(--amber-bg);
            --callout-border: var(--amber-border);
          }
          .callout-red {
            --callout-color: var(--red);
            --callout-bg: var(--red-bg);
            --callout-border: var(--red-border);
          }
          .callout-title {
            margin-bottom: 0.35em;
            font-weight: 700;
            color: var(--callout-color);
            font-family: ui-monospace, "SF Mono", Menlo, Consolas, "PingFang SC", monospace;
            font-size: 0.82rem;
          }

          code {
            padding: 0.14em 0.4em;
            border-radius: 5px;
            background: var(--code-bg);
            color: var(--accent-cool);
            font-family: ui-monospace, "SF Mono", "JetBrains Mono", Menlo, Consolas, "PingFang SC", "Hiragino Sans GB", monospace;
            font-size: 0.86em;
          }
          pre {
            overflow: auto;
            margin: 1.4em 0;
            padding: 1.05em 1.2em;
            border: 1px solid var(--border-soft);
            border-radius: 10px;
            background: var(--code-bg);
            line-height: 1.6;
          }
          pre code {
            padding: 0;
            border: 0;
            background: transparent;
            color: var(--text);
            font-size: 0.855em;
            line-height: 1.6;
          }

          ul, ol { padding-left: 1.55em; }
          li { margin: 0.28em 0; }
          li.task { list-style: none; margin-left: -1.35em; }
          input[type="checkbox"] {
            transform: translateY(1px);
            accent-color: var(--accent);
          }

          .table-wrap {
            margin: 1.5em 0;
            overflow-x: auto;
            border: 1px solid var(--border);
            border-radius: 10px;
          }
          table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            font-size: 0.93em;
            line-height: 1.55;
          }
          th, td {
            padding: 0.64em 0.9em;
            border-right: 1px solid var(--border-soft);
            border-bottom: 1px solid var(--border-soft);
            vertical-align: top;
            text-align: left;
          }
          th:last-child, td:last-child { border-right: 0; }
          tbody tr:last-child td { border-bottom: 0; }
          thead th {
            background: var(--code-bg);
            color: var(--text);
            font-weight: 640;
            letter-spacing: 0.005em;
            border-bottom: 1.5px solid var(--border);
            white-space: nowrap;
          }
          tbody tr:nth-child(even) td { background: rgba(130, 130, 130, 0.045); }
          tbody tr:hover td { background: var(--accent-soft); }

          hr {
            border: 0;
            border-top: 1px solid var(--border);
            margin: 2em 0;
          }

          img {
            max-width: 100%;
            height: auto;
            border-radius: 7px;
            border: 1px solid var(--border-soft);
          }

          .footnote-ref,
          sup { color: var(--accent); }

          @media (max-width: 760px) {
            body { padding: 32px 24px 54px; font-size: 16px; }
            h1 { font-size: 1.78rem; }
            h2 { font-size: 1.42rem; }
          }
          </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    private func makeStats(markdown: String, headings: Int) -> DocumentStats {
        let words = markdown
            .split { character in
                character.isWhitespace || character.isPunctuation
            }
            .count
        let minutes = words == 0 ? 0 : max(1, Int(ceil(Double(words) / 220.0)))
        return DocumentStats(
            words: words,
            characters: markdown.count,
            lines: markdown.split(separator: "\n", omittingEmptySubsequences: false).count,
            headings: headings,
            readingMinutes: minutes
        )
    }

    private func makeDiagnostics(markdown: String) -> [ProofDiagnostic] {
        var diagnostics: [ProofDiagnostic] = []
        let lines = markdown.components(separatedBy: .newlines)

        for (offset, line) in lines.enumerated() {
            if let match = line.firstMatch(pattern: #"(?i)\b([a-z]{3,})\s+\1\b"#) {
                diagnostics.append(
                    ProofDiagnostic(
                        id: "repeat-\(offset)-\(match)",
                        kind: .repeatedWord,
                        title: "Repeated word",
                        detail: match,
                        line: offset + 1
                    )
                )
            }

            if line.range(of: #"(?i)\b(TODO|FIXME|XXX)\b"#, options: .regularExpression) != nil {
                diagnostics.append(
                    ProofDiagnostic(
                        id: "task-\(offset)",
                        kind: .taskMarker,
                        title: "Task marker",
                        detail: line.trimmingCharacters(in: .whitespaces),
                        line: offset + 1
                    )
                )
            }
        }

        let sentences = markdown.components(separatedBy: CharacterSet(charactersIn: ".?!\n"))
        for (offset, sentence) in sentences.enumerated() {
            let count = sentence.split { $0.isWhitespace || $0.isPunctuation }.count
            guard count >= 45 else { continue }
            diagnostics.append(
                ProofDiagnostic(
                    id: "long-\(offset)",
                    kind: .longSentence,
                    title: "Long sentence",
                    detail: "\(count) words",
                    line: nil
                )
            )
        }

        return Array(diagnostics.prefix(12))
    }
}

private final class Parser {
    private let lines: [String]
    private var index = 0
    private var usedSlugs: [String: Int] = [:]
    private(set) var headings: [MarkdownHeading] = []

    init(markdown: String) {
        self.lines = markdown.components(separatedBy: .newlines)
    }

    func renderBody() -> String {
        var html: [String] = []

        while index < lines.count {
            let line = lines[index]

            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                index += 1
                continue
            }

            if let block = renderFrontMatter() {
                html.append(block)
            } else if let block = renderCodeFence() {
                html.append(block)
            } else if let block = renderHeading() {
                html.append(block)
            } else if let block = renderHorizontalRule() {
                html.append(block)
            } else if let block = renderTable() {
                html.append(block)
            } else if let block = renderBlockquote() {
                html.append(block)
            } else if let block = renderList() {
                html.append(block)
            } else {
                html.append(renderParagraph())
            }
        }

        return html.joined(separator: "\n")
    }

    private func renderFrontMatter() -> String? {
        guard index == 0, lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return nil
        }

        var content: [String] = []
        index += 1
        while index < lines.count {
            let line = lines[index]
            index += 1
            if line.trimmingCharacters(in: .whitespaces) == "---" { break }
            content.append(escapeHTML(line))
        }

        guard !content.isEmpty else { return "" }
        return "<pre><code>\(content.joined(separator: "\n"))</code></pre>"
    }

    private func renderCodeFence() -> String? {
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") else { return nil }

        let fence = String(trimmed.prefix(3))
        let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        var body: [String] = []
        index += 1

        while index < lines.count {
            let line = lines[index]
            index += 1
            if line.trimmingCharacters(in: .whitespaces).hasPrefix(fence) { break }
            body.append(escapeHTML(line))
        }

        let className = language.isEmpty ? "" : #" class="language-\#(escapeAttribute(language))""#
        return "<pre><code\(className)>\(body.joined(separator: "\n"))</code></pre>"
    }

    private func renderHeading() -> String? {
        let line = lines[index]
        guard let match = line.match(pattern: #"^(#{1,6})\s+(.+?)(?:\s+#+)?$"#),
              match.count > 2,
              let marker = match[1],
              let title = match[2]
        else {
            return nil
        }

        let level = marker.count
        let cleanTitle = stripInlineMarkdown(title)
        let slug = uniqueSlug(cleanTitle)
        let heading = MarkdownHeading(id: slug, title: cleanTitle, level: level, line: index + 1)
        headings.append(heading)
        index += 1

        return """
        <h\(level) id="\(escapeAttribute(slug))"><a class="heading-anchor" href="#\(escapeAttribute(slug))">#</a>\(inlineHTML(title))</h\(level)>
        """
    }

    private func renderHorizontalRule() -> String? {
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        guard trimmed.range(of: #"^([-*_])(?:\s*\1){2,}$"#, options: .regularExpression) != nil else {
            return nil
        }
        index += 1
        return "<hr>"
    }

    private func renderTable() -> String? {
        guard index + 1 < lines.count,
              lines[index].contains("|"),
              isTableSeparator(lines[index + 1])
        else {
            return nil
        }

        let headers = tableCells(lines[index])
        index += 2

        var rows: [[String]] = []
        while index < lines.count, lines[index].contains("|"), !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
            rows.append(tableCells(lines[index]))
            index += 1
        }

        let headerHTML = headers.map { "<th>\(inlineHTML($0))</th>" }.joined()
        let bodyHTML = rows.map { row in
            "<tr>\(row.map { "<td>\(inlineHTML($0))</td>" }.joined())</tr>"
        }.joined(separator: "\n")

        return """
        <div class="table-wrap">
        <table>
          <thead><tr>\(headerHTML)</tr></thead>
          <tbody>
          \(bodyHTML)
          </tbody>
        </table>
        </div>
        """
    }

    private func renderBlockquote() -> String? {
        guard lines[index].trimmingCharacters(in: .whitespaces).hasPrefix(">") else {
            return nil
        }

        var content: [String] = []
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(">") else { break }
            let text = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
            content.append(String(text))
            index += 1
        }

        if let first = content.first,
           let match = first.match(pattern: #"^\[!(\w+)\]\s*(.*)$"#),
           match.count > 1,
           let type = match[1] {
            let titleSuffix = match.count > 2 ? (match[2] ?? "").trimmingCharacters(in: .whitespaces) : ""
            let title = titleSuffix.isEmpty ? type.capitalized : "\(type.capitalized): \(titleSuffix)"
            let body = content.dropFirst().map { "<p>\(inlineHTML($0))</p>" }.joined()
            let className = calloutClass(for: type)
            return """
            <div class="callout \(className)">
              <div class="callout-title">\(escapeHTML(title))</div>
              \(body)
            </div>
            """
        }

        let body = content.map { "<p>\(inlineHTML($0))</p>" }.joined()
        return "<blockquote>\(body)</blockquote>"
    }

    private func renderList() -> String? {
        let line = lines[index]
        let isOrdered = line.range(of: #"^\s*\d+\.\s+"#, options: .regularExpression) != nil
        let isUnordered = line.range(of: #"^\s*[-*+]\s+"#, options: .regularExpression) != nil
        guard isOrdered || isUnordered else { return nil }

        let tag = isOrdered ? "ol" : "ul"
        var items: [String] = []

        while index < lines.count {
            let current = lines[index]
            let pattern = isOrdered ? #"^\s*\d+\.\s+(.*)$"# : #"^\s*[-*+]\s+(.*)$"#
            guard let match = current.match(pattern: pattern), match.count > 1, let item = match[1] else {
                break
            }
            let taskPattern = #"^\[( |x|X)\]\s+(.*)$"#
            if let task = item.match(pattern: taskPattern), task.count > 2, let checked = task[1], let text = task[2] {
                let checkedAttribute = checked.lowercased() == "x" ? " checked" : ""
                items.append(#"<li class="task"><input type="checkbox" disabled\#(checkedAttribute)> \#(inlineHTML(text))</li>"#)
            } else {
                items.append("<li>\(inlineHTML(item))</li>")
            }
            index += 1
        }

        return "<\(tag)>\n\(items.joined(separator: "\n"))\n</\(tag)>"
    }

    private func renderParagraph() -> String {
        var parts: [String] = []

        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }
            if isBlockStart(line, lookahead: index + 1 < lines.count ? lines[index + 1] : nil), !parts.isEmpty {
                break
            }
            parts.append(line)
            index += 1
        }

        return "<p>\(inlineHTML(parts.joined(separator: " ")))</p>"
    }

    private func isBlockStart(_ line: String, lookahead: String?) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") || trimmed.hasPrefix(">") {
            return true
        }
        if line.range(of: #"^(#{1,6})\s+"#, options: .regularExpression) != nil {
            return true
        }
        if line.range(of: #"^\s*([-*+]|\d+\.)\s+"#, options: .regularExpression) != nil {
            return true
        }
        if trimmed.range(of: #"^([-*_])(?:\s*\1){2,}$"#, options: .regularExpression) != nil {
            return true
        }
        if let lookahead, line.contains("|"), isTableSeparator(lookahead) {
            return true
        }
        return false
    }

    private func uniqueSlug(_ text: String) -> String {
        let base = slugify(text)
        let current = usedSlugs[base, default: 0]
        usedSlugs[base] = current + 1
        return current == 0 ? base : "\(base)-\(current + 1)"
    }

    private func slugify(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        var slug = ""
        var needsDash = false

        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                if needsDash, !slug.isEmpty { slug.append("-") }
                slug.append(String(scalar).lowercased())
                needsDash = false
            } else if !slug.isEmpty {
                needsDash = true
            }
        }

        return slug.isEmpty ? "heading" : slug
    }
}

private func isTableSeparator(_ line: String) -> Bool {
    let cells = tableCells(line)
    guard !cells.isEmpty else { return false }
    return cells.allSatisfy { cell in
        cell.range(of: #"^:?-{3,}:?$"#, options: .regularExpression) != nil
    }
}

private func tableCells(_ line: String) -> [String] {
    var trimmed = line.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("|") { trimmed.removeFirst() }
    if trimmed.hasSuffix("|") { trimmed.removeLast() }
    return trimmed.split(separator: "|", omittingEmptySubsequences: false)
        .map { String($0).trimmingCharacters(in: .whitespaces) }
}

private func calloutClass(for type: String) -> String {
    switch type.lowercased() {
    case "success", "done", "check", "conclusion", "verified", "recommend", "recommendation", "action":
        return "callout-green"
    case "warning", "warn", "important", "attention", "todo", "review":
        return "callout-amber"
    case "danger", "error", "risk", "fail", "failure", "avoid", "bug":
        return "callout-red"
    default:
        return "callout-blue"
    }
}

private func inlineHTML(_ text: String) -> String {
    var placeholders: [String] = []
    var working = text.replacingMatches(pattern: #"`([^`]+)`"#) { match, source in
        guard let value = match.capture(1, in: source) else { return match.fullMatch(in: source) }
        placeholders.append("<code>\(escapeHTML(value))</code>")
        return "%%CODE\(placeholders.count - 1)%%"
    }

    working = escapeHTML(working)
    working = working.replacingMatches(pattern: #"!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]+)")?\)"#) { match, source in
        let alt = match.capture(1, in: source) ?? ""
        let url = match.capture(2, in: source) ?? ""
        let title = match.capture(3, in: source)
        let titleHTML = title.map { #" title="\#(escapeAttribute($0))""# } ?? ""
        return #"<img src="\#(escapeAttribute(url))" alt="\#(escapeAttribute(alt))"\#(titleHTML)>"#
    }
    working = working.replacingMatches(pattern: #"\[([^\]]+)\]\(([^)\s]+)(?:\s+"([^"]+)")?\)"#) { match, source in
        let label = match.capture(1, in: source) ?? ""
        let url = match.capture(2, in: source) ?? ""
        let title = match.capture(3, in: source)
        let titleHTML = title.map { #" title="\#(escapeAttribute($0))""# } ?? ""
        return #"<a href="\#(escapeAttribute(url))"\#(titleHTML)>\#(label)</a>"#
    }
    working = working.replacingOccurrences(of: #"~~(.+?)~~"#, with: #"<del>$1</del>"#, options: .regularExpression)
    working = working.replacingOccurrences(of: #"==(.+?)=="#, with: #"<mark>$1</mark>"#, options: .regularExpression)
    working = working.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: #"<strong>$1</strong>"#, options: .regularExpression)
    working = working.replacingOccurrences(of: #"__(.+?)__"#, with: #"<strong>$1</strong>"#, options: .regularExpression)
    working = working.replacingOccurrences(of: #"(?<!\*)\*([^*\n]+)\*(?!\*)"#, with: #"<em>$1</em>"#, options: .regularExpression)
    working = working.replacingOccurrences(of: #"(?<!_)_([^_\n]+)_(?!_)"#, with: #"<em>$1</em>"#, options: .regularExpression)

    for (offset, html) in placeholders.enumerated() {
        working = working.replacingOccurrences(of: "%%CODE\(offset)%%", with: html)
    }

    return working
}

private func stripInlineMarkdown(_ text: String) -> String {
    var cleaned = text
    cleaned = cleaned.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
    cleaned = cleaned.replacingOccurrences(of: #"==(.+?)=="#, with: "$1", options: .regularExpression)
    cleaned = cleaned.replacingOccurrences(of: #"!\[([^\]]*)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
    cleaned = cleaned.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
    cleaned = cleaned.replacingOccurrences(of: #"[*_~#]"#, with: "", options: .regularExpression)
    return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func escapeHTML(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}

private func escapeAttribute(_ value: String) -> String {
    escapeHTML(value)
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}

private extension String {
    func firstMatch(pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range) else { return nil }
        return match.fullMatch(in: self)
    }

    func match(pattern: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range) else { return nil }
        return (0..<match.numberOfRanges).map { index in
            guard let range = Range(match.range(at: index), in: self) else { return nil }
            return String(self[range])
        }
    }

    func replacingMatches(
        pattern: String,
        transform: (NSTextCheckingResult, String) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        let nsString = self as NSString
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
        var result = self

        for match in matches.reversed() {
            guard let range = Range(match.range, in: result) else { continue }
            let replacement = transform(match, result)
            result.replaceSubrange(range, with: replacement)
        }

        return result
    }
}

private extension NSTextCheckingResult {
    func capture(_ index: Int, in source: String) -> String? {
        guard index < numberOfRanges,
              let range = Range(range(at: index), in: source)
        else {
            return nil
        }
        return String(source[range])
    }

    func fullMatch(in source: String) -> String {
        guard let range = Range(range, in: source) else { return "" }
        return String(source[range])
    }
}
