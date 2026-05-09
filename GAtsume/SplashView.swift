import SwiftUI

struct SplashView: View {
    @State private var titleScale: CGFloat = 0.6
    @State private var titleOpacity: Double = 0
    @State private var emojiBounce: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.10, blue: 0.22),
                    Color(red: 0.10, green: 0.05, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("🫘")
                    .font(.system(size: 110))
                    .offset(y: emojiBounce)
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 8)

                VStack(spacing: 4) {
                    Text("ゴキあつめ")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Goki Atsume")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(4)
                }
            }
            .scaleEffect(titleScale)
            .opacity(titleOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                emojiBounce = -8
            }
        }
    }
}
