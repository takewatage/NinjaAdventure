@tool
class_name FleeFromTargetAction extends ActionLeaf
## Runs away from the target for `duration` seconds, then SUCCESS.


@export var duration: float = 1.2
@export var speed_scale: float = 1.3

var _left: float = 0.0


func before_run(_actor: Node, _blackboard: Blackboard) -> void:
	_left = duration


func tick(actor: Node, blackboard: Blackboard) -> int:
	var enemy: Enemy = actor as Enemy
	var target: Node2D = blackboard.get_value(AIKeys.TARGET) as Node2D
	_left -= get_physics_process_delta_time()
	if not is_instance_valid(target) or _left <= 0.0:
		enemy.stop()
		return SUCCESS
	enemy.move(target.global_position.direction_to(enemy.global_position), speed_scale)
	return RUNNING


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	(actor as Enemy).stop()
	super(actor, blackboard)
