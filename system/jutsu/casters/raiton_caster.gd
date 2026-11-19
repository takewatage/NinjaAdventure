extends JutsuCaster
class_name RaitonCaster
## 雷遁・雷轟の術: tap to drop a bolt 36 px ahead (content/fx/raiton/raiton.json).
## The sheet is drawn facing right. It is never rotated: the bolt always comes
## down from the top of the screen and lands on the strike point, whatever the
## aim. The crackle around the hands (left part of the early frames) is cut out
## and shown at the character instead, mirrored when aiming left.
## The hit is a short-lived circle DamageArea on the strike point, so enemies
## are pushed away from it.


## Shows only the hand crackle (hand = true) or everything else (hand = false).
## The sheet is one column of `frames` cells, so UV.x is the cell x and
## UV.y * frames gives the frame and the y inside it.
const SPLIT_SHADER_CODE: String = """
shader_type canvas_item;
uniform float frames;
uniform vec2 cell;
uniform float max_x;
uniform float min_y;
uniform float max_y;
uniform float until_frame;
uniform bool hand;
void fragment() {
	float f = UV.y * frames;
	float frame = floor(f);
	float y = fract(f) * cell.y;
	float x = UV.x * cell.x;
	bool in_hand = x < max_x && y >= min_y && y <= max_y && frame < until_frame;
	if (in_hand != hand) {
		discard;
	}
}
"""

static var _split_shader: Shader

var _data: Dictionary
var _time: float = 0.0
var _end_at: float = 0.0
var _struck: bool = false
var _bolt_fx: JutsuFxOnce
var _hand_fx: JutsuFxOnce


func begin() -> void:
    _data = jutsu.data.data
    move_speed_mult = 0.0
    can_turn = false
    var character: Dictionary = _data["character"]
    var rows: PackedInt32Array = to_ints(character["rows"])
    var secs: PackedFloat32Array = to_floats(character["frame_sec"])
    player.play_cast_frames(rows, secs, false)
    for s: float in secs:
        _end_at += s
    var world: Node = player.get_parent()
    var block: Dictionary = _data["fx"]
    # Bolt: unrotated, moved so the sheet's own target lands on the strike point.
    var target_offset: Vector2 = to_vector(_data["strike"]["target_offset_from_character"])
    _bolt_fx = JutsuFxOnce.spawn(world, _strike_point() - target_offset, 0.0, block)
    _apply_split(_bolt_fx, false)
    # Hand crackle: at the character, mirrored when aiming left.
    _hand_fx = JutsuFxOnce.spawn(world, global_position, 0.0, block)
    if cos(aim_angle) < 0.0:
        _hand_fx.scale.x = -1.0
    _apply_split(_hand_fx, true)


func update(delta: float, _held: bool) -> void:
    _time += delta
    if not _struck and _time >= float(_data["strike"]["at_sec"]):
        _strike()
    if _time >= _end_at:
        _finish()
        queue_free()


## Where the bolt lands: target distance along the aim (caster is rotated by it).
func _strike_point() -> Vector2:
    return to_global(to_vector(_data["strike"]["target_offset_from_character"]))


func _apply_split(fx: JutsuFxOnce, hand: bool) -> void:
    if _split_shader == null:
        _split_shader = Shader.new()
        _split_shader.code = SPLIT_SHADER_CODE
    var block: Dictionary = _data["fx"]
    var split: Dictionary = block["hand_crackle"]
    var cell: Array = block["cell"]
    var mat := ShaderMaterial.new()
    mat.shader = _split_shader
    mat.set_shader_parameter("frames", float(block["vframes"]))
    mat.set_shader_parameter("cell", Vector2(float(cell[0]), float(cell[1])))
    mat.set_shader_parameter("max_x", float(split["max_x"]))
    mat.set_shader_parameter("min_y", float(split["min_y"]))
    mat.set_shader_parameter("max_y", float(split["max_y"]))
    mat.set_shader_parameter("until_frame", float(split["until_frame"]))
    mat.set_shader_parameter("hand", hand)
    for child: Node in fx.get_children():
        if child is SheetAnimator:
            (child as SheetAnimator).material = mat


func _strike() -> void:
    _struck = true
    var hit: Dictionary = _data["strike"]["hit"]
    var shape := CircleShape2D.new()
    shape.radius = float(hit["radius"])
    var collision := CollisionShape2D.new()
    collision.shape = shape
    var area := DamageArea.new()
    area.damage = jutsu.damage
    area.team = player.team
    # Hit each enemy inside once.
    area.repeat_while_overlapping = true
    area.repeat_interval = 999.0
    area.add_child(collision)
    player.get_parent().add_child(area)
    area.global_position = _strike_point()
    var active: Array = hit["active_sec"]
    var lifetime: float = maxf(float(active[1]) - float(active[0]), 0.05)
    # Overlaps are only known after a physics step, so keep it for a few frames.
    area.get_tree().create_timer(lifetime, false).timeout.connect(area.queue_free)


func cancel() -> void:
    # Interrupted before the strike: the bolt must not fall either.
    if not _struck:
        for fx: JutsuFxOnce in [_bolt_fx, _hand_fx]:
            if is_instance_valid(fx):
                fx.queue_free()
    super.cancel()
