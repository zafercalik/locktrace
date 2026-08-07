//
//  BreakLock2App.swift
//  BreakLock2
//
//  Created by Zafer Calik on 12.07.2025.
//

import SwiftUI

@main
struct BreakLock2App: App {
    init() {
        AdMobCoordinator.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AdMobCoordinator.shared)
        }
    }
}
