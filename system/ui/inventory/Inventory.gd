extends Node

class_name InventoryHud

@onready var inventory_ui: CanvasLayer = $'../InventoryUI'

func _input(event: InputEvent) -> void:
    if Input.is_action_just_pressed('toggle_inventory'):
        inventory_ui.toggle()
    
