import Foundation

/// ProductID厳守（コードとASC完全一致必須）。
/// 秘書検定 暗記カードは買い切りのみ（月額サブスクは作らない）。
enum ProductIDs {
    static let unlock = "com.goonobu.hishocard.unlock"
    static let all = [unlock]
}
