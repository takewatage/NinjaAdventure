@tool
class_name PerformAttackAction extends ActionLeaf
## Starts `attack` aimed at the target and stays RUNNING until the enemy's
## attack (windup -> active -> recovery) ends. FAILURE if it can't start.


@export var attack: ResourceEnemyAttack

var _started: bool = false


func before_run(_actor: Node, _blackboard: Blackboard) -> void:
	_started = false


func tick(actor: Node, blackboard: Blackboard) -> int:
	var enemy: Enemy = actor as Enemy
	if not _started:
		var target: Node2D = blackboard.get_value(AIKeys.TARGET) as Node2D
		if attack == null or not is_instance_valid(target):
			return FAILURE
		if not enemy.start_attack(attack, target.global_position):
			return FAILURE
		_started = true
		return RUNNING
	return RUNNING if enemy.is_attacking() else SUCCESS


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	(actor as Enemy).cancel_attack()
	_started = false
	super(actor, blackboard)
