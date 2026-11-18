extends SceneTree
## One-shot builder for the demo's placeholder field maps (new scenes only).
## Run: godot --headless --script tools/build_demo_maps.gd
## Files that already exist are skipped, so maps painted in the editor are safe.
##
## Each map: grass floor, a border of trees with openings for the exits,
## a few trees inside, slimes, grass / pots, campfires, entries and exits.
## Tiles come from content/map/tileset.tres (the village's tileset).

const DIR := "res://content/map/demo/"
const TUTORIAL := DIR + "tutorial_road.tscn"
const BOSS := DIR + "boss_road.tscn"
const VILLAGE := "res://content/map/map_village.tscn"

const LAYER_WALL := 0
const LAYER_FLOOR := 3
## tileset.tres sources
const SRC_VILLAGE := 0  # tileset_village_abandoned.png: big tree at (0..2, 6..8)
const SRC_FLOOR := 1    # tileset_floor.png: grass at (0..4, 12)
const SRC_SCENES := 5   # destroyables: 1 crate, 2 grass, 3 pot
const GRASS := 2
const POT := 3
## The Tilemap node of system/map/map.tscn sits at (8, 8).
const TILEMAP_OFFSET := Vector2(8, 8)
const GAP_FROM := 9   # exit opening: tiles x 9..14
const GAP_TO := 14


func _initialize() -> void:
    _build(TUTORIAL, {
        "name": "TutorialRoad",
        "size": Vector2i(26, 48),
        "top_exit": {"map": BOSS, "entry": &"from_tutorial", "from": &"from_boss_road"},
        "bottom_exit": {"map": VILLAGE, "entry": &"from_road", "from": &"from_village"},
        "trees": [Vector2i(5, 34), Vector2i(17, 28), Vector2i(8, 19), Vector2i(15, 11)],
        "slimes": [Vector2i(12, 25), Vector2i(10, 14)],
        "grass": [Vector2i(6, 41), Vector2i(19, 39), Vector2i(7, 9), Vector2i(19, 21), Vector2i(20, 22)],
        "pots": [Vector2i(20, 43)],
        "campfires": [],
    })
    _build(BOSS, {
        "name": "BossRoad",
        "size": Vector2i(26, 56),
        "top_exit": {},
        "bottom_exit": {"map": TUTORIAL, "entry": &"from_boss_road", "from": &"from_tutorial"},
        "trees": [Vector2i(16, 44), Vector2i(4, 36), Vector2i(14, 30), Vector2i(6, 24), Vector2i(17, 19)],
        "slimes": [Vector2i(12, 40), Vector2i(18, 33), Vector2i(9, 27), Vector2i(13, 18)],
        "grass": [Vector2i(20, 48), Vector2i(6, 45), Vector2i(19, 26), Vector2i(4, 20), Vector2i(5, 20)],
        "pots": [Vector2i(20, 40), Vector2i(21, 40)],
        "campfires": [Vector2i(8, 34)],
    })
    quit()


