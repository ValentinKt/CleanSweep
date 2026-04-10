//
//  CleanSweepApp.swift
//  CleanSweep
//

import SwiftUI

@main
struct CleanSweepApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)           // Liquid Glass toolbar extends edge-to-edge
        .windowResizability(.contentSize)
        .defaultSize(width: 960, height: 640)
    }
}
