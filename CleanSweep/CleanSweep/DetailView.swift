//
//  DetailView.swift
//  CleanSweep
//

import SwiftUI
import ScanEngine

struct DetailView: View {
    @Binding var selection: SidebarItem?
    var smartScanViewModel: SmartScanViewModel

    var body: some View {
        contentView
            .navigationTitle(selection?.rawValue.capitalized ?? "CleanSweep")
    }

    @ViewBuilder
    private var contentView: some View {
        if let selection {
            switch selection {
            case .dashboard:
                DashboardView()
            case .smartScan:
                if #available(macOS 26.0, *) {
                    SmartScanView(viewModel: smartScanViewModel, selection: $selection)
                } else {
                    Text("Smart Scan requires macOS 26.0")
                }
            case .systemJunk:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: SystemJunkScanner(), title: "System Junk")
                } else {
                    Text("System Junk requires macOS 26.0")
                }
            case .development:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: DevelopmentJunkScanner(), title: "Developer Junk")
                } else {
                    Text("Developer Junk requires macOS 26.0")
                }
            case .largeFiles:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: LargeFilesScanner(), title: "Large & Old Files")
                } else {
                    Text("Large & Old Files requires macOS 26.0")
                }
            case .screenshots:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: ScreenshotScanner(), title: "Screenshots & Recordings")
                } else {
                    Text("Screenshots requires macOS 26.0")
                }
            case .duplicates:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: DuplicateFinderScanner(), title: "Duplicates")
                } else {
                    Text("Duplicates requires macOS 26.0")
                }
            case .mailAttachments:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: MailAttachmentScanner(), title: "Mail Attachments")
                } else {
                    Text("Mail Attachments requires macOS 26.0")
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
            case .trash:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: TrashScanner(), title: "Trash")
                } else {
                    Text("Trash requires macOS 26.0")
                }
            case .privacy:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: PrivacyScanner(), title: "Privacy")
                } else {
                    Text("Privacy requires macOS 26.0")
                }
            case .uninstaller:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: AppUninstallerScanner(), title: "App Uninstaller")
                } else {
                    Text("App Uninstaller requires macOS 26.0")
                }
            case .startup:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: StartupManagerScanner(), title: "Startup Items")
                } else {
                    Text("Startup Manager requires macOS 26.0")
                }
            case .networkCache:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: NetworkCacheScanner(), title: "Network Cache")
                } else {
                    Text("Network Cache requires macOS 26.0")
                }
            case .fonts:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: FontManagerScanner(), title: "Font Manager")
                } else {
                    Text("Font Manager requires macOS 26.0")
                }
            default:
                ContentUnavailableView(
                    "\(selection.rawValue.capitalized)",
                    systemImage: "hammer.fill",
                    description: Text("This feature is under construction.")
                )
            }
        } else {
            ContentUnavailableView("Select an item", systemImage: "sidebar.left")
        }
    }
}
