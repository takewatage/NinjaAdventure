@tool
class_name HasTargetCondition extends ConditionLeaf
## SUCCESS while the blackboard has a valid target.


func tick(_actor: Node, blackboard: Blackboard) -> int:
	var target: Node2D = blackboard.get_value(AIKeys.TARGET) as Node2D
	return SUCCESS if is_instance_valid(target) else FAILURE
