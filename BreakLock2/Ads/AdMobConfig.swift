import Foundation

enum AdMobConfig {
    /// AdMob App ID (also set in Info.plist via build settings).
    static let appID = "ca-app-pub-3023673137817649~6618693867"

    /// Production banner unit.
    static let bannerAdUnitID = "ca-app-pub-3023673137817649/2292436041"

    /// Production rewarded unit.
    static let rewardedAdUnitID = "ca-app-pub-3023673137817649/2143041042"

    /// Extra attempts granted after a completed rewarded ad.
    static let bonusAttemptsPerReward = 5
}
