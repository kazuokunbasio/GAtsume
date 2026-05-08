import Foundation
import SwiftData

@Model
final class Wallet {
    var coins: Int

    init(coins: Int = 100) {
        self.coins = coins
    }
}
