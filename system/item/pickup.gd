extends Node2D
class_name Pickup
## An item lying on the ground: a talisman (refills a jutsu of its element) or a
## coin (money). When the player comes near it drifts toward them slowly, speeds
## up as it gets closer, and is taken when it reaches them.
## Drops (Pickup.drop) pop out of where they came from and vanish after a while.
## Placed by hand in a map (pickup.tscn), it stays until taken.

const TALISMAN_DATA: JSON = preload("res://content/item/talisman/talisman_items.json")
const TALISMAN_SHEET: Texture2D = preload("res://content/item/talisman/talisman_items.png")
const SILVER_COIN: Texture2D = preload("res://content/item/Treasure/SilverCoin.png")
## 4 frames of a spinning gold coin (10x10 each).
const GOLD_COIN: Texture2D = preload("res://content/item/Treasure/Coin2.png")
const SHADOW: Texture2D = preload("res://content/character/Shadow.png")
## Loaded at run time (pickup.tscn uses this script: no cyclic preload).
const SCENE_PATH := "res://content/item/pickup/pickup.tscn"

## Money of one coin.
const COIN_VALUE: Dictionary = {
    ResourceLootEntry.Kind.SILVER_COIN: 1,
    ResourceLootEntry.Kind.GOLD_COIN: 5,
}

@export var kind: ResourceLootEntry.Kind = ResourceLootEntry.Kind.TALISMAN
## Talisman only: 火 / 水 / 風 / 雷 / 土 / 陽 / 陰.
@export var element: String = "火"
## Size of the talisman picture (the art is 16x16; 0.5 = 8x8 on screen).
@export var talisman_scale: float = 0.5
## Seconds before it disappears (it blinks at the end). 0 = never.
@export var lifetime: float = 0.0

@export_category("pull toward the player")
## The player within this distance starts pulling the item.
@export var attract_radius: float = 36.0
## Speed when the pull starts (far away) ...
@export var slow_speed: float = 25.0
## ... and when it is right next to the player.
@export var fast_speed: float = 260.0
## Extra speed per second while being pulled, so a walking player is caught.
@export var speed_gain: float = 220.0
## Taken at this distance from the player's center.
@export var take_radius: float = 4.0

var _sprite: Sprite2D
var _shadow: Sprite2D
var _player: Player
var _pulled: bool = false
var _pull_time: float = 0.0
var _age: float = 0.0
## Not pullable until the pop-out has landed.
var _landed: bool = true
var _bob_phase: float = randf() * TAU
var _taken: bool = false


## Rolls `loot` and throws the items out around `at` (global), under `parent`
## (the map's y-sorted TileMap). Safe to call from physics callbacks.
static func drop(loot: ResourceLoot, at: Vector2, parent: Node, item_lifetime: float = 20.0) -> void:
    if loot == null or parent == null or not parent.is_inside_tree():
        return
    var book: ResourceJutsuBook = _player_book(parent.get_tree())
    var scene: PackedScene = load(SCENE_PATH)
    for result: Dictionary in loot.roll():
        for i: int in int(result["count"]):
            var item_kind: ResourceLootEntry.Kind = result["kind"]
            var item_element: String = String(result["element"])
            if item_kind == ResourceLootEntry.Kind.TALISMAN:
                item_element = _choose_element(book, item_element)
                if item_element == "":
                    continue
            var item: Pickup = scene.instantiate()
            item.kind = item_kind
            item.element = item_element
            item.lifetime = item_lifetime
            item.position = parent.to_local(at)
            item._landed = false
            parent.add_child.call_deferred(item)
            item.ready.connect(item._pop_out, CONNECT_ONE_SHOT)


static func _player_book(tree: SceneTree) -> ResourceJutsuBook:
    var player: Player = tree.get_first_node_in_group("player") as Player
    return player.book if player else null


## Fixed element: kept only if the player knows a jutsu of it. Random: among the
## known elements, preferring ones that are not full.
static func _choose_element(book: ResourceJutsuBook, wanted: String) -> String:
    if book == null:
        return ""
    if wanted != "":
        return wanted if not book.jutsu_of_element(wanted).is_empty() else ""
    var elements: PackedStringArray = book.talisman_elements(true)
    if elements.is_empty():
        elements = book.talisman_elements(false)
    return elements[randi() % elements.size()] if not elements.is_empty() else ""


func _ready() -> void:
    # Placed by hand in a map: taken once for good (World flag).
    if _is_placed() and _world_call("has_flag", [_key()]) == true:
        queue_free()
        return
    _shadow = Sprite2D.new()
    _shadow.texture = SHADOW
    _shadow.modulate.a = 0.6
    add_child(_shadow)
    _sprite = Sprite2D.new()
    add_child(_sprite)
    match kind:
        ResourceLootEntry.Kind.TALISMAN:
            _sprite.texture = TALISMAN_SHEET
            _sprite.hframes = int(TALISMAN_DATA.data["hframes"])
            _sprite.frame = int(TALISMAN_DATA.data["frame_from_element"].get(element, 0))
            _sprite.scale = Vector2.ONE * talisman_scale
            _shadow.scale = Vector2.ONE * talisman_scale
        ResourceLootEntry.Kind.SILVER_COIN:
            _sprite.texture = SILVER_COIN
            _shadow.scale = Vector2(0.6, 0.6)
        ResourceLootEntry.Kind.GOLD_COIN:
            _sprite.texture = GOLD_COIN
            _sprite.hframes = 4
            _shadow.scale = Vector2(0.8, 0.8)
    # The item floats a little above its shadow.
    _shadow.position = Vector2(0, 2)
    _sprite.position = Vector2(0, -4)


