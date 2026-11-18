extends StaticBody2D
class_name Campfire
## Save point (content/prop/campfire/campfire.json): unlit -> ignite -> lit.
## Interacting lights it and makes it the place to restart after dying.
## TODO: write the save data here once saving exists.


const DATA: JSON = preload("res://content/prop/campfire/campfire.json")

## Where the player restarts, relative to the campfire.
@export var respawn_offset: Vector2 = Vector2(0, 20)

@onready var sprite: SheetAnimator = $Sprite
@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    interactable.interacted.connect(_on_interacted)
    if _world_call("is_campfire_lit", [_key()]):
        _play("lit")
    else:
        _play("unlit")


func is_lit() -> bool:
    return _world_call("is_campfire_lit", [_key()]) == true


func _on_interacted(_player: Player) -> void:
    if not is_lit():
        _world_call("mark_campfire_lit", [_key()])
        _play("ignite")
        sprite.finished.connect(_play.bind("lit"), CONNECT_ONE_SHOT)
    _world_call("set_checkpoint", [global_position + respawn_offset])


## Unique per map: map file + node path.
func _key() -> String:
    var map: Node = owner if owner else get_parent()
    return "%s:%s" % [map.scene_file_path, map.get_path_to(self)]


func _play(state: String) -> void:
    var block: Dictionary = DATA.data["states"][state]
    var sheet: Texture2D = load(String(block["sheet"]))
    sprite.play_uniform(sheet, int(block["vframes"]), 1.0 / float(block["fps"]), bool(block["loop"]))


func _world_call(method: String, args: Array) -> Variant:
    var world: Node = get_tree().get_first_node_in_group("world")
    if world == null or not world.has_method(method):
        return null
    return world.callv(method, args)
