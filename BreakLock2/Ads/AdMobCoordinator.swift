import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import UIKit

@MainActor
final class AdMobCoordinator: NSObject, ObservableObject {
    static let shared = AdMobCoordinator()

    @Published private(set) var isRewardedReady = false
    @Published private(set) var isShowingRewarded = false

    private var rewardedAd: RewardedAd?
    private var rewardCompletion: ((Bool) -> Void)?

    private override init() {
        super.init()
    }

    func start() {
        MobileAds.shared.start(completionHandler: nil)
        requestTrackingIfNeeded()
        loadRewardedAd()
    }

    func loadRewardedAd() {
        RewardedAd.load(with: AdMobConfig.rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("Rewarded ad failed to load: \(error.localizedDescription)")
                    self.rewardedAd = nil
                    self.isRewardedReady = false
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isRewardedReady = ad != nil
            }
        }
    }

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        rewardCompletion = completion

        guard let rewardedAd else {
            loadRewardedAd()
            completion(false)
            return
        }

        guard let root = UIApplication.shared.topViewController else {
            completion(false)
            return
        }

        isShowingRewarded = true
        rewardedAd.present(from: root) { [weak self] in
            guard let self else { return }
            let reward = rewardedAd.adReward
            print("User earned reward: \(reward.amount) \(reward.type)")
            self.rewardCompletion?(true)
            self.rewardCompletion = nil
        }
    }

    private func requestTrackingIfNeeded() {
        // Delay slightly so the ATT prompt is not buried under launch UI.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { _ in }
            }
        }
    }
}

extension AdMobCoordinator: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            isShowingRewarded = false
            rewardedAd = nil
            isRewardedReady = false
            if rewardCompletion != nil {
                // Dismissed without earning reward.
                rewardCompletion?(false)
                rewardCompletion = nil
            }
            loadRewardedAd()
        }
    }

    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            print("Rewarded ad failed to present: \(error.localizedDescription)")
            isShowingRewarded = false
            rewardedAd = nil
            isRewardedReady = false
            rewardCompletion?(false)
            rewardCompletion = nil
            loadRewardedAd()
        }
    }
}

extension UIApplication {
    var topViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMost()
    }
}

private extension UIViewController {
    func topMost() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMost()
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMost()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMost()
        }
        return self
    }
}
