import Foundation
import Combine
import StoreKit

/// 課金商品 ID。App Store Connect / GAtsume.storekit と一致させる必要がある。
enum PurchaseProductID {
    static let removeAds = "com.gatsume.removeads"
}

/// `@AppStorage("adsRemoved")` と連携する StoreKit 2 ベースの課金マネージャ。
/// 起動時に `bootstrap()` を呼び、UI からは `purchaseRemoveAds()` / `restore()` / `reloadProducts()` を叩く。
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var isPurchasing: Bool = false

    /// 商品取得に失敗した場合の表示用メッセージ。SettingsView の購入セクションに inline で表示する。
    @Published private(set) var productLoadError: String?

    /// 購入/復元アクション中に発生した一過性エラー。alert で表示し、確認後にクリアする。
    @Published var actionErrorMessage: String?

    private var transactionListener: Task<Void, Never>?

    var removeAdsProduct: Product? {
        products.first { $0.id == PurchaseProductID.removeAds }
    }

    /// `Product.displayPrice` はロケール対応済みのフォーマット済み文字列 (例: "¥280")。
    var removeAdsPriceText: String? {
        removeAdsProduct?.displayPrice
    }

    var hasRemovedAds: Bool {
        purchasedProductIDs.contains(PurchaseProductID.removeAds)
    }

    private init() {
        transactionListener = startTransactionListener()
    }

    deinit {
        transactionListener?.cancel()
    }

    func bootstrap() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        productLoadError = nil
        defer { isLoadingProducts = false }
        do {
            let fetched = try await Product.products(for: [PurchaseProductID.removeAds])
            // StoreKit Configuration が Scheme に未設定 / App Store Connect 側で
            // Ready to Submit になっていない / ネットワーク不通 などのとき空配列が返る。
            if fetched.isEmpty {
                products = []
                productLoadError = "商品情報を取得できませんでした。シミュレータでは Edit Scheme → Run → Options → StoreKit Configuration に GAtsume.storekit を設定してください。実機では App Store Connect 側で商品が「Ready to Submit」になっているか確認してください。"
            } else {
                products = fetched
                productLoadError = nil
            }
        } catch {
            products = []
            productLoadError = "商品情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    /// SettingsView の「再読み込み」ボタンから呼ぶ。
    func reloadProducts() async {
        await loadProducts()
    }

    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else {
            actionErrorMessage = "商品情報が読み込めていません。先に「再読み込み」を実行してください。"
            return
        }
        await purchase(product)
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                // 親の承認待ちなど。Transaction.updates 経由で完了通知が届く。
                break
            @unknown default:
                break
            }
        } catch {
            actionErrorMessage = "購入に失敗しました: \(error.localizedDescription)"
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            actionErrorMessage = "購入の復元に失敗しました: \(error.localizedDescription)"
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil && !transaction.isUpgraded {
                ids.insert(transaction.productID)
            }
        }
        purchasedProductIDs = ids
        // 既存の AdBannerContainer (@AppStorage("adsRemoved")) と連携。
        UserDefaults.standard.set(hasRemovedAds, forKey: "adsRemoved")
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    /// 起動中に届く Transaction.updates (Sandbox 親承認復帰や別端末購入の同期など) を捕捉。
    nonisolated private func startTransactionListener() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
    }
}
