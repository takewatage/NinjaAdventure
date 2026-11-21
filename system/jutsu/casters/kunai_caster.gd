extends JutsuCaster
class_name KunaiCaster
## Basic kunai throw (content/fx/kunai/kunai.json): no talisman, unlimited.
## Plays the attack motion standing still and throws one kunai toward the aim.
## Holding the jutsu button keeps throwing (ResourceJutsu.repeat_while_held,
## spaced by ResourceJutsu.cooldown).


var _data: Dictionary
var _time: float = 0.0
var _end_at: float = 0.0
var _thrown: bool = false


func begin() -> void:
    _data = jutsu.data.data
    move_speed_mult = 0.0
    can_turn = false
    var character: Dictionary = _data["character"]
    var secs: PackedFloat32Array = to_floats(character["frame_sec"])
    player.play_cast_frames(to_ints(character["rows"]), secs, false)
    for s: float in secs:
        _end_at += s


func update(delta: float, _held: bool) -> void:
    _time += delta
    var block: Dictionary = _data["projectile"]
    if not _thrown and _time >= float(block["spawn_sec"]):
        _throw(block)
    if _time >= _end_at:
        _finish()
        queue_free()


func _throw(block: Dictionary) -> void:
    _thrown = true
    var offset: Vector2 = to_vector(block["spawn_offset_from_character"])
    # The caster may be mirrored; work out the spawn point in world space.
    var at: Vector2 = global_position + offset.rotated(aim_angle)
    KunaiProjectile.spawn(player.get_parent(), at, aim_vector(), block, jutsu.damage, player.team, global_position)
