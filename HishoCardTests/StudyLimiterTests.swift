import XCTest
@testable import HishoCard

final class StudyLimiterTests: XCTestCase {

    func testFreeTopicIsLawDesignatedQuantityOnly() {
        XCTAssertTrue(StudyLimiter.isCardFree(subject: .keigo, topic: "指定数量"))
        XCTAssertFalse(StudyLimiter.isCardFree(subject: .keigo, topic: "標識と掲示板"))
        XCTAssertFalse(StudyLimiter.isCardFree(subject: .manner, topic: "指定数量"))
    }

    func testDailyLimitBoundary() {
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 0), 20)
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 19), 1)
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 20), 0)
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 999), 0, "上限を超えても負数にならない")
    }

    func testCanStudyProAlwaysAllowed() {
        XCTAssertTrue(StudyLimiter.canStudy(subject: .manner, topic: "何でも", alreadyStudiedToday: 999, isPro: true))
    }

    func testCanStudyFreeUserWithinLimit() {
        XCTAssertTrue(StudyLimiter.canStudy(subject: .keigo, topic: "指定数量", alreadyStudiedToday: 5, isPro: false))
    }

    func testCanStudyFreeUserAtLimitBlocked() {
        XCTAssertFalse(StudyLimiter.canStudy(subject: .keigo, topic: "指定数量", alreadyStudiedToday: 20, isPro: false))
    }

    func testCanStudyFreeUserOutsideFreeTopicBlocked() {
        XCTAssertFalse(StudyLimiter.canStudy(subject: .jitsumu, topic: "泡消火の原理", alreadyStudiedToday: 0, isPro: false))
    }
}
