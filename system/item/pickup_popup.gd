extends Node2D
class_name PickupPopup
## A short text that rises and fades where an item was taken ("火遁 +3", "+5").

const SIZE: int = 7
const RISE: float = 10.0
const TIME: float = 0.8

var text: String = ""
var color: Color = Color.WHITE


static func show_at(parent: Node, at: Vector2, popup_text: String, popup_color: Color) -> void:
    if parent == null or not parent.is_inside_tree():
        return
    var popup := PickupPopup.new()
    popup.text = popup_text
    popup.color = popup_color
    popup.z_index = 10
    popup.position = parent.to_local(at) if parent is Node2D else at
    parent.add_child(popup)


func _ready() -> void:
    var tween: Tween = create_tween().set_parallel()
    tween.tween_property(self, "position:y", position.y - RISE, TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "modulate:a", 0.0, TIME * 0.4).set_delay(TIME * 0.6)
    tween.chain().tween_callback(queue_free)


func _draw() -> void:
    JutsuSlotArt.draw_text(self, Vector2.ZERO, text, SIZE, 1.0, color)
