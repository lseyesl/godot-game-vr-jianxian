extends RefCounted
class_name JourneyTheme

const INK := Color("#10272d")
const JADE := Color("#71d6ba")
const PAPER := Color("#ecede0")
const GOLD := Color("#dbc08b")

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 21
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Noto Sans CJK SC", "Microsoft YaHei", "PingFang SC", "sans-serif"])
	theme.default_font = font
	for type in ["Label", "Button", "CheckButton", "OptionButton"]:
		theme.set_color("font_color", type, PAPER)
	for type in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var box := panel(INK.lightened(0.12) if state in ["hover", "focus"] else INK)
			box.border_color = JADE if state in ["hover", "focus"] else Color("#36545b")
			box.set_border_width_all(1)
			box.content_margin_left = 24
			box.content_margin_right = 24
			box.content_margin_top = 13
			box.content_margin_bottom = 13
			theme.set_stylebox(state, type, box)
		theme.set_color("font_disabled_color", type, Color("#6e8589"))
	theme.set_stylebox("panel", "PanelContainer", panel())
	return theme

static func panel(color: Color = Color("#10272deb")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(10)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 20
	box.content_margin_bottom = 20
	return box

static func label(text: String, size: int = 21, color: Color = PAPER) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func button(text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(callback)
	return result
