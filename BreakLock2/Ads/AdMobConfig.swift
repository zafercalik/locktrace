import Foundation

enum AdMobConfig {
    /// AdMob App ID (also set in BreakLock2-Info.plist).
    static let appID = "ca-app-pub-3023673137817649~6618693867"

    /// Set to `true` only while verifying integration with Google sample units.
    /// `false` uses your real AdMob units (register the device as a test device in AdMob UI).
    static let useTestAds = false

    /// Production banner unit.
    private static let productionBannerAdUnitID = "ca-app-pub-3023673137817649/2292436041"

    /// Production rewarded unit.
    private static let productionRewardedAdUnitID = "ca-app-pub-3023673137817649/2143041042"

    /// Google official sample banner unit.
    private static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

    /// Google official sample rewarded unit.
    private static let testRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    static var bannerAdUnitID: String {
        useTestAds ? testBannerAdUnitID : productionBannerAdUnitID
    }

    static var rewardedAdUnitID: String {
        useTestAds ? testRewardedAdUnitID : productionRewardedAdUnitID
    }

    /// Extra attempts granted after a completed rewarded ad.
    static let bonusAttemptsPerReward = 5
}
