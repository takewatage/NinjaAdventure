extends Node
class_name HumanController


@export var active := true:
    set(v):
        active = v
        update_process()

@export var action_left := "move_left"
@export var action_right := "move_right"
@export var action_up := "move_up"
@export var action_down := "move_down"
@export var action_attack := "action"
@export var action_dodge := "dodge"
@export var action_jutsu := "jutsu"

var parent:Node2D


func _ready() -> void:
    parent = get_parent()
    update_process()


func update_process():
    if active:
        process_mode = Node.PROCESS_MODE_INHERIT
    else:
        process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
    parent.move_vector = Input.get_vector(action_left,action_right,action_up,action_down)
    # Characters that aim (e.g. Player) attack toward the mouse cursor.
    if "aim_point" in parent:
        parent.aim_point = parent.get_global_mouse_position()
    # The jutsu wheel is open (or closed by this very click): no actions.
    if JutsuWheel.blocks_input():
        if "jutsu_held" in parent:
            parent.jutsu_held = false
        return
    # Only characters that support these actions (e.g. Player) receive them.
    if Input.is_action_just_pressed(action_attack) and parent.has_method("attack"):
        parent.attack()
    if InputMap.has_action(action_dodge) and Input.is_action_just_pressed(action_dodge) and parent.has_method("dodge"):
        parent.dodge()
    if InputMap.has_action(action_jutsu) and "jutsu_held" in parent:
        parent.jutsu_held = Input.is_action_pressed(action_jutsu)
        if Input.is_action_just_pressed(action_jutsu):
            parent.cast_jutsu()
