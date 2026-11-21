# NinjaAdventure

Zelda-like 2D top-down RPG (Godot 4.7 / GDScript).

設計資料（体験版の範囲・忍術の仕様など）は `document/` にある。

## 状況

### できていること
- 主人公 `content/character/ninja_main/ninja_main.tscn`（スクリプト: `system/player/player.gd`）
  - 待機・歩き（4方向アニメ、8方向移動）
  - 回避ローリング（Shift / パッド B）: 0.3秒、移動中の方向へ転がる、転がり中は無敵
  - 三段攻撃コンボ（左クリック / Space）: なぎ払い → 逆なぎ払い → 突き。白い斬撃と、手に持ったクナイ（`Kunai` ノード、`content/weapon/kunai/kunai_rot16.png`）。数値・クナイの動きは `content/fx/combo3/combo3_8dir_kunai.json` が正
  - 攻撃はマウスカーソルの方向（各段の開始時に照準）。当たり判定・踏み込みは正確な角度。斬撃とクナイは最寄りの8方向の絵を、残りの角度（最大±22.5°）だけ回して判定に合わせる。踏み込みは1・2段目5px、3段目10px（`lunge_px`。素材のJSONより優先）。キャラの絵は最寄りの方向（4方向なので斜めは上下の絵）
  - 絵を回したくない場合: インスペクターで `rotate_fx_to_aim` をオフ、`snap_aim_to_8_directions` をオンにすると、判定のほうを8方向にそろえる
- 画面: 480×270（30×17マス）を整数倍で拡大（1920×1080 なら4倍）。カメラはプレイヤー追従。根拠は `document/素材の寸法と画面サイズ.md`
- 被ダメージ: HP6（`max_life`）。被弾で Hit.png のアニメ＋ノックバック（0.3秒操作不可）→ 1秒無敵（点滅）。HP0で操作不能になり、Hit.png → Dead.png（1列×2コマ）＋土煙（`DeathBurst`）→ 頭上で星が回り続ける（`DizzyStars`）の順。カメラは1.4倍までズーム（`death_zoom`）。回避中は無敵
- 体力表示: 左上のハート（`system/ui/player_ui.gd`、`content/ui/heart.png`）。ハート1個 = HP2（`life_per_heart`）なので HP6 = ハート3個、1ダメージで半分減る
- 死亡後: 2秒待って暗転 → 今のマップを読み直して、マップの初期位置・HP満タンでやり直し（`world.gd` の `_on_player_died`）。セーブができたら、最後の焚き火・家から再開に変える
- 体力表示と死亡後のやり直しは `world.tscn` 経由で動く
- デバッグ専用シーン `test.tscn`（ゲーム本編では使わない。エディタで開いて F6）: `content/jutsu/` にある術（`ResourceJutsu` の .tres）を全部覚えた状態で始まり、術符は撃ってもすぐ上限まで戻る（`system/debug/debug_scene.gd`。`infinite_talismans` で切り替え）。左上のハート・所持金と左下の術表示・術ホイールも出る。スライム3体・壺・草を配置。死んでもやり直しは無い（`world.tscn` 経由ではないため）
- 試験場 `content/map/map_test.tscn` で NinjaMain を操作キャラに設定（壺1・草2・スライム1を配置）
- マップのつながり（`world.tscn` から起動）: 村 `map_village.tscn` → チュートリアルの道 `content/map/demo/tutorial_road.tscn` → ボスまでの道 `content/map/demo/boss_road.tscn`。マップの端の出入口（`MapExit`）に入ると暗転して切り替わり、相手のマップの `MapEntry` に出る。プレイヤーはマップをまたいで同じ（体力・術符を引き継ぐ）
  - 村の出口は上の道の突き当たり。村のプレイヤーだった NinjaBlue は NPC にした（PlayerAssignor と攻撃判定を外した）。家の中へのテレポーターは Player でも使える
  - 道の2マップは仮（草の床・外周の木・木・スライム・草/壺・焚き火）。`tools/build_demo_maps.gd` で作った。以後はエディターで描き直してよい（ビルダーは既存ファイルを上書きしない）
