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

## The map currently loaded, so it can be reloaded when the player dies.
var _map_scene: PackedScene
var _player: Player


func _ready():
    generate_map(starting_map)
    camera_grid.animation_finished.connect(on_camera_animation_finished)


func on_camera_animation_finished():
    pivot.position = camera_grid.global_position


func generate_map(map_scene:PackedScene):
    if map:
        map.queue_free()
    _map_scene = map_scene
    map = map_scene.instantiate()
    add_child(map)
    if map.environment_area.get_child_count() > 0:
        map.environment_area.environment_changed.connect(apply_environment)
    _bind_player()


## Connects the player of the new map to the HUD and to the death handling.
func _bind_player() -> void:
    _player = null
    for node in get_tree().get_nodes_in_group("player"):
        if node is Player and map.is_ancestor_of(node):
            _player = node
            break
    if _player == null:
        jutsu_ui.player = null
        return
    player_ui.resource_life = _player.life
    jutsu_ui.player = _player
    _player.died.connect(_on_player_died)


## Defeat: wait, fade to black, reload the map (the player starts again at the
## map's start with full life), fade back in.
## TODO: once saving exists, restart from the last campfire / home instead.
func _on_player_died() -> void:
    await get_tree().create_timer(death_wait).timeout
    await transition.play(Transition.Type.FADE_IN)
    generate_map(_map_scene)
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
