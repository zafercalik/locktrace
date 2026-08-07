//
//  BreakLock2App.swift
//  BreakLock2
//
//  Created by Zafer Calik on 12.07.2025.
//

import SwiftUI
import GoogleMobileAds
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Ensure GADApplicationIdentifier from Info.plist is available before start.
        let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String
        if appID?.isEmpty != false {
            assertionFailure("Missing GADApplicationIdentifier in Info.plist")
            print("ERROR: Missing GADApplicationIdentifier in Info.plist")
        }
        MobileAds.shared.start(completionHandler: nil)
        AdMobCoordinator.shared.prepareAfterSDKStart()
        return true
    }
}

@main
struct BreakLock2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AdMobCoordinator.shared)
        }
    }
}
