extends Resource
class_name ResourceLoot
## A drop table: what a pot / grass / enemy / chest leaves behind.
## Pickup.drop() rolls it and throws the items out.


## On: one roll picks at most one entry (chances add up; the rest = nothing).
## Off: every entry rolls on its own.
@export var pick_one: bool = true
@export var entries: Array[ResourceLootEntry] = []


## Rolled entries -> list of {"kind": Kind, "count": int, "element": String}.
func roll() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    if pick_one:
        var r: float = randf()
        for entry: ResourceLootEntry in entries:
            if r < entry.chance:
                out.append(_result(entry))
                break
            r -= entry.chance
    else:
        for entry: ResourceLootEntry in entries:
            if randf() < entry.chance:
                out.append(_result(entry))
    return out


func _result(entry: ResourceLootEntry) -> Dictionary:
    return {"kind": entry.kind, "count": randi_range(entry.count_min, maxi(entry.count_min, entry.count_max)), "element": entry.element}
