extends SceneTree
## One-shot builder for the enemy / AI scenes (new scenes only).
## Run: godot --headless --script tools/build_enemy_scenes.gd
## It never overwrites: files that already exist are skipped, so edits made in
## the editor are safe. Delete a file first if you really want it rebuilt.

const ENEMY_TEAM := "res://content/team/enemy_team.tres"
const SHADOW := "res://content/character/Shadow.png"

const BT_HURT := "res://content/ai/bt_hurt.tscn"
const BT_CHASE := "res://content/ai/bt_chase.tscn"
const BT_WANDER := "res://content/ai/bt_wander.tscn"
const ENEMY_BASE := "res://content/enemy/enemy_base.tscn"

const SLIME_DIR := "res://content/enemy/Slime2/"
const SLIME_DATA := SLIME_DIR + "slime2.tres"
const SLIME_TACKLE := SLIME_DIR + "slime2_tackle.tres"
const SLIME_BRAIN := SLIME_DIR + "slime2_brain.tscn"
const SLIME := SLIME_DIR + "slime2.tscn"

var _failed: bool = false


func _initialize() -> void:
	_build_subtrees()
	_build_enemy_base()
	_build_slime_resources()
	_build_slime_brain()
	_build_slime()
	quit(1 if _failed else 0)


# --- reusable subtrees ------------------------------------------------------

func _build_subtrees() -> void:
	if not FileAccess.file_exists(BT_HURT):
		var hurt := SequenceReactiveComposite.new()
		hurt.name = "Hurt"
		_add(hurt, IsStunnedCondition.new(), "IsStunned")
		_add(hurt, IdleAction.new(), "Idle")
		_save(hurt, BT_HURT)

	if not FileAccess.file_exists(BT_CHASE):
		var chase := SequenceReactiveComposite.new()
		chase.name = "Chase"
		_add(chase, HasTargetCondition.new(), "HasTarget")
		_add(chase, MoveToTargetAction.new(), "MoveToTarget")
		_save(chase, BT_CHASE)

	if not FileAccess.file_exists(BT_WANDER):
		var wander := SequenceComposite.new()
		wander.name = "Wander"
		_add(wander, WanderMoveAction.new(), "WanderMove")
		_add(wander, WaitRandomAction.new(), "WaitRandom")
		_save(wander, BT_WANDER)


# --- enemy base -------------------------------------------------------------

func _build_enemy_base() -> void:
	if FileAccess.file_exists(ENEMY_BASE):
		return
	var root := CharacterBody2D.new()
	root.name = "Enemy"
	root.set_script(load("res://system/enemy/enemy.gd"))
	root.collision_layer = 2  # Character
	root.collision_mask = 3   # Wall + Character
	root.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	root.set("team", load(ENEMY_TEAM))

	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = load(SHADOW)
	_add(root, shadow)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.set_script(load("res://system/player/sheet_animator.gd"))
	sprite.set("cell_size", Vector2i(16, 16))
	sprite.set("columns", 4)
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.offset = Vector2(0, -4)
	_add(root, sprite)

	_add(root, _circle("Shape", 5.0, Vector2(0, -1)))

	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.set_script(load("res://system/damage/hitbox.gd"))
	hitbox.collision_layer = 4
	hitbox.collision_mask = 0
	hitbox.monitoring = false
	_add(root, hitbox)
	_add(hitbox, _circle("Shape", 7.0, Vector2(0, -3)))

	var attack_area := Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.set_script(load("res://system/damage/damage_area.gd"))
	attack_area.collision_layer = 0
	attack_area.collision_mask = 4
	attack_area.monitoring = false
	attack_area.monitorable = false
	_add(root, attack_area)
	_add(attack_area, _circle("Shape", 8.0, Vector2(0, -3)))

	var sensor := Area2D.new()
	sensor.name = "TargetSensor"
	sensor.set_script(load("res://system/ai/sensors/target_sensor.gd"))
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	sensor.monitorable = false
	_add(root, sensor)
	_add(sensor, _circle("Shape", 64.0, Vector2.ZERO))

	# Shared memory of the Brain. Kept outside the BeehaveTree because the tree
	# runs its first child as the root of the behavior.
	_add(root, Blackboard.new(), "Blackboard")

	_save(root, ENEMY_BASE)


# --- slime ------------------------------------------------------------------

func _build_slime_resources() -> void:
	if not FileAccess.file_exists(SLIME_DATA):
		var data := ResourceEnemy.new()
		data.max_life = 3.0
		data.speed = 40.0
		_save_resource(data, SLIME_DATA)

	if not FileAccess.file_exists(SLIME_TACKLE):
		var damage := ResourceDamage.new()
		damage.amount = 1
		damage.push_force = 60
		var tackle := ResourceEnemyAttack.new()
		tackle.damage = damage
		tackle.range_min = 0.0
		tackle.range_max = 36.0
		tackle.windup_time = 0.45
		tackle.active_time = 0.25
		tackle.recovery_time = 0.5
		tackle.cooldown = 1.2
		tackle.lunge_speed = 150.0
		_save_resource(tackle, SLIME_TACKLE)


