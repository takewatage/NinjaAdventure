@icon("../character/icon_character.png")
extends CharacterBody2D
class_name Enemy
## The "body" of an enemy. It moves, animates, attacks, takes damage and dies.
## It makes no decisions: the behavior tree child "Brain" (BeehaveTree) calls the
## command functions below (move / stop / start_attack ...).


signal died

enum State { MOVE, ATTACK, STUN, DEAD }
enum AttackPhase { WINDUP, ACTIVE, RECOVERY }

@export var data: ResourceEnemy
@export var team: ResourceDamageTeam
@export_category("sprites")
## Sheet layout: column = direction (down, up, left, right), row = frame.
@export var idle_frame_sec: float = 0.25
@export var walk_frame_sec: float = 0.12

var state: State = State.MOVE
var life: ResourceLife
## Where the enemy was placed. Wander stays around it.
var home_position: Vector2

var _move_dir: Vector2 = Vector2.ZERO
var _speed_scale: float = 1.0
var _facing: Vector2 = Vector2.DOWN
var _stun_left: float = 0.0

var _attack: ResourceEnemyAttack
var _attack_phase: AttackPhase = AttackPhase.WINDUP
var _attack_phase_left: float = 0.0
var _attack_dir: Vector2 = Vector2.DOWN
var _cooldowns: Dictionary[ResourceEnemyAttack, float] = {}
var _windup_tween: Tween
var _anim: StringName = &""

@onready var sprite: SheetAnimator = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var attack_area: DamageArea = $AttackArea
@onready var contact_area: DamageArea = $ContactArea
@onready var brain: BeehaveTree = get_node_or_null("Brain") as BeehaveTree


func _ready() -> void:
    if data == null:
        data = ResourceEnemy.new()
    home_position = global_position
    life = ResourceLife.new()
    life.max_life = data.max_life
    life.life = data.max_life
    life.killed.connect(_die)
    hitbox.team = team
    hitbox.damage_received.connect(_on_damage_received)
    attack_area.team = team
    attack_area.monitoring = false
    contact_area.team = team
    contact_area.damage = data.contact_damage
    contact_area.monitoring = data.contact_damage != null
    _play_idle()


# --- commands for the behavior tree -----------------------------------------

## Walk in a direction. speed_scale multiplies ResourceEnemy.speed.
func move(direction: Vector2, speed_scale: float = 1.0) -> void:
    _move_dir = direction.normalized()
    _speed_scale = speed_scale


func move_toward_point(point: Vector2, speed_scale: float = 1.0) -> void:
    move(global_position.direction_to(point), speed_scale)


func stop() -> void:
    _move_dir = Vector2.ZERO


func face(direction: Vector2) -> void:
    if direction != Vector2.ZERO:
        _facing = direction.normalized()
        sprite.column = _direction_to_column(_facing)


func can_act() -> bool:
    return state == State.MOVE


func is_stunned() -> bool:
    return state == State.STUN


func is_dead() -> bool:
    return state == State.DEAD


func is_attacking() -> bool:
    return state == State.ATTACK


func is_attack_ready(attack: ResourceEnemyAttack) -> bool:
    return _cooldowns.get(attack, 0.0) <= 0.0


## Starts an attack aimed at a point. Returns false when it can't start now.
func start_attack(attack: ResourceEnemyAttack, aim_point: Vector2) -> bool:
    if not can_act() or not is_attack_ready(attack):
        return false
    _attack = attack
    _attack_dir = global_position.direction_to(aim_point)
    if _attack_dir == Vector2.ZERO:
        _attack_dir = _facing
    face(_attack_dir)
    attack_area.damage = attack.damage
    _cooldowns[attack] = attack.cooldown
    state = State.ATTACK
    _set_attack_phase(AttackPhase.WINDUP)
    return true


## Stops the current attack (the tree calls it when the attack is interrupted).
func cancel_attack() -> void:
    if state != State.ATTACK:
        return
    _end_attack()
    state = State.MOVE


# --- loop -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
    for attack: ResourceEnemyAttack in _cooldowns.keys():
        _cooldowns[attack] = maxf(0.0, _cooldowns[attack] - delta)

    match state:
        State.MOVE:
            _process_move(delta)
        State.ATTACK:
            _process_attack(delta)
        State.STUN:
            _process_stun(delta)
        State.DEAD:
            velocity = velocity.move_toward(Vector2.ZERO, data.acceleration * delta)
    move_and_slide()


