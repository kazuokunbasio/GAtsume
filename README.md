# GAtsume (ゴキあつめ)

放置型コレクションゲーム。プレイヤーは部屋にエサや家具を置き、訪れるさまざまな「ゴキ」を観察・収集する。
ねこあつめの構造に、ブラックユーモア・奇妙な可愛さ・コレクション欲を載せた "妙に愛着が湧く変なアプリ"。

## 技術スタック

- **言語**: Swift 5
- **UI**: SwiftUI
- **永続化**: SwiftData
- **ゲーム描画**: SpriteKit (`RoomScene`)
- **広告**: Google Mobile Ads SDK (AdMob、バナー)
- **課金**: StoreKit 2 (Non-Consumable: 広告削除)
- **対応**: iOS 26.2+ (`IPHONEOS_DEPLOYMENT_TARGET`)

## ディレクトリ構成

```
GAtsume/
├── GAtsume.xcodeproj/          Xcode プロジェクト
│   └── xcshareddata/xcschemes/
│       └── GAtsume.xcscheme    StoreKit Configuration を埋め込んだ共有スキーム
├── GAtsume/                    アプリソース (synchronized group)
│   ├── GAtsumeApp.swift        @main エントリ
│   ├── ContentView.swift       TabView ルート
│   ├── HomeView/RoomView/...   各タブ
│   ├── Views/Ads/              AdMob バナー (UIViewRepresentable)
│   ├── Views/Purchase/         StoreKit 2 課金マネージャ
│   └── *.json                  ゴキ・家具・壁紙・エサのデータ
├── Info.plist                  GADApplicationIdentifier / SKAdNetworkItems
└── GAtsume.storekit            シミュレータ用 StoreKit Configuration
```

## セットアップ

```sh
git clone https://github.com/kazuokunbasio/GAtsume.git
cd GAtsume
open GAtsume.xcodeproj
```

Swift Package Manager 依存 (Google Mobile Ads SDK) は Xcode が起動時に自動解決します。

### シミュレータでの動作確認

1. Xcode で `Cmd+R` を実行
2. 共有スキームに `GAtsume.storekit` が紐付けてあるため、ローカル StoreKit テスト購入が可能
3. 設定 → 購入 → 「広告を削除」でローカル課金フローを確認

### 実機 / Sandbox テスト

- App Store Connect で `com.gatsume.removeads` を Non-Consumable として作成し、Sandbox テスターでサインインして実機ビルド
- バナー広告は DEBUG ビルドでは Google 公式テスト ID に自動切替 (`AdsConfig.bannerAdUnitID`)

## ライセンス

未定 (個人開発、AI 生成アセットを含む)。
