@icon("../teleporter/icon_teleporter.png")
extends Area2D
class_name MapExit
## Walking into this area loads another map (the World does the fade and swap).
## Give it a CollisionShape2D child for the size.


const MASK_PLAYER = 5

## The map to load (a path, not a PackedScene, so two maps can point at each other).
@export_file("*.tscn") var target_map: String
## MapEntry.id on the target map.
@export var target_entry: StringName = &"start"


func _ready() -> void:
    collision_layer = 0
    collision_mask = 0
    set_collision_mask_value(MASK_PLAYER, true)
    monitorable = false
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
    if body is Player and target_map != "":
        get_tree().call_group("world", "change_map", target_map, target_entry)