func _process_move(delta: float) -> void:
    velocity = velocity.move_toward(_move_dir * data.speed * _speed_scale, data.acceleration * delta)
    if _move_dir != Vector2.ZERO:
        face(_move_dir)
        _play_walk()
    else:
        _play_idle()


func _process_attack(delta: float) -> void:
    _attack_phase_left -= delta
    match _attack_phase:
        AttackPhase.WINDUP:
            velocity = velocity.move_toward(Vector2.ZERO, data.acceleration * delta)
            if _attack_phase_left <= 0.0:
                _set_attack_phase(AttackPhase.ACTIVE)
        AttackPhase.ACTIVE:
            velocity = _attack_dir * _attack.lunge_speed
            if _attack_phase_left <= 0.0:
                _set_attack_phase(AttackPhase.RECOVERY)
        AttackPhase.RECOVERY:
            velocity = velocity.move_toward(Vector2.ZERO, data.acceleration * delta)
            if _attack_phase_left <= 0.0:
                _end_attack()
                state = State.MOVE


func _set_attack_phase(phase: AttackPhase) -> void:
    _attack_phase = phase
    match phase:
        AttackPhase.WINDUP:
            _attack_phase_left = _attack.windup_time
            _play_idle()
            _telegraph(_attack.windup_time)
        AttackPhase.ACTIVE:
            _attack_phase_left = _attack.active_time
            _stop_telegraph()
            attack_area.set_deferred("monitoring", true)
            _play_walk()
        AttackPhase.RECOVERY:
            _attack_phase_left = _attack.recovery_time
            attack_area.set_deferred("monitoring", false)
            _play_idle()


func _end_attack() -> void:
    _stop_telegraph()
    attack_area.set_deferred("monitoring", false)
    _attack = null


func _process_stun(delta: float) -> void:
    velocity = velocity.move_toward(Vector2.ZERO, data.acceleration * delta)
    _stun_left -= delta
    if _stun_left <= 0.0:
        state = State.MOVE


# --- damage -----------------------------------------------------------------

func _on_damage_received(damage: ResourceDamage, at_pos: Vector2) -> void:
    if state == State.DEAD:
        return
    if state == State.ATTACK:
        _end_attack()
    var push_dir: Vector2 = at_pos.direction_to(global_position)
    velocity = push_dir * (data.knockback_speed + float(damage.push_force))
    _move_dir = Vector2.ZERO
    state = State.STUN
    _stun_left = data.stun_time
    _flash()
    life.damage(damage.amount)


func _die() -> void:
    if state == State.DEAD:
        return
    state = State.DEAD
    _end_attack()
    if brain:
        brain.disable()
    hitbox.disable()
    contact_area.set_deferred("monitoring", false)
    collision_layer = 0
    _play_idle()
    Pickup.drop(data.loot, global_position, get_parent())
    died.emit()
    var tween: Tween = create_tween()
    tween.tween_interval(0.2)
    tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
    tween.tween_callback(queue_free)


# --- visuals ----------------------------------------------------------------

func _flash() -> void:
    sprite.modulate = Color(5, 5, 5)
    var tween: Tween = create_tween()
    tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


## Squash and tint while winding up, so the player can see the attack coming.
func _telegraph(time: float) -> void:
    _stop_telegraph()
    _windup_tween = create_tween().set_parallel()
    _windup_tween.tween_property(sprite, "scale", Vector2(1.25, 0.75), time)
    _windup_tween.tween_property(sprite, "modulate", Color(1.6, 0.7, 0.7), time)


func _stop_telegraph() -> void:
    if _windup_tween:
        _windup_tween.kill()
        _windup_tween = null
    sprite.scale = Vector2.ONE
    if state != State.DEAD:
        sprite.modulate = Color.WHITE


func _play_idle() -> void:
    if _anim != &"idle":
        _anim = &"idle"
        sprite.play_uniform(sprite.texture, 2, idle_frame_sec, true)


func _play_walk() -> void:
    if _anim != &"walk":
        _anim = &"walk"
        sprite.play_uniform(sprite.texture, sprite.vframes, walk_frame_sec, true)



static func _direction_to_column(v: Vector2) -> int:
    if absf(v.x) > absf(v.y):
        return 3 if v.x > 0.0 else 2
    return 0 if v.y > 0.0 else 1
