# ZedMark

ZedMark is a native macOS Markdown reader and preview app inspired by Marked. It is focused on opening, reading, reviewing, and exporting Markdown files.

## Current features

- Open or drag in `.md`, `.markdown`, `.mdown`, and text files
- Live preview reloads when the source file changes on disk
- Collapsible sidebar with recent files and heading outline
- Reader zoom controls, including `Command +`, `Command -`, and `Command 0`
- Reader themes: Claude, GitHub, Notion, Paper, Misty, Lapis, Solarized, Nord, Catppuccin, Alucard, Academic, Carbon, Warm Parchment, and Mono
- Markdown canvas colors change with the selected reader theme
- English and Simplified Chinese UI, defaulting to English
- Document stats: words, lines, headings, and estimated reading time
- Lightweight proofing checks for repeated words, long sentences, and TODO markers
- Export rendered preview to HTML or PDF, with export status and Finder reveal action
- Open the source file in the default editor or reveal it in Finder

## Run

The built app bundle is created at:

```bash
dist/ZedMark.app
```

You can launch it from Finder by opening `dist/ZedMark.app`, or run:

```bash
./script/build_and_run.sh
```

For a build plus launch check:

```bash
./script/build_and_run.sh --verify
```

## Develop

Build with SwiftPM:

```bash
swift build
```

Run tests:

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" swift test --disable-sandbox
```


## Mac App Store readiness

This repository includes an Xcode project for App Store distribution:

```bash
open ZedMark.xcodeproj
```

The Xcode target uses:

- Bundle ID: `com.jeffzhang.ZedMark`
- Version: `0.1.0`
- Build: `1`
- App Sandbox enabled
- User-selected file read/write access
- App-scoped security-scoped bookmarks for recent files

You can validate the Xcode build without signing:

```bash
./script/build_xcode_app.sh
```

To archive for App Store Connect, set your Apple Developer Team ID:

```bash
DEVELOPMENT_TEAM=YOURTEAMID ./script/archive_app_store.sh
```

After archiving, open Xcode Organizer and upload the archive to App Store Connect. The app still needs App Store Connect metadata, screenshots, privacy details, and review submission.
