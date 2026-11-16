@icon("../../behavior/icon_area_target_finder.png")
extends Area2D
class_name TargetSensor
## Finds a target and writes it to the brain's blackboard (AIKeys.TARGET).
## Spots bodies in `target_group` that enter the shape; forgets them when they
## get farther than `lose_distance` from the sensor.


@export var target_group: StringName = &"player"
@export var lose_distance: float = 120.0

var _brain: BeehaveTree


func _ready() -> void:
	monitorable = false
	body_entered.connect(_on_body_entered)
	_brain = get_parent().get_node_or_null("Brain") as BeehaveTree
	if _brain == null:
		push_warning("TargetSensor: no sibling 'Brain' (BeehaveTree) on %s" % get_parent().name)
		set_physics_process(false)


func _on_body_entered(body: Node2D) -> void:
	if _brain == null or not body.is_in_group(target_group):
		return
	if not _brain.blackboard.has_value(AIKeys.TARGET):
		_brain.blackboard.set_value(AIKeys.TARGET, body)


func _physics_process(_delta: float) -> void:
	if not _brain.blackboard.has_value(AIKeys.TARGET):
		return
	var target: Node2D = _brain.blackboard.get_value(AIKeys.TARGET) as Node2D
	if not is_instance_valid(target) or global_position.distance_to(target.global_position) > lose_distance:
		forget()
		return
	_brain.blackboard.set_value(AIKeys.LAST_SEEN_POSITION, target.global_position)


func forget() -> void:
	_brain.blackboard.erase_value(AIKeys.TARGET)
