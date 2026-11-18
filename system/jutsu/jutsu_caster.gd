extends Node2D
class_name JutsuCaster
## Base of a jutsu's behavior. The player makes one per cast (ResourceJutsu.caster),
## adds it as a child at its visual center and calls aim() every frame.
## The fx art faces right; the node is rotated to the aim and mirrored when
## aiming left so the art stays upright.
##
## A caster ends in two steps:
## - `finished`: the player gets control back.
## - queue_free(): when its own fx are done (they may outlive `finished`).


signal finished

## Multiplies the player's speed while this jutsu is going. 0 = stand still.
var move_speed_mult: float = 0.0
## Off = the aim is locked (e.g. while throwing).
var can_turn: bool = true

var player: Player
var jutsu: ResourceJutsu
var aim_angle: float = 0.0
var _finished: bool = false


func setup(p_player: Player, p_jutsu: ResourceJutsu, angle: float) -> void:
    player = p_player
    jutsu = p_jutsu
    aim(angle)


## Called once, right after the node entered the tree.
func begin() -> void:
    pass


## Called every physics frame until the node is freed (also after `finished`).
## held = the jutsu button is still held.
func update(_delta: float, _held: bool) -> void:
    pass


func _physics_process(delta: float) -> void:
    update(delta, player.jutsu_held)


## The player was hit or dodged: stop now.
func cancel() -> void:
    _finish()
    queue_free()


func aim(angle: float) -> void:
    aim_angle = angle
    rotation = angle
    # Mirror vertically when aiming left so the right-facing art is not upside down.
    scale.y = -1.0 if cos(angle) < 0.0 else 1.0


func aim_vector() -> Vector2:
    return Vector2.from_angle(aim_angle)


func _finish() -> void:
    if _finished:
        return
    _finished = true
    move_speed_mult = 1.0
    finished.emit()


# --- helpers for json-driven fx --------------------------------------------

## A sprite for one fx block of the json ({sheet, cell, vframes, fps, pivot_in_cell}).
## The node's origin is the block's pivot.
static func make_fx(block: Dictionary) -> SheetAnimator:
    var sprite := SheetAnimator.new()
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var cell: Array = block["cell"]
    sprite.cell_size = Vector2i(int(cell[0]), int(cell[1]))
    sprite.columns = 1
    var pivot: Array = block["pivot_in_cell"]
    sprite.offset = Vector2(float(cell[0]) / 2.0 - float(pivot[0]), float(cell[1]) / 2.0 - float(pivot[1]))
    sprite.visible = false
    return sprite


## Plays a block on a sprite made by make_fx (blocks of one sprite share cell and pivot).
static func play_fx(sprite: SheetAnimator, block: Dictionary) -> void:
    sprite.visible = true
    var sheet: Texture2D = load(String(block["sheet"]))
    sprite.play_uniform(sheet, int(block["vframes"]), 1.0 / float(block["fps"]), bool(block["loop"]))


static func to_vector(value: Array) -> Vector2:
    return Vector2(float(value[0]), float(value[1]))


static func to_ints(values: Array) -> PackedInt32Array:
    var out := PackedInt32Array()
    for v: Variant in values:
        out.append(int(v))
    return out


static func to_floats(values: Array) -> PackedFloat32Array:
    var out := PackedFloat32Array()
    for v: Variant in values:
        out.append(float(v))
    return out
