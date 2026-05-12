# G集め (GAtsume)

ゴキブリを集める放置・収集系アプリ。部屋にエサや家具を置いて
さまざまな「ゴキ」を呼び寄せ、図鑑に収集していくカジュアルゲーム。

---

## 公式サイト (GitHub Pages)

App Store Connect の「マーケティングURL / 開発者Webサイト」と、
Google AdMob の `app-ads.txt` 確認用に GitHub Pages で公開しています。

| 項目 | URL |
| --- | --- |
| 公式サイト (マーケティングURL) | https://kazuokunbasio.github.io/GAtsume/ |
| プライバシーポリシー | https://kazuokunbasio.github.io/GAtsume/privacy.html |
| app-ads.txt (AdMob確認用) | https://kazuokunbasio.github.io/GAtsume/app-ads.txt |

公開ファイルは `docs/` フォルダにまとめています。

```
docs/
├── index.html      公式トップページ
├── privacy.html    プライバシーポリシー
└── app-ads.txt     AdMob認証ファイル
```

---

## GitHub Pages 公開手順 (初心者向け)

### 1. ファイルを GitHub にプッシュする

ターミナルでこのリポジトリのフォルダに移動し、以下を実行します。

```sh
cd /Users/kazuo/Documents/G集め/GAtsume
git add docs/index.html docs/app-ads.txt README.md
git commit -m "Add public site and app-ads.txt for AdMob"
git push origin main
```

### 2. GitHub Pages を有効にする

ブラウザで GitHub のリポジトリページを開いて以下を設定します。

1. https://github.com/kazuokunbasio/GAtsume を開く
2. 上部の **Settings** タブをクリック
3. 左メニューの **Pages** をクリック
4. **Source** で **Deploy from a branch** を選択
5. **Branch** を **main**、フォルダを **/docs** に設定
6. **Save** をクリック

設定後、数十秒〜数分待つと公開されます。

### 3. 公開を確認する

ブラウザで以下を開きます。

- https://kazuokunbasio.github.io/GAtsume/
  → トップページ (index.html) が表示されればOK
- https://kazuokunbasio.github.io/GAtsume/app-ads.txt
  → 1行だけのテキストが表示されればOK

---

## App Store Connect への登録

App Store Connect のアプリ情報で以下のURLを入力します。

| フィールド | 入力するURL |
| --- | --- |
| マーケティングURL | https://kazuokunbasio.github.io/GAtsume/ |
| プライバシーポリシーURL | https://kazuokunbasio.github.io/GAtsume/privacy.html |
| サポートURL | https://kazuokunbasio.github.io/GAtsume/ |

---

## AdMob (app-ads.txt) の確認方法

### app-ads.txt の内容

```
google.com, pub-2165259899292420, DIRECT, f08c47fec0942fa0
```

### ブラウザで確認

下記URLにアクセスし、上記1行がそのまま表示されることを確認します。

https://kazuokunbasio.github.io/GAtsume/app-ads.txt

### AdMob 側の手順

1. https://apps.admob.com/ にログイン
2. 左メニュー **アプリ** → 対象アプリを選択
3. **app-ads.txt** タブを開く
4. App Store Connect の「マーケティングURL」が
   `https://kazuokunbasio.github.io/GAtsume/` になっていることを確認
5. AdMob 側で **再クロールをリクエスト** をクリック
6. 数時間〜最大24時間ほどで「承認済み (Authorized)」になる

> 注意: AdMob が `app-ads.txt` を見つけるためには、
> App Store の公開ページの「デベロッパWebサイト」または
> App Store Connect の「マーケティングURL」が
> 上記の GitHub Pages URL になっている必要があります。

---

## 技術情報 (アプリ本体)

- **言語**: Swift 5
- **UI**: SwiftUI
- **永続化**: SwiftData
- **ゲーム描画**: SpriteKit (`RoomScene`)
- **広告**: Google Mobile Ads SDK (AdMob、バナー)
- **課金**: StoreKit 2 (Non-Consumable: 広告削除)
- **対応**: iOS 26.2+ (`IPHONEOS_DEPLOYMENT_TARGET`)

### ディレクトリ構成

```
GAtsume/
├── GAtsume.xcodeproj/          Xcode プロジェクト
├── GAtsume/                    アプリソース
│   ├── GAtsumeApp.swift        @main エントリ
│   ├── ContentView.swift       TabView ルート
│   ├── Views/Ads/              AdMob バナー
│   ├── Views/Purchase/         StoreKit 2 課金マネージャ
│   └── *.json                  ゴキ・家具・壁紙・エサのデータ
├── docs/                       GitHub Pages 公開ファイル
├── Info.plist                  GADApplicationIdentifier / SKAdNetworkItems
└── GAtsume.storekit            StoreKit Configuration
```

### セットアップ

```sh
git clone https://github.com/kazuokunbasio/GAtsume.git
cd GAtsume
open GAtsume.xcodeproj
```

## ライセンス

未定 (個人開発、AI 生成アセットを含む)。
