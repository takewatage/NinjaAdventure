@tool
class_name WaitRandomAction extends ActionLeaf
## Stands still for a random time between min_time and max_time, then SUCCESS.


@export var min_time: float = 0.5
@export var max_time: float = 1.5

var _left: float = 0.0


func before_run(_actor: Node, _blackboard: Blackboard) -> void:
	_left = randf_range(min_time, max_time)


func tick(actor: Node, _blackboard: Blackboard) -> int:
	(actor as Enemy).stop()
	_left -= get_physics_process_delta_time()
	return SUCCESS if _left <= 0.0 else RUNNING
