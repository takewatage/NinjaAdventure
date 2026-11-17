# NinjaAdventure

Zelda-like 2D top-down RPG (Godot 4.7 / GDScript).

設計資料（体験版の範囲・忍術の仕様など）は `document/` にある。

## 状況

### できていること
- 主人公 `content/character/ninja_main/ninja_main.tscn`（スクリプト: `system/player/player.gd`）
  - 待機・歩き（4方向アニメ、8方向移動）
  - 回避ローリング（Shift / パッド B）: 0.3秒、移動中の方向へ転がる、転がり中は無敵
  - 三段攻撃コンボ（左クリック / Space）: なぎ払い → 逆なぎ払い → 突き。攻撃方向に踏み込む（1・2段目5px、3段目10px）。数値は `content/fx/combo3/combo3_8dir.json` が正
  - 攻撃はマウスカーソルの方向（各段の開始時に照準）。当たり判定・踏み込みは正確な角度。エフェクトは最寄りの8方向の絵を、残りの角度（最大±22.5°）だけ回転させて判定に合わせる。キャラの絵は最寄りの方向（4方向なので斜めは上下の絵）
  - エフェクトの回転が見た目に合わない場合: インスペクターで `rotate_fx_to_aim` をオフ、`snap_aim_to_8_directions` をオンにすると、判定のほうを8方向に揃える
- 被ダメージ: HP6（`max_life`）。被弾で Hit.png のアニメ＋ノックバック（0.3秒操作不可）→ 1秒無敵（点滅）。HP0で操作不能になり、Hit.png → Dead.png（1列×2コマ）＋土煙（`DeathBurst`）→ 頭上で星が回り続ける（`DizzyStars`）の順。カメラは1.4倍までズーム（`death_zoom`）。回避中は無敵
- 体力表示: 左上のハート（`system/ui/player_ui.gd`、`content/ui/heart.png`）。ハート1個 = HP2（`life_per_heart`）なので HP6 = ハート3個、1ダメージで半分減る
- 死亡後: 2秒待って暗転 → 今のマップを読み直して、マップの初期位置・HP満タンでやり直し（`world.gd` の `_on_player_died`）。セーブができたら、最後の焚き火・家から再開に変える
- 体力表示と死亡後のやり直しは `world.tscn` 経由で動く（`test.tscn` 単体には HUD が無い）
- 試験場 `content/map/map_test.tscn` で NinjaMain を操作キャラに設定（壺1・草2・スライム1を配置）
- 敵 AI の土台（Beehave 2.9.3 のビヘイビアツリー）
  - スライム `content/enemy/Slime2/slime2.tscn`: うろつく → プレイヤー発見で追跡 → 射程内で「体当たり(重み3) / 逃げる(重み1)」をランダム選択 → 見失うと再びうろつく。被弾でノックバック＋硬直、HP3で死亡。体に触れるだけでもダメージ（`slime2.tres` の `contact_damage`）
  - 体当たりは 予備動作（つぶれ＋赤み）→ 突進（約66px）→ 硬直 → クールダウン。数値は `slime2_tackle.tres`

### これから
- 術システム（火遁・息吹、水遁・水手裏剣から）。素材は `content/fx/`、術ホイールは `content/ui/jutsu_wheel/`
- テレポーター対応（`Teleporter` は `Character` 型を前提にしており、`Player` は未対応）
- アイテム取得（`PickUpItem` との接触）
- 敵の2体目（使い回しの検証）、壁越しに見つけないための視線チェック、NavigationAgent2D による経路探索

## 操作

| 操作 | キー | パッド |
|---|---|---|
| 移動 | 矢印キー | 十字キー / 左スティック |
| 攻撃（カーソルの方向へ） | 左クリック / Space | — |
| 回避 | Shift | B（button 1） |

## 素材

| 素材 | 場所 | 用途 |
|---|---|---|
| 主人公スプライト | `content/character/ninja_main/*.png`（32×32、列=向き・行=コマ） | Idle / Walk / Attack / Roll / Hit / Dead を使用中 |
| 三段攻撃エフェクト | `content/fx/combo3/`（8方向版 `*_8dir*` を使用中。4方向版は未使用） | 攻撃エフェクト・当たり判定データ |
| スライム | `content/enemy/Slime2/Slime2.png`（16×16、列=向き・行=コマ） | Slime2 の歩き・待機 |
| 影 | `content/character/Shadow.png` | 主人公・敵の足元 |
| 死亡エフェクト | `content/fx/death/`（`death.json`） | 倒れた瞬間の土煙（`fx_death_burst.png`）と頭上の星（`fx_dizzy_stars.png`）を使用中 |

## 敵の作り方（構造）

体・感覚・頭脳・データを分けている。頭脳（ビヘイビアツリー）は体の関数を呼ぶだけで、物理には触らない。

| 層 | 場所 | 役割 |
|---|---|---|
| 体 | `system/enemy/enemy.gd`（`Enemy`）、基底シーン `content/enemy/enemy_base.tscn` | 移動・アニメ・攻撃の進行・被弾・死亡。命令: `move` / `move_toward_point` / `stop` / `face` / `start_attack` / `cancel_attack` |
| 感覚 | `system/ai/sensors/target_sensor.gd` | プレイヤー（グループ `player`）を見つけて Blackboard の `target` に書く。`lose_distance` より離れたら忘れる |
| 頭脳 | 葉ノード `system/ai/conditions/*.gd`・`system/ai/actions/*.gd`、使い回し用サブツリー `content/ai/bt_*.tscn` | 敵ごとの `*_brain.tscn` で組み合わせる |
| データ | `ResourceEnemy`（HP・速度・ノックバック）、`ResourceEnemyAttack`（ダメージ・射程・予備動作/判定/硬直・クールダウン・突進速度） | 敵ごと・攻撃ごとの `.tres` |

新しい敵を作る手順:
1. `enemy_base.tscn` から継承シーンを作り、`Sprite` のテクスチャと `data` を設定する
2. 攻撃ごとに `ResourceEnemyAttack` の `.tres` を作る
3. `*_brain.tscn`（ルートは `BeehaveTree`、名前は `Brain`）を作って子に入れ、インスペクターで `blackboard` に `../Blackboard` を指定する

行動の増やし方: ランダムにしたい箇所は `SelectorRandomComposite`（`use_weights` で重み付け）、攻撃パターンは `AttackReady` + `PerformAttack` の組を `.tres` 違いで並べる。

ダメージの当て方:
- `DamageArea`（攻撃側）が `Hitbox`（受ける側）に触れると `take_damage` が呼ばれる。陣営（`ResourceDamageTeam`）が同じ・味方なら当たらない
- `repeat_while_overlapping` をオンにすると重なっている間ずっと当て続ける（接触ダメージ用）。実際に何回痛がるかは受ける側の無敵時間で決まる
- 敵の `ContactArea` は常時、`AttackArea` は攻撃の判定中だけ有効

補足:
- `tools/build_enemy_scenes.gd` は最初の生成用。既存ファイルは上書きしないので、以後はエディターで編集してよい
- Beehave にローカル修正が1か所ある（`addons/beehave/debug/debugger_messages.gd` の `can_send_message()` にデバッガ接続チェックを追加。デバッガ無しで起動すると "No active debugger" が大量に出るため）。Beehave を更新するときは消える

