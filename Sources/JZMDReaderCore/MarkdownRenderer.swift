import Foundation

public struct MarkdownRenderer {
    public init() {}

    public func render(markdown: String, theme: ReaderTheme, baseURL: URL? = nil) -> MarkdownRenderResult {
        let parsed = parse(markdown: markdown, baseURL: baseURL)
        return MarkdownRenderResult(
            html: Self.documentHTML(body: parsed.body, theme: theme),
            headings: parsed.headings,
            stats: parsed.stats,
            diagnostics: parsed.diagnostics
        )
    }

    public func parse(markdown: String, baseURL: URL? = nil) -> MarkdownParseResult {
        let parser = Parser(markdown: markdown, baseURL: baseURL)
        let body = parser.renderBody()
        let stats = makeStats(markdown: markdown, headings: parser.headings.count)
        let diagnostics = makeDiagnostics(markdown: markdown)

        return MarkdownParseResult(
            body: body,
            headings: parser.headings,
            stats: stats,
            diagnostics: diagnostics,
            needsFolderAccessForImages: parser.missingImageAccess
        )
    }

    public static func emptyHTML(theme: ReaderTheme) -> String {
        documentHTML(body: "", theme: theme)
    }

    public static func documentHTML(body: String, theme: ReaderTheme) -> String {
        #"""
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
          :root {
            --tok-comment: #8a919c;
            --tok-string: #218a4d;
            --tok-number: #b45309;
            --tok-keyword: #176d80;
            \#(theme.cssVariables)
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
            font-family: \#(theme.bodyFont);
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

          mark.zm-find {
            padding: 0 0.06em;
            border-radius: 3px;
            background: var(--amber-bg);
            outline: 1px solid var(--amber-border);
          }
          mark.zm-find.zm-active {
            background: var(--accent);
            color: #ffffff;
            outline: none;
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

          .frontmatter {
            margin: 0 0 1.7em;
            padding: 0.85em 1.1em;
            border: 1px solid var(--border-soft);
            border-radius: 10px;
            background: var(--code-bg);
            font-size: 0.93em;
          }
          .frontmatter .fm-row {
            display: flex;
            gap: 1em;
            padding: 0.16em 0;
            align-items: baseline;
          }
          .frontmatter .fm-key {
            flex: 0 0 auto;
            min-width: 5.5em;
            color: var(--muted);
            font-weight: 620;
            font-size: 0.88em;
          }
          .frontmatter .fm-value { color: var(--text); }

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
          .tok-c { color: var(--tok-comment); font-style: italic; }
          .tok-s { color: var(--tok-string); }
          .tok-n { color: var(--tok-number); }
          .tok-k { color: var(--tok-keyword); font-weight: 600; }

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

          .footnote-ref a {
            text-decoration: none;
            font-weight: 600;
          }
          sup { color: var(--accent); }

          .footnotes {
            margin-top: 2.6em;
            padding-top: 1.1em;
            border-top: 1px solid var(--border);
            font-size: 0.92em;
            color: var(--muted);
          }
          .footnotes ol { padding-left: 1.4em; }
          .footnote-back {
            margin-left: 0.45em;
            text-decoration: none;
          }

          @media (max-width: 760px) {
            body { padding: 32px 24px 54px; font-size: 16px; }
            h1 { font-size: 1.78rem; }
            h2 { font-size: 1.42rem; }
          }
          </style>
        </head>
        <body>
        \#(body)
        <script>
        (function () {
          'use strict';
          function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }

          /* ---- lightweight syntax highlighting ---- */
          var KEYWORDS = {
            swift: 'func let var if else guard return for while repeat in switch case default break continue import struct class enum protocol extension init deinit self super throws rethrows throw try catch do as is nil true false public private internal fileprivate open static final lazy weak unowned mutating override where async await actor some any defer typealias associatedtype subscript convenience required indirect inout',
            js: 'function return if else for while do break continue switch case default new delete typeof instanceof in of var let const class extends super import export from as async await yield try catch finally throw this null undefined true false void interface type implements enum readonly static get set',
            py: 'def return if elif else for while break continue import from as class try except finally raise with lambda pass global nonlocal yield assert del in is not and or None True False async await match case self',
            rb: 'def end if elsif else unless while until for break next class module return yield begin rescue ensure raise require self nil true false and or not do then case when in',
            go: 'func return if else for range break continue switch case default package import var const type struct interface map chan go defer select fallthrough nil true false make new len cap append',
            rust: 'fn return if else for while loop break continue match impl trait struct enum mod use pub crate self super let mut const static ref move async await dyn where unsafe as in true false Some None Ok Err',
            java: 'public private protected static final void int long double float boolean char byte short class interface enum extends implements return if else for while do break continue switch case default new this super null true false try catch finally throw throws import package abstract synchronized volatile instanceof var val fun object when data sealed companion override',
            c: 'int long short char float double void unsigned signed const static struct union enum typedef return if else for while do break continue switch case default sizeof NULL true false extern inline auto register volatile goto namespace class public private protected template typename new delete using nullptr bool',
            sh: 'if then else elif fi for while do done case esac function in echo exit return local export readonly shift source set unset trap',
            sql: 'select from where insert into update delete set values create table alter drop index join left right inner outer on as and or not null primary key foreign references group by order having limit offset distinct union all exists between like in is count sum avg min max',
            css: '',
            html: '',
            json: 'true false null',
            yml: 'true false null no yes'
          };
          var ALIASES = { javascript: 'js', ts: 'js', typescript: 'js', jsx: 'js', tsx: 'js', node: 'js', python: 'py', ruby: 'rb', golang: 'go', rs: 'rust', kotlin: 'java', kt: 'java', cpp: 'c', 'c++': 'c', cc: 'c', h: 'c', hpp: 'c', objc: 'c', 'objective-c': 'c', cs: 'c', csharp: 'c', bash: 'sh', zsh: 'sh', shell: 'sh', console: 'sh', yaml: 'yml', toml: 'yml', xml: 'html', vue: 'html', svelte: 'html', scss: 'css', less: 'css' };
          var HASH_COMMENT = { py: 1, rb: 1, sh: 1, yml: 1 };
          var NO_SLASH_COMMENT = { py: 1, rb: 1, sh: 1, yml: 1, html: 1, sql: 1 };

          function tokenize(code, kw, useHash, useSlash) {
            var pattern = /(\/\*[\s\S]*?\*\/|<!--[\s\S]*?-->)|("""[\s\S]*?"""|'''[\s\S]*?''')|("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|`(?:\\.|[^`\\])*`)|(\/\/[^\n]*)|(#[^\n]*)|(\b\d[\d_]*(?:\.[\d_]+)?(?:[eE][+-]?\d+)?\b)|([A-Za-z_][A-Za-z0-9_]*)/g;
            var out = '', last = 0, m;
            while ((m = pattern.exec(code)) !== null) {
              out += esc(code.slice(last, m.index));
              last = pattern.lastIndex;
              var t = m[0], cls = '';
              if (m[1]) cls = 'tok-c';
              else if (m[2] || m[3]) cls = 'tok-s';
              else if (m[4]) cls = useSlash ? 'tok-c' : '';
              else if (m[5]) cls = useHash ? 'tok-c' : '';
              else if (m[6]) cls = 'tok-n';
              else if (m[7]) cls = kw[t] ? 'tok-k' : '';
              out += cls ? '<span class="' + cls + '">' + esc(t) + '</span>' : esc(t);
            }
            out += esc(code.slice(last));
            return out;
          }

          function highlightAll() {
            var blocks = document.querySelectorAll('pre code');
            for (var i = 0; i < blocks.length; i++) {
              var el = blocks[i];
              var lang = '';
              var m = /language-([\w+-]+)/.exec(el.className || '');
              if (m) lang = m[1].toLowerCase();
              lang = ALIASES[lang] || lang;
              var known = Object.prototype.hasOwnProperty.call(KEYWORDS, lang);
              var kw = {};
              (KEYWORDS[lang] || '').split(' ').forEach(function (k) { if (k) kw[k] = 1; });
              var useHash = known ? HASH_COMMENT[lang] === 1 : true;
              var useSlash = known ? NO_SLASH_COMMENT[lang] !== 1 : true;
              el.innerHTML = tokenize(el.textContent, kw, useHash, useSlash);
            }
          }

          /* ---- scroll + active heading reporting (app preview only) ---- */
          var bridge = (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.zmState) || null;
          var headings = [];
          function collectHeadings() {
            headings = Array.prototype.slice.call(
              document.querySelectorAll('h1[id],h2[id],h3[id],h4[id],h5[id],h6[id]')
            );
          }
          function currentHeading() {
            var cur = '';
            for (var i = 0; i < headings.length; i++) {
              if (headings[i].getBoundingClientRect().top <= 96) cur = headings[i].id;
              else break;
            }
            return cur;
          }
          var reportPending = false;
          function report() {
            if (!bridge || reportPending) return;
            reportPending = true;
            setTimeout(function () {
              reportPending = false;
              try { bridge.postMessage({ y: window.scrollY || 0, h: currentHeading() }); } catch (e) {}
            }, 120);
          }
          window.addEventListener('scroll', report, { passive: true });

          /* ---- in-document find ---- */
          var findMarks = [], findIndex = -1;
          function clearFind() {
            for (var i = 0; i < findMarks.length; i++) {
              var mk = findMarks[i], parent = mk.parentNode;
              if (!parent) continue;
              parent.replaceChild(document.createTextNode(mk.textContent), mk);
              parent.normalize();
            }
            findMarks = [];
            findIndex = -1;
          }
          function activate() {
            for (var i = 0; i < findMarks.length; i++) {
              findMarks[i].classList.toggle('zm-active', i === findIndex);
            }
            if (findIndex >= 0) findMarks[findIndex].scrollIntoView({ block: 'center' });
          }
          window.__zmFindClear = function () { clearFind(); return [0, 0]; };
          window.__zmFind = function (query) {
            clearFind();
            if (!query) return [0, 0];
            var q = query.toLowerCase();
            var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
              acceptNode: function (node) {
                var p = node.parentNode && node.parentNode.nodeName;
                if (p === 'SCRIPT' || p === 'STYLE') return NodeFilter.FILTER_REJECT;
                return node.nodeValue.toLowerCase().indexOf(q) >= 0
                  ? NodeFilter.FILTER_ACCEPT
                  : NodeFilter.FILTER_SKIP;
              }
            });
            var nodes = [];
            while (walker.nextNode()) nodes.push(walker.currentNode);
            for (var n = 0; n < nodes.length; n++) {
              var node = nodes[n], text = node.nodeValue, lower = text.toLowerCase();
              var frag = document.createDocumentFragment(), pos = 0, idx;
              while ((idx = lower.indexOf(q, pos)) >= 0) {
                if (idx > pos) frag.appendChild(document.createTextNode(text.slice(pos, idx)));
                var mk = document.createElement('mark');
                mk.className = 'zm-find';
                mk.textContent = text.slice(idx, idx + query.length);
                frag.appendChild(mk);
                findMarks.push(mk);
                pos = idx + query.length;
              }
              if (pos < text.length) frag.appendChild(document.createTextNode(text.slice(pos)));
              node.parentNode.replaceChild(frag, node);
            }
            if (findMarks.length) { findIndex = 0; activate(); }
            return [findMarks.length ? 1 : 0, findMarks.length];
          };
          window.__zmFindNav = function (dir) {
            if (!findMarks.length) return [0, 0];
            findIndex = (findIndex + dir + findMarks.length) % findMarks.length;
            activate();
            return [findIndex + 1, findMarks.length];
          };

          function boot() { highlightAll(); collectHeadings(); report(); }
          if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
          else boot();
        })();
        </script>
        </body>
        </html>
        """#
    }

    // MARK: - Stats

    /// Counts Latin-style words and CJK characters separately so word counts
    /// and reading time stay meaningful for Chinese/Japanese/Korean text.
    static func textUnits(in text: String) -> (latinWords: Int, cjkCharacters: Int) {
        var latin = 0
        var cjk = 0
        var inWord = false

        for scalar in text.unicodeScalars {
            if isCJK(scalar) {
                cjk += 1
                if inWord {
                    latin += 1
                    inWord = false
                }
            } else if CharacterSet.whitespacesAndNewlines.contains(scalar)
                || CharacterSet.punctuationCharacters.contains(scalar) {
                if inWord {
                    latin += 1
                    inWord = false
                }
            } else {
                inWord = true
            }
        }
        if inWord { latin += 1 }
        return (latin, cjk)
    }

    static func isCJK(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3040...0x30FF,   // Hiragana + Katakana
             0x3400...0x4DBF,   // CJK Extension A
             0x4E00...0x9FFF,   // CJK Unified Ideographs
             0xF900...0xFAFF,   // CJK Compatibility Ideographs
             0xAC00...0xD7AF:   // Hangul Syllables
            return true
        default:
            return false
        }
    }

    private func makeStats(markdown: String, headings: Int) -> DocumentStats {
        let units = Self.textUnits(in: markdown)
        let words = units.latinWords + units.cjkCharacters
        let minutes: Int
        if words == 0 {
            minutes = 0
        } else {
            let estimate = Double(units.latinWords) / 220.0 + Double(units.cjkCharacters) / 380.0
            minutes = max(1, Int(ceil(estimate)))
        }
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
                        detail: line.trimmingCharacters(in: .whitespaces),
                        line: offset + 1
                    )
                )
            }
        }

        // Sentence boundaries include CJK terminal punctuation so long-sentence
        // detection works for Chinese text too.
        let sentences = markdown.components(separatedBy: CharacterSet(charactersIn: ".?!。！？；\n"))
        for (offset, sentence) in sentences.enumerated() {
            let units = Self.textUnits(in: sentence)
            let count = units.latinWords + units.cjkCharacters
            guard count >= 45 else { continue }
            diagnostics.append(
                ProofDiagnostic(
                    id: "long-\(offset)",
                    kind: .longSentence,
                    detail: "\(count)",
                    line: nil
                )
            )
        }

        return Array(diagnostics.prefix(12))
    }
}

// MARK: - Parser

private final class Parser {
    private let lines: [String]
    private let baseURL: URL?
    private var index = 0
    private var usedSlugs: [String: Int] = [:]
    private var consumedLines: Set<Int> = []
    private var footnoteNumbers: [String: Int] = [:]
    private var footnoteOrder: [(id: String, text: String)] = []
    private(set) var headings: [MarkdownHeading] = []
    private(set) var missingImageAccess = false

    init(markdown: String, baseURL: URL?) {
        self.lines = markdown.components(separatedBy: .newlines)
        self.baseURL = baseURL
        scanFootnoteDefinitions()
    }

    func renderBody() -> String {
        var html: [String] = []

        while index < lines.count {
            if consumedLines.contains(index) {
                index += 1
                continue
            }

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

        let footnotes = renderFootnotesSection()
        if !footnotes.isEmpty {
            html.append(footnotes)
        }

        return html.joined(separator: "\n")
    }

    // MARK: Footnotes

    /// Pre-scan for `[^id]: definition` lines (skipping fenced code) so inline
    /// references can be numbered in a single pass.
    private func scanFootnoteDefinitions() {
        var inFence = false
        var i = 0

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                i += 1
                continue
            }
            if inFence {
                i += 1
                continue
            }

            if let match = lines[i].match(pattern: #"^\[\^([^\]\s]+)\]:\s*(.*)$"#),
               match.count > 2,
               let id = match[1] {
                var text = (match[2] ?? "").trimmingCharacters(in: .whitespaces)
                consumedLines.insert(i)

                var j = i + 1
                while j < lines.count,
                      lines[j].range(of: #"^(\t| {2,})\S"#, options: .regularExpression) != nil {
                    text += " " + lines[j].trimmingCharacters(in: .whitespaces)
                    consumedLines.insert(j)
                    j += 1
                }

                if footnoteNumbers[id] == nil {
                    footnoteNumbers[id] = footnoteOrder.count + 1
                    footnoteOrder.append((id: id, text: text))
                }
                i = j
                continue
            }

            i += 1
        }
    }

    private func renderFootnotesSection() -> String {
        guard !footnoteOrder.isEmpty else { return "" }
        let items = footnoteOrder.enumerated().map { offset, note in
            let n = offset + 1
            return "<li id=\"fn-\(n)\">\(inline(note.text)) <a class=\"footnote-back\" href=\"#fnref-\(n)\">&#8617;</a></li>"
        }.joined(separator: "\n")

        return "<section class=\"footnotes\"><ol>\n\(items)\n</ol></section>"
    }

    // MARK: Blocks

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
            content.append(line)
        }

        let meaningful = content.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !meaningful.isEmpty else { return "" }

        // Simple `key: value` front matter becomes a tidy metadata card;
        // anything more structured falls back to a code block.
        var rows: [(key: String, value: String)] = []
        var isSimple = true
        for line in meaningful {
            if let match = line.match(pattern: #"^([^:\s][^:]{0,48}):\s+(.+)$"#),
               match.count > 2,
               let key = match[1],
               let value = match[2] {
                rows.append((key.trimmingCharacters(in: .whitespaces), value.trimmingCharacters(in: .whitespaces)))
            } else {
                isSimple = false
                break
            }
        }

        guard isSimple, !rows.isEmpty else {
            return "<pre><code>\(meaningful.map(escapeHTML).joined(separator: "\n"))</code></pre>"
        }

        let rowHTML = rows.map { row in
            #"<div class="fm-row"><div class="fm-key">\#(escapeHTML(row.key))</div><div class="fm-value">\#(inline(row.value))</div></div>"#
        }.joined(separator: "\n")

        return "<div class=\"frontmatter\">\n\(rowHTML)\n</div>"
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
        <h\(level) id="\(escapeAttribute(slug))"><a class="heading-anchor" href="#\(escapeAttribute(slug))">#</a>\(inline(title))</h\(level)>
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
        let alignments = tableAlignments(lines[index + 1])
        index += 2

        var rows: [[String]] = []
        while index < lines.count, lines[index].contains("|"), !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
            rows.append(tableCells(lines[index]))
            index += 1
        }

        func alignAttribute(_ column: Int) -> String {
            guard column < alignments.count, let alignment = alignments[column] else { return "" }
            return #" style="text-align:\#(alignment)""#
        }

        let headerHTML = headers.enumerated().map { column, cell in
            "<th\(alignAttribute(column))>\(inline(cell))</th>"
        }.joined()
        let bodyHTML = rows.map { row in
            "<tr>\(row.enumerated().map { column, cell in "<td\(alignAttribute(column))>\(inline(cell))</td>" }.joined())</tr>"
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

    private func tableAlignments(_ line: String) -> [String?] {
        tableCells(line).map { cell in
            let leading = cell.hasPrefix(":")
            let trailing = cell.hasSuffix(":")
            if leading && trailing { return "center" }
            if trailing { return "right" }
            return nil
        }
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
            let body = content.dropFirst().map { "<p>\(inline($0))</p>" }.joined()
            let className = calloutClass(for: type)
            return """
            <div class="callout \(className)">
              <div class="callout-title">\(escapeHTML(title))</div>
              \(body)
            </div>
            """
        }

        let body = content.map { "<p>\(inline($0))</p>" }.joined()
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
            if consumedLines.contains(index) { break }
            let current = lines[index]
            let pattern = isOrdered ? #"^\s*\d+\.\s+(.*)$"# : #"^\s*[-*+]\s+(.*)$"#
            guard let match = current.match(pattern: pattern), match.count > 1, let item = match[1] else {
                break
            }
            let taskPattern = #"^\[( |x|X)\]\s+(.*)$"#
            if let task = item.match(pattern: taskPattern), task.count > 2, let checked = task[1], let text = task[2] {
                let checkedAttribute = checked.lowercased() == "x" ? " checked" : ""
                items.append(#"<li class="task"><input type="checkbox" disabled\#(checkedAttribute)> \#(inline(text))</li>"#)
            } else {
                items.append("<li>\(inline(item))</li>")
            }
            index += 1
        }

        return "<\(tag)>\n\(items.joined(separator: "\n"))\n</\(tag)>"
    }

    private func renderParagraph() -> String {
        var parts: [String] = []

        while index < lines.count {
            if consumedLines.contains(index) { break }
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }
            if isBlockStart(line, lookahead: index + 1 < lines.count ? lines[index + 1] : nil), !parts.isEmpty {
                break
            }
            parts.append(line)
            index += 1
        }

        return "<p>\(inline(parts.joined(separator: " ")))</p>"
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

    // MARK: Inline

    private func inline(_ text: String) -> String {
        inlineHTML(text, footnotes: footnoteNumbers, resolveImage: { [weak self] source in
            self?.resolveImageSource(source) ?? source
        })
    }

    /// Inlines small local images as data URIs so the sandboxed preview can
    /// show them without a file base URL. Remote and data URLs pass through.
    private func resolveImageSource(_ source: String) -> String {
        let lower = source.lowercased()
        guard !lower.hasPrefix("http:"),
              !lower.hasPrefix("https:"),
              !lower.hasPrefix("data:"),
              !lower.hasPrefix("file:"),
              let baseURL
        else {
            return source
        }

        // The captured source comes from escaped text; undo the one entity
        // that can occur in paths, then percent-decoding.
        var decoded = source.replacingOccurrences(of: "&amp;", with: "&")
        decoded = decoded.removingPercentEncoding ?? decoded

        let fileURL: URL
        if decoded.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: decoded)
        } else {
            fileURL = baseURL.appendingPathComponent(decoded).standardizedFileURL
        }

        let mimeTypes: [String: String] = [
            "png": "image/png",
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "gif": "image/gif",
            "webp": "image/webp",
            "svg": "image/svg+xml",
            "heic": "image/heic",
            "bmp": "image/bmp",
            "tif": "image/tiff",
            "tiff": "image/tiff"
        ]
        guard let mime = mimeTypes[fileURL.pathExtension.lowercased()] else { return source }

        guard let data = try? Data(contentsOf: fileURL), data.count <= 12_000_000 else {
            missingImageAccess = true
            return source
        }

        return "data:\(mime);base64,\(data.base64EncodedString())"
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

private func inlineHTML(
    _ text: String,
    footnotes: [String: Int] = [:],
    resolveImage: ((String) -> String)? = nil
) -> String {
    var placeholders: [String] = []
    var working = text.replacingMatches(pattern: #"`([^`]+)`"#) { match, source in
        guard let value = match.capture(1, in: source) else { return match.fullMatch(in: source) }
        placeholders.append("<code>\(escapeHTML(value))</code>")
        return "%%CODE\(placeholders.count - 1)%%"
    }

    working = escapeHTML(working)
    working = working.replacingMatches(pattern: #"!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]+)")?\)"#) { match, source in
        let alt = match.capture(1, in: source) ?? ""
        var url = match.capture(2, in: source) ?? ""
        if let resolveImage {
            url = resolveImage(url)
        }
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
    if !footnotes.isEmpty {
        working = working.replacingMatches(pattern: #"\[\^([^\]\s]+)\]"#) { match, source in
            guard let id = match.capture(1, in: source), let number = footnotes[id] else {
                return match.fullMatch(in: source)
            }
            return "<sup class=\"footnote-ref\" id=\"fnref-\(number)\"><a href=\"#fn-\(number)\">\(number)</a></sup>"
        }
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
