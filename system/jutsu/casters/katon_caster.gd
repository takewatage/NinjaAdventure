extends JutsuCaster
class_name KatonCaster
## 火遁・息吹の術: hold to breathe fire in a cone (content/fx/katon/katon.json).
## press: start fx -> loop fx while held -> end fx on release.
## The cone grows during the start and hits every damage_tick_sec (multi-hit).


enum Phase { START, LOOP, END }

var _data: Dictionary
var _phase: Phase = Phase.START
var _time: float = 0.0
var _released_at: float = -1.0
var _fx: SheetAnimator
var _area: DamageArea
var _shape: CollisionPolygon2D
var _hit_until: float = INF


func begin() -> void:
    _data = jutsu.data.data
    var character: Dictionary = _data["character"]
    var hit_info: Dictionary = _data["hit"]
    move_speed_mult = float(character["move_speed_mult_while_breathing_suggestion"])

    _fx = make_fx(_data["start"])
    add_child(_fx)
    play_fx(_fx, _data["start"])

    _area = DamageArea.new()
    _area.damage = jutsu.damage
    _area.team = player.team
    _area.repeat_while_overlapping = true
    _area.repeat_interval = float(hit_info["damage_tick_sec"])
    _area.position = to_vector(hit_info["origin_offset_from_character"])
    _shape = CollisionPolygon2D.new()
    var polygon := PackedVector2Array()
    for p: Variant in hit_info["polygon_facing_right"]:
        polygon.append(to_vector(p))
    _shape.polygon = polygon
    _shape.scale = Vector2(0.05, 0.05)
    _area.add_child(_shape)
    add_child(_area)

    # Character: row 0 briefly, then hold row 1 while breathing.
    var start_rows: PackedInt32Array = to_ints(character["start_rows"])
    var start_secs: PackedFloat32Array = to_floats(character["start_frame_sec"])
    start_secs[start_secs.size() - 1] = 3600.0
    player.play_cast_frames(start_rows, start_secs, false)


func update(delta: float, held: bool) -> void:
    _time += delta
    var hit_info: Dictionary = _data["hit"]
    var grow: float = clampf(_time / float(hit_info["radius_grows_over_start_sec"]), 0.05, 1.0)
    _shape.scale = Vector2(grow, grow)

    if _released_at < 0.0 and not held:
        _released_at = _time
    match _phase:
        Phase.START:
            if _time >= float(_data["start"]["duration_sec"]):
                if _released_at >= 0.0:
                    _end()
                else:
                    _phase = Phase.LOOP
                    play_fx(_fx, _data["loop"])
        Phase.LOOP:
            if _released_at >= 0.0 and _time >= float(_data["min_hold_sec"]):
                _end()
        Phase.END:
            if _time >= _hit_until and _area.monitoring:
                _area.set_deferred("monitoring", false)


func _end() -> void:
    _phase = Phase.END
    can_turn = false
    _hit_until = _time + float(_data["hit"]["active_until_sec_after_release"])
    play_fx(_fx, _data["end"])
    _fx.finished.connect(queue_free, CONNECT_ONE_SHOT)
    var character: Dictionary = _data["character"]
    player.play_cast_frames(to_ints(character["end_rows"]), to_floats(character["end_frame_sec"]), false)
    var end_secs: PackedFloat32Array = to_floats(character["end_frame_sec"])
    var end_time: float = 0.0
    for s: float in end_secs:
        end_time += s
    get_tree().create_timer(end_time, false).timeout.connect(_finish)