func _build_slime_brain() -> void:
	if FileAccess.file_exists(SLIME_BRAIN):
		return
	var tackle: ResourceEnemyAttack = load(SLIME_TACKLE)

	var brain := BeehaveTree.new()
	brain.name = "Brain"
	var root := SelectorReactiveComposite.new()
	_add(brain, root, "Root")

	_add(root, (load(BT_HURT) as PackedScene).instantiate())

	var engage := SequenceComposite.new()
	_add(root, engage, "Engage")
	_add(engage, HasTargetCondition.new(), "HasTarget")
	var tackle_ready := AttackReadyCondition.new()
	tackle_ready.attack = tackle
	_add(engage, tackle_ready, "TackleReady")
	var choose := SelectorRandomComposite.new()
	_add(engage, choose, "Choose")
	var do_tackle := PerformAttackAction.new()
	do_tackle.attack = tackle
	_add(choose, do_tackle, "Tackle")
	_add(choose, FleeFromTargetAction.new(), "Flee")
	choose.use_weights = true
	choose.set("Weights/Tackle", 3)
	choose.set("Weights/Flee", 1)

	_add(root, (load(BT_CHASE) as PackedScene).instantiate())
	_add(root, (load(BT_WANDER) as PackedScene).instantiate())

	_save(brain, SLIME_BRAIN)
	# BeehaveTree's blackboard getter creates an internal node, and pack() stores
	# a path to it that can't resolve. The enemy scene assigns ../Blackboard.
	_strip_lines(SLIME_BRAIN, ["blackboard = NodePath("])
	_replace_in_file(SLIME_BRAIN, ' node_paths=PackedStringArray("blackboard")', "")


## Written as text: pack() can't produce an inherited scene from a builder.
func _build_slime() -> void:
	if FileAccess.file_exists(SLIME):
		return
	var text: String = """[gd_scene format=3]

[ext_resource type="PackedScene" path="%s" id="1_base"]
[ext_resource type="Resource" path="%s" id="2_data"]
[ext_resource type="Texture2D" path="%sSlime2.png" id="3_tex"]
[ext_resource type="PackedScene" path="%s" id="4_brain"]

[node name="Slime2" instance=ExtResource("1_base")]
data = ExtResource("2_data")

[node name="Sprite" parent="."]
texture = ExtResource("3_tex")

[node name="Brain" parent="." node_paths=PackedStringArray("blackboard") instance=ExtResource("4_brain")]
blackboard = NodePath("../Blackboard")
""" % [ENEMY_BASE, SLIME_DATA, SLIME_DIR, SLIME_BRAIN]
	var f: FileAccess = FileAccess.open(SLIME, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	var scene: PackedScene = ResourceLoader.load(SLIME, "", ResourceLoader.CACHE_MODE_IGNORE)
	var node: Node = scene.instantiate() if scene else null
	if node == null or node.get_node_or_null("Brain") == null or node.get_node_or_null("Blackboard") == null:
		push_error("slime scene broken: " + SLIME)
		_failed = true
	else:
		print("built ", SLIME, " (", _count(node), " nodes)")
	if node:
		node.free()


# --- helpers ----------------------------------------------------------------

func _add(parent: Node, child: Node, child_name: String = "") -> void:
	if child_name != "":
		child.name = child_name
	parent.add_child(child)


func _circle(node_name: String, radius: float, pos: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	shape.name = node_name
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = pos
	return shape


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		if child.owner == null:
			child.owner = owner_node
		if child.scene_file_path.is_empty():
			_set_owner_recursive(child, owner_node)


func _count(node: Node) -> int:
	var n: int = 1
	for child: Node in node.get_children():
		n += _count(child)
	return n


func _save(root: Node, path: String) -> void:
	_set_owner_recursive(root, root)
	var expected: int = _count(root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("pack failed: " + path)
		_failed = true
		return
	var test: Node = packed.instantiate()
	var got: int = _count(test)
	test.free()
	root.free()
	if got < expected:
		push_error("nodes dropped (%d < %d): %s" % [got, expected, path])
		_failed = true
		return
	if ResourceSaver.save(packed, path) != OK:
		push_error("save failed: " + path)
		_failed = true
		return
	print("built ", path)


func _save_resource(res: Resource, path: String) -> void:
	if ResourceSaver.save(res, path) != OK:
		push_error("save failed: " + path)
		_failed = true
		return
	print("built ", path)


func _strip_lines(path: String, prefixes: Array[String]) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	var out := PackedStringArray()
	for line: String in lines:
		var drop: bool = false
		for prefix: String in prefixes:
			if line.begins_with(prefix):
				drop = true
		if not drop:
			out.append(line)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()


func _replace_in_file(path: String, what: String, with: String) -> void:
	var text: String = FileAccess.get_file_as_string(path).replace(what, with)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