- 焚き火（`content/prop/campfire/campfire.tscn`）: 近くで F を押すと火がつき、死んだときの再開地点になる。一度つけた焚き火はマップを出入りしてもついたまま。再開時は体力満タン、術符はそのまま。焚き火をつける前に死ぬと村のスタート地点から
- 敵 AI の土台（Beehave 2.9.3 のビヘイビアツリー）
  - スライム `content/enemy/Slime2/slime2.tscn`: うろつく → プレイヤー発見で追跡 → 射程内で「体当たり(重み3) / 逃げる(重み1)」をランダム選択 → 見失うと再びうろつく。被弾でノックバック＋硬直、HP3で死亡。体に触れるだけでもダメージ（`slime2.tres` の `contact_damage`）
  - 体当たりは 予備動作（つぶれ＋赤み）→ 突進（約66px）→ 硬直 → クールダウン。数値は `slime2_tackle.tres`

- 術（`document/忍術システム仕様.md`）
  - 火遁・息吹の術: 押している間、前方の扇形に炎（0.15秒ごとに多段ヒット）。歩きは0.3倍速。離すと終わる（最短0.33秒）
  - 水遁・水手裏剣の術: 短く押すと手裏剣（1ダメージ・1体で止まる）。0.9秒溜めると大手裏剣（2ダメージ・貫通・着弾で範囲1ダメージ）。溜め中は0.4倍速
  - 雷遁・雷轟の術: 押すと狙った方向の36px先に、0.3秒後に雷が落ちる（半径20pxの円の範囲、2ダメージ、当たった敵は落雷点から外向きに押される）。絵は回転させず、どの向きに撃っても雷は画面の上から落ちる。手元の火花だけキャラの位置に出す（左向きは左右反転）。発動中は立ち止まり、向きも固定。落雷前に被弾・回避すると雷も落ちない
  - クナイ（術符なし・弾数無限）: 術ホイールの一番上。術ボタンで、攻撃モーション（Attack.png の 0→1→2 段、0.3秒）の間は立ち止まり、カーソルの方向へ1本投げる。押しっぱなしで0.5秒ごとに投げ続ける（`kunai.tres` の `cooldown` / `repeat_while_held`）。1ダメージ・最初の敵か壁で止まる・射程160px・速さ240px/秒（`content/fx/kunai/kunai.json`）。絵は `Kunai.png` を投げた向きに回転。動きは `system/jutsu/casters/kunai_caster.gd`、飛び道具は `system/weapon/kunai_projectile.gd`。初期の術書に入っていて、最初から使える
  - 術符: 術ごとに所持数。1回1枚。足りないと撃てず、左下の表示が揺れる（他の術に自動で切り替えない）。初期値は火遁10/20枚、水遁15/30枚、雷轟5/10枚（仮。`content/jutsu/player_jutsu_book.tres`）
  - 左下に選択中の術（アイコン・術符の数・名前）。術ホイールで切り替え（開いている間はゲームが0.2倍速）
  - 被弾・回避で術は中断。死んでも術符の数はそのまま
- アイテム（段階3）
  - 拾えるアイテム `Pickup`（`system/item/pickup.gd`、`content/item/pickup/pickup.tscn`）: 術符（印ごと7種の絵、半分の大きさ＝8×8で表示。`talisman_scale`）・銀貨(1)・金貨(5、回転アニメ)。近づくと（36px）ゆっくり寄ってきて、近いほど速くなり、プレイヤーに届くと取れる。取ると頭上に「火遁 +3」「+5」が浮かぶ
  - 術符を拾うと、同じ印の術のうちいちばん減っている術が `talisman_pickup` 枚回復（火遁3・水遁5・雷轟2）。全部満タンなら寄ってこない
  - ドロップ表 `ResourceLoot`（`content/item/loot/*.tres`）: 草・壺（`Destroyable.loot`）、敵（`ResourceEnemy.loot`）、宝箱に設定。術符は「印ランダム」か「印を確定」。落ちた物は20秒で消える（最後の4秒点滅）
  - 所持金 `ResourceWallet`: 左上のハートの下に表示（増えるとカウントアップ）。死んでも減らない
  - 宝箱 `content/prop/chest/chest.tscn`: F で開けると中身が飛び出す。巻物（`scroll` に術を入れる）なら術を覚える。開けた宝箱・手置きのアイテムは再訪しても戻らない（`world.gd` の `has_flag` / `set_flag`。セーブができたらそこへ）

