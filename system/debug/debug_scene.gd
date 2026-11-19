extends Node
class_name DebugScene
## Root of test.tscn (debug only, not part of the game).
## The player learns every jutsu in jutsu_dir, talismans never run out, and
## the HUD (hearts, money, jutsu) is bound to the player.
## A jutsu added to content/jutsu/ shows up here without editing the scene.


## Every ResourceJutsu (.tres) in this folder is learned.
@export_dir var jutsu_dir: String = "res://content/jutsu"
## Talismans are refilled to max_stock right after each cast.
@export var infinite_talismans: bool = true

@onready var player_ui: Control = %PlayerUi
@onready var jutsu_ui: JutsuUi = %JutsuUi

var _player: Player


func _ready() -> void:
    # Children are ready first, so the player has already copied its book.
    _player = _find_player()
    assert(_player != null, "DebugScene: no Player in the scene")
    var all_jutsu: Array[ResourceJutsu] = _load_all_jutsu()
    assert(not all_jutsu.is_empty(), "DebugScene: no ResourceJutsu in " + jutsu_dir)
    for jutsu: ResourceJutsu in all_jutsu:
        _player.book.learn(jutsu)
    _refill()
    player_ui.resource_life = _player.life
    player_ui.wallet = _player.wallet
    jutsu_ui.player = _player
    if infinite_talismans:
        _player.book.changed.connect(_refill)


func _find_player() -> Player:
    for node: Node in find_children("*", "", true, false):
        if node is Player:
            return node
    return null


func _load_all_jutsu() -> Array[ResourceJutsu]:
    var list: Array[ResourceJutsu] = []
    for file: String in ResourceLoader.list_directory(jutsu_dir):
        if not file.ends_with(".tres"):
            continue
        var res: Resource = load(jutsu_dir.path_join(file))
        if res is ResourceJutsu:
            list.append(res)
    return list


## Tops every learned jutsu up to its max. Writes the dictionary directly so it
## does not emit `changed` again from inside the changed handler.
func _refill() -> void:
    var book: ResourceJutsuBook = _player.book
    for jutsu: ResourceJutsu in book.learned:
        if jutsu.uses_talisman:
            book.stock[jutsu.id] = jutsu.max_stock
