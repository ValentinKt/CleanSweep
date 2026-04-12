//
//  CleanSweepApp.swift
//  CleanSweep
//

import SwiftUI

@main
struct CleanSweepApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let appModel = AppModel.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 960, height: 640)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                appModel.resume()
            case .background, .inactive:
                appModel.suspend()
            @unknown default:
                break
            }
        }
    }
}
