import Foundation

public struct MarkdownRenderResult: Equatable {
    public var html: String
    public var headings: [MarkdownHeading]
    public var stats: DocumentStats
    public var diagnostics: [ProofDiagnostic]

    public static let empty = MarkdownRenderResult(
        html: MarkdownRenderer.emptyHTML(theme: .claude),
        headings: [],
        stats: .empty,
        diagnostics: []
    )
}

public struct MarkdownHeading: Identifiable, Hashable {
    public var id: String
    public var title: String
    public var level: Int
    public var line: Int
}

public struct DocumentStats: Equatable {
    public var words: Int
    public var characters: Int
    public var lines: Int
    public var headings: Int
    public var readingMinutes: Int

    public static let empty = DocumentStats(
        words: 0,
        characters: 0,
        lines: 0,
        headings: 0,
        readingMinutes: 0
    )
}

public struct ProofDiagnostic: Identifiable, Equatable {
    public enum Kind: String {
        case repeatedWord = "Repeated word"
        case longSentence = "Long sentence"
        case taskMarker = "Task marker"
    }

    public var id: String
    public var kind: Kind
    public var title: String
    public var detail: String
    public var line: Int?
}

public enum ReaderTheme: String, CaseIterable, Identifiable, Hashable {
    case claude = "Claude"
    case github = "GitHub"
    case notion = "Notion"
    case paper = "Paper"
    case misty = "Misty"
    case lapis = "Lapis"
    case solarized = "Solarized"
    case nord = "Nord"
    case catppuccin = "Catppuccin"
    case alucard = "Alucard"
    case academic = "Academic"
    case carbon = "Carbon"
    case warmParchment = "Warm Parchment"
    case mono = "Mono"

    public var id: String { rawValue }

    var cssVariables: String {
        baseCSS + "\n" + Self.memoryCSS
    }

