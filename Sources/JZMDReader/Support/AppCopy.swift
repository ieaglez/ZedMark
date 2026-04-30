import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case english
    case simplifiedChinese

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "中文"
        }
    }
}

struct AppCopy {
    static let appName = "ZedMark"

    var language: AppLanguage

    var sidebarSubtitle: String {
        switch language {
        case .english: return "markdown reader"
        case .simplifiedChinese: return "Markdown 阅读器"
        }
    }

    var emptySubtitle: String {
        switch language {
        case .english: return "open a markdown file"
        case .simplifiedChinese: return "打开一个 Markdown 文件"
        }
    }

    var openMarkdown: String {
        switch language {
        case .english: return "Open Markdown"
        case .simplifiedChinese: return "打开 Markdown"
        }
    }

    var openMarkdownMenu: String {
        switch language {
        case .english: return "Open Markdown..."
        case .simplifiedChinese: return "打开 Markdown..."
        }
    }

    var recent: String {
        switch language {
        case .english: return "Recent"
        case .simplifiedChinese: return "最近"
        }
    }

    var outline: String {
        switch language {
        case .english: return "Outline"
        case .simplifiedChinese: return "大纲"
        }
    }

    var noFilesYet: String {
        switch language {
        case .english: return "No files yet"
        case .simplifiedChinese: return "还没有文件"
        }
    }

    var noHeadings: String {
        switch language {
        case .english: return "No headings"
        case .simplifiedChinese: return "没有标题"
        }
    }


    var all: String {
        switch language {
        case .english: return "All"
        case .simplifiedChinese: return "全部"
        }
    }

    var recentFiles: String {
        switch language {
        case .english: return "Recent files"
        case .simplifiedChinese: return "最近文件"
        }
    }

    var close: String {
        switch language {
        case .english: return "Close"
        case .simplifiedChinese: return "关闭"
        }
    }

    var dismiss: String {
        switch language {
        case .english: return "Dismiss"
        case .simplifiedChinese: return "关闭"
        }
    }

    var live: String {
        switch language {
        case .english: return "live"
        case .simplifiedChinese: return "实时"
        }
    }

    var manual: String {
        switch language {
        case .english: return "manual"
        case .simplifiedChinese: return "手动"
        }
    }

    var previewStyle: String {
        switch language {
        case .english: return "Preview Style"
        case .simplifiedChinese: return "预览样式"
        }
    }

    var languageLabel: String {
        switch language {
        case .english: return "Language"
        case .simplifiedChinese: return "语言"
        }
    }

    var theme: String {
        switch language {
        case .english: return "Theme"
        case .simplifiedChinese: return "主题"
        }
    }

    var openInEditor: String {
        switch language {
        case .english: return "Open in Editor"
        case .simplifiedChinese: return "用编辑器打开"
        }
    }

    var revealInFinder: String {
        switch language {
        case .english: return "Reveal in Finder"
        case .simplifiedChinese: return "在 Finder 中显示"
        }
    }

    var reload: String {
        switch language {
        case .english: return "Reload"
        case .simplifiedChinese: return "重新载入"
        }
    }

    var export: String {
        switch language {
        case .english: return "Export"
        case .simplifiedChinese: return "导出"
        }
    }

    var exportHTML: String {
        switch language {
        case .english: return "Export HTML"
        case .simplifiedChinese: return "导出 HTML"
        }
    }

    var exportHTMLMenu: String {
        switch language {
        case .english: return "Export HTML..."
        case .simplifiedChinese: return "导出 HTML..."
        }
    }

    var exportPDF: String {
        switch language {
        case .english: return "Export PDF"
        case .simplifiedChinese: return "导出 PDF"
        }
    }

    var exportPDFMenu: String {
        switch language {
        case .english: return "Export PDF..."
        case .simplifiedChinese: return "导出 PDF..."
        }
    }

    var inspector: String {
        switch language {
        case .english: return "Inspector"
        case .simplifiedChinese: return "检查器"
        }
    }

    var light: String {
        switch language {
        case .english: return "light"
        case .simplifiedChinese: return "浅色"
        }
    }

    var stats: String {
        switch language {
        case .english: return "Stats"
        case .simplifiedChinese: return "统计"
        }
    }

    var words: String {
        switch language {
        case .english: return "Words"
        case .simplifiedChinese: return "字数"
        }
    }

    var read: String {
        switch language {
        case .english: return "Read"
        case .simplifiedChinese: return "阅读"
        }
    }

    var lines: String {
        switch language {
        case .english: return "Lines"
        case .simplifiedChinese: return "行数"
        }
    }

    var heads: String {
        switch language {
        case .english: return "Heads"
        case .simplifiedChinese: return "标题"
        }
    }

    var proofing: String {
        switch language {
        case .english: return "Proofing"
        case .simplifiedChinese: return "校对"
        }
    }

