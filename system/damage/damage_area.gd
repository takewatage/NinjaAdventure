@icon("../damage/icon_damage_area.png")
extends Area2D
class_name DamageArea


const HITBOX_MASK = 3

@export var damage:ResourceDamage
@export var team:ResourceDamageTeam
## On: keep hitting every Hitbox that stays inside, every physics frame (contact
## damage). The receiver's invincibility time decides how often it really hurts.
## Off: hit once when a Hitbox enters.
@export var repeat_while_overlapping := false


func _ready() -> void:
    area_entered.connect(on_area_entered)
    collision_layer = 0
    collision_mask = 0
    set_collision_mask_value(HITBOX_MASK,true)
    monitorable = false


func _physics_process(_delta: float) -> void:
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
    area.take_damage(damage,global_position)
