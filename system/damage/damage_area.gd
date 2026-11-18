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
    if repeat_interval > 0.0:
        if _last_hit.has(area) and _time - _last_hit[area] < repeat_interval:
            return
        _last_hit[area] = _time
    area.take_damage(damage,global_position)
    hit.emit(area)
