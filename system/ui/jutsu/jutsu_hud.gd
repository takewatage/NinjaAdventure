extends Control
class_name JutsuHud
## Bottom-left: the selected jutsu (active slot + icon + talisman badge + name).
## Shakes when a cast fails for lack of talismans.

const WHEEL_DATA: JSON = preload("res://content/ui/jutsu_wheel/jutsu_wheel.json")
const MARGIN := Vector2(6, 6)
const NAME_SIZE: int = 6

var player: Player:
    set(v):
        if player and player.book:
            player.book.changed.disconnect(queue_redraw)
            player.book.dry_fired.disconnect(_on_dry_fired)
        player = v
        if player and player.book:
            player.book.changed.connect(queue_redraw)
            player.book.dry_fired.connect(_on_dry_fired)
        queue_redraw()

var _art: JutsuSlotArt
var _shake: float = 0.0
var _shake_tween: Tween


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _art = JutsuSlotArt.new(WHEEL_DATA.data)
    get_viewport().size_changed.connect(queue_redraw)


func _draw() -> void:
    if player == null or player.book == null:
        return
    var jutsu: ResourceJutsu = player.book.get_selected()
    if jutsu == null:
        return
    var ui_scale: float = get_canvas_transform().get_scale().x
    var screen: Vector2 = get_viewport_rect().size / ui_scale
    var top_left := Vector2(MARGIN.x + _shake, screen.y - MARGIN.y - JutsuSlotArt.SLOT_SIZE)
    _art.draw(self, top_left, JutsuSlotArt.SlotState.ACTIVE, jutsu, player.book)
    var name_pos := top_left + Vector2(JutsuSlotArt.SLOT_SIZE + 6, JutsuSlotArt.SLOT_SIZE / 2.0 - 4)
    var width: float = ThemeDB.fallback_font.get_string_size(jutsu.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(NAME_SIZE * ui_scale)).x / ui_scale
    JutsuSlotArt.draw_text(self, name_pos + Vector2(width / 2.0, 0), jutsu.display_name, NAME_SIZE, ui_scale, Color.WHITE)


func _on_dry_fired(_jutsu: ResourceJutsu) -> void:
    if _shake_tween:
        _shake_tween.kill()
    _shake_tween = create_tween()
    var from: float = _shake
    for x: float in [3.0, -3.0, 2.0, -2.0, 0.0]:
        _shake_tween.tween_method(_set_shake, from, x, 0.04)
        from = x
    # TODO: a "no talismans" sound (no sfx asset in the project yet).


func _set_shake(value: float) -> void:
    _shake = value
    queue_redraw()
