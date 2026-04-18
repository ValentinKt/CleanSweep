//
//  DetailView.swift
//  CleanSweep
//

import SwiftUI
import ScanEngine

struct DetailView: View {
    @Binding var selection: SidebarItem?
    var smartScanViewModel: SmartScanViewModel
    var moduleSessionStore: ModuleScanSessionStore

    var body: some View {
        contentView
            .navigationTitle(selection?.rawValue.capitalized ?? "CleanSweep")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var contentView: some View {
        if let selection {
            switch selection {
            case .dashboard:
                if #available(macOS 26.0, *) {
                    DashboardView {
                        self.selection = .smartScan
                        Task { await smartScanViewModel.startScan() }
                    }
                } else {
                    Text("Dashboard requires macOS 26.0")
                }
            case .smartScan:
                if #available(macOS 26.0, *) {
                    SmartScanView(viewModel: smartScanViewModel, selection: $selection)
                } else {
                    Text("Smart Scan requires macOS 26.0")
                }
            case .systemJunk, .development, .largeFiles, .screenshots, .duplicates,
                    .mailAttachments, .trash, .privacy, .uninstaller, .startup,
                    .networkCache, .fonts, .leftovers:
                if #available(macOS 26.0, *) {
                    moduleScanView(for: selection)
                } else {
                    Text("\(selection.localizedName) requires macOS 26.0")
                }
            case .memory:
                if #available(macOS 26.0, *) {
                    MemoryMonitorView()
                } else {
                    Text("Memory Monitor requires macOS 26.0")
                }
            case .disk:
                if #available(macOS 26.0, *) {
                    DiskAnalyzerView()
                } else {
                    Text("Disk Analyzer requires macOS 26.0")
                }
            }
        } else {
            ContentUnavailableView("Select an item", systemImage: "sidebar.left")
        }
    }

    @available(macOS 26.0, *)
    @ViewBuilder
    private func moduleScanView(for item: SidebarItem) -> some View {
        if let descriptor = item.moduleScanDescriptor {
            let seedsFromSmartScan = smartScanViewModel.reviewSeedDestination == item
            ModuleScanView(
                viewModel: moduleSessionStore.viewModel(for: item, descriptor: descriptor),
                title: descriptor.title,
                systemImage: descriptor.systemImage,
                descriptionText: descriptor.descriptionText,
                highlights: descriptor.highlights,
                initialResults: seedsFromSmartScan ? smartScanSeedResults(for: item) : [],
                initialResultsSeedID: seedsFromSmartScan ? smartScanViewModel.reviewSeedID : nil
            )
            .task(id: seedsFromSmartScan) {
                guard seedsFromSmartScan else { return }
                smartScanViewModel.clearReviewSeed()
            }
        }
    }

    private func smartScanSeedResults(for item: SidebarItem) -> [ScanResult] {
        let categories = item.smartScanCategories
        guard !categories.isEmpty else { return [] }

        return smartScanViewModel.results.filter { categories.contains($0.category) }
    }
}

@MainActor
@Observable
final class ModuleScanSessionStore {
    private var viewModels: [SidebarItem: ModuleScanViewModel] = [:]

    fileprivate func viewModel(for item: SidebarItem, descriptor: ModuleScanDescriptor) -> ModuleScanViewModel {
        if let existing = viewModels[item] {
            return existing
        }

        let viewModel = ModuleScanViewModel(
            scanner: descriptor.makeScanner(),
            moduleName: descriptor.title
        )
        viewModels[item] = viewModel
        return viewModel
    }
}

private struct ModuleScanDescriptor {
    let title: String
    let systemImage: String
    let descriptionText: String
    let highlights: [ModuleScanHighlight]
    let makeScanner: () -> any ModuleScanner
}

