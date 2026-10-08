extends Control
class_name MainMenu

const Style = preload("res://scripts/ui/JourneyTheme.gd")
var mode_select: OptionButton
var comfort_select: OptionButton
var continue_button: Button
var status: Label

func _ready() -> void:
	get_window().min_size = Vector2i(1000, 650)
	get_tree().paused = false
	get_viewport().use_xr = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = Style.create()
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0b2029")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 60)
	margin.add_child(row)
	var story := VBoxContainer.new()
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.add_theme_constant_override("separation", 20)
	row.add_child(story)
	story.add_child(Style.label("Q I N G L A N   /   剑 修 初 行", 18, Style.JADE))
	story.add_child(Style.label("青 岚\n剑 仙 试 炼", 62, Style.PAPER))
	story.add_child(Style.label("一剑入青山，归来仍少年。", 26, Style.GOLD))
	var prose := Style.label("遗失的飞剑化作青光，落入山谷。\n向镇中人问路，驱散山魈，净化古老封印。\n取回属于你的剑，乘风归来。", 21)
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_child(prose)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.add_child(space)
	story.add_child(Style.label("单人试炼  /  自动保存  /  键鼠与 PCVR", 18, Style.JADE))
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 420
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(Style.label("启 程", 30, Style.GOLD))
	box.add_child(Style.label("游玩方式", 18))
	mode_select = OptionButton.new()
	mode_select.add_item("键鼠 · 无需头显")
	mode_select.add_item("PCVR · OpenXR 头显")
	box.add_child(mode_select)
	comfort_select = OptionButton.new()
	comfort_select.add_item("舒适模式 · 瞬移 / 分段转向")
	comfort_select.add_item("沉浸模式 · 平滑移动 / 转向")
	box.add_child(comfort_select)
	var start := Style.button("开始新的试炼", _on_start_button_pressed)
	box.add_child(start)
	continue_button = Style.button("继续上次试炼", _continue_game)
	continue_button.disabled = not get_node("/root/Game").has_checkpoint()
	box.add_child(continue_button)
	box.add_child(Style.button("退出游戏", func(): get_tree().quit()))
	status = Style.label("新试炼会替换旧进度。每个任务阶段自动存档。\nWASD 移动 · F 交谈 · 左键 / Q / E 施法\n取剑后 V 御剑 · 空格 / Ctrl 升降 · Esc 暂停", 16, Color("#adc2c2"))
	status.custom_minimum_size.x = 370
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)
	start.grab_focus()

func _prepare_mode() -> bool:
	var game := get_node("/root/Game")
	game.selected_player_mode = "desktop_simulation"
	if mode_select.selected == 1:
		var xr := XRServer.find_interface("OpenXR")
		if xr == null or (not xr.is_initialized() and not xr.initialize()):
			status.text = "未检测到可用 OpenXR 头显。\n请先启动 SteamVR / OpenXR 运行时，并以 --xr-mode on 启动；也可选择键鼠试玩。"
			return false
		game.selected_player_mode = "vr"
	return true

func _on_start_button_pressed() -> void:
	if not _prepare_mode(): return
	var game := get_node("/root/Game")
	game.reset_demo()
	game.apply_comfort_mode("immersive" if comfort_select.selected == 1 else "comfort")
	game.save_checkpoint()
	_launch()

func _continue_game() -> void:
	if not _prepare_mode(): return
	if not get_node("/root/Game").load_checkpoint():
		status.text = "存档不可读。请选择开始新的试炼。"
		continue_button.disabled = true
		return
	_launch()

func _launch() -> void:
	var result := get_tree().change_scene_to_file("res://scenes/main/PlayableJourney.tscn")
	if result != OK: status.text = "场景加载失败：%s" % error_string(result)

func _on_reset_button_pressed() -> void:
	get_node("/root/Game").reset_demo()
