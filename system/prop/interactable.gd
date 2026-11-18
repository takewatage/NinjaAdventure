extends Node2D
class_name Interactable
## Something the player can use with the interact button (F / pad A) when close.
## The player picks the nearest one within `radius`.


signal interacted(player: Player)

@export var radius: float = 20.0
@export var enabled: bool = true


func _ready() -> void:
    add_to_group("interactable")


func can_interact(player: Player) -> bool:
    return enabled and global_position.distance_to(player.global_position) <= radius


func interact(player: Player) -> void:
    interacted.emit(player)