private extension SidebarItem {
    var moduleScanDescriptor: ModuleScanDescriptor? {
        switch self {
        case .systemJunk:
            ModuleScanDescriptor(
                title: "System Junk",
                systemImage: iconName,
                descriptionText: "Find caches, logs, temp files, and other reclaimable clutter " +
                    "with the same review flow as Smart Scan.",
                highlights: [
                    ModuleScanHighlight(title: "Caches", systemImage: "internaldrive"),
                    ModuleScanHighlight(title: "Logs", systemImage: "doc.text"),
                    ModuleScanHighlight(
                        title: "Temp Files",
                        systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                    )
                ],
                makeScanner: { SystemJunkScanner() }
            )
        case .development:
            ModuleScanDescriptor(
                title: "Developer Junk",
                systemImage: iconName,
                descriptionText: "Review build products, simulators, and package caches with " +
                    "the same ranked cleanup experience as Smart Scan.",
                highlights: [
                    ModuleScanHighlight(title: "Derived Data", systemImage: "hammer"),
                    ModuleScanHighlight(title: "Simulators", systemImage: "iphone"),
                    ModuleScanHighlight(title: "SPM Cache", systemImage: "shippingbox")
                ],
                makeScanner: { DevelopmentJunkScanner() }
            )
        case .largeFiles:
            ModuleScanDescriptor(
                title: "Large & Old Files",
                systemImage: iconName,
                descriptionText: "Surface the heaviest files first so you can review aging " +
                    "storage hotspots with Smart Scan style controls.",
                highlights: [
                    ModuleScanHighlight(title: "Largest First", systemImage: "arrow.down"),
                    ModuleScanHighlight(title: "Old Files", systemImage: "calendar"),
                    ModuleScanHighlight(title: "Quick Review", systemImage: "eye")
                ],
                makeScanner: { LargeFilesScanner() }
            )
        case .screenshots:
            ModuleScanDescriptor(
                title: "Screenshots & Recordings",
                systemImage: iconName,
                descriptionText: "Gather screen captures and recordings into a single Smart " +
                    "Scan style review surface before cleanup.",
                highlights: [
                    ModuleScanHighlight(title: "Screenshots", systemImage: "camera"),
                    ModuleScanHighlight(title: "Recordings", systemImage: "video"),
                    ModuleScanHighlight(title: "Preview Ready", systemImage: "sparkles")
                ],
                makeScanner: { ScreenshotScanner() }
            )
        case .duplicates:
            ModuleScanDescriptor(
                title: "Duplicates",
                systemImage: iconName,
                descriptionText: "Review duplicate files with the same focused Smart Scan " +
                    "presentation before sending extras to Trash.",
                highlights: [
                    ModuleScanHighlight(title: "Matched Files", systemImage: "doc.on.doc"),
                    ModuleScanHighlight(title: "Select Extras", systemImage: "checkmark.circle"),
                    ModuleScanHighlight(title: "Safe Review", systemImage: "shield")
                ],
                makeScanner: { DuplicateFinderScanner() }
            )
        case .mailAttachments:
            ModuleScanDescriptor(
                title: "Mail Attachments",
                systemImage: iconName,
                descriptionText: "Sort downloaded attachments by size and clean them up with " +
                    "the same Smart Scan style workflow.",
                highlights: [
                    ModuleScanHighlight(title: "Mailbox Files", systemImage: "envelope"),
                    ModuleScanHighlight(title: "Largest First", systemImage: "arrow.down.circle"),
                    ModuleScanHighlight(title: "Select to Clean", systemImage: "checklist")
                ],
                makeScanner: { MailAttachmentScanner() }
            )
        case .trash:
            ModuleScanDescriptor(
                title: "Trash",
                systemImage: iconName,
                descriptionText: "Review trashed items with the same Smart Scan inspired shell " +
                    "before permanently clearing space.",
                highlights: [
                    ModuleScanHighlight(title: "Trash Items", systemImage: "trash"),
                    ModuleScanHighlight(title: "Recoverable Space", systemImage: "externaldrive"),
                    ModuleScanHighlight(title: "Select to Empty", systemImage: "checkmark.circle")
                ],
                makeScanner: { TrashScanner() }
            )
        case .privacy:
            ModuleScanDescriptor(
                title: "Privacy",
                systemImage: iconName,
                descriptionText: "Review privacy-sensitive traces with the same clean, " +
                    "selectable Smart Scan experience.",
                highlights: [
                    ModuleScanHighlight(title: "Recent Traces", systemImage: "clock"),
                    ModuleScanHighlight(title: "Browser Data", systemImage: "globe"),
                    ModuleScanHighlight(title: "Selectable", systemImage: "checkmark.circle")
                ],
                makeScanner: { PrivacyScanner() }
            )
        case .uninstaller:
            ModuleScanDescriptor(
                title: "App Uninstaller",
                systemImage: iconName,
                descriptionText: "Inspect removable apps with the same polished Smart Scan " +
                    "layout before uninstalling selected items.",
                highlights: [
                    ModuleScanHighlight(title: "Installed Apps", systemImage: "app.dashed"),
                    ModuleScanHighlight(title: "Select to Remove", systemImage: "minus.circle"),
                    ModuleScanHighlight(title: "Size Ranked", systemImage: "arrow.down.circle")
                ],
                makeScanner: { AppUninstallerScanner() }
            )
        case .leftovers:
            ModuleScanDescriptor(
                title: "Leftovers",
                systemImage: iconName,
                descriptionText: "Clean up files left behind by uninstalled applications.",
                highlights: [
                    ModuleScanHighlight(title: "App Leftovers", systemImage: "puzzlepiece.extension"),
                    ModuleScanHighlight(title: "Reclaim Space", systemImage: "arrow.down.circle"),
                    ModuleScanHighlight(title: "Select to Clean", systemImage: "checklist")
                ],
                makeScanner: { LeftoversScanner() }
            )
        case .startup:
            ModuleScanDescriptor(
                title: "Startup Items",
                systemImage: iconName,
                descriptionText: "Review launch items with the same guided Smart Scan style " +
                    "shell and selective cleanup flow.",
                highlights: [
                    ModuleScanHighlight(
                        title: "Login Items",
                        systemImage: "person.crop.circle.badge.checkmark"
                    ),
                    ModuleScanHighlight(title: "Selective Control", systemImage: "switch.2"),
                    ModuleScanHighlight(title: "Quick Review", systemImage: "eye")
                ],
                makeScanner: { StartupManagerScanner() }
            )
        case .networkCache:
            ModuleScanDescriptor(
                title: "Network Cache",
                systemImage: iconName,
                descriptionText: "Sweep browser and network caches through the same Tahoe-style " +
                    "review surface used by Smart Scan.",
                highlights: [
                    ModuleScanHighlight(title: "Browser Cache", systemImage: "safari"),
                    ModuleScanHighlight(title: "Network Data", systemImage: "network"),
                    ModuleScanHighlight(title: "Largest First", systemImage: "arrow.down")
                ],
                makeScanner: { NetworkCacheScanner() }
            )
        case .fonts:
            ModuleScanDescriptor(
                title: "Font Manager",
                systemImage: iconName,
                descriptionText: "Inspect duplicate and removable fonts inside the same Smart " +
                    "Scan inspired selection workflow.",
                highlights: [
                    ModuleScanHighlight(title: "Duplicate Fonts", systemImage: "textformat"),
                    ModuleScanHighlight(
                        title: "Sorted Results",
                        systemImage: "line.3.horizontal.decrease.circle"
                    ),
                    ModuleScanHighlight(title: "Select to Clean", systemImage: "checklist")
                ],
                makeScanner: { FontManagerScanner() }
            )
        default:
            nil
        }
    }

    var smartScanCategories: Set<FileCategory> {
        switch self {
        case .systemJunk:
            [.userCache, .systemLog, .tempFile, .languagePack, .appSupportOrphan]
        case .largeFiles:
            [.largeFile, .oldFile]
        case .duplicates:
            [.duplicate]
        case .screenshots:
            [.screenshot, .screenRecording]
        case .development:
            [.xcodeDerivedData, .xcodeSimulator, .spmCache]
        case .mailAttachments:
            [.mailAttachment]
        case .trash:
            [.trashItem]
        case .networkCache:
            [.browserCache, .networkCache]
        case .uninstaller:
            [.application]
        case .startup:
            [.startupItem]
        case .fonts:
            [.fontDuplicate]
        default:
            []
        }
    }
}
