extends Resource
class_name ResourceEnemyAttack
## One attack pattern. Add more patterns by making more .tres files.
## Timeline: windup (telegraph) -> active (AttackArea on) -> recovery -> cooldown.


@export var damage: ResourceDamage
@export_category("range")
## The attack can start only when the target is between these distances.
@export var range_min: float = 0.0
@export var range_max: float = 32.0
@export_category("timing")
@export var windup_time: float = 0.4
@export var active_time: float = 0.25
@export var recovery_time: float = 0.4
@export var cooldown: float = 1.5
@export_category("motion")
## Speed toward the aimed direction while active. 0 = attack in place.
@export var lunge_speed: float = 0.0