    var noObviousIssues: String {
        switch language {
        case .english: return "No obvious issues"
        case .simplifiedChinese: return "没有明显问题"
        }
    }

    var readerMenu: String {
        switch language {
        case .english: return "Reader"
        case .simplifiedChinese: return "阅读器"
        }
    }

    var livePreview: String {
        switch language {
        case .english: return "Live Preview"
        case .simplifiedChinese: return "实时预览"
        }
    }

    var toggleInspector: String {
        switch language {
        case .english: return "Toggle Inspector"
        case .simplifiedChinese: return "切换检查器"
        }
    }


    var toggleSidebar: String {
        switch language {
        case .english: return "Toggle Sidebar"
        case .simplifiedChinese: return "切换侧边栏"
        }
    }

    var viewMenu: String {
        switch language {
        case .english: return "View"
        case .simplifiedChinese: return "视图"
        }
    }

    var zoom: String {
        switch language {
        case .english: return "Zoom"
        case .simplifiedChinese: return "缩放"
        }
    }

    var zoomIn: String {
        switch language {
        case .english: return "Zoom In"
        case .simplifiedChinese: return "放大"
        }
    }

    var zoomOut: String {
        switch language {
        case .english: return "Zoom Out"
        case .simplifiedChinese: return "缩小"
        }
    }

    var resetZoom: String {
        switch language {
        case .english: return "Reset Zoom"
        case .simplifiedChinese: return "重置缩放"
        }
    }

    var ready: String {
        switch language {
        case .english: return "Ready"
        case .simplifiedChinese: return "就绪"
        }
    }

    var openPanelTitle: String { openMarkdown }

    var unsupportedFile: String {
        switch language {
        case .english: return "Unsupported file"
        case .simplifiedChinese: return "不支持的文件"
        }
    }

    var unsupportedFileDetail: String {
        switch language {
        case .english: return "ZedMark opens Markdown and plain text files."
        case .simplifiedChinese: return "ZedMark 支持打开 Markdown 和纯文本文件。"
        }
    }

    var livePreviewOn: String {
        switch language {
        case .english: return "Live preview on"
        case .simplifiedChinese: return "实时预览已开启"
        }
    }

    var loaded: String {
        switch language {
        case .english: return "Loaded"
        case .simplifiedChinese: return "已载入"
        }
    }

    var couldNotOpenFile: String {
        switch language {
        case .english: return "Could not open file"
        case .simplifiedChinese: return "无法打开文件"
        }
    }

    var reloaded: String {
        switch language {
        case .english: return "Reloaded"
        case .simplifiedChinese: return "已重新载入"
        }
    }

    var couldNotReloadFile: String {
        switch language {
        case .english: return "Could not reload file"
        case .simplifiedChinese: return "无法重新载入文件"
        }
    }

    func exporting(_ kind: ExportKind) -> String {
        switch language {
        case .english: return "Exporting \(kind.rawValue)..."
        case .simplifiedChinese: return "正在导出 \(kind.rawValue)..."
        }
    }

    func exported(_ kind: ExportKind) -> String {
        switch language {
        case .english: return "\(kind.rawValue) exported"
        case .simplifiedChinese: return "\(kind.rawValue) 已导出"
        }
    }

    var exportCancelled: String {
        switch language {
        case .english: return "Export cancelled"
        case .simplifiedChinese: return "已取消导出"
        }
    }

    var savedTo: String {
        switch language {
        case .english: return "Saved to"
        case .simplifiedChinese: return "已保存到"
        }
    }

    var lastExport: String {
        switch language {
        case .english: return "Last export"
        case .simplifiedChinese: return "上次导出"
        }
    }

    var showInFinder: String {
        switch language {
        case .english: return "Show in Finder"
        case .simplifiedChinese: return "在 Finder 中显示"
        }
    }

    var exportHint: String {
        switch language {
        case .english: return "Choose HTML or PDF to export the current preview."
        case .simplifiedChinese: return "选择 HTML 或 PDF 导出当前预览。"
        }
    }

    var exportNeedsDocument: String {
        switch language {
        case .english: return "Open a Markdown file before exporting."
        case .simplifiedChinese: return "先打开一个 Markdown 文件再导出。"
        }
    }

    var exportFailed: String {
        switch language {
        case .english: return "Export failed"
        case .simplifiedChinese: return "导出失败"
        }
    }

    var couldNotExportHTML: String {
        switch language {
        case .english: return "Could not export HTML"
        case .simplifiedChinese: return "无法导出 HTML"
        }
    }

    var couldNotExportPDF: String {
        switch language {
        case .english: return "Could not export PDF"
        case .simplifiedChinese: return "无法导出 PDF"
        }
    }

    var externalChangesAvailable: String {
        switch language {
        case .english: return "External changes available"
        case .simplifiedChinese: return "外部文件已有更新"
        }
    }
}
