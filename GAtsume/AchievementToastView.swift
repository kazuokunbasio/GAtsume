import SwiftUI

struct AchievementToastView: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundStyle(.yellow)
                .frame(width: 36, height: 36)
                .background(.yellow.opacity(0.18), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("達成バッジ獲得")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(achievement.title)
                    .font(.subheadline.bold())
                Text(achievement.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.yellow.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}
