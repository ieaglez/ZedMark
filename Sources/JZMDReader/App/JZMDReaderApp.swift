import AppKit
import SwiftUI
#if canImport(JZMDReaderCore)
import JZMDReaderCore
#endif

@main
struct JZMDReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ReaderStore()

    var body: some Scene {
        // A single shared store means a single window: a second window would
        // just mirror the same document.
        Window(AppCopy.appName, id: "main") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 640)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(store.copy.openMarkdownMenu) {
                    store.showOpenPanel()
                }
                .keyboardShortcut("o")
            }

            CommandGroup(after: .saveItem) {
                Button(store.copy.exportHTMLMenu) {
                    store.exportHTML()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(store.document == nil)

                Button(store.copy.exportPDFMenu) {
                    store.exportPDF()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(store.document == nil)

                Button(store.copy.copyHTMLMenu) {
                    store.copyHTML()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(store.document == nil)
            }

            CommandGroup(after: .textEditing) {
                Button(store.copy.find) {
                    store.showFindBar()
                }
                .keyboardShortcut("f")
                .disabled(store.document == nil)
            }

            CommandMenu(store.copy.readerMenu) {
                Picker(store.copy.languageLabel, selection: Binding(
                    get: { store.language },
                    set: { store.language = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }

                Picker(store.copy.theme, selection: Binding(
                    get: { store.theme },
                    set: { store.theme = $0 }
                )) {
                    ForEach(ReaderTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }

                Divider()

                Button(store.copy.reload) {
                    store.reloadFromDisk()
                }
                .keyboardShortcut("r")
                .disabled(store.document == nil)

                Button(store.copy.grantFolderAccess) {
                    store.grantImageFolderAccess()
                }
                .disabled(store.document == nil)

                Button(store.copy.toggleInspector) {
                    store.showInspector.toggle()
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }

            CommandMenu(store.copy.viewMenu) {
                Button(store.copy.toggleSidebar) {
                    store.toggleSidebar()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])

                Divider()

                Button(store.copy.zoomIn) {
                    store.increaseZoom()
                }
                .keyboardShortcut("+")
                .disabled(!store.canZoomIn)

                Button(store.copy.zoomOut) {
                    store.decreaseZoom()
                }
                .keyboardShortcut("-")
                .disabled(!store.canZoomOut)

                Button(store.copy.resetZoom) {
                    store.resetZoom()
                }
                .keyboardShortcut("0")
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        NotificationCenter.default.post(name: .jzOpenMarkdownURLs, object: urls)
    }
}
