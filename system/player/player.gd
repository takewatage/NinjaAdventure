@icon("../character/icon_character.png")
extends CharacterBody2D
class_name Player
## Top-down player: idle / walk / dodge (roll) / 3-hit attack combo / hurt / dead.
## Driven by HumanController (move_vector, aim_point, attack(), dodge()).
## Each hit aims at aim_point (the mouse cursor) at the moment it starts. The hit shape
## and lunge use the exact angle; the fx uses the nearest of 8 columns, rotated by the
## remaining gap (rotate_fx_to_aim). The 4-direction character sprite uses the column
## given by combo_data's direction table.
## Combo timings, hit shapes and fx come from combo_data (content/fx/combo3/combo3_8dir.json).

signal died

enum State { MOVE, ATTACK, DODGE, HURT, DEAD }
## Character sheet columns (column = direction).
enum Dir { DOWN, UP, LEFT, RIGHT }

const DIR_VECTORS: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
const CELL_HEIGHT: int = 32
const AIM_COLUMNS: int = 8
## Releasing a diagonal (two keys) is never exactly simultaneous. A switch from a
## diagonal to one of its neighbours is applied only after it is held this long.
const AIM_RELEASE_GRACE: float = 0.08

@export_category("physics")
@export var speed: float = 100.0
@export var acceleration: float = 1000.0
@export var deceleration: float = 800.0

@export_category("life")
@export var max_life: float = 6.0
## Seconds of hit reaction (no control) after taking damage.
@export var hurt_duration: float = 0.3
## Seconds of invincibility after taking damage (the sprite blinks).
@export var invincible_time: float = 1.0
## Speed of the push received when hit (added to the damage's push_force).
@export var knockback_speed: float = 120.0

@export_category("dodge")
@export var dodge_speed: float = 160.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 0.15

@export_category("attack")
@export var combo_data: JSON
@export var attack_damage: ResourceDamage
@export var team: ResourceDamageTeam
## On: snap the hit shape and lunge to the fx column (every 45 deg), so they match the
## visuals exactly. Off: use the exact cursor angle.
@export var snap_aim_to_8_directions: bool = false
## On: rotate the fx by the gap between the exact aim and its column (<= 22.5 deg),
## so the fx lines up with the hit shape. Pixel art gets jagged when rotated; if that
## looks bad, turn this off and turn snap_aim_to_8_directions on instead.
@export var rotate_fx_to_aim: bool = true

@export_category("sprites")
@export var idle_sheet: Texture2D
@export var walk_sheet: Texture2D
@export var attack_sheet: Texture2D
@export var dodge_sheet: Texture2D
@export var hurt_sheet: Texture2D
@export var idle_frame_sec: float = 0.25
@export var walk_frame_sec: float = 0.15

var move_vector: Vector2 = Vector2.ZERO
## 4-direction facing of the character sprite.
var facing: Dir = Dir.DOWN
## Point to attack toward (global). Set by HumanController to the mouse cursor.
## Vector2.INF = no aim; attacks then go toward move_column.
var aim_point: Vector2 = Vector2.INF
## Last movement direction in 8 directions: 0 = right, clockwise every 45 degrees
## (2 = down, 4 = left, 6 = up). Used for dodging in place and as the aim fallback.
var move_column: int = 2
var state: State = State.MOVE
var life: ResourceLife

var _state_time: float = 0.0
var _attack_pressed: bool = false
var _dodge_pressed: bool = false
var _dodge_vector: Vector2 = Vector2.DOWN
var _dodge_cooldown_left: float = 0.0
var _pending_aim: int = -1
var _pending_aim_left: float = 0.0

var _directions: Array[Dictionary] = []
var _hits: Array[Dictionary] = []
var _hit_polygons: Array[PackedVector2Array] = []
var _fx_sheets: Array[Texture2D] = []
var _fx_frame_sec: float = 1.0 / 30.0
var _reset_after_sec: float = 0.25
var _hit_index: int = 0
var _hit_column: int = 2
var _hit_angle: float = PI / 2.0
var _next_hit: int = 0
var _combo_buffered: bool = false
var _combo_reset_left: float = 0.0
var _fx_spawned: bool = false
var _attack_active: bool = false
var _invincible_left: float = 0.0

