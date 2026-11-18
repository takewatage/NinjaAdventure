extends Resource
class_name ResourceJutsuBook
## The jutsu the player knows, the talismans held for each, and the selected one.
## The player duplicates it on _ready. Later this belongs in the save data.


## Resource.changed is emitted when the selection, stock or learned list changes.
## A cast was tried without enough talismans (the UI shakes the slot).
signal dry_fired(jutsu: ResourceJutsu)

@export var learned: Array[ResourceJutsu] = []
## Talismans held per jutsu id. Missing = 0.
@export var stock: Dictionary[StringName, int] = {}
@export var selected_id: StringName


func get_selected() -> ResourceJutsu:
    for jutsu: ResourceJutsu in learned:
        if jutsu.id == selected_id:
            return jutsu
    return learned[0] if not learned.is_empty() else null


func find(id: StringName) -> ResourceJutsu:
    for jutsu: ResourceJutsu in learned:
        if jutsu.id == id:
            return jutsu
    return null


func select(id: StringName) -> bool:
    if find(id) == null:
        return false
    selected_id = id
    emit_changed()
    return true


func learn(jutsu: ResourceJutsu) -> void:
    if find(jutsu.id) != null:
        return
    learned.append(jutsu)
    if selected_id == &"":
        selected_id = jutsu.id
    emit_changed()


func get_stock(jutsu: ResourceJutsu) -> int:
    return stock.get(jutsu.id, 0)


func can_cast(jutsu: ResourceJutsu) -> bool:
    return not jutsu.uses_talisman or get_stock(jutsu) >= jutsu.per_cast


## Uses the talismans for one cast. Returns false (and emits dry_fired) if short.
func consume(jutsu: ResourceJutsu) -> bool:
    if not can_cast(jutsu):
        dry_fired.emit(jutsu)
        return false
    if jutsu.uses_talisman:
        stock[jutsu.id] = get_stock(jutsu) - jutsu.per_cast
        emit_changed()
    return true


## Adds talismans (pick-ups, shop). Returns how many were really added.
func add_talismans(id: StringName, amount: int) -> int:
    var jutsu: ResourceJutsu = find(id)
    if jutsu == null:
        return 0
    var before: int = get_stock(jutsu)
    stock[id] = mini(jutsu.max_stock, before + amount)
    emit_changed()
    return stock[id] - before
