extends Control
class_name JutsuWheel
## Radial jutsu selector (content/ui/jutsu_wheel/jutsu_wheel.json).
## Hold the jutsu_wheel action to open (the game slows down), point with the
## mouse, left click to choose. Releasing the button or right click cancels.
## Slots: the json's slot table says which jutsu sits where; jutsu the player
## has not learned show as locked.

const WHEEL_DATA: JSON = preload("res://content/ui/jutsu_wheel/jutsu_wheel.json")
const ACTION := "jutsu_wheel"
const LABEL_SIZE: int = 7
const SLOT_COUNT: int = 8

## The wheel is open, or was closed this frame (the closing click must not attack).
static var _open: bool = false
static var _closed_frame: int = -1

var player: Player:
    set(v):
        if player and player.book and player.book.changed.is_connected(queue_redraw):
            player.book.changed.disconnect(queue_redraw)
        player = v
        if player and player.book:
            player.book.changed.connect(queue_redraw)
        if _is_open:
            _close()

var _data: Dictionary
var _art: JutsuSlotArt
var _slots: Array[Dictionary] = []
var _is_open: bool = false
var _hold_usec: int = -1
var _hovered: int = -1
var _anim: float = 0.0
var _hover_scale: PackedFloat32Array = PackedFloat32Array()
var _tween: Tween

var bg: Texture2D = preload("res://content/ui/jutsu_wheel/ui_wheel_bg.png")
var highlight: Texture2D = preload("res://content/ui/jutsu_wheel/ui_wheel_highlight.png")
var hub: Texture2D = preload("res://content/ui/jutsu_wheel/ui_wheel_hub.png")


static func blocks_input() -> bool:
    return _open or Engine.get_process_frames() <= _closed_frame + 1


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _data = WHEEL_DATA.data
    _art = JutsuSlotArt.new(_data)
    for s: Variant in _data["layout"]["slots"]:
        _slots.append(s as Dictionary)
    _hover_scale.resize(SLOT_COUNT)
    _hover_scale.fill(1.0)
    visible = false


func _exit_tree() -> void:
    if _is_open:
        _close()


func _process(_delta: float) -> void:
    var can_open: bool = player != null and is_instance_valid(player) and player.state != Player.State.DEAD
    if Input.is_action_pressed(ACTION) and can_open:
        if _hold_usec < 0:
            _hold_usec = Time.get_ticks_usec()
        var held: float = float(Time.get_ticks_usec() - _hold_usec) / 1_000_000.0
        if not _is_open and held >= _open_delay():
            _open_wheel()
    else:
        _hold_usec = -1
        if _is_open:
            _close()  # Released without choosing = cancel.
    if _is_open:
        _update_hover()
        queue_redraw()


func _input(event: InputEvent) -> void:
    if not _is_open:
        return
    var mb := event as InputEventMouseButton
    if mb == null or not mb.pressed:
        return
    if mb.button_index == MOUSE_BUTTON_LEFT:
        _confirm()
        get_viewport().set_input_as_handled()
    elif mb.button_index == MOUSE_BUTTON_RIGHT:
        _close()
        get_viewport().set_input_as_handled()


func _open_delay() -> float:
    return 0.15


func _open_wheel() -> void:
    _is_open = true
    _open = true
    visible = true
    _hovered = -1
    Engine.time_scale = float(_data["time"]["time_scale_while_open"])
    _animate_to(1.0, float(_data["anim"]["open_sec"]), Tween.TRANS_BACK)


func _close() -> void:
    _is_open = false
    _open = false
    _closed_frame = Engine.get_process_frames()
    Engine.time_scale = 1.0
    _animate_to(0.0, float(_data["anim"]["close_sec"]), Tween.TRANS_SINE)


func _confirm() -> void:
    if _hovered >= 0:
        var jutsu: ResourceJutsu = _slot_jutsu(_hovered)
        if jutsu != null:
            player.book.select(jutsu.id)
    _close()


func _animate_to(value: float, time: float, trans: Tween.TransitionType) -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween().set_ignore_time_scale(true)
    _tween.tween_method(_set_anim, _anim, value, time).set_trans(trans).set_ease(Tween.EASE_OUT)
    if value == 0.0:
        _tween.tween_callback(func() -> void: visible = false)


func _set_anim(value: float) -> void:
    _anim = value
    queue_redraw()