@onready var sprite: SheetAnimator = $Sprite
@onready var fx: SheetAnimator = $Fx
@onready var hitbox: Hitbox = $Hitbox
@onready var attack_area: DamageArea = $AttackArea
@onready var attack_shape: CollisionPolygon2D = $AttackArea/Shape
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
    _load_combo()
    attack_area.damage = attack_damage
    attack_area.team = team
    attack_area.monitoring = false
    life = ResourceLife.new()
    life.max_life = max_life
    life.life = max_life
    hitbox.team = team
    hitbox.damage_received.connect(_on_damage_received)
    fx.visible = false
    fx.finished.connect(_on_fx_finished)
    # PlayerAssignor (a child) has already added us to "player" by now.
    if is_in_group("player"):
        camera.make_current()
    else:
        camera.enabled = false
    _set_facing(Dir.DOWN)
    _play_loop(idle_sheet, idle_frame_sec)


## Called by HumanController.
func attack() -> void:
    _attack_pressed = true


## Called by HumanController.
func dodge() -> void:
    _dodge_pressed = true


func _physics_process(delta: float) -> void:
    _dodge_cooldown_left = maxf(0.0, _dodge_cooldown_left - delta)
    if _combo_reset_left > 0.0:
        _combo_reset_left -= delta
        if _combo_reset_left <= 0.0:
            _next_hit = 0
    _update_aim(delta)

    match state:
        State.MOVE:
            _process_move(delta)
        State.ATTACK:
            _process_attack(delta)
        State.DODGE:
            _process_dodge(delta)
        State.HURT:
            _process_hurt(delta)
        State.DEAD:
            velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
    _update_invincibility(delta)

    _attack_pressed = false
    _dodge_pressed = false
    move_and_slide()


# --- aim ----------------------------------------------------------------

func _update_aim(delta: float) -> void:
    if move_vector == Vector2.ZERO:
        # Released: keep the current aim and drop a half-released diagonal.
        _pending_aim = -1
        return
    var column: int = vector_to_column(move_vector)
    if column == move_column:
        _pending_aim = -1
        return
    var leaving_diagonal: bool = move_column % 2 == 1 and _column_distance(column, move_column) == 1
    if not leaving_diagonal:
        move_column = column
        _pending_aim = -1
        return
    if _pending_aim != column:
        _pending_aim = column
        _pending_aim_left = AIM_RELEASE_GRACE
    _pending_aim_left -= delta
    if _pending_aim_left <= 0.0:
        move_column = column
        _pending_aim = -1


static func vector_to_column(v: Vector2) -> int:
    return posmod(roundi(v.angle() / (PI / 4.0)), AIM_COLUMNS)


static func column_to_vector(column: int) -> Vector2:
    return Vector2.RIGHT.rotated(float(column) * PI / 4.0)


func _column_distance(a: int, b: int) -> int:
    var d: int = absi(a - b) % AIM_COLUMNS
    return mini(d, AIM_COLUMNS - d)


# --- move ---------------------------------------------------------------

func _process_move(delta: float) -> void:
    if _dodge_pressed and _dodge_cooldown_left <= 0.0:
        _start_dodge()
        return
    if _attack_pressed and not _hits.is_empty():
        _start_hit(_next_hit)
        return

    if move_vector != Vector2.ZERO:
        _set_facing(_vector_to_dir(move_vector))
        velocity = velocity.move_toward(move_vector * speed, acceleration * delta)
        _play_loop(walk_sheet, walk_frame_sec)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
        _play_loop(idle_sheet, idle_frame_sec)


func _play_loop(sheet: Texture2D, frame_sec: float) -> void:
    if sprite.is_playing_sheet(sheet):
        return
    sprite.flip_h = false
    sprite.play_uniform(sheet, _frame_count(sheet), frame_sec, true)


# --- dodge --------------------------------------------------------------

func _start_dodge() -> void:
    state = State.DODGE
    _state_time = 0.0
    var v: Vector2 = move_vector if move_vector != Vector2.ZERO else column_to_vector(move_column)
    _dodge_vector = v.normalized()
    _set_facing(_vector_to_dir(_dodge_vector))
    var frames: int = _frame_count(dodge_sheet)
    sprite.flip_h = false
    sprite.play_uniform(dodge_sheet, frames, dodge_duration / float(frames), false)
    fx.visible = false
    # Invincible while rolling: damage areas can't see the hitbox.
    hitbox.set_deferred("monitorable", false)


func _process_dodge(delta: float) -> void:
    _state_time += delta
    velocity = _dodge_vector * dodge_speed
    if _state_time >= dodge_duration:
        state = State.MOVE
        velocity = _dodge_vector * speed
        _dodge_cooldown_left = dodge_cooldown
        hitbox.set_deferred("monitorable", true)