### これから
- 調べられる物に近づいたときの表示（「F」の吹き出しなど）。村の外周は壁が無く、マップの外へ歩いて出られる
- タイトル画面（`content/menu/title_screen.tscn`）は 1920×1080 前提の文字サイズのまま。480×270 に合わせて作り直す（段階6）
- 設定画面（段階6）: BGM・効果音の音量（`default_bus_layout.tres` の Music / Sound バスを `AudioServer.set_bus_volume_db` で変える。今は Music を -10dB に固定）、画面モード
- アイテム: 拾う音・宝箱の音（効果音素材が無い）、鍵と扉、術符屋・道具屋での売買
- 雷轟は今は初期の術書に入っている（確認用の暫定）。巻物で術を覚える流れを作るときに外す
- 火遁の炎の絵は壁の上にも描かれる（当たり判定は壁で止まる）。絵も壁で切るなら別対応
- 雷轟: 画面の揺れ・光の演出、気絶時間を技ごとに変える仕組み、連鎖（レベル）。落雷点にぴったり重なった敵は押されない（向きが0になる）
- 術: 術のレベル、8方向の絵（今は右向きの絵を回転）、空撃ち・術符を使ったときの音と演出、日本語のドット絵フォント
- テレポーター対応（`Teleporter` は `Character` 型を前提にしており、`Player` は未対応）
- 旧アイテム `PickUpItem`（gloot 用）は未使用。新しい仕組みは `Pickup`
- クナイ: 投げる音、刺さった・壁に当たったときの演出。押した瞬間がクールタイム中だと何も起きない（押しっぱなしなら0.5秒ごとに出る）
- 敵の2体目（使い回しの検証）、壁越しに見つけないための視線チェック、NavigationAgent2D による経路探索

## 操作

| 操作 | キー | パッド |
|---|---|---|
| 移動 | W A S D | 十字キー / 左スティック |
| 攻撃（カーソルの方向へ） | 左クリック / Space | — |
| 回避 | Shift | B（button 1） |
| 術を使う（カーソルの方向へ。長押しで溜め・吹き続け） | 右クリック / E | X（button 2） |
| 術ホイール（長押しで開く → カーソルで選んで左クリック。離すか右クリックでキャンセル） | Q | LB（button 9）※選択はマウスのみ |
| 調べる（焚き火・宝箱など） | F | A（button 0） |

## 素材

| 素材 | 場所 | 用途 |
|---|---|---|
| 主人公スプライト | `content/character/ninja_main/*.png`（32×32、列=向き・行=コマ） | Idle / Walk / Attack / Roll / Hit / Dead を使用中 |
| 三段攻撃エフェクト | `content/fx/combo3/`（8方向版 `*_8dir*` を使用中。4方向版は未使用） | 攻撃エフェクト・当たり判定データ |
| スライム | `content/enemy/Slime2/Slime2.png`（16×16、列=向き・行=コマ） | Slime2 の歩き・待機 |
| 影 | `content/character/Shadow.png` | 主人公・敵の足元 |
| 術符アイテム | `content/item/talisman/talisman_items.png`（16×16×7、印ごと） | 落ちている術符 |
| コイン・宝箱 | `content/item/Treasure/`（SilverCoin・Coin2（金貨4コマ）・GoldCoin・LittleTreasureChest） | 銀貨・金貨・所持金アイコン・宝箱 |
| クナイ | `content/weapon/kunai/`（`kunai_rot16.png` 16×16×16コマ、22.5°刻み。元絵 `kunai_small.png` 11×5。`Kunai.png` 16×16） | 三段攻撃の手持ちクナイ（`kunai_rot16.png`）・投げクナイ（`Kunai.png` 16×16、右上向き） |
| 雷轟の絵 | `content/fx/raiton/`（`raiton.json`, `fx_raiton.png`） | 雷遁・雷轟の術（キャラの印・落雷・当たり判定のデータ） |
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
- 壁（物理レイヤー1）: 飛び道具（クナイ・水手裏剣）は壁で止まる。毎フレーム前の位置から次の位置までをレイで調べ（`DamageArea.sweep_walls`）、壁の手前で止める。壁に密着して撃っても、投げた人の位置から調べるので壁の向こうには出ない。当たった物が壺・草のように Hitbox を持っていれば、そのままダメージを与える
- 壁越しに当てない: `DamageArea.blocked_by_walls` をオンにすると、発生源（`wall_check_origin`、空ならエリアの位置）から相手までの間に壁があれば当てない。火遁の炎・雷轟・大手裏剣の爆風で使用。雷轟は落雷点が壁の向こうなら壁の手前に落ちる
- 注意: `monitorable = false` の Area2D は壁（StaticBody・TileMap）を検知しない（Godot の既知の不具合 #17238）。`DamageArea` は `monitorable = false` にしているので、壁で止めたい飛び道具は `monitorable = true` に戻している（`collision_layer` は0のまま）

