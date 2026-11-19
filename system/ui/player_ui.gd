extends Control


## How much life one heart holds. heart.png has quarter steps, so with 2 a hit
## of 1 empties half a heart (player max_life 6 = 3 hearts).
@export var life_per_heart: float = 2.0

## Money: a coin icon and the amount, under the hearts.
@export var money_at: Vector2 = Vector2(4, 21)

const COIN_ICON: Texture2D = preload("res://content/item/Treasure/GoldCoin.png")
const NUMBER_FONT: Font = preload("res://content/ui/jutsu_wheel/ui_font_3x5.fnt")
const NUMBER_SIZE: int = 6

@onready var receptacle_bar: Control = %ReceptacleBar


var resource_life:ResourceLife:
    set(v):
        if resource_life and resource_life.life_changed.is_connected(on_life_changed):
            resource_life.life_changed.disconnect(on_life_changed)
        resource_life = v
        if resource_life == null:
            return
        receptacle_bar.max_life = _to_bar(resource_life.max_life)
        resource_life.life_changed.connect(on_life_changed)
        on_life_changed()


var wallet: ResourceWallet:
    set(v):
        if wallet and wallet.changed.is_connected(_on_money_changed):
            wallet.changed.disconnect(_on_money_changed)
        wallet = v
        if wallet:
            wallet.changed.connect(_on_money_changed)
        _shown_money = wallet.money if wallet else 0
        queue_redraw()

## The number counts up to the real amount instead of jumping.
var _shown_money: int = 0
var _count_tween: Tween


func _on_money_changed() -> void:
    if _count_tween:
        _count_tween.kill()
    _count_tween = create_tween()
    var steps: int = absi(wallet.money - _shown_money)
    _count_tween.tween_method(_set_shown_money, _shown_money, wallet.money, clampf(steps * 0.03, 0.05, 0.4))


func _set_shown_money(value: int) -> void:
    _shown_money = value
    queue_redraw()


func _draw() -> void:
    if wallet == null:
        return
    draw_texture(COIN_ICON, money_at)
    var text_pos: Vector2 = money_at + Vector2(COIN_ICON.get_width() + 3, 1 + NUMBER_FONT.get_ascent(NUMBER_SIZE))
    var text: String = str(_shown_money)
    # 1px dark outline so the number reads on any ground.
    for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
        draw_string(NUMBER_FONT, text_pos + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, Color("#141b1b"))
    draw_string(NUMBER_FONT, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, Color("#ffe9a8"))


func on_life_changed():
    receptacle_bar.life = _to_bar(resource_life.life)


func _to_bar(value: float) -> int:
    return roundi(value * receptacle_bar.receptacle_size / life_per_heart)