# --- hurt / dead --------------------------------------------------------

func is_invincible() -> bool:
    return state == State.DODGE or state == State.DEAD or _invincible_left > 0.0


func _on_damage_received(damage: ResourceDamage, at_pos: Vector2) -> void:
    if is_invincible():
        return
    _cancel_attack()
    var push_dir: Vector2 = at_pos.direction_to(global_position)
    if push_dir == Vector2.ZERO:
        push_dir = -DIR_VECTORS[facing]
    velocity = push_dir * (knockback_speed + float(damage.push_force))
    # Turn toward whatever hit us.
    _set_facing(_vector_to_dir(-push_dir))
    _invincible_left = invincible_time
    state = State.HURT
    _state_time = 0.0
    var frames: int = _frame_count(hurt_sheet)
    sprite.flip_h = false
    sprite.play_uniform(hurt_sheet, frames, hurt_duration / float(frames), false)
    life.damage(damage.amount)
    if not life.is_alive():
        _die()


func _process_hurt(delta: float) -> void:
    _state_time += delta
    velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
    if _state_time >= hurt_duration:
        state = State.MOVE


## Blink while invincible after a hit.
func _update_invincibility(delta: float) -> void:
    if _invincible_left <= 0.0:
        return
    _invincible_left -= delta
    if _invincible_left <= 0.0 or state == State.DEAD:
        sprite.visible = true
    else:
        sprite.visible = int(_invincible_left * 20.0) % 2 == 0


## No control any more. Keeps the last hurt frame (Dead.png is a different layout).
func _die() -> void:
    state = State.DEAD
    _invincible_left = 0.0
    sprite.visible = true
    sprite.modulate = Color(0.6, 0.6, 0.6)
    hitbox.set_deferred("monitorable", false)
    died.emit()


func _cancel_attack() -> void:
    _set_attack_active(false)
    fx.visible = false
    _combo_buffered = false
    _next_hit = 0


# --- attack combo -------------------------------------------------------

func _load_combo() -> void:
    if combo_data == null:
        push_error("Player: combo_data is not set")
        return
    var root: Dictionary = combo_data.data
    var combo: Dictionary = root["combo"]
    var fx_common: Dictionary = root["fx_common"]
    _reset_after_sec = float(combo["reset_after_sec"])
    _fx_frame_sec = 1.0 / float(fx_common["fps"])
    for d: Variant in root["directions"]:
        _directions.append(d as Dictionary)
    for h: Variant in combo["hits"]:
        var hit: Dictionary = h
        _hits.append(hit)
        var fx_info: Dictionary = hit["fx"]
        var sheet: Texture2D = load(String(fx_info["sheet"]))
        _fx_sheets.append(sheet)
        var shape: Dictionary = hit["hit_shape"]
        var polygon := PackedVector2Array()
        for p: Variant in shape["polygon"]:
            var point: Array = p
            polygon.append(Vector2(float(point[0]), float(point[1])))
        _hit_polygons.append(polygon)


func _start_hit(index: int) -> void:
    state = State.ATTACK
    _state_time = 0.0
    _hit_index = index
    _aim_hit()
    _combo_buffered = false
    _combo_reset_left = 0.0
    _fx_spawned = false
    velocity = Vector2.ZERO

    var direction: Dictionary = _directions[_hit_column]
    _set_facing(int(direction["character_column"]) as Dir)
    var hit: Dictionary = _hits[index]
    sprite.play(attack_sheet, _to_ints(hit["character_rows"]), _to_floats(hit["character_frame_sec"]), false)
    sprite.flip_h = _hit_flip_h(hit, direction)

    # Hit shapes are defined facing right; rotate them to the aim angle.
    attack_shape.polygon = _hit_polygons[index]
    attack_shape.rotation = _hit_angle

    fx.visible = false
    _set_attack_active(false)


## Sets _hit_angle (exact, or snapped) and _hit_column (nearest of 8) for this hit.
func _aim_hit() -> void:
    var angle: float = column_to_vector(move_column).angle()
    if aim_point != Vector2.INF:
        # Aim from the character's visual center (the AttackArea origin).
        var to_aim: Vector2 = aim_point - attack_area.global_position
        if to_aim.length() > 1.0:
            angle = to_aim.angle()
    _hit_column = vector_to_column(Vector2.from_angle(angle))
    _hit_angle = float(_hit_column) * PI / 4.0 if snap_aim_to_8_directions else angle


