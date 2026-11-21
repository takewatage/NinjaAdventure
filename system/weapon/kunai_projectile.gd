extends DamageArea
class_name KunaiProjectile
## A thrown kunai (KunaiCaster). Flies straight and stops on the first enemy,
## a wall (layer 1) or at max range. Data: the "projectile" block of
## content/fx/kunai/kunai.json.


var direction: Vector2 = Vector2.RIGHT
var speed: float = 240.0
var max_range: float = 160.0

var _travelled: float = 0.0
var _radius: float = 0.0
var _prev: Vector2 = Vector2.ZERO
var _done: bool = false


static func spawn(parent: Node, at: Vector2, dir: Vector2, block: Dictionary, p_damage: ResourceDamage, p_team: ResourceDamageTeam, from: Vector2 = Vector2.INF) -> KunaiProjectile:
    ## from: where the thrower stands. A shot fired against a wall is pulled back
    ## to this side of it instead of appearing on the other side.
    var node := KunaiProjectile.new()
    node.direction = dir.normalized()
    node.speed = float(block["speed_px_s"])
    node.max_range = float(block["max_range_px"])
    node.damage = p_damage
    node.team = p_team
    node.rotation = node.direction.angle()
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = float(block["hit_radius"])
    node._radius = circle.radius
    shape.shape = circle
    node.add_child(shape)
    var sprite := Sprite2D.new()
    sprite.texture = load(String(block["sprite"]))
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    # The art points at sprite_points_at_deg; turn it so it points along +x.
    sprite.rotation = -deg_to_rad(float(block["sprite_points_at_deg"]))
    node.add_child(sprite)
    parent.add_child(node)
    node.global_position = at
    if from != Vector2.INF:
        var wall: Dictionary = node.sweep_walls(from, at, node._radius, false)
        if not wall.is_empty():
            node.global_position = wall["position"]
    node._prev = node.global_position
    return node


func _ready() -> void:
    super._ready()
    # Walls, pots, ... (layer 1) stop it.
    set_collision_mask_value(1, true)
    # Must stay monitorable: an Area2D with monitorable off never reports static
    # bodies (walls, TileMap), so it would fly through them (Godot issue #17238).
    # collision_layer stays 0, so no other area detects it.
    monitorable = true
    body_entered.connect(_on_body_entered)
    hit.connect(_on_hit)


func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if _done:
        return
    var step: float = speed * delta
    var next: Vector2 = global_position + direction * step
    var wall: Dictionary = sweep_walls(_prev, next, _radius)
    if not wall.is_empty():
        global_position = wall["position"]
        _stop()
        return
    global_position = next
    _prev = next
    _travelled += step
    if _travelled >= max_range:
        _stop()


func _on_hit(_area: Hitbox) -> void:
    _stop()


func _on_body_entered(_body: Node2D) -> void:
    _stop()


func _stop() -> void:
    if _done:
        return
    _done = true
    set_deferred("monitoring", false)
    queue_free()
