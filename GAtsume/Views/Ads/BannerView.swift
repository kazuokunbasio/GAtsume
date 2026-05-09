import SwiftUI
import GoogleMobileAds
import UIKit

enum AdsConfig {
    static let productionBannerAdUnitID = "ca-app-pub-2165259899292420/6791906149"

    // Google公式のテスト用バナーID。シミュレータ/DEBUGビルドで利用。
    // https://developers.google.com/admob/ios/test-ads
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

    static var bannerAdUnitID: String {
        #if DEBUG
        return testBannerAdUnitID
        #else
        return productionBannerAdUnitID
        #endif
    }
}

@MainActor
enum AdsBootstrap {
    private static var didStart = false

    static func startIfNeeded() {
        guard !didStart else { return }
        didStart = true

        #if DEBUG
        // 実機でテスト広告を強制したい場合はここにデバイスIDを追記する。
        // シミュレータは自動的にテスト広告として扱われる。
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = []
        #endif

        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}

struct BannerView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdsConfig.bannerAdUnitID) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.topViewController()
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    private static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

/// 広告削除フラグを尊重して表示するコンテナ。
/// 将来 RevenueCat 連携時は AppStorage("adsRemoved") を購入状態で書き換えるだけで非表示化できる。
struct AdBannerContainer: View {
    @AppStorage("adsRemoved") private var adsRemoved: Bool = false

    var body: some View {
        if !adsRemoved {
            BannerView()
                .frame(height: 50)
        }
    }
}

/// タブのコンテンツ領域内・最下部にバナーを配置する。タブバーは下にそのまま残るので
/// 画面遷移ボタンと重ならない。`AdBannerContainer` が広告削除フラグを見ているので、
/// 購入後は自動でバナー分の余白も消える。
struct BannerHostingView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            AdBannerContainer()
        }
    }
}

extension View {
    /// 画面下に AdBannerContainer を貼り付け、画面コンテンツがその上に収まるようにする。
    /// 設定画面など広告を出したくない画面では呼ばないこと。
    func withBanner() -> some View {
        BannerHostingView { self }
    }
}
