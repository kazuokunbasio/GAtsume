import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerBlock

                    section(
                        title: "1. 収集する情報",
                        body: """
                        本アプリは外部サーバへの個人情報送信を行いません。
                        以下のデータは端末内 (SwiftData) にのみ保存されます。
                        ・ゴキの捕獲記録
                        ・所有家具・壁紙・エサ
                        ・コイン残高
                        ・ログイン日数・ミッション進捗
                        """
                    )

                    section(
                        title: "2. 端末の機能の利用",
                        body: """
                        以下の機能はユーザーの許可があった場合にのみ利用します。
                        ・通知 (毎日のリマインド送信)
                        ・写真ライブラリ (共有メニューから画像保存)
                        いずれもオプションであり、拒否してもアプリは動作します。
                        """
                    )

                    section(
                        title: "3. 解析と広告",
                        body: """
                        本アプリは Google AdMob を利用してアプリ下部にバナー広告を表示します。
                        AdMob は広告の最適化のために、広告識別子 (IDFA) や端末情報、広告との接触状況などを取得・利用することがあります。
                        詳細は Google のプライバシーポリシー (https://policies.google.com/privacy) をご確認ください。
                        将来的に広告削除のアプリ内課金を提供する予定です。
                        """
                    )

                    section(
                        title: "4. データの削除",
                        body: """
                        設定タブの「すべてリセット」から保存されている全データを削除できます。
                        アプリをアンインストールしても、端末内のデータは消去されます。
                        """
                    )

                    section(
                        title: "5. 子供のプライバシー",
                        body: """
                        本アプリは13歳未満の子供から個人を特定できる情報を意図的に収集することはありません。
                        """
                    )

                    section(
                        title: "6. お問い合わせ",
                        body: """
                        ご質問は開発者までお問い合わせください。
                        本ポリシーは予告なく変更されることがあります。最新版は本画面でご確認ください。
                        """
                    )

                    Text("最終更新: 2026年5月")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("プライバシーポリシー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ゴキあつめ プライバシーポリシー")
                .font(.title2.bold())
            Text("ご利用ありがとうございます。本アプリにおける情報の取り扱いについてご説明します。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
