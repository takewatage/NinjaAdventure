extends Resource

class_name FieldItem

### 当たり判定のtres
#@export var ground_collision: Shape2D
### 画像
#@export var texture :Texture2D
### 画像サブ
#@export var sub_texture :Texture2D

## アイテム種類
@export_enum("Treasure", "Weapoon") 
var item_type: String = ''

## アイテムID
@export var item_id: String = "GoldCoin"

var stack = 1
