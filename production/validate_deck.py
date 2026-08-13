#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
デッキ自己検証スクリプト（秘書検定 暗記カード）。

チェック項目:
  1. 各deck-*.jsonがJSONとしてパースできる
  2. カードごとの必須フィールドが空でない（id/topic/question/answer/goro/goroNote/source/hintImage.template）
  3. choicesがちょうど3件、重複なし、answerを含まない
  4. id重複がデッキ全体でゼロ
  5. hintImage.templateが既存15種（別名込み）のいずれかである
  6. subjectがCardDefinition.Subject（keigo/manner/jitsumu、または日本語表記）としてデコード可能
  7. 総カード数が仕様の320枚に対して±10%以内（288〜352枚）

Swiftのソースを実行しない純粋なJSONベースの検証（xcodebuildと独立に実行できる）。
"""
import json
import sys
from pathlib import Path
from collections import Counter, defaultdict

DECK_DIR = Path(__file__).resolve().parent.parent / "HishoCard" / "Resources" / "deck"
TARGET_TOTAL = 320
TOLERANCE = 0.10

DECK_FILES = ["deck-keigo.json", "deck-manner.json", "deck-jitsumu.json"]

# HintImageView.swift の HintTemplateKind に対応する既存15種＋別名（EDITORIAL.md記載の別名を含む）
VALID_TEMPLATES = {
    # rawValue（正式名・別名含む）
    "thermometer", "drum", "sign_board", "beaker", "fire_compare", "tank",
    "hazard_badge", "safety_ruler", "cross_section", "color_swatch",
    "vapor_weight", "static_electricity", "mixed_table", "deadline_calendar",
    "staffing",
    # デッキ執筆側の別名（HintTemplateKind.init?(deckValue:)が受理するもの）
    "signboard", "distance", "structure", "colorChip", "vapor", "static",
    "mixLoad", "calendar", "personnel", "gradeBadge", "extinguish",
}

VALID_SUBJECTS = {
    "keigo", "敬語", "敬語・言葉遣い",
    "manner", "来客・接遇・マナー", "来客・接遇", "マナー",
    "jitsumu", "文書・慶弔・事務", "事務", "文書",
}

REQUIRED_STR_FIELDS = ["id", "topic", "question", "answer", "goro", "goroNote", "source"]


def fail(msg):
    print(f"NG  {msg}")


ok_count = 0
ng_count = 0


def check(condition, msg):
    global ok_count, ng_count
    if condition:
        ok_count += 1
    else:
        ng_count += 1
        fail(msg)


def main():
    print(f"デッキディレクトリ: {DECK_DIR}")
    if not DECK_DIR.is_dir():
        print(f"NG  デッキディレクトリが存在しません: {DECK_DIR}")
        sys.exit(1)

    all_cards = []
    per_file_counts = {}
    topic_by_file = defaultdict(Counter)

    for fname in DECK_FILES:
        path = DECK_DIR / fname
        if not path.is_file():
            check(False, f"ファイルが存在しない: {fname}")
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            check(False, f"{fname}: JSONパースエラー: {e}")
            continue
        check(True, f"{fname}: JSONパース成功")

        cards = data.get("cards")
        check(isinstance(cards, list) and len(cards) > 0, f"{fname}: cards配列が存在し空でない")
        if not isinstance(cards, list):
            continue

        per_file_counts[fname] = len(cards)
        for c in cards:
            topic_by_file[fname][c.get("topic", "?")] += 1
        all_cards.extend((fname, c) for c in cards)

    print()
    print("=== 1. 必須フィールド・choices・hintImage.template のカード単位チェック ===")
    field_violations = 0
    choices_violations = 0
    template_violations = 0
    subject_violations = 0

    for fname, c in all_cards:
        cid = c.get("id", "?")

        for f in REQUIRED_STR_FIELDS:
            v = c.get(f)
            if not isinstance(v, str) or not v.strip():
                field_violations += 1
                fail(f"{fname} [{cid}]: 必須フィールド'{f}'が空または欠落")

        hint = c.get("hintImage") or {}
        tmpl = hint.get("template")
        if not isinstance(tmpl, str) or not tmpl.strip():
            field_violations += 1
            fail(f"{fname} [{cid}]: hintImage.templateが空または欠落")
        elif tmpl not in VALID_TEMPLATES:
            template_violations += 1
            fail(f"{fname} [{cid}]: 未知のhintImage.template '{tmpl}'")

        choices = c.get("choices")
        answer = c.get("answer")
        if not isinstance(choices, list) or len(choices) != 3:
            choices_violations += 1
            fail(f"{fname} [{cid}]: choicesが3件でない（実際: {len(choices) if isinstance(choices, list) else 'なし'}件）")
        else:
            if len(set(choices)) != 3:
                choices_violations += 1
                fail(f"{fname} [{cid}]: choicesに重複がある")
            if any(not isinstance(x, str) or not x.strip() for x in choices):
                choices_violations += 1
                fail(f"{fname} [{cid}]: choicesに空文字がある")
            if answer in choices:
                choices_violations += 1
                fail(f"{fname} [{cid}]: choicesにanswerが含まれている")

        subj = c.get("subject")
        if subj not in VALID_SUBJECTS:
            subject_violations += 1
            fail(f"{fname} [{cid}]: 未知のsubject '{subj}'")

    check(field_violations == 0, f"必須フィールド欠落ゼロ（違反件数: {field_violations}）")
    check(choices_violations == 0, f"choices違反ゼロ（違反件数: {choices_violations}）")
    check(template_violations == 0, f"hintImage.template違反ゼロ（違反件数: {template_violations}）")
    check(subject_violations == 0, f"subject違反ゼロ（違反件数: {subject_violations}）")

    print()
    print("=== 2. id重複チェック（デッキ全体） ===")
    id_counter = Counter(c.get("id") for _, c in all_cards)
    dupes = [i for i, n in id_counter.items() if n > 1]
    for d in dupes:
        fail(f"id重複: '{d}' が{id_counter[d]}回出現")
    check(len(dupes) == 0, f"id重複ゼロ（総id数: {len(id_counter)}、重複数: {len(dupes)}）")

    print()
    print("=== 3. 使用テンプレートの内訳 ===")
    tmpl_counter = Counter(
        (c.get("hintImage") or {}).get("template", "?") for _, c in all_cards
    )
    for t, n in sorted(tmpl_counter.items(), key=lambda x: -x[1]):
        mark = "OK" if t in VALID_TEMPLATES else "NG"
        print(f"  [{mark}] {t}: {n}枚")

    print()
    print("=== 4. カード総数チェック（仕様320枚 ±10%） ===")
    total = len(all_cards)
    lower = int(TARGET_TOTAL * (1 - TOLERANCE))
    upper = int(TARGET_TOTAL * (1 + TOLERANCE))
    print(f"  総カード数: {total}枚（許容範囲: {lower}〜{upper}枚）")
    for fname in DECK_FILES:
        print(f"    {fname}: {per_file_counts.get(fname, 0)}枚")
    check(lower <= total <= upper, f"総カード数が許容範囲内（実際: {total}枚、範囲: {lower}〜{upper}枚）")

    print()
    print("=== 5. ファイル別トピック内訳 ===")
    for fname in DECK_FILES:
        print(f"  {fname}:")
        for topic, n in topic_by_file[fname].items():
            print(f"    - {topic}: {n}枚")

    print()
    print("=" * 60)
    print(f"OK: {ok_count}件 / NG: {ng_count}件")
    if ng_count == 0:
        print("すべての検証項目に合格しました。")
        sys.exit(0)
    else:
        print("検証に失敗した項目があります。")
        sys.exit(1)


if __name__ == "__main__":
    main()
