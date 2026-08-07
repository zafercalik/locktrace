import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    @ObservedObject private var ads = AdMobCoordinator.shared

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.topViewController
        bannerView.delegate = context.coordinator
        context.coordinator.bannerView = bannerView
        if ads.canLoadAds {
            context.coordinator.loadIfNeeded()
        }
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.rootViewController == nil {
            uiView.rootViewController = UIApplication.shared.topViewController
        }
        context.coordinator.bannerView = uiView
        if ads.canLoadAds {
            context.coordinator.loadIfNeeded()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var bannerView: BannerView?
        private var didLoad = false

        func loadIfNeeded() {
            guard !didLoad, let bannerView else { return }
            didLoad = true
            if bannerView.rootViewController == nil {
                bannerView.rootViewController = UIApplication.shared.topViewController
            }
            print("AdMob: loading banner unit \(bannerView.adUnitID ?? "nil")")
            bannerView.load(Request())
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("AdMob: banner loaded")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("AdMob: banner failed: \(error.localizedDescription)")
            // Allow a later retry after ATT / next appearance.
            didLoad = false
        }
    }
}
