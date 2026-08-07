import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import UIKit

@MainActor
final class AdMobCoordinator: NSObject, ObservableObject {
    static let shared = AdMobCoordinator()

    @Published private(set) var isRewardedReady = false
    @Published private(set) var isShowingRewarded = false
    @Published private(set) var isLoadingRewarded = false

    private var rewardedAd: RewardedAd?
    private var rewardCompletion: ((Bool) -> Void)?
    private var isLoadInFlight = false
    private var loadWaitContinuations: [CheckedContinuation<Bool, Never>] = []

    private override init() {
        super.init()
    }

    /// Called after `MobileAds.shared.start` from AppDelegate.
    func prepareAfterSDKStart() {
        if AdMobConfig.useTestAds {
            print("AdMob: using Google SAMPLE ad unit IDs (test mode)")
        } else {
            print("AdMob: using PRODUCTION ad unit IDs")
        }
        requestTrackingIfNeeded()
        loadRewardedAd()
    }

    func loadRewardedAd() {
        guard !isLoadInFlight else { return }
        isLoadInFlight = true
        isLoadingRewarded = true

        print("AdMob: loading rewarded unit \(AdMobConfig.rewardedAdUnitID)")
        RewardedAd.load(with: AdMobConfig.rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoadInFlight = false
                self.isLoadingRewarded = false

                if let error {
                    print("AdMob: rewarded load failed: \(error.localizedDescription)")
                    self.rewardedAd = nil
                    self.isRewardedReady = false
                    self.finishLoadWaiters(success: false)
                    // Retry shortly; new accounts / network blips are common.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.loadRewardedAd()
                    }
                    return
                }

                print("AdMob: rewarded ad ready")
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isRewardedReady = ad != nil
                self.finishLoadWaiters(success: ad != nil)
            }
        }
    }

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            let ready = await ensureRewardedReady(timeoutSeconds: 12)
            guard ready, let rewardedAd else {
                print("AdMob: rewarded still not ready after wait")
                completion(false)
                return
            }

            guard let root = UIApplication.shared.topViewController else {
                print("AdMob: no root view controller to present rewarded ad")
                completion(false)
                return
            }

            rewardCompletion = completion
            isShowingRewarded = true
            rewardedAd.present(from: root) { [weak self] in
                guard let self else { return }
                let reward = rewardedAd.adReward
                print("AdMob: user earned reward \(reward.amount) \(reward.type)")
                self.rewardCompletion?(true)
                self.rewardCompletion = nil
            }
        }
    }

    private func ensureRewardedReady(timeoutSeconds: TimeInterval) async -> Bool {
        if rewardedAd != nil { return true }

        loadRewardedAd()

        return await withCheckedContinuation { continuation in
            loadWaitContinuations.append(continuation)

            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
                guard let self else { return }
                // If still waiting after timeout, fail this waiter only.
                if let index = self.loadWaitContinuations.firstIndex(where: { ObjectIdentifier($0) == ObjectIdentifier(continuation) }) {
                    // CheckedContinuation isn't Equatable; close all waiters if still pending after timeout when not ready.
                }
                if self.rewardedAd == nil && !self.loadWaitContinuations.isEmpty {
                    self.finishLoadWaiters(success: false)
                }
            }
        }
    }

    private func finishLoadWaiters(success: Bool) {
        let waiters = loadWaitContinuations
        loadWaitContinuations.removeAll()
        waiters.forEach { $0.resume(returning: success) }
    }

    private func requestTrackingIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { status in
                    print("AdMob: ATT status \(status.rawValue)")
                }
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
            print("AdMob: rewarded present failed: \(error.localizedDescription)")
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
