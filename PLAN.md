# CleanSweep — macOS Tahoe Cleaning App
## Engineering Plan & Best Practices

> **Target Platform:** macOS Tahoe 26+ (minimum macOS 14 with graceful degradation)
> **UI Paradigm:** Liquid Glass, NavigationSplitView, SwiftUI-first with AppKit escape hatches
> **Architecture:** Clean Architecture + Observable macro + Swift Concurrency (async/await, actors)
> **Distribution:** Free — notarized DMG, direct download

---

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [Feature Inventory](#2-feature-inventory)
3. [Architecture & Project Structure](#3-architecture--project-structure)
4. [Sandboxing & Entitlements Strategy](#4-sandboxing--entitlements-strategy)
5. [Core Scanning Engine](#5-core-scanning-engine)
6. [Feature Specifications](#6-feature-specifications)
7. [UI / UX Design System](#7-ui--ux-design-system)
8. [Performance Engineering](#8-performance-engineering)
9. [Security & Privacy Best Practices](#9-security--privacy-best-practices)
10. [Data Persistence](#10-data-persistence)
11. [Testing Strategy](#11-testing-strategy)
12. [Distribution](#12-distribution)
13. [Accessibility](#13-accessibility)
14. [Localization](#14-localization)
15. [Observability & Diagnostics](#15-observability--diagnostics)
16. [macOS Best Practices Checklist](#16-macos-best-practices-checklist)

---

## 1. Product Vision

**CleanSweep** is a fully free, native macOS Tahoe cleaning utility that combines deep system analysis with an exceptionally polished Liquid Glass UI. It surfaces actionable insights — not just raw file lists — helping users reclaim disk space, protect privacy, and keep their Mac running smoothly. Every feature is available to every user, with no paywalls, no subscriptions, and no telemetry without explicit opt-in.

Differentiators:
- Completely free with no feature restrictions
- Full macOS Tahoe Liquid Glass aesthetics, designed specifically for macOS (not a port of iOS styles)
- Privacy-first: all processing is entirely local, zero data leaves the device
- Non-destructive by default: every deletion is previewed and reversible via Trash
- Genuinely fast scanning using structured concurrency, actor isolation, and FS events
- Transparent about what it does: every file listed shows exactly why it was flagged

---

## 2. Feature Inventory

| Module | Description |
|---|---|
| Smart Scan | One-click overview of all cleanable categories with a unified summary |
| System Junk | Caches, logs, temp files, language packs, Xcode artifacts |
| Mail Attachments | Attachments stored on disk by Mail.app, surfaced by type and sender |
| Large & Old Files | Files >100 MB or untouched >1 year, with Quick Look preview |
| Duplicate Finder | SHA-256 content hash deduplication with smart keep-selection |
| Privacy Cleaner | Browser history, cookies, recent items, clipboard |
| App Uninstaller | Full bundle + all support file removal with size recovery summary |
| Startup Manager | Login items, launch agents/daemons with enable/disable toggles |
| Memory Monitor | Real-time memory pressure visualization via Mach kernel stats |
| Disk Analyzer | Sunburst / treemap visualization of disk usage |
| Trash Manager | View, sort, and empty per-app or per-category Trash contents |
| Network Cache Cleaner | DNS cache, URLSession caches, browser network storage |
| Development Junk | Xcode derived data, simulators, SPM/CocoaPods/Carthage caches |
| Font Manager | Detect and remove duplicate or unused fonts |
| Screenshot & Recording Cleaner | Surface old screenshots and screen recordings from Desktop/Documents |
| Health Dashboard | Continuous disk usage, battery cycle count, and storage health overview |

---

## 3. Architecture & Project Structure

### 3.1 Architecture Pattern

Use **Clean Architecture** with three distinct layers, enforced via Swift Package Manager local packages:

```
CleanSweep/
├── App/                            # Entry point, AppDelegate, scene config
├── Features/                       # One folder per feature (vertical slices)
│   ├── SmartScan/
│   │   ├── SmartScanView.swift
│   │   ├── SmartScanViewModel.swift
│   │   └── SmartScanUseCase.swift
│   ├── SystemJunk/
│   ├── DuplicateFinder/
│   ├── DiskAnalyzer/
│   ├── HealthDashboard/
│   └── ...
├── Packages/
│   ├── ScanEngine/                 # Pure Swift — no UI, no AppKit, fully testable
│   │   ├── Sources/ScanEngine/
│   │   │   ├── Scanners/           # One scanner per module
│   │   │   ├── Models/             # ScanResult, FileCategory, ScanSummary
│   │   │   ├── Actors/             # ScanActor, DeletionActor
│   │   │   └── Utilities/          # SHA256, SizeFormatter, PathMatcher
│   │   └── Tests/ScanEngineTests/
│   └── DesignSystem/               # Liquid Glass components, tokens, shared ViewModifiers
├── Resources/                      # Assets.xcassets, Localizable.xcstrings, entitlements
└── CleanSweep.xcodeproj
```

### 3.2 Data Flow

```
View (SwiftUI)
  └─▶ ViewModel (@Observable, @MainActor)
        └─▶ UseCase (protocol, constructor-injected)
              └─▶ Repository (protocol)
                    └─▶ Scanner / FileManager / IOKit  (ScanEngine package)
```

- **Views** are pure layout — no business logic, no direct file access.
- **ViewModels** use `@Observable` (Swift 5.9+), never `ObservableObject`. Marked `@MainActor`.
- **UseCases** are plain structs or actors with a single async throwing method.
- **Repositories** abstract all OS APIs so UseCases remain unit-testable with mock implementations.

### 3.3 Concurrency Model

```swift
// All scanning runs on a dedicated actor — never blocks the main thread
actor ScanActor {
    private let fileManager = FileManager.default

    func scanStream(at root: URL) -> AsyncStream<ScanResult> {
        AsyncStream { continuation in
            Task.detached(priority: .utility) {
                // Enumerate, categorize, yield
                continuation.finish()
            }
        }
    }
}

// ViewModel consumes the stream and publishes updates on MainActor
@MainActor
@Observable
final class ScanViewModel {
    var results: [ScanResult] = []
    var progress: Double = 0
    var phase: ScanPhase = .idle

    func startScan() async {
        phase = .scanning
        for await result in scanActor.scanStream(at: .homeDirectory) {
            results.append(result)
            progress = result.progressFraction
        }
        phase = .complete
    }
}
```

**Rules:**
- Never use `DispatchQueue.main.async` — use `@MainActor` and `await`.
- Never use `Thread.sleep` — use `Task.sleep(for:)`.
- Use `TaskGroup` for parallel module scanning.
- Use `AsyncStream` to stream results to the UI progressively — never wait for all results before showing anything.
- Cancel `Task` on view disappear via the `.task {}` modifier, which auto-cancels on disappear.
- Respect `Task.isCancelled` in all tight enumeration loops.

### 3.4 Dependency Injection

Use constructor injection via a lightweight `AppContainer` service locator initialized at app launch:

```swift
@main
struct CleanSweepApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container.scanViewModel)
                .environment(container.diskViewModel)
                .environment(container.healthViewModel)
        }
    }
}
```

---

## 4. Sandboxing & Entitlements Strategy

This is the **hardest constraint** for a cleaning app. A cleaning app requires access to paths that the App Sandbox actively restricts.

### 4.1 Sandbox Limitations

The Mac App Store **requires** the App Sandbox. This means:

- Direct access to `~/Library/Caches` of OTHER apps is **blocked**.
- Reading `/System` or `/private/var` is **blocked**.
- Writing to arbitrary paths is **blocked**.

### 4.2 Recommended Approach

**Option A: Privileged XPC Helper Tool (for future MAS distribution)**

Use `SMAppService` (macOS 13+) to register a privileged XPC helper bundled inside the main app. The helper runs outside the sandbox and communicates only via a well-typed XPC protocol:

```swift
// Register helper at runtime (prompts user once)
try SMAppService.daemon(plistName: "com.yourco.cleansweep.helper.plist").register()

// XPC interface (defined in shared framework, imported by both app and helper)
@objc protocol CleanHelperProtocol {
    func scanDirectory(_ url: URL, reply: @escaping ([URL]) -> Void)
    func moveToTrash(_ urls: [URL], reply: @escaping (Bool) -> Void)
}
```

The helper must:
- Be code-signed with Hardened Runtime
- Have its own sandboxless entitlements file
- Validate ALL incoming URLs — reject any outside expected prefixes
- Never expose a "run arbitrary shell command" surface

**Option B: Direct sale outside MAS — notarization only (recommended for v1)**

Removes the sandbox requirement entirely. The app uses `NSOpenPanel` for user-scoped bookmarks and can access any path the user has granted. Simpler, more capable, and allows the app to clean paths MAS would never permit.

**Recommendation:** Ship as a notarized DMG. This is what the app is — a powerful system utility. MAS can be a future goal with the helper architecture.

### 4.3 Security-Scoped Bookmarks

For any user-selected folder, persist access across launches:

```swift
// After NSOpenPanel selection
let bookmarkData = try url.bookmarkData(
    options: .withSecurityScope,
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)
UserDefaults.standard.set(bookmarkData, forKey: "savedBookmark")

// On next launch
var isStale = false
let resolvedURL = try URL(
    resolvingBookmarkData: bookmarkData,
    options: .withSecurityScope,
    relativeTo: nil,
    bookmarkDataIsStale: &isStale
)
resolvedURL.startAccessingSecurityScopedResource()
defer { resolvedURL.stopAccessingSecurityScopedResource() }
```

### 4.4 Required Entitlements

```xml
<!-- com.yourco.cleansweep.entitlements (direct sale, no sandbox) -->
<key>com.apple.security.app-sandbox</key><false/>
<!-- Hardened Runtime is still required for notarization -->
```

---

## 5. Core Scanning Engine

### 5.1 Directory Enumeration

```swift
// FileManager.DirectoryEnumerator is streaming — it never loads all results into memory at once
func enumerateDirectory(at root: URL) -> AsyncStream<URL> {
    AsyncStream { continuation in
        Task.detached(priority: .utility) {
            let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [
                    .fileSizeKey,
                    .totalFileAllocatedSizeKey,
                    .contentModificationDateKey,
                    .contentAccessDateKey,
                    .isDirectoryKey,
                    .isSymbolicLinkKey,
                    .isPackageKey
                ],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            while let url = enumerator?.nextObject() as? URL {
                guard !Task.isCancelled else { break }
                continuation.yield(url)
            }
            continuation.finish()
        }
    }
}
```

**Best practices:**
- Pre-fetch all needed resource keys in the enumerator call — avoids per-file `stat()` syscalls later.
- Skip package descendants by default (`.app`, `.bundle`). Only descend into packages during App Uninstaller or Development Junk scans.
- Check `Task.isCancelled` every iteration in tight loops — the overhead is negligible; unresponsive cancellation is not.
- Use `.utility` task priority for scanning; reserve `.userInitiated` only for operations where the user is actively waiting on a result.

### 5.2 File Categorization

```swift
enum FileCategory: String, CaseIterable, Sendable {
    case userCache, systemLog, tempFile, languagePack, xcodeDerivedData,
         xcodeSimulator, spmCache, mailAttachment, browserCache,
         appSupportOrphan, largeFile, oldFile, duplicate, screenshot,
         screenRecording, fontDuplicate, trashItem, networkCache
}

actor Categorizer {
    // Returns nil if the file does not match any cleanable category
    func category(for url: URL, attributes: URLResourceValues) -> FileCategory? {
        let path = url.path
        if path.contains("/DerivedData")           { return .xcodeDerivedData }
        if path.contains("/CoreSimulator/Devices") { return .xcodeSimulator }
        if path.contains("/SourcePackages")        { return .spmCache }
        if url.pathExtension == "log"              { return .systemLog }
        if path.contains("/Caches/")               { return .userCache }
        // ... ordered from most specific to least specific
        return nil
    }
}
```

### 5.3 Parallel Scanning with TaskGroup

```swift
func scanAllModules() async throws -> ScanSummary {
    try await withThrowingTaskGroup(of: ModuleResult.self) { group in
        group.addTask { try await SystemJunkScanner().scan() }
        group.addTask { try await LargeFilesScanner().scan() }
        group.addTask { try await MailScanner().scan() }
        group.addTask { try await DevelopmentJunkScanner().scan() }
        group.addTask { try await ScreenshotScanner().scan() }

        var summary = ScanSummary()
        for try await result in group {
            summary.merge(result)
        }
        return summary
    }
}
```

### 5.4 Safe Deletion

**NEVER call `FileManager.removeItem` directly.** Always move to Trash:

```swift
func moveToTrash(_ urls: [URL]) async throws {
    // NSWorkspace.recycle is the canonical safe deletion API.
    // It moves files to the Trash and provides undo capability.
    try await NSWorkspace.shared.recycle(urls)
}
```

For permanent deletion (only when the user explicitly requests it after a secondary confirmation):

```swift
func permanentlyDelete(_ urls: [URL]) async throws {
    for url in urls {
        try FileManager.default.removeItem(at: url)
        await auditLog.record(DeletionEvent(url: url, permanent: true))
    }
}
```

Every deletion — Trash or permanent — must be logged to the audit trail with timestamp, path, size, and category.

---

## 6. Feature Specifications

### 6.1 Smart Scan

The entry point. Runs all module scanners in parallel via `TaskGroup` and aggregates results into a unified summary screen.

**UI:** A large circular progress ring (Liquid Glass) fills as modules complete. A status label beneath it updates with the currently active module name and elapsed time. When complete, the ring transitions (`.blurReplace`) to a summary dashboard showing each category as a glass card with its space recovery potential. A prominent "Clean All" button and per-category "Review & Clean" buttons give the user full control.

**Logic:**
- Scan runs at `.utility` priority.
- Results stream in via `AsyncStream` — the UI updates progressively; do not wait for all modules to complete before showing anything.
- Cache the last scan result to `Application Support/LastScan.json`. Display it immediately on next launch before a new scan completes, clearly labelled with the scan timestamp.

**Best practices:**
- Show elapsed time and the currently scanned module name.
- Allow cancellation at any time; partial results are shown and remain actionable.
- Never auto-delete. Smart Scan is always read-only. The user confirms before any deletion occurs.

---

### 6.2 System Junk

Targets:
- `~/Library/Caches/*` — user-space application caches
- `~/Library/Logs/*` — application log files
- `/private/var/log/*` — system logs (requires Full Disk Access)
- `~/Library/Application Support/*/CrashReporter/`
- Language pack `.lproj` directories inside `/Applications/*.app/Contents/Resources/` (excluding the user's active locales)
- Old iOS Device Backups: `~/Library/Application Support/MobileSync/Backup/`
- Old iOS Software Updates: `~/Library/iTunes/iPhone Software Updates/`

**Safety rules:**
- Maintain a whitelist of known-safe cache directories. Never silently delete `com.apple.*` caches — flag them for user review instead.
- Detect `NSLocale.preferredLanguages` and preserve matching `.lproj` bundles.
- Show last-modified date for each item so the user can make an informed decision.
- Display each item's originating app name (resolved from bundle ID) in the UI.

---

### 6.3 Mail Attachments

Scan `~/Library/Mail/V*/*/Attachments/` and surface all files by type, size, and originating account.

Use a glob pattern rather than hardcoded version paths to future-proof against Mail version updates.

**UI:** Group attachments by estimated sender domain (derived from the folder path structure). Show thumbnail previews using `QLThumbnailGenerator` for images and document types. Allow filtering by file type (images, PDFs, archives, etc.).

---

### 6.4 Large & Old Files

Two sub-modes surfaced in a single view:

1. **Large Files:** Files exceeding a user-configurable threshold (default 100 MB), sorted by size descending.
2. **Old Files:** Files not accessed in longer than a user-configurable duration (default 1 year), using `URLResourceKey.contentAccessDateKey`.

Scan targets: `~/Documents`, `~/Downloads`, `~/Desktop`, `~/Movies`, `~/Music`. Respect custom home folder locations.

**UI:** A sortable, filterable list. Press Space on any row to open Quick Look preview (`.quickLookPreview()` modifier). Inline file type badge. Row swipe actions for quick "Move to Trash" or "Reveal in Finder."

**Best practices:**
- Show both logical size and on-disk (allocated) size — allocated size is what's actually recovered.
- Allow the user to exclude folders (e.g. a Time Machine backup folder) from the scan via a persistent exclusion list.

---

### 6.5 Duplicate Finder

**Algorithm — three-pass strategy for maximum speed:**

1. **Pass 1 — Size grouping:** Group all files by byte size. Files with a unique size are guaranteed not to be duplicates; discard them immediately. This eliminates ~95% of candidates with zero I/O.
2. **Pass 2 — Prefix sampling:** Within each size group, read and compare the first 4 KB of each file using `FileHandle`. Discard groups where the prefix doesn't match.
3. **Pass 3 — Full SHA-256 hash:** Hash the remaining candidates in full using CryptoKit.

```swift
import CryptoKit

func sha256(of url: URL) async throws -> SHA256Digest {
    // .mappedIfSafe = memory-mapped; OS handles paging, no heap allocation for entire file
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    return SHA256.hash(data: data)
}
```

**UI:** Duplicate groups are shown as expandable cards. Within each group, the app auto-selects a recommended "keep" candidate (newest modification date, or the one closest to `~/Documents`). The user can change the selection. The total space recovered by deleting the non-kept copies is shown in real time as the selection changes.

**Best practices:**
- Never auto-select the delete action — the user must confirm per group or in bulk.
- Exclude system files and app bundles from the duplicate scan scope.
- Show the full path of each duplicate to help the user understand context.

---

### 6.6 Privacy Cleaner

Targets:
- Safari: `~/Library/Safari/History.db`, `~/Library/Cookies/Cookies.binarycookies`
- Chrome/Brave: `~/Library/Application Support/Google/Chrome/Default/History`
- Firefox: `~/Library/Application Support/Firefox/Profiles/*/places.sqlite`
- macOS Recent Items: `~/Library/Application Support/com.apple.sharedfilelist/`
- Clipboard: `NSPasteboard.general.clearContents()`
- Recent apps list in Dock: remove via `defaults write com.apple.dock`

**Warning:** SQLite databases must not be modified while the target browser is open. Detect running processes with `NSWorkspace.runningApplications` before proceeding and surface a warning sheet if the browser is active.

**Best practices:**
- Show the user which browser histories will be cleared before any action — never silently touch browser data.
- Offer selective clearing: "Clear history only" vs "Clear history + cookies" vs "Clear everything."
- Clipboard clearing must be instant and confirm with an unobtrusive toast notification.

---

### 6.7 App Uninstaller

**Complete uninstall targets for a given `.app` bundle:**

```
~/Library/Application Support/<BundleID>/
~/Library/Caches/<BundleID>/
~/Library/Preferences/<BundleID>.plist
~/Library/HTTPStorages/<BundleID>/
~/Library/Containers/<BundleID>/           (sandboxed apps)
~/Library/Group Containers/<GroupID>/
~/Library/Saved Application State/<BundleID>.savedState/
~/Library/WebKit/<BundleID>/
/Library/Application Support/<BundleID>/  (requires elevation)
/Library/LaunchAgents/<BundleID>*.plist
/Library/LaunchDaemons/<BundleID>*.plist
```

Parse `CFBundleIdentifier` from `Info.plist` programmatically — never guess bundle IDs from app names.

**UI:** A list of all installed applications with their total on-disk footprint (bundle + all support files). Search bar to filter by app name. Selecting an app expands a detail panel showing every support path with its individual size. A "Find Leftovers" mode scans for orphaned support files from apps that have already been manually deleted.

**Best practices:**
- Warn if the app is running before offering uninstall — terminate it first or abort.
- Warn for system apps and prevent uninstall of macOS built-ins.
- Move the `.app` bundle and all support files to Trash in a single `NSWorkspace.recycle` call so the user can restore everything at once if needed.

---

### 6.8 Startup Manager

Enumerate and manage:
- **Login Items** via `SMAppService.loginItem` (macOS 13+) — the modern, sandboxed API.
- **Launch Agents** in `~/Library/LaunchAgents/*.plist` and `/Library/LaunchAgents/*.plist`.
- **Launch Daemons** in `/Library/LaunchDaemons/*.plist`.

```swift
import ServiceManagement

// Modern login items API (macOS 13+)
let status = SMAppService.statusForLoginItem(withIdentifier: "com.example.app")

// Enable/disable without elevated privileges
try SMAppService.loginItem(identifier: "com.example.app").register()
try SMAppService.loginItem(identifier: "com.example.app").unregister()
```

**UI:** A table with columns for Name, Type (Login Item / Launch Agent / Launch Daemon), Status (Enabled/Disabled), and the responsible app. Toggle switches per row. Color-code known macOS system agents as read-only. Show the resolved executable path on hover via a tooltip.

**Best practices:**
- Disable items by setting `Disabled` key in the plist rather than deleting them — allow re-enabling later.
- Flag items with non-existent executable paths as "broken" — these are safe to remove.
- Show the impact on boot time with an estimated "delay this adds to startup" metric if available.

---

### 6.9 Memory Monitor

There is no legitimate API to "free" RAM on modern macOS. The kernel manages memory pressure automatically and far better than any user-space app can. Do not implement fake "RAM flush" features.

Instead provide **genuine, accurate monitoring:**

- Real-time memory pressure display using `host_statistics64` (Mach API), updated every 2 seconds.
- Breakdown of: Wired / Active / Inactive / Compressed / Free.
- Visual memory pressure indicator: Normal / Warning / Critical — matching the kernel's own thresholds.
- Compressed memory visualization (shows Compressor effectiveness — a ratio far above 2:1 indicates real pressure).
- Notification when pressure transitions to Warning or Critical.

```swift
import Darwin

func memoryStats() -> MemoryStats {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(
        MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
    )
    host_statistics64(mach_host_self(), HOST_VM_INFO64, &stats, &count)
    let pageSize = Int64(vm_page_size)
    return MemoryStats(
        wired:      Int64(stats.wire_count)            * pageSize,
        active:     Int64(stats.active_count)          * pageSize,
        inactive:   Int64(stats.inactive_count)        * pageSize,
        compressed: Int64(stats.compressor_page_count) * pageSize,
        free:       Int64(stats.free_count)            * pageSize
    )
}
```

---

### 6.10 Disk Analyzer

An interactive sunburst / treemap visualization of disk usage.

**Implementation:**

Use `FileManager.enumerator` to walk the volume recursively, accumulating allocated sizes per directory. Render the visualization using SwiftUI's `Canvas` API — it is GPU-accelerated and comfortably handles thousands of rectangles.

```swift
extension FileManager {
    func allocatedSize(at url: URL) throws -> Int64 {
        var size: Int64 = 0
        let enumerator = self.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey]
        )
        while let fileURL = enumerator?.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            size += Int64(values.totalFileAllocatedSize ?? 0)
        }
        return size
    }
}
```

**UI:** Click a sunburst segment to zoom into that directory. Breadcrumb navigation back to the root. Color-code by file type category (media, documents, development, system, other). A sidebar panel shows the top-10 largest items in the selected segment. Hover over any segment for a tooltip showing name, size, and percentage.

---

### 6.11 Trash Manager

A dedicated view of the current Trash contents, with capabilities beyond Finder's Trash:

- List all files in `~/.Trash/`, sorted by size, date, or originating app.
- Filter by category (images, videos, archives, documents).
- "Empty Trash" with a confirmation sheet showing total size to be freed.
- "Selective Empty" — delete only files matching a filter (e.g. delete all videos in Trash).
- Show how long each item has been in Trash.

**Best practices:**
- Show a "This is permanent" warning before any Trash deletion, distinct from the standard move-to-Trash flow.
- Never delete from Trash without a two-step confirmation, since this action is irreversible.

---

### 6.12 Network Cache Cleaner

Targets:
- System DNS cache: flush via `dscacheutil -flushcache` and `killall -HUP mDNSResponder` (requires administrator password via `AuthorizationServices`).
- `URLSession` shared cache: `URLCache.shared.removeAllCachedResponses()`.
- Browser network storage (distinct from history — covers IndexedDB, localStorage): in `~/Library/WebKit/<BundleID>/WebsiteData/`.
- App-specific network caches in `~/Library/Caches/*/com.apple.nsurlsessiond/`.

**Best practices:**
- Do not flush DNS automatically — always require explicit user action with a description of what the flush does ("Helps resolve connection issues caused by stale DNS entries").
- DNS flush requires an admin password; use `AuthorizationServices` and never store the password.

---

### 6.13 Development Junk

Targets developers who accumulate gigabytes of build artifacts:

- **Xcode DerivedData:** `~/Library/Developer/Xcode/DerivedData/` — list by project, show last build date.
- **Xcode Archives:** `~/Library/Developer/Xcode/Archives/` — list by app and date, allow selective removal.
- **iOS Simulators:** `~/Library/Developer/CoreSimulator/Devices/` — list by OS version, show which are unavailable/outdated.
- **SPM Caches:** `~/Library/Caches/org.swift.swiftpm/` and `~/.cache/org.swift.swiftpm/`.
- **CocoaPods Cache:** `~/Library/Caches/CocoaPods/`.
- **Carthage Binaries:** `~/Library/Caches/org.carthage.CarthageKit/`.
- **npm / node_modules:** Surface `node_modules` directories across the home folder, sorted by size.
- **Homebrew Cache:** `$(brew --cache)` — detect Homebrew installation and clean its download cache.

**UI:** Group by tool (Xcode, SPM, CocoaPods, npm, Homebrew). Show total size per tool category with a breakdown by project/version. For simulators, indicate which runtime versions are still installed and which are orphaned.

---

### 6.14 Font Manager

- Enumerate fonts in `~/Library/Fonts/` and `/Library/Fonts/`.
- Detect duplicate fonts (same PostScript name, different files).
- Flag fonts not used by any installed application (heuristic based on app resource scanning).
- Open the system Font Book for any selected font via `NSWorkspace.open`.

**Best practices:**
- Never delete system fonts in `/System/Library/Fonts/` — make these read-only in the UI.
- Show a font preview (rendered sample string) using `NSFont` before any deletion.
- Moving fonts to Trash may not immediately deregister them — advise users to log out or use `CTFontManagerUnregisterFontURLs` to deactivate first.

---

### 6.15 Screenshot & Recording Cleaner

Scan `~/Desktop`, `~/Documents`, and the configured Screenshots folder (`com.apple.screencapture location` defaults key) for:

- Screenshots: files matching the default naming pattern (`Screenshot YYYY-MM-DD at HH.MM.SS.png`).
- Screen recordings: files matching (`Screen Recording YYYY-MM-DD at HH.MM.SS.mov`).

**UI:** A grid view with thumbnails (via `QLThumbnailGenerator`). Sort by date or size. Multi-select with ⌘-click and ⇧-click. Show the total size of selected items in the toolbar.

---

### 6.16 Health Dashboard

A persistent overview visible on every app launch — not a scan module, but a real-time status panel.

Metrics:
- **Storage:** Total / Used / Available, with a color-coded usage bar. Warn below 10 GB available.
- **Memory Pressure:** Current kernel pressure level (Normal / Warning / Critical).
- **Battery Health:** Cycle count, maximum capacity percentage, and charge status via `IOKit`.
- **Last Scan:** Timestamp and total space recovered from the last cleaning session.
- **Startup Items:** Count of active login items and launch agents.

```swift
import IOKit.ps

func batteryInfo() -> BatteryInfo {
    let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let sources  = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
    // Parse IOPSGetPowerSourceDescription for cycle count, capacity, etc.
}
```

**UI:** Displayed as a row of compact glass metric cards at the top of the app, always visible regardless of which feature module is selected in the sidebar. Cards animate their values on update.

---

## 7. UI / UX Design System

### 7.1 Design Principles

1. **Clarity over cleverness.** Every element exists to help the user understand their system — not to impress. Decorative elements are subordinate to informational hierarchy.
2. **Non-destructive confidence.** Users should feel safe using the app. The UI must make it crystal clear that nothing is deleted without review and confirmation.
3. **Progressive disclosure.** The top level shows totals and categories. Drilling down reveals individual files. Never show file paths before the user has elected to inspect something.
4. **Native macOS feel.** The app should feel indistinguishable from a first-party Apple utility in its use of system controls, spacing, typography, and interaction patterns.
5. **Motion is meaningful.** Animations communicate state changes — scan progress, completion, file removal. They are never decorative.

---

### 7.2 Window & Layout Structure

The app uses a single primary window with `NavigationSplitView`, matching the macOS Tahoe standard layout for utility apps.

```swift
@main
struct CleanSweepApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)           // Liquid Glass toolbar extends edge-to-edge
        .windowResizability(.contentSize)
        .defaultSize(width: 960, height: 640)
        .windowMinimumSize(width: 800, height: 540)
    }
}

struct RootView: View {
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            DetailView(selection: selection)
                .backgroundExtensionEffect()    // macOS 26: fills floating sidebar gap
        }
    }
}
```

**Layout Zones:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Liquid Glass Toolbar]  CleanSweep    [Scan Now]   [Status Label]  │
├──────────────┬──────────────────────────────────────────────────────┤
│              │  [Health Dashboard — always-visible metric cards]     │
│   SIDEBAR    ├──────────────────────────────────────────────────────┤
│              │                                                       │
│  Dashboard   │              Detail / Module View                     │
│  Smart Scan  │                                                       │
│  ─────────   │     (Results list, visualization, or empty state)     │
│  System Junk │                                                       │
│  Duplicates  │                                                       │
│  Privacy     │                                                       │
│  ...         │                                                       │
│              │                                                       │
│  [Settings]  ├──────────────────────────────────────────────────────┤
│              │  [Deletion Summary Bar — appears after scan]          │
└──────────────┴──────────────────────────────────────────────────────┘
```

---

### 7.3 Sidebar Design

The sidebar uses `.listStyle(.sidebar)` with grouped sections. macOS Tahoe automatically applies the floating Liquid Glass material — do **not** add `NSVisualEffectView` or any custom background.

```swift
struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section("Overview") {
                SidebarRow(item: .dashboard,  symbol: "gauge.medium",              label: "Dashboard")
                SidebarRow(item: .smartScan,  symbol: "sparkles.rectangle.stack",  label: "Smart Scan")
            }
            Section("Clean") {
                SidebarRow(item: .systemJunk,   symbol: "trash.slash",        label: "System Junk",      badge: viewModel.junkBadge)
                SidebarRow(item: .development,  symbol: "hammer",             label: "Developer Junk",   badge: viewModel.devBadge)
                SidebarRow(item: .largeFiles,   symbol: "archivebox",         label: "Large & Old Files")
                SidebarRow(item: .duplicates,   symbol: "doc.on.doc",         label: "Duplicates")
                SidebarRow(item: .screenshots,  symbol: "camera.viewfinder",  label: "Screenshots")
                SidebarRow(item: .mailAttach,   symbol: "paperclip",          label: "Mail Attachments")
                SidebarRow(item: .trash,        symbol: "trash",              label: "Trash",            badge: viewModel.trashBadge)
            }
            Section("Protect") {
                SidebarRow(item: .privacy,  symbol: "hand.raised",  label: "Privacy")
                SidebarRow(item: .network,  symbol: "network",      label: "Network Cache")
            }
            Section("Manage") {
                SidebarRow(item: .uninstaller,  symbol: "app.badge.minus",  label: "Uninstaller")
                SidebarRow(item: .startup,      symbol: "bolt.fill",        label: "Startup Items")
                SidebarRow(item: .fonts,        symbol: "textformat",       label: "Font Manager")
                SidebarRow(item: .memory,       symbol: "memorychip",       label: "Memory")
                SidebarRow(item: .disk,         symbol: "externaldrive",    label: "Disk Analyzer")
            }
        }
        .listStyle(.sidebar)
        // ✅ Do NOT add .padding(.top) — it breaks the macOS 26 scroll-edge glass effect
    }
}
```

Sidebar badges use system-style `Badge` modifiers displaying size strings (e.g. "2.4 GB") after a scan has produced results.

---

### 7.4 Toolbar Design

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Scan Now", systemImage: "magnifyingglass") {
            Task { await viewModel.startScan() }
        }
        .buttonStyle(.glassProminent)           // accent-tinted glass (macOS 26+)
        .disabled(viewModel.isScanning)
    }
    ToolbarItem(placement: .status) {
        Text(viewModel.statusText)              // "Last scanned 2 minutes ago" / "Scanning..."
        // Plain Text in toolbar has no glass backing automatically
    }
    ToolbarItem(placement: .automatic) {
        Button("Settings", systemImage: "gear") { showSettings = true }
    }
}
```

---

### 7.5 Health Dashboard Cards

The always-visible metric cards use `GlassEffectContainer` so adjacent cards share a single compositing pass:

```swift
struct HealthDashboardRow: View {
    @Environment(\.healthViewModel) var vm

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            MetricCard(symbol: "internaldrive",        label: "Storage",      value: vm.storageUsed,        tint: vm.storageWarning ? .orange : .blue)
            MetricCard(symbol: "memorychip",           label: "Memory",       value: vm.memoryPressureLabel, tint: vm.memoryTint)
            MetricCard(symbol: "battery.100percent",   label: "Battery",      value: vm.batteryHealthLabel,  tint: .green)
            MetricCard(symbol: "clock.arrow.circlepath", label: "Last Cleaned", value: vm.lastCleanedRelative, tint: .secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

struct MetricCard: View {
    let symbol: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.title3)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

---

### 7.6 Scan Results List

Results stream in progressively. Each row is a `ScanResultRow` in a `LazyVStack` inside a `ScrollView`:

```swift
struct ScanResultRow: View {
    let result: ScanResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.systemSymbol)
                .font(.title2)
                .foregroundStyle(result.category.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.displayName)
                    .font(.body)
                    .lineLimit(1)
                Text(result.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(result.formattedSize)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassEffect(.regular, in: Capsule())

            Toggle("", isOn: $result.isSelected)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([result.url]) }
            Button("Quick Look")       { showQuickLook = true }
            Divider()
            Button("Move to Trash", role: .destructive) { /* ... */ }
        }
    }
}
```

**Interaction design:**
- Click a row to toggle its checkbox.
- ⌘+A selects all items in the current list.
- Space bar on a focused row opens Quick Look preview (`.quickLookPreview()` modifier).
- Right-click opens a context menu: Reveal in Finder, Quick Look, Move to Trash.
- Delete key on selected items triggers the deletion confirmation sheet.

---

### 7.7 Deletion Confirmation Sheet

Never delete without a summary sheet. The sheet must communicate: how many files, total size recovered, where they go (Trash vs permanent), and a clear way to cancel.

```swift
struct DeletionConfirmationSheet: View {
    let items: [ScanResult]
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("Move \(items.count) Items to Trash?")
                    .font(.title2.bold())
                Text("This will free up \(totalSize) of disk space.")
                    .foregroundStyle(.secondary)
            }

            // Preview of first 5 items
            VStack(alignment: .leading) {
                ForEach(items.prefix(5)) { item in
                    Label(item.displayName, systemImage: item.systemSymbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if items.count > 5 {
                    Text("…and \(items.count - 5) more items.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Move to Trash", action: onConfirm)
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.return)
            }
        }
        .padding(28)
        .frame(width: 420)
    }
}
```

---

### 7.8 Smart Scan Progress View

```swift
struct SmartScanProgressView: View {
    @Bindable var vm: ScanViewModel

    var body: some View {
        VStack(spacing: 32) {
            // Liquid Glass progress ring
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .foregroundStyle(.tint)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: vm.progress)
                VStack(spacing: 4) {
                    Text(vm.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.title.bold().monospacedDigit())
                    Text(vm.currentModuleName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)
            .glassEffect(.regular, in: Circle())

            // Per-module status list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ScanModule.allCases) { module in
                    HStack {
                        Image(systemName: vm.statusSymbol(for: module))
                            .foregroundStyle(vm.statusColor(for: module))
                        Text(module.displayName)
                            .font(.subheadline)
                        Spacer()
                        if let size = vm.result(for: module)?.formattedSize {
                            Text(size)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 320)

            if vm.isScanning {
                Button("Cancel Scan") { vm.cancelScan() }
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
    }
}
```

---

### 7.9 Empty States

Use `ContentUnavailableView` (macOS 14+) for all empty states — it automatically adopts system styling:

```swift
// No scan run yet
ContentUnavailableView(
    "Ready to Scan",
    systemImage: "sparkles",
    description: Text("Click Scan Now to find junk files and free up space.")
)

// Scan completed, nothing found
ContentUnavailableView(
    "Nothing to Clean",
    systemImage: "checkmark.circle",
    description: Text("This category is already clean.")
)
```

---

### 7.10 Animations & Transitions

All animations must be meaningful — they communicate state changes, not decoration.

| Transition | Animation | When |
|---|---|---|
| Scan idle → scanning | `.blurReplace` | Progress ring replaces idle state |
| Scanning → results | `.blurReplace` | Results dashboard replaces ring |
| Row insertion (streaming) | `.spring(duration: 0.35)` on count | New results stream in |
| Row deletion (after clean) | `.easeOut` with scale to 0 | Deleted items leave the list |
| Glass card expand to detail | `matchedGeometryEffect` + `GlassEffectContainer` | Category card → full results |

Respect `@Environment(\.accessibilityReduceMotion)` — all custom animations must be disabled. Use:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

.animation(reduceMotion ? .none : .spring(duration: 0.35), value: results.count)
```

---

### 7.11 Color System

Never hardcode colors. Always use semantic system colors:

```swift
// ✅ Correct
Color(.windowBackgroundColor)    // Adapts to light/dark/vibrant
Color.primary                    // High-emphasis text
Color.secondary                  // Secondary text
Color.accentColor                // System accent, user-configurable

// Category tints — always system colors
extension FileCategory {
    var tint: Color {
        switch self {
        case .userCache:         return .blue
        case .systemLog:         return .gray
        case .xcodeDerivedData:  return .purple
        case .duplicate:         return .orange
        case .browserCache:      return .teal
        case .largeFile:         return .red
        default:                 return .secondary
        }
    }
}

// ❌ Never hardcode hex or fixed RGB values
Color(red: 0.2, green: 0.5, blue: 1.0)
```

---

### 7.12 Typography

Use system font styles exclusively for all UI chrome. Custom fonts are reserved for marketing materials only.

| Context | Font Style |
|---|---|
| Screen title | `.title2.bold()` |
| Section header | `.headline` |
| Body / list row | `.body` |
| Secondary label | `.subheadline` |
| Metadata / path | `.caption` |
| Numeric metrics (live) | `.title3.monospacedDigit()` |
| Size values | `.callout.monospacedDigit()` |

Always use `.monospacedDigit()` on any numeric text that updates live — without it, the layout shifts as digit widths vary.

---

### 7.13 Settings

Structure settings into tabs using the `Settings` scene:

```swift
Settings {
    TabView {
        GeneralSettingsTab()
            .tabItem { Label("General",       systemImage: "gear") }
        ScanSettingsTab()
            .tabItem { Label("Scanning",      systemImage: "magnifyingglass") }
        ExclusionsSettingsTab()
            .tabItem { Label("Exclusions",    systemImage: "eye.slash") }
        PrivacySettingsTab()
            .tabItem { Label("Privacy",       systemImage: "hand.raised") }
        NotificationsTab()
            .tabItem { Label("Notifications", systemImage: "bell") }
    }
    .frame(width: 520)
}
```

**General:** Launch at login toggle, dock icon behavior, default scan scope.
**Scanning:** Large file threshold (slider), old file age threshold (slider), modules to include in Smart Scan.
**Exclusions:** List of excluded paths (add via drag-and-drop or `NSOpenPanel`). All paths in this list are silently skipped during all scans.
**Privacy:** Analytics opt-in (off by default), audit log location, clear audit log button.
**Notifications:** When to notify (scan complete, space below threshold, memory pressure warnings).

---

### 7.14 Onboarding

First-launch onboarding is a single modal sheet — not a multi-step wizard:

1. What the app does in two sentences.
2. A "Grant Full Disk Access" button that opens System Settings to the correct pane via `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles`.
3. An "I'll do this later" dismiss option — the app works without Full Disk Access for user-accessible paths.

Show onboarding only on first launch. On subsequent launches, detect Full Disk Access status and show a non-intrusive inline banner (not a sheet) when the user attempts to scan a restricted path.

---

### 7.15 Liquid Glass — Implementation Rules

```swift
// ✅ Glass over real content (NavigationSplitView detail)
DetailView()
    .backgroundExtensionEffect()

// ✅ Glass card — real window content is visible behind it
ScanResultCard()
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))

// ✅ Group of adjacent cards — shared compositing layer, can visually merge
GlassEffectContainer(spacing: 10) {
    MetricCard(...)
    MetricCard(...)
}

// ✅ Accent-tinted glass for the primary CTA button
Button("Clean Now") { ... }
    .buttonStyle(.glassProminent)

// ✅ Accessibility fallback
.glassEffect(.regular, in: shape, isEnabled: !reduceTransparency)

// ❌ Glass over an opaque Color fill — renders as a dark blob with no lensing
Color.windowBackground
    .glassEffect(...)

// ❌ NSVisualEffectView in a sidebar on macOS 26 — blocks system glass
// Remove it entirely; the system applies glass automatically
```

**Concentricity hierarchy:**
- Window chrome: ~12 pt (system-controlled)
- Main content cards: 14 pt
- Inline size badges: `Capsule()` (fully round)
- Buttons inside cards: 10 pt
- Sub-elements inside buttons: 8 pt

---

## 8. Performance Engineering

### 8.1 Scanning Performance Budgets

| Operation | Target | Hard Limit |
|---|---|---|
| UI frame rate during scan | 60 fps | 45 fps minimum |
| Time-to-first-result | < 500 ms | 2 s |
| Full smart scan (100 GB disk) | < 30 s | 90 s |
| Memory footprint during scan | < 80 MB | 150 MB |
| Post-scan UI response | < 16 ms | 50 ms |
| App cold launch to interactive | < 1 s | 2 s |

### 8.2 Thread Safety

- **Never** access `FileManager.default` from multiple threads — wrap it in a dedicated actor.
- **Never** call `URLResourceValues` from the main thread for large batches.
- Use `@MainActor` strictly for UI updates only; never apply it to business logic or scanning code.
- Enable Swift 6 strict concurrency checking (`SWIFT_STRICT_CONCURRENCY = complete`) and resolve all warnings before release.

### 8.3 Memory-Efficient File Reading

```swift
// ✅ Memory-mapped: OS handles paging, no heap allocation for the whole file
let data = try Data(contentsOf: url, options: .mappedIfSafe)

// ❌ Loads entire file into heap — dangerous for large files
let data = try Data(contentsOf: url)
```

### 8.4 UI Virtualization

Use `LazyVStack` inside `ScrollView` for all file lists — never `VStack` with large result sets. For the Disk Analyzer canvas, throttle redraws to 30 fps during data loading using a debounce strategy.

### 8.5 FileSystem Event Monitoring

Watch key directories for external changes and invalidate cached scan results:

```swift
let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fd,
    eventMask: [.write, .delete, .rename],
    queue: .global(qos: .utility)
)
source.setEventHandler { [weak self] in
    Task { await self?.invalidateCachedResults() }
}
source.resume()
```

### 8.6 Instruments Profiling Requirements

Before each release, profile with:
- **Time Profiler** — no main thread work > 16 ms
- **Allocations** — no unexpected spikes during scan
- **Leaks** — zero leaks after a full scan + deletion cycle
- **File Activity** — confirm all I/O occurs off the main thread
- **SwiftUI Instrument** — no unnecessary view body re-evaluations during scanning

---

## 9. Security & Privacy Best Practices

### 9.1 Principle of Least Privilege

- Request only the permissions needed for the specific action the user is performing.
- Guide the user to grant Full Disk Access only when they attempt to scan a restricted path — never request it proactively.
- Never store file contents, browser history data, credentials, or any user-identifiable information.

### 9.2 Code Signing & Notarization

```bash
# Sign with Hardened Runtime (required for notarization)
codesign --sign "Developer ID Application: Your Name (TEAMID)" \
         --options runtime \
         --entitlements CleanSweep.entitlements \
         --deep CleanSweep.app

# Notarize before every public release
xcrun notarytool submit CleanSweep.dmg \
    --keychain-profile "notarytool-profile" \
    --wait

# Staple the ticket to the DMG
xcrun stapler staple CleanSweep.dmg
```

### 9.3 Privacy Manifest (PrivacyInfo.xcprivacy)

```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array><string>C617.1</string></array>
    </dict>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array><string>85F4.1</string></array>
    </dict>
</array>
```

### 9.4 Deletion Safety

Every deletion follows this flow without exception:
1. **Scan** — read-only analysis, nothing is modified.
2. **Review** — user sees exactly what will be deleted, with sizes and paths.
3. **Confirm** — explicit confirmation sheet with item count and total size.
4. **Trash** — files moved to Trash via `NSWorkspace.recycle`.
5. **Log** — every deletion recorded to the audit log.

Permanent deletion is available only as a secondary option in the confirmation sheet, requiring an additional explicit toggle and a separate confirmation.

---

## 10. Data Persistence

### 10.1 Storage Strategy

| Data | Storage | Rationale |
|---|---|---|
| Last scan summary | `Application Support/LastScan.json` | Fast read on launch; survives app updates |
| User preferences | `@AppStorage` / `UserDefaults` | Simple key-value |
| Exclusion list | `Application Support/Exclusions.plist` | Structured, human-readable |
| Deletion audit log | `Application Support/AuditLog.sqlite` | Queryable, append-only |
| Security-scoped bookmarks | `UserDefaults` (raw `Data`) | Required for sandbox persistence |
| Health snapshot | In-memory only | Refreshed on every launch |

### 10.2 Deletion Audit Log Schema

```sql
CREATE TABLE deletion_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    path        TEXT NOT NULL,
    file_name   TEXT NOT NULL,
    size_bytes  INTEGER NOT NULL,
    category    TEXT NOT NULL,
    deleted_at  TEXT NOT NULL,      -- ISO-8601
    was_trashed INTEGER NOT NULL DEFAULT 1   -- 1 = Trash, 0 = permanent
);
```

The audit log is viewable in Settings → Privacy → View Deletion History. The user can export it as CSV or clear it entirely.

---

## 11. Testing Strategy

### 11.1 Unit Tests (ScanEngine package)

- Test `Categorizer` with fixture URLs — one test case per category path pattern.
- Test SHA-256 deduplication with synthetic duplicate files in a temp directory.
- Test directory size calculation against known directory trees.
- Test scan cancellation: `Task.cancel()` mid-scan must halt within one iteration.
- Use Swift Testing (`@Test`, `#expect`) — not XCTest — for all new tests.

### 11.2 Integration Tests

- Create a temporary directory tree with synthetic files (various sizes, types, modification dates).
- Run each scanner against the synthetic tree and assert the expected `ScanResult` set.
- Test that `moveToTrash` results in files appearing in `~/.Trash/`.
- Test the exclusion list: excluded paths must never appear in any scan result.

### 11.3 UI Tests (XCUITest)

- Test the Smart Scan flow end-to-end.
- Test that the deletion confirmation sheet appears and that cancellation is fully respected.
- Test keyboard navigation: Tab through all controls, Delete key triggers confirmation.
- Test VoiceOver: every control must have an `accessibilityLabel` that makes sense when read aloud.

### 11.4 Performance Tests

```swift
@Test
func scanPerformance() async throws {
    let clock = ContinuousClock()
    let elapsed = try await clock.measure {
        _ = try await SystemJunkScanner().scan()
    }
    #expect(elapsed < .seconds(30), "Full scan exceeded 30-second budget")
}
```

---

## 12. Distribution

### 12.1 Build Pipeline

Maintain a `Makefile` or shell script that performs: clean → build → test → archive → sign → notarize → staple → package DMG. Use `xcodebuild` from CI (GitHub Actions or Xcode Cloud) for reproducible builds. Never ship a build that has not passed all unit and integration tests.

### 12.2 DMG Packaging

```bash
create-dmg \
  --volname "CleanSweep" \
  --background "Assets/dmg-background.png" \
  --window-size 600 400 \
  --icon-size 128 \
  --icon "CleanSweep.app" 150 200 \
  --app-drop-link 450 200 \
  "CleanSweep.dmg" \
  "build/CleanSweep.app"
```

### 12.3 Auto-Updates (Sparkle 2)

```swift
import Sparkle

@main
struct CleanSweepApp: App {
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
}
```

Host an `appcast.xml` on a static CDN. Sign all update packages with `sign_update` (Sparkle's EdDSA signing tool). Enable `SUEnableAutomaticChecks` in Info.plist.

### 12.4 Versioning

Use semantic versioning: `MAJOR.MINOR.PATCH`. Increment `CFBundleVersion` on every build; increment the marketing version on every public release.

---

## 13. Accessibility

- All interactive elements must have `accessibilityLabel`, `accessibilityHint`, and `accessibilityRole`.
- Deletion confirmation dialogs must be focusable by VoiceOver and announce item count and total size when the sheet appears.
- Respect `@Environment(\.accessibilityReduceMotion)` — disable all custom animations.
- Respect `@Environment(\.accessibilityReduceTransparency)` — replace glass effects with opaque fills (see §7.15).
- Respect `@Environment(\.accessibilityDifferentiateWithoutColor)` — never use color as the sole indicator of state.
- Minimum interactive target: 44×44 pt for all buttons.
- Test with VoiceOver fully enabled before every release — navigate the entire app with keyboard and VoiceOver only.
- Support Dynamic Type — use semantic font styles only, never hardcoded point sizes.
- Sunburst/treemap visualization must have an accessible alternative: a plain sorted list of directories by size.

---

## 14. Localization

- Wrap ALL user-facing strings in `String(localized:)` or `LocalizedStringKey`. No bare string literals in Views.
- Use `formatted(.byteCount(style: .file))` for all file sizes — never manually construct "MB" or "GB".
- Use `formatted(.relative(presentation: .named))` for human-relative dates ("2 years ago").
- Use `Localizable.xcstrings` (Xcode 15+ string catalog format).
- Prioritize: English → French → German → Japanese → Chinese (Simplified) → Spanish.
- Test right-to-left layout with Arabic or Hebrew pseudo-localization before adding real RTL languages.
- Never concatenate localized strings — use format strings with named parameters.

---

## 15. Observability & Diagnostics

### 15.1 Logging

```swift
import OSLog

extension Logger {
    static let scan    = Logger(subsystem: "com.yourco.cleansweep", category: "scan")
    static let delete  = Logger(subsystem: "com.yourco.cleansweep", category: "delete")
    static let storage = Logger(subsystem: "com.yourco.cleansweep", category: "storage")
}

Logger.scan.info("Started scan at \(root.path, privacy: .public)")
Logger.delete.critical("Failed to move file to Trash: \(error, privacy: .public)")
```

Privacy rules: file paths → `.private`. File names → `.private`. Sizes, counts, durations → `.public`. System paths → `.public`.

### 15.2 Crash Reporting

```swift
import MetricKit

extension AppDelegate: MXMetricManagerSubscriber {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MXMetricManager.shared.add(self)
    }
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Save locally; surface in Settings → Diagnostics
        // Send to endpoint ONLY if user opted in
    }
}
```

### 15.3 Analytics (strictly opt-in, off by default)

Collect only: scan duration per module, module usage frequency, macOS version, deletion count and total bytes recovered (aggregate only). Never collect: file paths, file names, browser history data, or any content of deleted files.

---

## 16. macOS Best Practices Checklist

### App Lifecycle
- [ ] Use `@main` + `App` protocol (SwiftUI); use `@NSApplicationDelegateAdaptor` only when strictly necessary
- [ ] Handle `applicationShouldTerminateAfterLastWindowClosed` appropriately
- [ ] Support State Restoration — the selected sidebar item persists across launches
- [ ] Respond correctly to `NSWorkspace.willSleepNotification` — pause background scans

### Window Management
- [ ] Persist window frame across launches via `Scene.windowIdRestoration`
- [ ] Support full-screen mode
- [ ] Use `.windowStyle(.hiddenTitleBar)` for Liquid Glass apps
- [ ] Minimum window size prevents layout breakage

### Menu Bar
- [ ] Complete menu bar: File, Edit, View, Window, Help
- [ ] All major actions are keyboard-accessible
- [ ] Edit > Undo is implemented for all deletions (moves back from Trash)
- [ ] Help menu opens documentation or the app website
- [ ] File > Reveal in Finder works on the selected item

### Keyboard & Mouse
- [ ] Tab navigates all focusable elements in logical order
- [ ] Return/Space activate focused buttons
- [ ] Escape dismisses sheets and cancels scans
- [ ] ⌘A selects all in lists
- [ ] Delete key on selected items triggers deletion confirmation
- [ ] Right-click context menus on all list rows

### Drag & Drop
- [ ] Accept file drops onto the app icon (scan the dropped file/folder)
- [ ] Accept folder drops onto the Large Files and Duplicate Finder views
- [ ] Exclusions list accepts drag-and-drop of folders from Finder

### System Integration
- [ ] Respect System Appearance (Light/Dark/Auto) — never hardcode colors
- [ ] Respond to accent color changes (`Color.accentColor`)
- [ ] Show scan progress in Dock tile badge (`NSApplication.shared.dockTile`)
- [ ] Post `UserNotifications` when a background scan completes
- [ ] Register for `NSWorkspace.didMountVolumeNotification` to detect new external drives
- [ ] Open System Settings to specific panes using `x-apple.systempreferences:` URLs

### Liquid Glass (macOS 26)
- [ ] Remove all `NSVisualEffectView` from sidebar — blocks system glass on macOS 26
- [ ] Use `.backgroundExtensionEffect()` on NavigationSplitView detail views
- [ ] Apply `.glassEffect()` only where real content is behind it (never over opaque fills)
- [ ] Use `GlassEffectContainer` for groups of adjacent glass elements
- [ ] Respect concentricity: nested corner radii decrease inward
- [ ] All macOS 26-only APIs gated with `#available(macOS 26.0, *)`
- [ ] Opaque fallbacks for all glass elements when Reduce Transparency is enabled

### Performance
- [ ] Zero main-thread file I/O (verified with Thread Sanitizer)
- [ ] No `Thread.sleep` or blocking calls anywhere in scan code
- [ ] Memory footprint < 150 MB during a full scan (verified with Allocations instrument)
- [ ] Cold launch to interactive UI < 1 second
- [ ] Swift 6 strict concurrency checking enabled with zero warnings

### Privacy & Security
- [ ] `PrivacyInfo.xcprivacy` is present and complete
- [ ] Hardened Runtime enabled in all release builds
- [ ] No private API usage (`nm -g CleanSweep | grep -v " U "` to audit)
- [ ] All file deletions go to Trash first (never direct `removeItem` on first action)
- [ ] Deletion always requires explicit user confirmation
- [ ] No analytics without explicit opt-in

### Distribution
- [ ] App notarized and ticket stapled before every public release
- [ ] Sparkle 2 integrated with EdDSA-signed appcast
- [ ] Version and build number increment on every release
- [ ] DMG tested on a clean VM before distribution

---

*Last updated: April 2026 — targets macOS Tahoe 26, Xcode 26, Swift 6.1*
