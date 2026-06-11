import XCTest
@testable import JZMDReaderCore

final class MarkdownRendererTests: XCTestCase {
    private let renderer = MarkdownRenderer()

    // MARK: - Core blocks

    func testRendersCoreMarkdownBlocks() {
        let markdown = """
        # Title

        Paragraph with **strong** text and `code`.

        | A | B |
        | --- | --- |
        | one | two |

        - [x] done
        - item
        """

        let result = renderer.render(markdown: markdown, theme: .paper)

        XCTAssertEqual(result.headings.first?.title, "Title")
        XCTAssertEqual(result.stats.headings, 1)
        XCTAssertTrue(result.html.contains("<table>"))
        XCTAssertTrue(result.html.contains("<strong>strong</strong>"))
        XCTAssertTrue(result.html.contains("type=\"checkbox\""))
    }

    func testRendersSemanticCalloutsAndHighlights() {
        let markdown = """
        > [!warning] Retrieval cue
        > Keep color meanings consistent.

        This is ==worth reviewing== later.
        """

        let result = renderer.render(markdown: markdown, theme: .claude)

        XCTAssertTrue(result.html.contains("callout-amber"))
        XCTAssertTrue(result.html.contains("<mark>worth reviewing</mark>"))
    }

    func testNewThemesRenderCanvasColorsAndCodexFont() {
        let dark = renderer.render(markdown: "# Dark", theme: .carbon)
        XCTAssertTrue(dark.html.contains("--bg: #0f1115"))
        XCTAssertTrue(dark.html.contains("--page: #181b20"))

        let parchment = renderer.render(markdown: "# Warm", theme: .warmParchment)
        XCTAssertTrue(parchment.html.contains("--page: #f5efd9"))
        XCTAssertTrue(parchment.html.contains("SF Pro Text"))
        XCTAssertTrue(parchment.html.contains("PingFang SC"))
    }

    // MARK: - Diagnostics

    func testDiagnosticsCatchRepeatedWordsAndTodos() {
        let markdown = "TODO: fix the the sentence."
        let result = renderer.render(markdown: markdown, theme: .paper)

        XCTAssertTrue(result.diagnostics.contains { $0.kind == .taskMarker })
        XCTAssertTrue(result.diagnostics.contains { $0.kind == .repeatedWord })
    }

    func testLongSentenceDetectionHandlesChinesePunctuation() {
        // One sentence of 60 Chinese characters terminated by 。 should flag,
        // while several short sentences should not.
        let longSentence = String(repeating: "这是一个用来验证长句检测的相当长的句子", count: 3) + "。"
        let long = renderer.render(markdown: longSentence, theme: .claude)
        XCTAssertTrue(long.diagnostics.contains { $0.kind == .longSentence })

        let shortSentences = "这是短句。这也是短句。还是短句。"
        let short = renderer.render(markdown: shortSentences, theme: .claude)
        XCTAssertFalse(short.diagnostics.contains { $0.kind == .longSentence })
    }

    func testLongSentenceDetailIsUnitCount() {
        let words = Array(repeating: "word", count: 50).joined(separator: " ") + "."
        let result = renderer.render(markdown: words, theme: .claude)
        let diagnostic = result.diagnostics.first { $0.kind == .longSentence }
        XCTAssertEqual(diagnostic?.detail, "50")
    }

    // MARK: - CJK statistics

    func testChineseWordCountCountsCharacters() {
        let chinese = String(repeating: "汉", count: 100)
        let result = renderer.render(markdown: chinese, theme: .claude)
        XCTAssertEqual(result.stats.words, 100)
        XCTAssertGreaterThanOrEqual(result.stats.readingMinutes, 1)
    }

    func testMixedLanguageWordCount() {
        let mixed = "hello world 你好世界"
        let result = renderer.render(markdown: mixed, theme: .claude)
        // 2 Latin words + 4 CJK characters.
        XCTAssertEqual(result.stats.words, 6)
    }

    // MARK: - Tables

    func testTableAlignmentFromSeparatorColons() {
        let markdown = """
        | Left | Center | Right |
        | :--- | :---: | ---: |
        | a | b | c |
        """
        let result = renderer.render(markdown: markdown, theme: .claude)

        XCTAssertTrue(result.html.contains("<th style=\"text-align:center\">"))
        XCTAssertTrue(result.html.contains("<th style=\"text-align:right\">"))
        XCTAssertTrue(result.html.contains("<td style=\"text-align:center\">"))
        XCTAssertTrue(result.html.contains("class=\"table-wrap\""))
    }

