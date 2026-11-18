extends Sprite2D
class_name SheetAnimator
## Plays a "column = direction, row = frame" sprite sheet (ninja_main / combo3 layout).
## 4 columns: 0=down, 1=up, 2=left, 3=right (same order as SpriteCharacter.FrameDirection).
## 8 columns (combo3_8dir): 0=right, then clockwise every 45 degrees.
## A sheet narrower than `columns` cells (e.g. Dead.png, 1 column) is shown with
## its last column for any direction.

signal finished

@export var cell_size: Vector2i = Vector2i(32, 32)
@export var columns: int = 4

var column: int = 0:
    set(v):
        column = v
        _apply_frame()

var _rows: PackedInt32Array = PackedInt32Array([0])
var _frame_secs: PackedFloat32Array = PackedFloat32Array([1.0])
var _loop: bool = true
var _time: float = 0.0
var _index: int = 0
var _playing: bool = false


## rows: sheet row per frame. frame_secs: seconds per frame (same length as rows).
func play(sheet: Texture2D, rows: PackedInt32Array, frame_secs: PackedFloat32Array, loop: bool) -> void:
    if sheet != texture:
        texture = sheet
        hframes = clampi(int(sheet.get_width()) / cell_size.x, 1, columns)
        vframes = maxi(1, int(sheet.get_height()) / cell_size.y)
    _rows = rows
    _frame_secs = frame_secs
    _loop = loop
    _time = 0.0
    _index = 0
    _playing = true
    _apply_frame()


## Same as play(), with every frame shown for the same time.
func play_uniform(sheet: Texture2D, frame_count: int, frame_sec: float, loop: bool) -> void:
    var rows := PackedInt32Array()
    var secs := PackedFloat32Array()
    for i: int in frame_count:
        rows.append(i)
        secs.append(frame_sec)
    play(sheet, rows, secs, loop)


func is_playing_sheet(sheet: Texture2D) -> bool:
    return _playing and texture == sheet


func _process(delta: float) -> void:
    if not _playing:
        return
    _time += delta
    while _time >= _frame_secs[_index]:
        _time -= _frame_secs[_index]
        _index += 1
        if _index >= _rows.size():
            if _loop:
                _index = 0
            else:
                _index = _rows.size() - 1
                _playing = false
                _apply_frame()
                finished.emit()
                return
    _apply_frame()


func _apply_frame() -> void:
    if texture == null:
        return
    frame_coords = Vector2i(mini(column, hframes - 1), _rows[_index])
