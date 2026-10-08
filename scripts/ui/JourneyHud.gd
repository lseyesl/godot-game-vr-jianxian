extends CanvasLayer
class_name JourneyHud

const Style = preload("res://scripts/ui/JourneyTheme.gd")
var objective: Label
var direction: Label
var health: Label
var skills: Label
var feedback: Label
var dialogue: Label
var modal: PanelContainer
var modal_title: Label
var modal_text: Label
var resume_button: Button
var mode := ""
var feedback_time := 0.0
var dialogue_time := 0.0
var vr_label: Label3D
var tone: AudioStreamPlayer
var vignette: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Style.create()
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment() { float edge = smoothstep(0.25, 0.7, length(UV - vec2(0.5))); COLOR = vec4(0.01, 0.04, 0.05, edge * 0.55); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	vignette.material = material
	root.add_child(vignette)
	add_child(root)
	var top := VBoxContainer.new()
	top.position = Vector2(30, 24)
	top.add_theme_constant_override("separation", 7)
	root.add_child(top)
	top.add_child(Style.label("青 岚  ·  剑 仙 试 炼", 18, Style.GOLD))
	objective = Style.label("", 25)
	top.add_child(objective)
	direction = Style.label("", 18, Style.JADE)
	top.add_child(direction)
	health = Style.label("气血  ● ● ● ● ●", 20, Style.JADE)
	top.add_child(health)
	var cross := Style.label("·", 32, Style.PAPER)
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.add_child(cross)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 30
	bottom.offset_right = -30
	bottom.offset_top = -168
	bottom.offset_bottom = -18
	bottom.add_theme_constant_override("separation", 10)
	root.add_child(bottom)
	dialogue = Style.label("", 21, Style.GOLD)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(dialogue)
	feedback = Style.label("", 20, Style.JADE)
	bottom.add_child(feedback)
	skills = Style.label("", 18)
	bottom.add_child(skills)
	bottom.add_child(Style.label("WASD 移动  ·  鼠标转向  ·  F 交谈  ·  V 御剑  ·  空格 / Ctrl 升降  ·  Esc 暂停", 17, Color("#b1c7c5")))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	modal = PanelContainer.new()
	modal.custom_minimum_size.x = 550
	center.add_child(modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	modal.add_child(box)
	modal_title = Style.label("", 34, Style.GOLD)
	box.add_child(modal_title)
	modal_text = Style.label("", 19)
	modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_text.custom_minimum_size = Vector2(490, 90)
	box.add_child(modal_text)
	resume_button = Style.button("继续试炼", close_modal)
	box.add_child(resume_button)
	box.add_child(Style.button("从检查点重试", retry))
	box.add_child(Style.button("返回主菜单", return_to_menu))
	modal.hide()
	tone = AudioStreamPlayer.new()
	add_child(tone)
	var bus := get_node("/root/EventBus")
	bus.objective_changed.connect(func(text: String): objective.text = text)
	bus.dialogue_shown.connect(_on_dialogue)
	bus.player_health_changed.connect(_on_health)
	bus.player_defeated.connect(_on_defeated)
	bus.completion_feedback_requested.connect(_on_complete)
	bus.combat_feedback_requested.connect(_on_combat)
	bus.spell_cast.connect(_on_spell)
	bus.notification_requested.connect(notify_player)
	bus.pause_requested.connect(toggle_pause)
	bus.retry_requested.connect(retry)
	bus.menu_requested.connect(return_to_menu)
	objective.text = get_node("/root/Game").quest_state.current_objective()
	if get_node("/root/Game").selected_player_mode == "vr":
		vr_label = Label3D.new()
		vr_label.position = Vector3(0, -0.22, -1.5)
		vr_label.font_size = 30
		vr_label.pixel_size = 0.0008
		vr_label.no_depth_test = true
		get_viewport().get_camera_3d().add_child(vr_label)
	if get_node("/root/Game").quest_state.current_step == "complete":
		call_deferred("_on_complete", "试炼完成", get_node("/root/Game").COMPLETION_MESSAGE)

func _process(delta: float) -> void:
	if not get_tree().paused:
		feedback_time = maxf(0, feedback_time - delta)
		dialogue_time = maxf(0, dialogue_time - delta)
		if feedback_time == 0: feedback.text = ""
		if dialogue_time == 0: dialogue.text = ""
	var world := get_parent()
	var player: Node = world.player_node
	var game := get_node("/root/Game")
	vignette.visible = game.selected_player_mode != "vr" and player.flight_enabled and game.comfort_settings.flight_vignette_enabled
	var target: Vector3 = world.TARGETS.get(game.quest_state.current_step, Vector3.ZERO)
	var offset: Vector3 = target - world.player_position()
	var camera := get_viewport().get_camera_3d()
	var bearing := "前方"
	if camera != null:
		var local := camera.global_basis.inverse() * offset
		if local.z > 0: bearing = "身后"
		elif absf(local.x) > absf(local.z) * 0.45: bearing = "左前方" if local.x < 0 else "右前方"
	direction.text = "目标在%s  ·  %d 米  ·  跟随青色光环" % [bearing, int(offset.length())]
	var controller = player.get_spell_controller()
	if controller != null and controller.spell_caster != null:
		var cooldowns: Dictionary = controller.spell_caster.cooldowns
		skills.text = "左键 灵光弹 %s   |   Q 护身诀 %s   |   E 破封诀 %s" % [
			_cooldown(cooldowns, "spirit_bolt"), _cooldown(cooldowns, "guard_charm"), _cooldown(cooldowns, "seal_break")]
		if controller.guard_remaining > 0: skills.text += "   ·   护身中 %.1fs" % controller.guard_remaining
	if vr_label != null:
		vr_label.text = objective.text + "\n" + direction.text + "\n" + health.text + "\n" + dialogue.text + "\n" + feedback.text
		if not mode.is_empty():
			vr_label.text = modal_title.text + "\n" + modal_text.text + "\n右 B：继续   左 X：检查点重试   左 Y：主菜单"

func _cooldown(cooldowns: Dictionary, id: String) -> String:
	var remaining := float(cooldowns.get(id, 0))
	return "就绪" if remaining <= 0 else "%.1fs" % remaining

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if mode == "pause": close_modal()
	elif mode.is_empty(): _show_modal("pause", "歇 息 片 刻", "任务进度会在每个阶段自动保存。\n继续探索，或从最近的任务检查点重试。")

func _show_modal(state: String, title: String, text: String) -> void:
	mode = state
	modal_title.text = title
	modal_text.text = text
	resume_button.visible = state == "pause"
	modal.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if resume_button.visible: resume_button.grab_focus()
	else: modal.get_child(0).get_child(3).grab_focus()

func close_modal() -> void:
	if mode != "pause": return
	mode = ""
	modal.hide()
	get_tree().paused = false
	if get_node("/root/Game").selected_player_mode != "vr":
		get_parent().player_node.request_mouse_capture()

func retry() -> void:
	if mode.is_empty(): return
	var game := get_node("/root/Game")
	if not game.load_checkpoint(): game.reset_demo()
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	if mode.is_empty(): return
	get_tree().paused = false
	get_viewport().use_xr = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _on_dialogue(npc_id: String, text: String) -> void:
	var names := {"innkeeper": "客栈掌柜", "tavern_keeper": "说书人", "trial_spirit": "守山灵"}
	dialogue.text = "%s：%s" % [names.get(npc_id, "路人"), text]
	dialogue_time = 14
	_play_tone(440, 0.12)

func _on_health(current: int, maximum: int) -> void:
	health.text = "气血  " + "● ".repeat(maxi(0, current)) + "○ ".repeat(maxi(0, maximum - current))

func _on_defeated(_source: String) -> void:
	if not mode.is_empty(): return
	_show_modal("defeat", "灵 息 未 尽", "你在试炼中耗尽了气血。\n按 Q 使用护身诀，边移动边施法。重试会恢复气血和当前任务阶段。")
	_play_tone(150, 0.35)

func _on_complete(title: String, message: String) -> void:
	_show_modal("complete", title, message + "\n你可以返回主菜单，重新开启一段旅程。")
	_play_tone(660, 0.6)

func _on_combat(_spell: String, target: String, outcome: String) -> void:
	var text := "命中 · " + target
	if outcome == "cleanse": text = "封印已净化，前往祭台取回飞剑"
	if outcome == "blocked": text = "先驱散守护封印的山魈"
	notify_player(text)
	_play_tone(740 if outcome == "cleanse" else 330, 0.1)

func _on_spell(spell: String) -> void:
	if spell == "guard_charm": notify_player("护身诀生效 · 3 秒内抵挡伤害")
	_play_tone(540, 0.08)

func notify_player(text: String) -> void:
	feedback.text = text
	feedback_time = 4

func _play_tone(frequency: float, duration: float) -> void:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var envelope := sin(PI * float(i) / count)
		var value := int(sin(TAU * frequency * float(i) / 22050) * envelope * 5000)
		data.encode_s16(i * 2, value)
	sound.data = data
	tone.stream = sound
	tone.play()
