import SwiftUI

struct StreakMilestone: Identifiable {
    let id = UUID()
    let days: Int
    let bonusCoins: Int
}

struct StreakCelebrationView: View {
    let milestone: StreakMilestone
    @Environment(\.dismiss) private var dismiss

    private var headline: String {
        switch milestone.days {
        case 3: return "三日坊主、回避！"
        case 7: return "1週間連続！"
        case 14: return "2週間連続！"
        case 30: return "1ヶ月連続！"
        case 100: return "100日連続！"
        default: return "\(milestone.days)日連続！"
        }
    }

    private var subtitle: String {
        switch milestone.days {
        case 3: return "ここから始まる"
        case 7: return "ゴキたちもあなたを覚えた"
        case 14: return "もはや日課"
        case 30: return "この部屋の主"
        case 100: return "伝説の調教師"
        default: return "順調"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .shadow(color: .orange.opacity(0.5), radius: 12)

                Text(headline)
                    .font(.largeTitle.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(.yellow)
                    .font(.title)
                Text("+\(milestone.bonusCoins)")
                    .font(.system(size: 48, weight: .bold).monospacedDigit())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.yellow.opacity(0.18), in: .rect(cornerRadius: 18))

            Text("ボーナスコイン")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("受け取る")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: .capsule)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .padding(.horizontal)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.15), .red.opacity(0.05), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .interactiveDismissDisabled()
    }
}
