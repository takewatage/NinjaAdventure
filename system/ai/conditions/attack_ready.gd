@tool
class_name AttackReadyCondition extends ConditionLeaf
## SUCCESS when `attack` is off cooldown and the target is inside its range.


@export var attack: ResourceEnemyAttack


func tick(actor: Node, blackboard: Blackboard) -> int:
	var enemy: Enemy = actor as Enemy
	var target: Node2D = blackboard.get_value(AIKeys.TARGET) as Node2D
	if attack == null or not is_instance_valid(target) or not enemy.is_attack_ready(attack):
		return FAILURE
	var dist: float = enemy.global_position.distance_to(target.global_position)
	return SUCCESS if dist >= attack.range_min and dist <= attack.range_max else FAILURE
