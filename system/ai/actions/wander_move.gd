@tool
class_name WanderMoveAction extends ActionLeaf
## Walks to a random point within `radius` of the enemy's home, then SUCCESS.
## Gives up (SUCCESS) after `max_time` in case a wall is in the way.


@export var radius: float = 40.0
@export var speed_scale: float = 0.6
@export var max_time: float = 3.0
@export var arrive_distance: float = 3.0

var _point: Vector2
var _left: float = 0.0


func before_run(actor: Node, _blackboard: Blackboard) -> void:
	var enemy: Enemy = actor as Enemy
	_point = enemy.home_position + Vector2.from_angle(randf() * TAU) * randf_range(0.3, 1.0) * radius
	_left = max_time


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy: Enemy = actor as Enemy
	_left -= get_physics_process_delta_time()
	if _left <= 0.0 or enemy.global_position.distance_to(_point) <= arrive_distance:
		enemy.stop()
		return SUCCESS
	enemy.move_toward_point(_point, speed_scale)
	return RUNNING


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	(actor as Enemy).stop()
	super(actor, blackboard)
