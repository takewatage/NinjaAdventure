extends RefCounted
class_name JutsuSlotArt
## Draws one jutsu slot (frame + icon + talisman badge) for the wheel and the HUD.
## Sprites and badge regions come from content/ui/jutsu_wheel/jutsu_wheel.json.

enum SlotState { NORMAL, HOVER, ACTIVE, LOCKED }

const SLOT_SIZE: float = 32.0
const ICON_SIZE: float = 24.0
const ICON_OFFSET := Vector2(4, 4)
const BADGE_STICK_OUT := Vector2(3, 3)
const AMMO_COLOR := Color("#e6ecf8")
const AMMO_EMPTY_COLOR := Color("#ff786e")
const EMPTY_ICON_ALPHA: float = 0.45
const NUMBER_FONT_SIZE: int = 6

var slot_sheet: Texture2D = preload("res://content/ui/jutsu_wheel/ui_wheel_slot.png")
var icon_sheet: Texture2D = preload("res://content/ui/jutsu_wheel/ui_jutsu_icons.png")
var badge_sheet: Texture2D = preload("res://content/ui/jutsu_wheel/ui_wheel_badges.png")
var number_font: Font = preload("res://content/ui/jutsu_wheel/ui_font_3x5.fnt")
var locked_icon: int = 7
## Badge name -> {"region": Rect2, "text_at": Vector2}
var badges: Dictionary = {}


func _init(wheel_data: Dictionary) -> void:
    var regions: Dictionary = wheel_data["progression"]["badges"]["regions"]
    for badge_name: String in regions:
        var info: Dictionary = regions[badge_name]
        var r: Array = info["region"]
        var t: Array = info["text_at"]
        badges[badge_name] = {
            "region": Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])),
            "text_at": Vector2(float(t[0]), float(t[1])),
        }


## top_left: slot's top-left corner. jutsu null = locked slot.
func draw(canvas: CanvasItem, top_left: Vector2, state: SlotState, jutsu: ResourceJutsu, book: ResourceJutsuBook) -> void:
    var frame: int = SlotState.LOCKED if jutsu == null else state
    canvas.draw_texture_rect_region(slot_sheet, Rect2(top_left, Vector2(SLOT_SIZE, SLOT_SIZE)),
        Rect2(frame * SLOT_SIZE, 0, SLOT_SIZE, SLOT_SIZE))
    var icon_index: int = locked_icon if jutsu == null else jutsu.icon_index
    var empty: bool = jutsu != null and book != null and not book.can_cast(jutsu)
    var icon_color := Color(1, 1, 1, EMPTY_ICON_ALPHA if empty else 1.0)
    if jutsu != null and jutsu.icon_texture != null:
        var size: Vector2 = jutsu.icon_texture.get_size()
        var at: Vector2 = top_left + ICON_OFFSET + ((Vector2.ONE * ICON_SIZE - size) / 2.0).floor()
        canvas.draw_texture(jutsu.icon_texture, at, icon_color)
    else:
        canvas.draw_texture_rect_region(icon_sheet, Rect2(top_left + ICON_OFFSET, Vector2(ICON_SIZE, ICON_SIZE)),
            Rect2(icon_index * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE), icon_color)
    if jutsu != null and book != null and jutsu.uses_talisman:
        _draw_ammo(canvas, top_left, mini(book.get_stock(jutsu), 999), empty)


func _draw_ammo(canvas: CanvasItem, top_left: Vector2, count: int, empty: bool) -> void:
    var text: String = str(count)
    var badge_name: String = "%s%ddigit" % ["ammo_empty_" if empty else "ammo_", text.length()]
    var badge: Dictionary = badges[badge_name]
    var region: Rect2 = badge["region"]
    # Bottom-right corner of the slot, sticking out a little.
    var pos: Vector2 = top_left + Vector2(SLOT_SIZE, SLOT_SIZE) + BADGE_STICK_OUT - region.size
    canvas.draw_texture_rect_region(badge_sheet, Rect2(pos, region.size), region)
    var text_pos: Vector2 = pos + badge["text_at"] + Vector2(0, number_font.get_ascent(NUMBER_FONT_SIZE))
    canvas.draw_string(number_font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE,
        AMMO_EMPTY_COLOR if empty else AMMO_COLOR)


## Japanese text: no pixel font for it in the project yet, so it is drawn with
## the system fallback at screen resolution (size * ui_scale, then scaled down).
static func draw_text(canvas: CanvasItem, center_top: Vector2, text: String, size: int, ui_scale: float, color: Color) -> void:
    var font: Font = ThemeDB.fallback_font
    var px: int = roundi(size * ui_scale)
    var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / ui_scale
    var pos := Vector2(center_top.x - width / 2.0, center_top.y)
    canvas.draw_set_transform(pos, 0.0, Vector2.ONE / ui_scale)
    canvas.draw_string_outline(font, Vector2(0, font.get_ascent(px)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, roundi(ui_scale), Color(0, 0, 0, color.a))
    canvas.draw_string(font, Vector2(0, font.get_ascent(px)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
    canvas.draw_set_transform(Vector2.ZERO)
