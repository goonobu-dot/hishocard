import XCTest
@testable import HishoCard

/// facts.json（出典付き正解値）とデッキのanswer文字列を機械照合するテスト。
/// spec-v1.0.md §テスト「facts.json数値突合テスト（全数値カード）」
final class FactsCrossCheckTests: XCTestCase {

    func testFactsLoad() throws {
        let facts = try FactsCatalog.load(from: Bundle(for: DeckRepository.self))
        XCTAssertFalse(facts.isEmpty)
    }

    func testAllFactRefsResolveAndMatchAnswerText() throws {
        let cards = try DeckLoader.loadAll(from: Bundle(for: DeckRepository.self))
        let facts = try FactsCatalog.load(from: Bundle(for: DeckRepository.self))
        let violations = FactsCatalog.crossCheck(cards: cards, facts: facts)
        XCTAssertTrue(violations.isEmpty, violations.joined(separator: "\n"))
    }

    func testAtLeastSomeCardsReferenceFacts() throws {
        let cards = try DeckLoader.loadAll(from: Bundle(for: DeckRepository.self))
        let withRefs = cards.filter { !$0.factRefs.isEmpty }
        XCTAssertGreaterThan(withRefs.count, 0, "数値突合の仕組みが実際に稼働していることの確認")
    }

    func testUnknownFactIDIsDetected() {
        let card = CardDefinition(
            id: "test-unknown-fact", subject: .keigo, topic: "t", question: "q", answer: "a",
            choices: ["a", "b", "c"], hintImage: HintImageSpec(template: "drum", params: [:]),
            goro: "g", goroNote: "n", source: "s", tags: [], factRefs: ["does.not.exist"]
        )
        let violations = FactsCatalog.crossCheck(card: card, facts: [:])
        XCTAssertEqual(violations.count, 1)
    }

    func testMismatchedValueIsDetected() {
        let facts = ["x.value": FactRecord(id: "x.value", value: 200, unit: "L", source: "test")]
        let card = CardDefinition(
            id: "test-mismatch", subject: .keigo, topic: "t", question: "q", answer: "100L",
            choices: ["100L", "b", "c"], hintImage: HintImageSpec(template: "drum", params: [:]),
            goro: "g", goroNote: "n", source: "s", tags: [], factRefs: ["x.value"]
        )
        let violations = FactsCatalog.crossCheck(card: card, facts: facts)
        XCTAssertEqual(violations.count, 1)
    }
}