func _physics_process(delta: float) -> void:
    if _taken or _sprite == null:
        return
    _age += delta
    if _landed:
        _sprite.position.y = -4.0 + sin(_age * 4.0 + _bob_phase) * 1.0
    if kind == ResourceLootEntry.Kind.GOLD_COIN:
        _sprite.frame = int(_age * 10.0) % 4

    if lifetime > 0.0 and not _pulled:
        var left: float = lifetime - _age
        if left <= 0.0:
            queue_free()
            return
        visible = left > 4.0 or int(left * 8.0) % 2 == 0

    if not _landed:
        return
    var player: Player = _find_player()
    if player == null or not _can_take(player):
        _pulled = false
        return
    var target: Vector2 = player.global_position + player.cast_origin
    var distance: float = global_position.distance_to(target)
    if not _pulled:
        if distance > attract_radius:
            return
        _pulled = true
        _pull_time = 0.0
        visible = true
    _pull_time += delta
    # Slow at the edge of the radius, fast close to the player (eased), plus a
    # gain over time so it always catches up.
    var closeness: float = 1.0 - clampf(distance / attract_radius, 0.0, 1.0)
    var speed: float = lerpf(slow_speed, fast_speed, closeness * closeness * closeness) + speed_gain * _pull_time * _pull_time
    var step: float = speed * delta
    if distance <= take_radius or step >= distance:
        _take(player)
        return
    global_position += global_position.direction_to(target) * step
    # Lift off the ground while flying in.
    _sprite.position.y = move_toward(_sprite.position.y, -6.0, 20.0 * delta)


func _find_player() -> Player:
    if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
        _player = get_tree().get_first_node_in_group("player") as Player
    return _player


func _can_take(player: Player) -> bool:
    if player.state == Player.State.DEAD:
        return false
    if kind == ResourceLootEntry.Kind.TALISMAN:
        return player.book != null and player.book.can_take_element(element)
    return player.wallet != null


func _take(player: Player) -> void:
    _taken = true
    if _is_placed():
        _world_call("set_flag", [_key()])
    var text: String = ""
    var color := Color.WHITE
    if kind == ResourceLootEntry.Kind.TALISMAN:
        var result: Dictionary = player.book.add_talisman_of_element(element)
        if result.is_empty():
            _taken = false
            return
        var jutsu: ResourceJutsu = result["jutsu"]
        text = "%s +%d" % [_short_name(jutsu), int(result["added"])]
        color = _element_color()
    else:
        var value: int = COIN_VALUE[kind]
        player.wallet.add(value)
        text = "+%d" % value
        color = Color("#ffd75e")
    # TODO: a pick-up sound (no sfx asset in the project yet).
    PickupPopup.show_at(get_parent(), player.global_position + Vector2(0, -22), text, color)
    var tween: Tween = create_tween()
    tween.tween_property(_sprite, "scale", _sprite.scale * 1.6, 0.05)
    tween.parallel().tween_property(_sprite, "modulate", Color(3, 3, 3, 0.0), 0.12)
    tween.tween_callback(queue_free)
    _shadow.visible = false


## "火遁・息吹の術" -> "火遁".
func _short_name(jutsu: ResourceJutsu) -> String:
    var dot: int = jutsu.display_name.find("・")
    return jutsu.display_name.substr(0, dot) if dot > 0 else jutsu.display_name


func _element_color() -> Color:
    for frame: Dictionary in TALISMAN_DATA.data["frames"]:
        if String(frame["element"]) == element:
            return Color(String(frame["color"])).lightened(0.35)
    return Color.WHITE


## Thrown out of a pot / enemy / chest: a short hop to a random spot nearby.
func _pop_out() -> void:
    _landed = false
    var land: Vector2 = position + Vector2.from_angle(randf() * TAU) * randf_range(6.0, 14.0)
    var time: float = 0.35
    var tween: Tween = create_tween()
    tween.tween_property(self, "position", land, time)
    # Height: up then down (sprite only, the shadow stays on the ground).
    var hop: Tween = create_tween()
    hop.tween_property(_sprite, "position:y", -16.0, time * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    hop.tween_property(_sprite, "position:y", -4.0, time * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    hop.tween_property(_sprite, "position:y", -7.0, 0.08)
    hop.tween_property(_sprite, "position:y", -4.0, 0.08)
    # A short pause before it can be pulled, so the drop is seen.
    hop.tween_interval(0.15)
    hop.tween_callback(func() -> void: _landed = true)


## Part of a map scene (not a drop).
func _is_placed() -> bool:
    return owner != null


func _key() -> String:
    return "pickup:%s:%s" % [owner.scene_file_path, owner.get_path_to(self)]


func _world_call(method: String, args: Array) -> Variant:
    var world: Node = get_tree().get_first_node_in_group("world")
    if world == null or not world.has_method(method):
        return null
    return world.callv(method, args)
