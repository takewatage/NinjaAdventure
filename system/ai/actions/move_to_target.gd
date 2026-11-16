@tool
class_name MoveToTargetAction extends ActionLeaf
## Chases the blackboard target and stays `stop_distance` away (RUNNING).
## FAILURE when there is no target.


@export var stop_distance: float = 12.0
@export var speed_scale: float = 1.0


func tick(actor: Node, blackboard: Blackboard) -> int:
	var enemy: Enemy = actor as Enemy
	var target: Node2D = blackboard.get_value(AIKeys.TARGET) as Node2D
	if not is_instance_valid(target):
		enemy.stop()
		return FAILURE
	if enemy.global_position.distance_to(target.global_position) > stop_distance:
		enemy.move_toward_point(target.global_position, speed_scale)
	else:
		enemy.stop()
		enemy.face(enemy.global_position.direction_to(target.global_position))
	return RUNNING


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	(actor as Enemy).stop()
	super(actor, blackboard)