補足:
- `tools/build_enemy_scenes.gd` は最初の生成用。既存ファイルは上書きしないので、以後はエディターで編集してよい
- Beehave にローカル修正が1か所ある（`addons/beehave/debug/debugger_messages.gd` の `can_send_message()` にデバッガ接続チェックを追加。デバッガ無しで起動すると "No active debugger" が大量に出るため）。Beehave を更新するときは消える

## 術の作り方（構造）

| 層 | 場所 | 役割 |
|---|---|---|
| データ | `ResourceJutsu`（`system/jutsu/resource_jutsu.gd`）、術ごとの `content/jutsu/<id>.tres` | 名前・印・アイコン・術符（1回の枚数・上限）・ダメージ・動きのスクリプト・素材のJSON |
| 所持 | `ResourceJutsuBook`、初期値 `content/jutsu/player_jutsu_book.tres` | 覚えた術・術ごとの術符の数・選択中の術。プレイヤーが `_ready` で複製して使う |
| 動き | `JutsuCaster` を継承したスクリプト（`system/jutsu/casters/`） | 1回の発動ごとにプレイヤーの子として作られる。押している間・離した時の動き、エフェクト、当たり判定 |
| 飛び道具 | `JutsuProjectile`（`DamageArea` を継承） | まっすぐ飛び、射程・壁・命中で着弾。貫通・着弾時の範囲ダメージに対応 |
| UI | `system/ui/jutsu/`（`jutsu_ui.tscn` を `world.tscn` の Hud に配置） | 左下の術表示 `JutsuHud`、術ホイール `JutsuWheel` |

新しい術を足す手順:
1. `JutsuCaster` を継承したスクリプトを `system/jutsu/casters/` に作る（`begin()` で開始、`update(delta, held)` で毎フレーム、終わったら `_finish()`）
2. `ResourceJutsu` の `.tres` を作り、`caster` にそのスクリプト、`data` に素材のJSONを入れる
3. `player_jutsu_book.tres` の `learned` に足す（ゲーム中は修行場で `book.learn()` を呼ぶ形にする予定）

## マップの作り方（構造）

| 部品 | 場所 | 役割 |
|---|---|---|
| マップ | `system/map/map.tscn` を継承したシーン | タイル（`Tilemap`）・環境（BGM・天気の `EnvironmentArea`）。キャラは `Tilemap` の子に置くと前後が正しく重なる |
| 出てくる位置 | `MapEntry`（`system/map/map_entry.gd`） | `id` と向き。別のマップから来たときにここに出る |
| 出入口 | `MapExit`（`system/map/map_exit.gd`）＋ CollisionShape2D | 入ると `target_map` の `target_entry` へ移る |
| 焚き火 | `content/prop/campfire/campfire.tscn` | 調べると火がつき、再開地点になる |
| 調べられる物 | `Interactable`（`system/prop/interactable.gd`） | 近く（`radius`）で F を押すと `interacted` が出る。NPC の会話にも使う予定 |

- プレイヤーは `world.gd` が作り、マップをまたいで使い回す。マップの中に置いたテスト用のプレイヤー（`map_test` の NinjaMain など）は、`world.tscn` から起動すると World のプレイヤーに置き換わる
- 最初のマップは `world.tscn` の `starting_map` と `starting_entry`（今は村の `start`）
