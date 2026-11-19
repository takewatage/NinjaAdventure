extends Node2D


@export var starting_map:PackedScene
@export var stating_weapon:ResourceWeapon

var map:Map

@onready var rain: GPUParticles2D = %Rain
@onready var snow: GPUParticles2D = %Snow
@onready var cloud: GPUParticles2D = %Cloud
@onready var leaf: GPUParticles2D = %Leaf
@onready var raylight: GPUParticles2D = %Raylight
@onready var fog: TextureRect = %Fog

@onready var transition: Transition = %Transition
@onready var music: AudioStreamPlayer = %Music
@onready var color_correction: ColorRect = %ColorCorrection
@onready var camera_grid: CameraGrid = %CameraGrid
@onready var pivot: Node2D = %Pivot
@onready var player_ui: Control = %PlayerUi
@onready var jutsu_ui: JutsuUi = %JutsuUi


## Seconds the player lies defeated before the screen fades out.
@export var death_wait: float = 2.0
## MapEntry.id where the game starts on starting_map.
@export var starting_entry: StringName = &"start"
## The player character. One instance lives across maps (life, talismans...).
@export var player_scene: PackedScene = preload("res://content/character/ninja_main/ninja_main.tscn")

const PLAYER_ASSIGNOR: PackedScene = preload("res://system/character/player_assignor.tscn")

var _map_path: String
var _player: Player
var _changing_map: bool = false
## Where to restart after dying: {"map": path, "entry": id, "position": Vector2 or INF}.
var _checkpoint: Dictionary = {}
## Campfires already lit (Campfire._key()). TODO: move into the save data.
var _lit_campfires: Dictionary[String, bool] = {}
var _flags: Dictionary[String, bool] = {}


func _ready():
    add_to_group("world")
    _checkpoint = {"map": starting_map.resource_path, "entry": starting_entry, "position": Vector2.INF}
    generate_map(starting_map, starting_entry)
    camera_grid.animation_finished.connect(on_camera_animation_finished)


func on_camera_animation_finished():
    pivot.position = camera_grid.global_position


# --- maps -------------------------------------------------------------------

## Called by MapExit (through the "world" group): fade out, swap maps, fade in.
func change_map(map_path: String, entry_id: StringName) -> void:
    if _changing_map or _player == null or _player.state == Player.State.DEAD:
        return
    _changing_map = true
    await transition.play(Transition.Type.FADE_IN)
    generate_map(load(map_path), entry_id)
    await transition.play(Transition.Type.FADE_OUT)
    _changing_map = false


## Loads a map and puts the player at entry_id (or at `at`, or where the map's
## own test player stands). A player placed in the map by hand (for testing the
## map alone) is replaced by the World's player.
func generate_map(map_scene: PackedScene, entry_id: StringName = &"", at: Vector2 = Vector2.INF):
    if _player and _player.get_parent():
        _player.get_parent().remove_child(_player)
    if map:
        map.queue_free()
    _map_path = map_scene.resource_path
    map = map_scene.instantiate()
    add_child(map)
    if map.environment_area.get_child_count() > 0:
        map.environment_area.environment_changed.connect(apply_environment)

    var placeholder: Node2D = _take_map_player()
    var parent: Node = placeholder.get_parent() if placeholder else _y_sort_parent()
    var pos: Vector2 = Vector2.ZERO
    var face: Vector2 = Vector2.ZERO
    var entry: MapEntry = _find_entry(entry_id)
    if entry:
        pos = entry.global_position
        face = entry.facing
    elif at != Vector2.INF:
        pos = at
    elif placeholder:
        pos = placeholder.global_position
    if placeholder:
        placeholder.get_parent().remove_child(placeholder)
        placeholder.queue_free()

    if _player == null:
        _player = _new_player(null, null)
    parent.add_child(_player)
    _player.place_at(pos, face)


func _take_map_player() -> Node2D:
    for node: Node in map.find_children("*", "", true, false):
        if node is Player:
            return node
    return null


## Characters are y-sorted inside the map's TileMap.
func _y_sort_parent() -> Node:
    for node: Node in map.find_children("*", "TileMap", true, false):
        return node
    return map


func _find_entry(entry_id: StringName) -> MapEntry:
    if entry_id == &"":
        return null
    for node: Node in map.find_children("*", "", true, false):
        if node is MapEntry and node.id == entry_id:
            return node
    return null


## A fresh player. `book` carries the jutsu and talismans over, `wallet` the
## money (null = initial).
func _new_player(book: ResourceJutsuBook, wallet: ResourceWallet) -> Player:
    var player: Player = player_scene.instantiate()
    if book:
        player.jutsu_book = book
    player.wallet = wallet
    player.add_child(PLAYER_ASSIGNOR.instantiate())
    player.died.connect(_on_player_died)
    player.ready.connect(_bind_ui.bind(player), CONNECT_ONE_SHOT)
    return player


func _bind_ui(player: Player) -> void:
    player_ui.resource_life = player.life
    player_ui.wallet = player.wallet
    jutsu_ui.player = player


# --- checkpoints (campfires) ------------------------------------------------

## Restart here after dying (a campfire calls this). Position on the current map.
func set_checkpoint(pos: Vector2) -> void:
    _checkpoint = {"map": _map_path, "entry": &"", "position": pos}


## One-time things already done (chests opened...). Key: map file + node path.
## TODO: move into the save data.
func has_flag(key: String) -> bool:
    return _flags.get(key, false)


func set_flag(key: String) -> void:
    _flags[key] = true


func is_campfire_lit(key: String) -> bool:
    return _lit_campfires.get(key, false)


func mark_campfire_lit(key: String) -> void:
    _lit_campfires[key] = true


## Defeat: wait, fade to black, a new player (full life, same jutsu and
## talismans) at the last checkpoint, fade back in.
func _on_player_died() -> void:
    await get_tree().create_timer(death_wait).timeout
    await transition.play(Transition.Type.FADE_IN)
    var book: ResourceJutsuBook = _player.book
    var wallet: ResourceWallet = _player.wallet
    _player.get_parent().remove_child(_player)
    _player.queue_free()
    _player = _new_player(book, wallet)
    generate_map(load(_checkpoint["map"]), _checkpoint["entry"], _checkpoint["position"])
    await transition.play(Transition.Type.FADE_OUT)


func apply_environment(resource_environment:ResourceEnvironment):
    # METEO
    if !resource_environment:
        return
    rain.emitting = ResourceEnvironment.Meteo.RAIN in resource_environment.meteo_list
    snow.emitting = ResourceEnvironment.Meteo.SNOW in resource_environment.meteo_list
    cloud.emitting = ResourceEnvironment.Meteo.CLOUD in resource_environment.meteo_list
    leaf.emitting = ResourceEnvironment.Meteo.LEAF in resource_environment.meteo_list
    fog.active = ResourceEnvironment.Meteo.FOG in resource_environment.meteo_list
    raylight.emitting = ResourceEnvironment.Meteo.RAY in resource_environment.meteo_list
    # MUSIC
    if resource_environment.music:
        music.change_music(resource_environment.music)
    else:
        music.stop_music()
    
    # GRADIENT
    color_correction.gradient = resource_environment.color_gradient


func play_transition(type:Transition.Type):
    await transition.play(type)
