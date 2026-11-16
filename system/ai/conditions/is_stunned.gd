@tool
class_name IsStunnedCondition extends ConditionLeaf
## SUCCESS while the enemy is in hit-stun.


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy: Enemy = actor as Enemy
	return SUCCESS if enemy.is_stunned() else FAILURE
