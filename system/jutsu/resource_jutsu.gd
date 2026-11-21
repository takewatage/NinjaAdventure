extends Resource
class_name ResourceJutsu
## Data of one jutsu (spec: document/忍術システム仕様.md).
## How it plays is a JutsuCaster script; the fx / timings / hit shapes come from
## the jutsu's JSON in content/fx/<id>/.


@export var id: StringName
@export var display_name: String
## 印 (火 / 水 / 雷 / 土 ...).
@export var element: String
## Column in content/ui/jutsu_wheel/ui_jutsu_icons.png.
@export var icon_index: int = 0
## Set = drawn (centered, unscaled) instead of the icon_index column.
@export var icon_texture: Texture2D

@export_category("talisman")
## Off = never needs talismans (and shows no ammo badge).
@export var uses_talisman: bool = true
## Talismans used per cast.
@export var per_cast: int = 1
## The most talismans of this jutsu the player can hold.
@export var max_stock: int = 20
## Talismans restored by picking up one talisman of this jutsu's element.
@export var talisman_pickup: int = 3

@export_category("cast")
## A script extending JutsuCaster. A new node with it is made for every cast.
@export var caster: Script
## Seconds from one cast's start until the next can start. 0 = no wait.
@export var cooldown: float = 0.0
## On: holding the jutsu button casts again as soon as the cooldown allows.
@export var repeat_while_held: bool = false
## Fx / timing data read by the caster (content/fx/<id>/<id>.json).
@export var data: JSON
## Extra data, e.g. the charged version of the water shuriken.
@export var data_extra: JSON
@export var damage: ResourceDamage
@export var damage_extra: ResourceDamage
