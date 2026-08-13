import XCTest
@testable import HishoCard

/// 本デッキ執筆エージェント（別プロセス）が書いた実データとの互換性テスト。
/// deck-draft/EDITORIAL.md で使われているsubjectの日本語表記・テンプレ別名
/// （signboard/distance/structure/colorChip/vapor/static/mixLoad/calendar/personnel/gradeBadge/extinguish）が
/// このアプリのスキーマでデコード可能であることを固定する回帰テスト。
final class DeckCompatibilityTests: XCTestCase {

    func testSubjectAcceptsJapaneseDisplayNames() {
        XCTAssertEqual(Subject(deckValue: "法令"), .keigo)
        XCTAssertEqual(Subject(deckValue: "law"), .keigo)
        XCTAssertEqual(Subject(deckValue: "物理・化学"), .manner)
        XCTAssertEqual(Subject(deckValue: "性状と火災予防・消火"), .jitsumu)
        XCTAssertNil(Subject(deckValue: "unknown"))
    }

    func testHintTemplateAcceptsEditorialAliases() {
        let aliasMap: [String: HintTemplateKind] = [
            "signboard": .signBoard,
            "distance": .safetyRuler,
            "structure": .crossSection,
            "colorChip": .colorSwatch,
            "vapor": .vaporWeight,
            "static": .staticElectricity,
            "mixLoad": .mixedTable,
            "calendar": .deadlineCalendar,
            "personnel": .staffing,
            "gradeBadge": .hazardBadge,
            "extinguish": .fireCompare
        ]
        for (alias, expected) in aliasMap {
            XCTAssertEqual(HintTemplateKind(deckValue: alias), expected, alias)
        }
    }

    /// deck-draft/deck-houri.json の実カード（H001）と同じ構造をデコードできることを確認する。
    func testDecodesActualDraftCardShape() throws {
        let json = """
        {
          "id": "H001",
          "subject": "法令",
          "topic": "総則・定義",
          "question": "消防法で「危険物」を定めているのはどの別表か？",
          "answer": "別表第一",
          "choices": ["別表第二", "別表第三", "附則第一"],
          "hintImage": { "template": "signboard", "params": { "text": "危険物" } },
          "goro": "「別表イチ（一）が危険物のモト」",
          "goroNote": "別表第一＝危険物の品名・性質・指定数量を定める表",
          "source": "消防法第2条・別表第一",
          "tags": ["法令", "総則"]
        }
        """.data(using: .utf8)!

        let card = try JSONDecoder().decode(CardDefinition.self, from: json)
        XCTAssertEqual(card.subject, .keigo)
        XCTAssertEqual(HintTemplateKind(deckValue: card.hintImage.template), .signBoard)
        // 注意: このカードのanswer「別表第一」はchoicesに含まれないため、DeckValidatorでは
        // 要"free-form-answer"タグ（自由記述解答）扱いとする必要がある（本デッキ側と要すり合わせ）。
    }
}
