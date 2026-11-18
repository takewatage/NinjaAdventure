@icon("../map/icon_map.png")
extends Marker2D
class_name MapEntry
## Where the player appears when arriving on this map (MapExit.target_entry).


@export var id: StringName = &"start"
## Direction the player faces on arrival.
@export var facing: Vector2 = Vector2.DOWN
