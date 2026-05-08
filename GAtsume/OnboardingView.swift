import SwiftUI

struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    @AppStorage("onboardingShown") private var onboardingShown = false
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🏠",
            title: "ようこそ",
            body: "気持ち悪いのに、なぜか毎日見てしまう。\nそんな放置型コレクションアプリ。"
        ),
        OnboardingPage(
            emoji: "🫘",
            title: "タップで捕獲",
            body: "部屋に出てくるゴキをタップで捕まえる。\nコインが手に入る。"
        ),
        OnboardingPage(
            emoji: "📦",
            title: "家具を置く",
            body: "家具を買って配置すると、\n出てくるゴキの種類が変わる。"
        ),
        OnboardingPage(
            emoji: "🍯",
            title: "エサで誘き出す",
            body: "エサは時間限定で特定のゴキを呼び寄せる。\nレア種狙いに使える。"
        ),
        OnboardingPage(
            emoji: "📕",
            title: "図鑑を埋めよう",
            body: "捕まえたゴキは図鑑に記録。\nコンプリートを目指せ。"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    OnboardingPageView(page: pages[i])
                        .tag(i)
                        .padding(.horizontal, 32)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onboardingShown = true
                }
            } label: {
                Text(page < pages.count - 1 ? "次へ" : "始める")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: .capsule)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .interactiveDismissDisabled()
        .overlay(alignment: .topTrailing) {
            Button("スキップ") {
                onboardingShown = true
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(20)
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text(page.emoji)
                .font(.system(size: 110))
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.largeTitle.bold())
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
}
