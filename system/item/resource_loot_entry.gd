extends Resource
class_name ResourceLootEntry
## One line of a drop table (ResourceLoot).


enum Kind { TALISMAN, SILVER_COIN, GOLD_COIN }

@export var kind: Kind = Kind.TALISMAN
## 0..1. With ResourceLoot.pick_one, the chances of all entries add up (max 1).
@export_range(0.0, 1.0, 0.01) var chance: float = 0.5
## How many items drop.
@export var count_min: int = 1
@export var count_max: int = 1
## Talisman only. The element (印: 火 / 水 / 雷 / 土 ...) = always that one
## (nothing drops if the player knows no jutsu of it).
## Empty = a random element among the jutsu the player knows (preferring
## elements that are not full).
@export var element: String = ""