func _build(path: String, spec: Dictionary) -> void:
    if FileAccess.file_exists(path):
        print("skip (exists) ", path)
        return
    var size: Vector2i = spec["size"]
    var floor_tiles := PackedInt32Array()
    var wall: Dictionary = {}  # Vector2i -> [source, atlas, alt]

    for y in size.y:
        for x in size.x:
            # A few grass tufts, always the same.
            var h: int = (x * 73856093) ^ (y * 19349663)
            var variant: int = 0 if posmod(h, 7) != 0 else 1 + posmod(h >> 3, 4)
            _append(floor_tiles, Vector2i(x, y), SRC_FLOOR, Vector2i(variant, 12), 0)

    # Border trees (3x3 each). Openings in the top / bottom rows for the exits.
    for y in range(0, size.y, 3):
        _tree(wall, Vector2i(0, mini(y, size.y - 3)))
        _tree(wall, Vector2i(size.x - 3, mini(y, size.y - 3)))
    for x in range(3, size.x - 3, 3):
        var covers_gap: bool = x + 2 >= GAP_FROM and x <= GAP_TO
        if not (covers_gap and not spec["top_exit"].is_empty()):
            _tree(wall, Vector2i(x, 0))
        if not (covers_gap and not spec["bottom_exit"].is_empty()):
            _tree(wall, Vector2i(x, size.y - 3))
    for t: Vector2i in spec["trees"]:
        _tree(wall, t)
    for g: Vector2i in spec["grass"]:
        wall[g] = [SRC_SCENES, Vector2i.ZERO, GRASS]
    for p: Vector2i in spec["pots"]:
        wall[p] = [SRC_SCENES, Vector2i.ZERO, POT]

    var wall_tiles := PackedInt32Array()
    for cell: Vector2i in wall:
        var t: Array = wall[cell]
        _append(wall_tiles, cell, t[0], t[1], t[2])

    var text := ""
    text += '[gd_scene format=3]\n\n'
    text += '[ext_resource type="PackedScene" path="res://system/map/map.tscn" id="1_map"]\n'
    text += '[ext_resource type="PackedScene" path="res://content/enemy/Slime2/slime2.tscn" id="2_slime"]\n'
    text += '[ext_resource type="PackedScene" path="res://content/prop/campfire/campfire.tscn" id="3_fire"]\n'
    text += '[ext_resource type="Script" path="res://system/map/map_entry.gd" id="4_entry"]\n'
    text += '[ext_resource type="Script" path="res://system/map/map_exit.gd" id="5_exit"]\n'
    text += '[ext_resource type="Script" path="res://system/environment/environment_shape.gd" id="6_envshape"]\n'
    text += '[ext_resource type="Resource" path="res://content/environment/field/environment.tres" id="7_env"]\n\n'
    text += '[sub_resource type="RectangleShape2D" id="RectangleShape2D_exit"]\nsize = Vector2(96, 16)\n\n'
    text += '[sub_resource type="RectangleShape2D" id="RectangleShape2D_env"]\nsize = Vector2(%d, %d)\n\n' % [size.x * 16, size.y * 16]
    text += '[node name="%s" instance=ExtResource("1_map")]\n\n' % spec["name"]
    text += '[node name="Tilemap" parent="." index="1"]\n'
    text += 'layer_0/tile_data = PackedInt32Array(%s)\n' % _ints(wall_tiles)
    text += 'layer_3/tile_data = PackedInt32Array(%s)\n\n' % _ints(floor_tiles)

    var i: int = 1
    for s: Vector2i in spec["slimes"]:
        text += '[node name="Slime%d" parent="Tilemap" instance=ExtResource("2_slime")]\nposition = %s\n\n' % [i, _v(_tile_local(s))]
        i += 1
    i = 1
    for c: Vector2i in spec["campfires"]:
        text += '[node name="Campfire%d" parent="Tilemap" instance=ExtResource("3_fire")]\nposition = %s\n\n' % [i, _v(_tile_local(c))]
        i += 1

    text += '[node name="EnvironmentShape" type="CollisionShape2D" parent="EnvironmentArea"]\n'
    text += 'position = %s\nshape = SubResource("RectangleShape2D_env")\nscript = ExtResource("6_envshape")\nresource_environment = ExtResource("7_env")\n\n' % _v(TILEMAP_OFFSET + Vector2(size) * 8.0)

    var gap_center_x: float = TILEMAP_OFFSET.x + (GAP_FROM + GAP_TO + 1) * 8.0
    if not spec["bottom_exit"].is_empty():
        var e: Dictionary = spec["bottom_exit"]
        text += _entry("Entry_" + String(e["from"]), e["from"], Vector2(gap_center_x, _row_center(size.y - 5)), Vector2.UP)
        text += _exit("ExitBottom", e, Vector2(gap_center_x, _row_center(size.y - 1)))
    if not spec["top_exit"].is_empty():
        var e: Dictionary = spec["top_exit"]
        text += _entry("Entry_" + String(e["from"]), e["from"], Vector2(gap_center_x, _row_center(4)), Vector2.DOWN)
        text += _exit("ExitTop", e, Vector2(gap_center_x, _row_center(0)))

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
    var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    f.store_string(text)
    f.close()
    var scene: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
    var node: Node = scene.instantiate() if scene else null
    if node == null:
        push_error("map scene broken: " + path)
    else:
        print("built ", path)
        node.free()


func _tree(wall: Dictionary, top_left: Vector2i) -> void:
    for j in 3:
        for i in 3:
            if i == 0 and j == 0:
                continue  # the tree's top-left corner is empty (no tile in the tileset)
            wall[top_left + Vector2i(i, j)] = [SRC_VILLAGE, Vector2i(i, 6 + j), 0]


## TileMap format 2: cell, source | atlas.x << 16, atlas.y | alternative << 16.
func _append(out: PackedInt32Array, cell: Vector2i, source: int, atlas: Vector2i, alt: int) -> void:
    out.append((cell.x & 0xFFFF) | ((cell.y & 0xFFFF) << 16))
    out.append(source | (atlas.x << 16))
    out.append(atlas.y | (alt << 16))


func _ints(values: PackedInt32Array) -> String:
    var parts := PackedStringArray()
    for v: int in values:
        parts.append(str(v))
    return ", ".join(parts)


## Center of a tile in the Tilemap's local space.
func _tile_local(cell: Vector2i) -> Vector2:
    return Vector2(cell) * 16.0 + Vector2(8, 8)


## Center y of a tile row in map space.
func _row_center(row: int) -> float:
    return TILEMAP_OFFSET.y + row * 16.0 + 8.0


func _v(v: Vector2) -> String:
    return "Vector2(%s, %s)" % [v.x, v.y]


func _entry(node_name: String, id: StringName, pos: Vector2, face: Vector2) -> String:
    return '[node name="%s" type="Marker2D" parent="."]\nposition = %s\nscript = ExtResource("4_entry")\nid = &"%s"\nfacing = %s\n\n' % [node_name, _v(pos), id, _v(face)]


func _exit(node_name: String, e: Dictionary, pos: Vector2) -> String:
    var text := '[node name="%s" type="Area2D" parent="."]\nposition = %s\nscript = ExtResource("5_exit")\ntarget_map = "%s"\ntarget_entry = &"%s"\n\n' % [node_name, _v(pos), e["map"], e["entry"]]
    text += '[node name="Shape" type="CollisionShape2D" parent="%s"]\nshape = SubResource("RectangleShape2D_exit")\n\n' % node_name
    return text
