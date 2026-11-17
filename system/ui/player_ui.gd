extends Control


## How much life one heart holds. heart.png has quarter steps, so with 2 a hit
## of 1 empties half a heart (player max_life 6 = 3 hearts).
@export var life_per_heart: float = 2.0

@onready var receptacle_bar: Control = %ReceptacleBar


var resource_life:ResourceLife:
    set(v):
        if resource_life and resource_life.life_changed.is_connected(on_life_changed):
            resource_life.life_changed.disconnect(on_life_changed)
        resource_life = v
        if resource_life == null:
            return
        receptacle_bar.max_life = _to_bar(resource_life.max_life)
        resource_life.life_changed.connect(on_life_changed)
        on_life_changed()


func on_life_changed():
    receptacle_bar.life = _to_bar(resource_life.life)


func _to_bar(value: float) -> int:
    return roundi(value * receptacle_bar.receptacle_size / life_per_heart)
