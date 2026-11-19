@icon("../stat/icon.png")
extends Resource
class_name ResourceEnemy
## Tuning numbers for one kind of enemy. One .tres per enemy type.


@export var max_life: float = 3.0
## Damage dealt by just touching the enemy (ContactArea). null = harmless body.
@export var contact_damage: ResourceDamage
@export_category("move")
@export var speed: float = 40.0
@export var acceleration: float = 600.0
@export_category("hurt")
## Speed of the push received when hit (added to the damage's push_force).
@export var knockback_speed: float = 140.0
## Seconds the enemy can't act after being hit.
@export var stun_time: float = 0.35
@export_category("drop")
## Rolled when the enemy dies (money, mostly). null = nothing.
@export var loot: ResourceLoot