## flip_h is a bool, or the string "directions[].hit2_flip_h" (look it up per direction).
func _hit_flip_h(hit: Dictionary, direction: Dictionary) -> bool:
    var flip: Variant = hit["flip_h"]
    if flip is bool:
        return flip
    return bool(direction["hit2_flip_h"])


func _process_attack(delta: float) -> void:
    _state_time += delta
    var hit: Dictionary = _hits[_hit_index]

    var fx_info: Dictionary = hit["fx"]
    if not _fx_spawned and _state_time >= float(fx_info["spawn_at_sec"]):
        _spawn_fx(_hit_index, int(fx_info["vframes"]))

    var active: Array = hit["active_sec"]
    var active_start: float = float(active[0])
    var active_end: float = float(active[1])
    var is_active: bool = _state_time >= active_start and _state_time < active_end
    if is_active != _attack_active:
        _set_attack_active(is_active)

    # Lunge: spread lunge_px_along_aim over the active window, toward the aim.
    var lunge_px: float = float(hit["lunge_px_along_aim"])
    if is_active and lunge_px > 0.0:
        velocity = Vector2.from_angle(_hit_angle) * lunge_px / (active_end - active_start)
    else:
        velocity = Vector2.ZERO

    # Input is buffered from the active start; the next hit starts at cancel_from.
    var has_next: bool = _hit_index < _hits.size() - 1
    if _attack_pressed and has_next and _state_time >= active_start:
        _combo_buffered = true
    var cancel_from: Variant = hit["cancel_from_sec"]
    if _combo_buffered and cancel_from != null and _state_time >= float(cancel_from):
        _start_hit(_hit_index + 1)
        return

    if _state_time >= float(hit["duration_sec"]):
        _set_attack_active(false)
        state = State.MOVE
        velocity = Vector2.ZERO
        if has_next:
            # No buffered input: the next press within reset_after_sec continues the combo.
            _next_hit = _hit_index + 1
            _combo_reset_left = _reset_after_sec
        else:
            _next_hit = 0


func _spawn_fx(index: int, frame_count: int) -> void:
    _fx_spawned = true
    var direction: Dictionary = _directions[_hit_column]
    # Each column is drawn for its direction, and the reverse swing is drawn into
    # the hit-2 sheet; flip_h is for the character only.
    fx.flip_h = false
    fx.column = _hit_column
    # The fx pivot (cell center) is the character's visual center, so rotating the
    # node turns the slash around the same origin as the hit shape.
    var column_angle: float = float(_hit_column) * PI / 4.0
    fx.rotation = wrapf(_hit_angle - column_angle, -PI, PI) if rotate_fx_to_aim else 0.0
    fx.play_uniform(_fx_sheets[index], frame_count, _fx_frame_sec, false)
    var behind: bool = bool(direction["fx_behind_character"])
    var fx_before_sprite: bool = fx.get_index() < sprite.get_index()
    if behind != fx_before_sprite:
        move_child(fx, sprite.get_index())
    fx.visible = true


func _on_fx_finished() -> void:
    fx.visible = false


func _set_attack_active(on: bool) -> void:
    _attack_active = on
    attack_area.set_deferred("monitoring", on)


# --- helpers ------------------------------------------------------------

func _set_facing(dir: Dir) -> void:
    facing = dir
    sprite.column = dir


func _vector_to_dir(v: Vector2) -> Dir:
    var ax: float = absf(v.x)
    var ay: float = absf(v.y)
    if is_equal_approx(ax, ay):
        # Diagonal: keep the current facing if it is one of the two components.
        if facing == Dir.LEFT and v.x < 0.0 or facing == Dir.RIGHT and v.x > 0.0:
            return facing
        if facing == Dir.UP and v.y < 0.0 or facing == Dir.DOWN and v.y > 0.0:
            return facing
    if ax > ay:
        return Dir.RIGHT if v.x > 0.0 else Dir.LEFT
    return Dir.DOWN if v.y > 0.0 else Dir.UP


func _frame_count(sheet: Texture2D) -> int:
    return maxi(1, int(sheet.get_height()) / CELL_HEIGHT)


func _to_ints(values: Array) -> PackedInt32Array:
    var out := PackedInt32Array()
    for v: Variant in values:
        out.append(int(v))
    return out


func _to_floats(values: Array) -> PackedFloat32Array:
    var out := PackedFloat32Array()
    for v: Variant in values:
        out.append(float(v))
    return out
