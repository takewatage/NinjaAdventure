@icon("../damage/icon_damage_area.png")
extends Area2D
class_name DamageArea


## A Hitbox took damage from this area.
signal hit(area: Hitbox)

const HITBOX_MASK = 3

@export var damage:ResourceDamage
@export var team:ResourceDamageTeam
## On: keep hitting every Hitbox that stays inside, every physics frame (contact
## damage). The receiver's invincibility time decides how often it really hurts.
## Off: hit once when a Hitbox enters.
@export var repeat_while_overlapping := false
## With repeat_while_overlapping: seconds between two hits on the same Hitbox
## (multi-hit attacks such as a fire breath). 0 = every physics frame.
@export var repeat_interval: float = 0.0
## On: no damage when a wall (physics layer 1) is between wall_check_origin and
## the Hitbox (fire breath, lightning and explosions must not hit through walls).
## The body that owns the Hitbox (e.g. a pot) does not count as a wall.
@export var blocked_by_walls := false
## Global point the wall check starts from. Vector2.INF = this area's position.
var wall_check_origin: Vector2 = Vector2.INF

var _time: float = 0.0
var _last_hit: Dictionary[Hitbox, float] = {}


func _ready() -> void:
    area_entered.connect(on_area_entered)
    collision_layer = 0
    collision_mask = 0
    set_collision_mask_value(HITBOX_MASK,true)
    monitorable = false


func _physics_process(delta: float) -> void:
    _time += delta
    if not repeat_while_overlapping or not monitoring:
        return
    for area in get_overlapping_areas():
        if area is Hitbox:
            _try_damage(area)


func on_area_entered(area:Hitbox):
    _try_damage(area)


func _try_damage(area:Hitbox) -> void:
    if not area.monitorable:
        return
    if area.team and team:
        if area.team == team:
            return
        if area.team.is_ally(team):
            return
    if blocked_by_walls and _wall_between(area):
        return
    if repeat_interval > 0.0:
        if _last_hit.has(area) and _time - _last_hit[area] < repeat_interval:
            return
        _last_hit[area] = _time
    area.take_damage(damage,global_position)
    hit.emit(area)


const WALL_LAYER = 1


## For flying attacks: casts a ray from `from` to `to` (plus `radius` ahead) against
## walls (layer 1). Returns {} when clear, else {"position": where the center must
## stop, "collider": what was hit}. A breakable thing that was hit (a pot: a body
## with a Hitbox) takes this area's damage here, since the area stops before it.
## Signals alone are not enough: body_entered comes a step late, so a fast or
## point-blank shot would already be on the other side of a thin wall.
func sweep_walls(from: Vector2, to: Vector2, radius: float, damage_breakables: bool = true) -> Dictionary:
    var dir: Vector2 = (to - from).normalized()
    if dir == Vector2.ZERO:
        return {}
    var query := PhysicsRayQueryParameters2D.create(from, to + dir * radius, WALL_LAYER)
    var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    if result.is_empty():
        return {}
    var hit_at: Vector2 = result["position"]
    var stop: Vector2 = hit_at - dir * radius
    if (stop - from).dot(dir) < 0.0:
        stop = from
    var collider: Object = result["collider"]
    if damage_breakables and collider is Node:
        for child: Node in (collider as Node).get_children():
            if child is Hitbox:
                _try_damage(child as Hitbox)
    return {"position": stop, "collider": collider}


func _wall_between(target: Hitbox) -> bool:
    var from: Vector2 = global_position if wall_check_origin == Vector2.INF else wall_check_origin
    var query := PhysicsRayQueryParameters2D.create(from, target.global_position, WALL_LAYER)
    var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    if result.is_empty():
        return false
    var collider: Object = result["collider"]
    # The target's own body (a pot's StaticBody, ...) is not a wall in front of it.
    return not (collider is Node and ((collider as Node).is_ancestor_of(target) or collider == target.get_parent()))
