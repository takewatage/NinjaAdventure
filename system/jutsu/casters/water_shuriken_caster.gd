extends JutsuCaster
class_name WaterShurikenCaster
## 水遁・水手裏剣の術: hold to charge, release to throw.
## Released before full charge: the normal shuriken (water_shuriken.json).
## Released after: the big piercing one (water_shuriken_charge.json).


enum Phase { CHARGE, THROW }

## Holding shorter than this is a tap: the charge fx is not shown.
const CHARGE_FX_DELAY: float = 0.15

var _normal: Dictionary
var _charged: Dictionary
var _phase: Phase = Phase.CHARGE
var _time: float = 0.0
var _full: bool = false
var _big: bool = false
var _spawn_at: float = 0.0
var _spawned: bool = false
var _end_at: float = 0.0
var _charge_fx: SheetAnimator
var _full_fx: SheetAnimator
var _throw_fx: SheetAnimator


func begin() -> void:
    _normal = jutsu.data.data
    _charged = jutsu.data_extra.data
    move_speed_mult = float(_charged["character"]["move_speed_mult_while_charging_suggestion"])
    _charge_fx = make_fx(_charged["charge_loop"])
    add_child(_charge_fx)
    _full_fx = make_fx(_charged["charge_full"])
    add_child(_full_fx)
    _full_fx.finished.connect(func() -> void: _full_fx.visible = false)
    # Hold the wind-up frame while charging.
    player.play_cast_frames(PackedInt32Array([int(_charged["character"]["charging_row"])]), PackedFloat32Array([3600.0]), false)


func update(delta: float, held: bool) -> void:
    _time += delta
    match _phase:
        Phase.CHARGE:
            if _time >= CHARGE_FX_DELAY and not _charge_fx.visible:
                play_fx(_charge_fx, _charged["charge_loop"])
            if not _full and _time >= float(_charged["input"]["full_charge_sec"]):
                _full = true
                play_fx(_full_fx, _charged["charge_full"])
            if not held:
                _throw()
        Phase.THROW:
            if not _spawned and _time >= _spawn_at:
                _spawn_projectile()
            if _time >= _end_at:
                _finish()
                if _throw_fx == null or not _throw_fx.visible:
                    queue_free()


func _throw() -> void:
    _phase = Phase.THROW
    _big = _full
    _time = 0.0
    can_turn = false
    move_speed_mult = 0.0
    _charge_fx.visible = false
    _full_fx.visible = false
    var data: Dictionary = _charged if _big else _normal
    var throw_block: Dictionary = data["big_throw"] if _big else data["cast"]
    _throw_fx = make_fx(throw_block)
    add_child(_throw_fx)
    play_fx(_throw_fx, throw_block)
    _throw_fx.finished.connect(func() -> void:
        _throw_fx.visible = false
        if _finished:
            queue_free())
    var character: Dictionary = data["character"]
    var rows: PackedInt32Array
    var secs: PackedFloat32Array
    if _big:
        rows = to_ints(character["release_rows"])
        secs = to_floats(character["release_frame_sec"])
        _spawn_at = float(data["projectile"]["spawn_delay_sec"])
    else:
        rows = to_ints(character["rows"])
        secs = to_floats(character["frame_sec"])
        _spawn_at = float(data["projectile"]["spawn_sec"])
    player.play_cast_frames(rows, secs, false)
    _end_at = 0.0
    for s: float in secs:
        _end_at += s


func _spawn_projectile() -> void:
    _spawned = true
    var data: Dictionary = _charged if _big else _normal
    var block: Dictionary = data["projectile"]
    var offset: Vector2 = to_vector(block["spawn_offset_from_character"])
    # The caster may be mirrored; work out the spawn point in world space.
    var at: Vector2 = global_position + offset.rotated(aim_angle)
    var p_damage: ResourceDamage = jutsu.damage_extra if _big and jutsu.damage_extra else jutsu.damage
    var projectile := JutsuProjectile.spawn(player.get_parent(), at, aim_vector(), block, p_damage, player.team)
    projectile.impact_block = data["impact"]
    var splash: Variant = data["impact"].get("splash")
    if splash is Dictionary:
        projectile.splash = splash
        projectile.splash_damage = jutsu.damage
