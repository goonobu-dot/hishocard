import Foundation

/// 無料プランの制限:
/// 無料=最初の3トピック（約40枚）＋1日20枚まで。
/// 純関数として切り出し、日付境界やカウントのバグを単体テストで固定する。
public enum StudyLimiter {

    public static let freeDailyCardLimit = 20
    /// 無料開放するトピック（敬語・言葉遣いの最初の3トピック）
    public static let freeUnlockedTopics: Set<String> = ["尊敬語の基本", "謙譲語の基本", "丁寧語と言葉遣いの基本"]

    /// カードが無料ユーザーに閲覧可能かどうか。
    public static func isCardFree(subject: Subject, topic: String) -> Bool {
        subject == .keigo && freeUnlockedTopics.contains(topic)
    }

    /// 本日すでに学習した枚数から、無料ユーザーがあと何枚学習できるかを返す。
    public static func remainingFreeCardsToday(alreadyStudiedToday: Int) -> Int {
        max(0, freeDailyCardLimit - alreadyStudiedToday)
    }

    /// 無料ユーザーが今このカードを学習開始できるか。
    public static func canStudy(
        subject: Subject,
        topic: String,
        alreadyStudiedToday: Int,
        isPro: Bool
    ) -> Bool {
        if isPro { return true }
        guard isCardFree(subject: subject, topic: topic) else { return false }
        return remainingFreeCardsToday(alreadyStudiedToday: alreadyStudiedToday) > 0
    }
}