func _update_hover() -> void:
    var to_mouse: Vector2 = get_local_mouse_position() - _center()
    var hovered: int = -1
    if to_mouse.length() >= float(_data["input"]["deadzone_px"]):
        hovered = posmod(roundi(to_mouse.angle() / (PI / 4.0)), SLOT_COUNT)
    _hovered = hovered
    for i: int in SLOT_COUNT:
        var target: float = 1.15 if i == _hovered else 1.0
        _hover_scale[i] = move_toward(_hover_scale[i], target, 0.15 / 0.06 * get_process_delta_time() / maxf(Engine.time_scale, 0.01))


func _slot_jutsu(index: int) -> ResourceJutsu:
    if player == null or player.book == null:
        return null
    return player.book.find(StringName(String(_slots[index]["jutsu"])))


func _ui_scale() -> float:
    return get_canvas_transform().get_scale().x


func _center() -> Vector2:
    return get_viewport_rect().size / _ui_scale() / 2.0


func _draw() -> void:
    if _anim <= 0.0 or player == null or player.book == null:
        return
    var screen: Vector2 = get_viewport_rect().size / _ui_scale()
    var dim: Dictionary = _data["time"]["screen_dim"]
    var dim_color := Color(String(dim["color"]))
    dim_color.a = float(dim["alpha"]) * clampf(_anim, 0.0, 1.0)
    draw_rect(Rect2(Vector2.ZERO, screen), dim_color)

    var center: Vector2 = _center()
    var wheel_scale: float = lerpf(0.6, 1.0, _anim)
    var alpha: float = clampf(_anim, 0.0, 1.0)
    var white := Color(1, 1, 1, alpha)
    draw_set_transform(center, 0.0, Vector2.ONE * wheel_scale)
    draw_texture(bg, -bg.get_size() / 2.0, white)
    if _hovered >= 0:
        draw_texture_rect_region(highlight, Rect2(Vector2(-84, -84), Vector2(168, 168)), Rect2(_hovered * 168, 0, 168, 168), white)

    var selected: ResourceJutsu = player.book.get_selected()
    for i: int in SLOT_COUNT:
        var slot: Dictionary = _slots[i]
        var jutsu: ResourceJutsu = _slot_jutsu(i)
        var state: JutsuSlotArt.SlotState = JutsuSlotArt.SlotState.NORMAL
        if i == _hovered:
            state = JutsuSlotArt.SlotState.HOVER
        elif jutsu != null and jutsu == selected:
            state = JutsuSlotArt.SlotState.ACTIVE
        var offset: Vector2 = JutsuCaster.to_vector(slot["center_from_wheel_center"])
        var s: float = _hover_scale[i] * wheel_scale
        draw_set_transform(center + offset * wheel_scale, 0.0, Vector2.ONE * s)
        _art.draw(self, -Vector2.ONE * JutsuSlotArt.SLOT_SIZE / 2.0, state, jutsu, player.book)

    draw_set_transform(center, 0.0, Vector2.ONE * wheel_scale)
    var hub_frame: int = _hovered if _hovered >= 0 else 8
    draw_texture_rect_region(hub, Rect2(Vector2(-24, -24), Vector2(48, 48)), Rect2(hub_frame * 48, 0, 48, 48), white)
    draw_set_transform(Vector2.ZERO)

    if _hovered >= 0:
        _draw_label(center + Vector2(0, 80), _slot_jutsu(_hovered), alpha)


func _draw_label(at: Vector2, jutsu: ResourceJutsu, alpha: float) -> void:
    var ui_scale: float = _ui_scale()
    if jutsu == null:
        JutsuSlotArt.draw_text(self, at, "未習得", LABEL_SIZE, ui_scale, Color(0.7, 0.7, 0.7, alpha))
        return
    JutsuSlotArt.draw_text(self, at, jutsu.display_name, LABEL_SIZE, ui_scale, Color(1, 1, 1, alpha))
    if jutsu.uses_talisman:
        var line: String = "術符 ×%d（%d枚/回）" % [player.book.get_stock(jutsu), jutsu.per_cast]
        var color := Color(1, 1, 1, alpha) if player.book.can_cast(jutsu) else Color(1.0, 0.47, 0.43, alpha)
        JutsuSlotArt.draw_text(self, at + Vector2(0, LABEL_SIZE + 3), line, LABEL_SIZE - 1, ui_scale, color)