    private var baseCSS: String {
        switch self {
        case .claude:
            return """
            --bg: #f7f8fa;
            --page: #ffffff;
            --text: #1f2530;
            --muted: #4b5563;
            --faint: #6b7280;
            --accent: #0eb0c9;
            --accent-soft: #e3f7fb;
            --accent-cool: #0a7d8f;
            --border: #e4e7eb;
            --border-soft: #eef0f3;
            --code-bg: #f4f6f8;
            --panel: #ffffff;
            --quote: #f3f5f8;
            """
        case .github:
            return """
            --bg: #f6f8fa;
            --page: #ffffff;
            --text: #24292f;
            --muted: #57606a;
            --faint: #6e7781;
            --accent: #0969da;
            --accent-soft: #ddf4ff;
            --accent-cool: #0969da;
            --border: #d0d7de;
            --border-soft: #d8dee4;
            --code-bg: #f6f8fa;
            --panel: #ffffff;
            --quote: #f6f8fa;
            """
        case .notion:
            return """
            --bg: #f7f6f3;
            --page: #ffffff;
            --text: #37352f;
            --muted: #787774;
            --faint: #9b9a97;
            --accent: #0f7b8a;
            --accent-soft: #e9f6f7;
            --accent-cool: #0b5f6b;
            --border: #e6e4de;
            --border-soft: #efede7;
            --code-bg: #f1f1ef;
            --panel: #fbfaf8;
            --quote: #f1f1ef;
            """
        case .paper:
            return """
            --bg: #f7f8f7;
            --page: #ffffff;
            --text: #1f2528;
            --muted: #697176;
            --faint: #8a9296;
            --accent: #0eb0c9;
            --accent-soft: #dffcff;
            --accent-cool: #00829a;
            --border: #d9dddc;
            --border-soft: #e9eceb;
            --code-bg: #eef1ef;
            --panel: #ffffff;
            --quote: #e5efeb;
            """
        case .misty:
            return """
            --bg: #f8faf8;
            --page: #ffffff;
            --text: #2c3135;
            --muted: #687175;
            --faint: #8e9699;
            --accent: #5f8f8b;
            --accent-soft: #e8f3f1;
            --accent-cool: #3f716e;
            --border: #dce4e1;
            --border-soft: #edf1ef;
            --code-bg: #f1f5f3;
            --panel: #fbfdfc;
            --quote: #eef6f3;
            """
        case .lapis:
            return """
            --bg: #f7fbff;
            --page: #ffffff;
            --text: #1f2937;
            --muted: #526173;
            --faint: #8190a4;
            --accent: #2f6fba;
            --accent-soft: #e9f2ff;
            --accent-cool: #245a99;
            --border: #d6e4f5;
            --border-soft: #e8f0fb;
            --code-bg: #f0f6ff;
            --panel: #fbfdff;
            --quote: #eef6ff;
            """
        case .solarized:
            return """
            --bg: #fdf6e3;
            --page: #fffdf1;
            --text: #586e75;
            --muted: #657b83;
            --faint: #93a1a1;
            --accent: #268bd2;
            --accent-soft: #e5f2f6;
            --accent-cool: #2aa198;
            --border: #eee8d5;
            --border-soft: #f3ecd8;
            --code-bg: #f6efdc;
            --panel: #fff9e8;
            --quote: #eee8d5;
            """
        case .nord:
            return """
            --bg: #eceff4;
            --page: #f8fafc;
            --text: #2e3440;
            --muted: #4c566a;
            --faint: #6b778d;
            --accent: #5e81ac;
            --accent-soft: #e5edf7;
            --accent-cool: #3b638d;
            --border: #d8dee9;
            --border-soft: #e5e9f0;
            --code-bg: #edf1f6;
            --panel: #f8fafc;
            --quote: #e5e9f0;
            """
        case .catppuccin:
            return """
            --bg: #eff1f5;
            --page: #ffffff;
            --text: #4c4f69;
            --muted: #5c5f77;
            --faint: #7c7f93;
            --accent: #1e66f5;
            --accent-soft: #e6ecff;
            --accent-cool: #179299;
            --border: #dce0e8;
            --border-soft: #e6e9ef;
            --code-bg: #f1f3f8;
            --panel: #f7f8fb;
            --quote: #e6e9ef;
            """
        case .alucard:
            return """
            --bg: #fffbeb;
            --page: #fffdf4;
            --text: #1f1f1f;
            --muted: #6c664b;
            --faint: #8a8366;
            --accent: #036a96;
            --accent-soft: #e4f1f5;
            --accent-cool: #036a96;
            --border: #dedccf;
            --border-soft: #ece9df;
            --code-bg: #f3efdf;
            --panel: #fffbeb;
            --quote: #efeddc;
            """
        case .academic:
            return """
            --bg: #f8f7f2;
            --page: #fffffb;
            --text: #20242a;
            --muted: #555b63;
            --faint: #7d858f;
            --accent: #4b5563;
            --accent-soft: #f0f1f2;
            --accent-cool: #374151;
            --border: #ddd8c7;
            --border-soft: #ece7d7;
            --code-bg: #f3f1ea;
            --panel: #fffef8;
            --quote: #f0ead8;
            """
        case .carbon:
            return """
            --bg: #0f1115;
            --page: #181b20;
            --text: #e8eaed;
            --muted: #b2b8c2;
            --faint: #7f8792;
            --accent: #0eb0c9;
            --accent-soft: #12333a;
            --accent-cool: #55d6e8;
            --heading-3: #86ddea;
            --border: #343941;
            --border-soft: #282d34;
            --code-bg: #111419;
            --panel: #1e2228;
            --quote: #20262d;
            """
        case .warmParchment:
            return """
            --bg: #eee8d4;
            --page: #f5efd9;
            --text: #111111;
            --muted: #5f5a51;
            --faint: #8d8678;
            --accent: #8c806d;
            --accent-soft: #ebe2c8;
            --accent-cool: #766b5b;
            --heading-3: #6f6658;
            --border: #8f8678;
            --border-soft: #d8cfb6;
            --code-bg: #ebe3cd;
            --panel: #f5efd9;
            --quote: #eee6cf;
            """
        case .mono:
            return """
            --bg: #f4f6f8;
            --page: #ffffff;
            --text: #16191c;
            --muted: #606872;
            --faint: #858d96;
            --accent: #0eb0c9;
            --accent-soft: #dffcff;
            --accent-cool: #005666;
            --border: #d3d7dc;
            --border-soft: #e7eaee;
            --code-bg: #e9ecef;
            --panel: #ffffff;
            --quote: #e5e8eb;
            """
        }
    }

    private static let memoryCSS = """
            --blue: #2563eb;
            --blue-bg: #eff6ff;
            --blue-border: #bfdbfe;
            --green: #2e7d32;
            --green-bg: #f0f8f1;
            --green-border: #cde8d0;
            --amber: #8a5a00;
            --amber-bg: #fff8e6;
            --amber-border: #efd28b;
            --red: #b42318;
            --red-bg: #fff1f1;
            --red-border: #f3b8b8;
            """

    var bodyFont: String {
        switch self {
        case .mono:
            return #"ui-monospace, "SF Mono", Menlo, Consolas, "PingFang SC", monospace"#
        default:
            return #"-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Helvetica Neue", Arial, sans-serif"#
        }
    }
}
