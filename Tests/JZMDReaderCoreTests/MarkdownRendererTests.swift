import XCTest
@testable import JZMDReaderCore

final class MarkdownRendererTests: XCTestCase {
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

        let result = MarkdownRenderer().render(markdown: markdown, theme: .paper)

        XCTAssertEqual(result.headings.first?.title, "Title")
        XCTAssertEqual(result.stats.headings, 1)
        XCTAssertTrue(result.html.contains("<table>"))
        XCTAssertTrue(result.html.contains("<strong>strong</strong>"))
        XCTAssertTrue(result.html.contains("type=\"checkbox\""))
    }

    func testDiagnosticsCatchRepeatedWordsAndTodos() {
        let markdown = "TODO: fix the the sentence."
        let result = MarkdownRenderer().render(markdown: markdown, theme: .paper)

        XCTAssertTrue(result.diagnostics.contains { $0.kind == .taskMarker })
        XCTAssertTrue(result.diagnostics.contains { $0.kind == .repeatedWord })
    }

    func testRendersSemanticCalloutsAndHighlights() {
        let markdown = """
        > [!warning] Retrieval cue
        > Keep color meanings consistent.

        This is ==worth reviewing== later.
        """

        let result = MarkdownRenderer().render(markdown: markdown, theme: .claude)

        XCTAssertTrue(result.html.contains("callout-amber"))
        XCTAssertTrue(result.html.contains("<mark>worth reviewing</mark>"))
    }

    func testNewThemesRenderCanvasColorsAndCodexFont() {
        let dark = MarkdownRenderer().render(markdown: "# Dark", theme: .carbon)
        XCTAssertTrue(dark.html.contains("--bg: #0f1115"))
        XCTAssertTrue(dark.html.contains("--page: #181b20"))

        let parchment = MarkdownRenderer().render(markdown: "# Warm", theme: .warmParchment)
        XCTAssertTrue(parchment.html.contains("--page: #f5efd9"))
        XCTAssertTrue(parchment.html.contains("SF Pro Text"))
        XCTAssertTrue(parchment.html.contains("PingFang SC"))
    }

}
