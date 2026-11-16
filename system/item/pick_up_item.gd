extends Area2D

class_name PickUpItem

@export var field_item: FieldItem
@export var stacks: int = 1

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
    var _item = InventoryItem.new()
    var ptotoset = ItemProtoset.new()
    _item.protoset = preload('res://content/item/item.tres')
    _item.prototype_id = field_item.item_id
    add_child(_item)
    sprite_2d.texture = _item.get_texture()

func get_texture() -> void:
    pass
