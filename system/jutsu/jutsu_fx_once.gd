extends Node2D
class_name JutsuFxOnce
## Plays one fx block of a jutsu json once where it was put, then frees itself.
## Used for impacts that must stay after the projectile is gone.


static func spawn(parent: Node, at: Vector2, angle: float, block: Dictionary) -> JutsuFxOnce:
    var node := JutsuFxOnce.new()
    var sprite: SheetAnimator = JutsuCaster.make_fx(block)
    node.add_child(sprite)
    parent.add_child(node)
    node.global_position = at
    node.rotation = angle
    node.scale.y = -1.0 if cos(angle) < 0.0 else 1.0
    sprite.finished.connect(node.queue_free)
    JutsuCaster.play_fx(sprite, block)
    return node
