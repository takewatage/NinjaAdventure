extends DamageArea
class_name JutsuProjectile
## A flying jutsu (e.g. the water shuriken). Moves straight from where it was
## spawned, explodes at max range, on a wall, or on the first hit (unless pierce).
## Data: a "projectile" block of the jutsu json, plus an optional "impact" block.


var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var max_range: float = 112.0
## Passes through enemies (each one is hit once).
var pierce: bool = false
var impact_block: Dictionary = {}
## Area damage when exploding: {"radius", "active_sec": [from, to]} or empty.
var splash: Dictionary = {}
var splash_damage: ResourceDamage

var _travelled: float = 0.0
var _exploded: bool = false


static func spawn(parent: Node, at: Vector2, dir: Vector2, block: Dictionary, p_damage: ResourceDamage, p_team: ResourceDamageTeam) -> JutsuProjectile:
    var node := JutsuProjectile.new()
    node.direction = dir.normalized()
    node.speed = float(block["speed_px_s"])
    node.max_range = float(block["max_range_px"])
    node.pierce = bool(block.get("pierce", false))
    node.damage = p_damage
    node.team = p_team
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = float(block["hit_shape"]["radius"])
    shape.shape = circle
    node.add_child(shape)
    var sprite: SheetAnimator = JutsuCaster.make_fx(block)
    node.add_child(sprite)
    parent.add_child(node)
    node.global_position = at
    node.rotation = dir.angle()
    node.scale.y = -1.0 if dir.x < 0.0 else 1.0
    JutsuCaster.play_fx(sprite, block)
    return node


func _ready() -> void:
    super._ready()
    # Walls (layer 1) stop it.
    set_collision_mask_value(1, true)
    body_entered.connect(_on_body_entered)
    hit.connect(_on_hit)


func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if _exploded:
        return
    var step: float = speed * delta
    global_position += direction * step
    _travelled += step
    if _travelled >= max_range:
        explode()


func _on_hit(_area: Hitbox) -> void:
    if not pierce:
        explode()


## Only layer 1 (walls, pots, ...) is in the body mask.
func _on_body_entered(_body: Node2D) -> void:
    explode()


func explode() -> void:
    if _exploded:
        return
    _exploded = true
    set_deferred("monitoring", false)
    if not impact_block.is_empty():
        JutsuFxOnce.spawn(get_parent(), global_position, 0.0, impact_block)
    if not splash.is_empty():
        _spawn_splash()
    queue_free()


func _spawn_splash() -> void:
    var area := DamageArea.new()
    area.damage = splash_damage if splash_damage else damage
    area.team = team
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = float(splash["radius"])
    shape.shape = circle
    area.add_child(shape)
    get_parent().add_child(area)
    area.global_position = global_position
    var active: Array = splash["active_sec"]
    # Overlaps are only known after a physics step, so check from the next frames.
    area.repeat_while_overlapping = true
    area.repeat_interval = 999.0
    area.get_tree().create_timer(maxf(float(active[1]), 0.05), false).timeout.connect(area.queue_free)
