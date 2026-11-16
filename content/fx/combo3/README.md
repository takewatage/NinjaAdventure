# combo3 — ninja_main 三段攻撃 素材一式

キャラ: `res://content/character/ninja_main/Attack.png`（32×32 / 4列×4行）
データ: `combo3.json`（すべての数値はここが正）

## ファイル

| ファイル | 内容 |
|---|---|
| `fx_combo3_hit1_slash.png` | 1段目 なぎ払い。96×96 × 4列 × 12行 |
| `fx_combo3_hit2_slash_reverse.png` | 2段目 逆なぎ払い。96×96 × 4列 × 12行 |
| `fx_combo3_hit3_thrust.png` | 3段目 突き。96×96 × 4列 × 13行 |
| `combo3.json` | 段ごとのコマ・時間・当たり判定・踏み込み・キャンセル可能時間 |
| `source/` | プレビューGIF・pixelfxのエフェクトソース（`.gdignore` 済み、Godotは読み込まない） |

## シートの並び（キャラと同じ）

- **列 = 向き**: 0=down / 1=up / 2=left / 3=right（`SpriteCharacter.FrameDirection` と同じ順）
- **行 = コマ**: 上から順に再生、30fps、ループなし
- Sprite2D なら `hframes=4`, `vframes=12 or 13`, `frame_coords = Vector2i(向き, コマ)`

## 位置合わせ

- エフェクトの1コマの中心 (48,48) = **キャラの見た目の中心**
- キャラのセル内の見た目の中心は (16,17)。セル中心より1px下なので、centered な Sprite2D 同士なら
  エフェクトは **キャラSprite位置 + (0, 1)** に置く
- 描画順: down/left/right はキャラの**前**、up はキャラの**後ろ**（`fx_common.z_by_direction`）
- 3段目は踏み込みあり（`lunge_px`、3px）。エフェクトもキャラと一緒に動かす

## 各段の要点（down向き）

| 段 | キャラ行 | 1コマの秒数 | エフェクト開始 | 当たり判定 有効 | 判定範囲（キャラ中心基準） | 反転 |
|---|---|---|---|---|---|---|
| 1 | 0,1,2,3 | 0.08 ×4 | 0.08 | 0.08〜0.18 | 前方横3マス x-24..24, y8..24 | なし |
| 2 | 0,1,2,3 | 0.08 ×4 | 0.08 | 0.08〜0.18 | 同上 | down/up のみ `flip_h` |
| 3 | 0,1,1,2,3 | 0.12,0.08,0.12,0.10,0.10 | 0.12 | 0.12〜0.24 | 正面縦2マス x-8..8, y8..40 | なし |

- 他の向きの判定範囲は `combo3.json` の `hitbox.<dir>` に回転済みの値あり（1マス=16px）
- コンボ受付: 現在の段の当たり判定開始から入力を受け付け、`cancel_from_sec`（1・2段目 0.16秒）以降に次の段へ。
  入力がなければ最後まで再生して終了、`reset_after_sec` (0.25) 以内に入力がなければ1段目に戻る
- 2段目の `flip_h` を left/right で使わないのは、横向きのコマを反転すると逆を向いてしまうため

## 作り直すとき

`source/fx/*.js` は pixelfx（https://github.com/patch-gg/pixelfx, MIT）のエフェクトソース。
`facing`（向き）、`reach`（半径）、`palette`（色）、`mirror`（2段目の逆振り）をオプションで変えて
`node tools/render.mjs melee/front-slash-topdown --sheet --opts '{...}'` で書き出し直せる。
