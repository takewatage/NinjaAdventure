extends StaticBody2D
class_name Chest
## Treasure chest. Interact (F / pad A) to open: the contents pop out as
## pickups (they stay until taken), and a scroll teaches its jutsu at once.
## Stays open for the rest of the play (World flag). TODO: save data.


## What comes out (use chance 1 entries, pick_one off, for fixed contents).
@export var loot: ResourceLoot
## A scroll inside: the player learns this jutsu. null = none.
@export var scroll: ResourceJutsu
## Talismans of the scroll's jutsu that come with it.
@export var scroll_talismans: int = 5

@onready var sprite: Sprite2D = $Sprite
@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    interactable.interacted.connect(_on_interacted)
    _show_open(is_open())


func is_open() -> bool:
    return _world_call("has_flag", [_key()]) == true


func _on_interacted(player: Player) -> void:
    if is_open():
        return
    _world_call("set_flag", [_key()])
    _show_open(true)
    var tween: Tween = create_tween()
    tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.06)
    tween.tween_property(sprite, "scale", Vector2(0.9, 1.1), 0.08)
    tween.tween_property(sprite, "scale", Vector2.ONE, 0.08)
    Pickup.drop(loot, global_position + Vector2(0, 6), get_parent(), 0.0)
    if scroll and player.book:
        player.book.learn(scroll)
        if scroll_talismans > 0:
            player.book.add_talismans(scroll.id, scroll_talismans)
        PickupPopup.show_at(get_parent(), global_position + Vector2(0, -20), "%sを覚えた！" % scroll.display_name, Color("#fff1c2"))
    # TODO: an opening sound (no sfx asset in the project yet).


func _show_open(open: bool) -> void:
    sprite.frame = 1 if open else 0
    interactable.enabled = not open


## Unique per map: map file + node path.
func _key() -> String:
    var map: Node = owner if owner else get_parent()
    return "chest:%s:%s" % [map.scene_file_path, map.get_path_to(self)]


func _world_call(method: String, args: Array) -> Variant:
    var world: Node = get_tree().get_first_node_in_group("world")
    if world == null or not world.has_method(method):
        return null
    return world.callv(method, args)