    // MARK: - Footnotes

    func testFootnotesRenderReferencesAndSection() {
        let markdown = """
        Body text with a footnote.[^note]

        [^note]: The footnote definition.
        """
        let result = renderer.render(markdown: markdown, theme: .claude)

        XCTAssertTrue(result.html.contains("class=\"footnote-ref\""))
        XCTAssertTrue(result.html.contains("href=\"#fn-1\""))
        XCTAssertTrue(result.html.contains("class=\"footnotes\""))
        XCTAssertTrue(result.html.contains("The footnote definition."))
        // Definition line must not leak into the body as a paragraph.
        XCTAssertFalse(result.html.contains("<p>[^note]:"))
    }

    func testUndefinedFootnoteReferenceStaysLiteral() {
        let parsed = renderer.parse(markdown: "Reference only.[^missing]")
        XCTAssertFalse(parsed.body.contains("footnote-ref"))
        XCTAssertTrue(parsed.body.contains("[^missing]"))
    }

    // MARK: - Front matter

    func testSimpleFrontMatterBecomesMetadataCard() {
        let markdown = """
        ---
        title: ZedMark Notes
        date: 2026-06-01
        ---

        # Heading
        """
        let result = renderer.render(markdown: markdown, theme: .claude)

        XCTAssertTrue(result.html.contains("class=\"frontmatter\""))
        XCTAssertTrue(result.html.contains("ZedMark Notes"))
        XCTAssertTrue(result.html.contains("2026-06-01"))
    }

    func testComplexFrontMatterFallsBackToCodeBlock() {
        let markdown = """
        ---
        tags:
          - one
          - two
        ---

        Body
        """
        let result = renderer.render(markdown: markdown, theme: .claude)
        XCTAssertFalse(result.html.contains("class=\"frontmatter\""))
        XCTAssertTrue(result.html.contains("<pre><code>"))
    }

    // MARK: - Image inlining

    func testRelativeImageInlinedAsDataURI() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("zedmark-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        try imageData.write(to: directory.appendingPathComponent("pic.png"))

        let parsed = renderer.parse(markdown: "![alt](pic.png)", baseURL: directory)

        XCTAssertTrue(parsed.body.contains("src=\"data:image/png;base64,"))
        XCTAssertFalse(parsed.needsFolderAccessForImages)
    }

    func testMissingLocalImageSetsFolderAccessFlag() {
        let directory = FileManager.default.temporaryDirectory
        let parsed = renderer.parse(markdown: "![alt](definitely-missing-\(UUID().uuidString).png)", baseURL: directory)

        XCTAssertTrue(parsed.needsFolderAccessForImages)
    }

    func testRemoteImagePassesThrough() {
        let parsed = renderer.parse(markdown: "![alt](https://example.com/x.png)", baseURL: FileManager.default.temporaryDirectory)
        XCTAssertTrue(parsed.body.contains("src=\"https://example.com/x.png\""))
        XCTAssertFalse(parsed.needsFolderAccessForImages)
    }

    // MARK: - Document chrome (scripts & styles)

    func testDocumentHTMLIncludesFindAndHighlightSupport() {
        let html = MarkdownRenderer.documentHTML(body: "<p>x</p>", theme: .claude)

        XCTAssertTrue(html.contains("__zmFind"))
        XCTAssertTrue(html.contains("__zmFindNav"))
        XCTAssertTrue(html.contains("zmState"))
        XCTAssertTrue(html.contains("tok-comment"))
        XCTAssertTrue(html.contains("mark.zm-find"))
    }

    func testThemeRestyleKeepsParseStable() {
        let markdown = "# Title\n\nSome paragraph."
        let parsed = renderer.parse(markdown: markdown)
        let light = MarkdownRenderer.documentHTML(body: parsed.body, theme: .claude)
        let dark = MarkdownRenderer.documentHTML(body: parsed.body, theme: .carbon)

        XCTAssertTrue(light.contains(parsed.body))
        XCTAssertTrue(dark.contains(parsed.body))
        XCTAssertNotEqual(light, dark)
    }
}
