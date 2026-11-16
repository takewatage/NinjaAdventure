@tool
class_name IdleAction extends ActionLeaf
## Stands still forever (RUNNING). Use under a reactive parent that leaves it.


func tick(actor: Node, _blackboard: Blackboard) -> int:
	(actor as Enemy).stop()
	return RUNNING
