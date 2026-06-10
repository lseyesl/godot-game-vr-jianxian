extends RefCounted

const DESKTOP_PLAYER_SCENE := "res://scenes/player/DesktopDebugPlayer.tscn"

func run(t) -> void:
	_test_project_wasd_actions(t)
	_test_movement_input_vector(t)
	_test_yaw_relative_direction(t)
	_test_mouse_look_pitch_clamp(t)
	_test_camera_eye_height(t)
	_test_mouse_capture_events(t)
	_test_health_reception(t)
	_test_spell_input_actions_exist(t)
	_test_desktop_scene_has_spell_controller(t)
	_test_desktop_spell_methods_delegate(t)
	_test_spell_input_defaults(t)

func _test_project_wasd_actions(t) -> void:
	for action in ["move_forward", "move_back", "move_left", "move_right"]:
		t.assert_true(InputMap.has_action(action), "%s input action exists" % action)

func _test_movement_input_vector(t) -> void:
	var player = _instantiate_player(t)
	if player == null:
		return
	if not player.has_method("get_movement_input_vector"):
		t.fail("DesktopDebugPlayer", "missing get_movement_input_vector")
		player.free()
		return
	if not _has_move_actions():
		player.free()
		return
	Input.action_press("move_forward")
	Input.action_press("move_left")
	var input_vector: Vector3 = player.get_movement_input_vector()
	Input.action_release("move_forward")
	Input.action_release("move_left")
	t.assert_equal(input_vector, Vector3(-1, 0, -1), "W+A maps to local left-forward input")
	player.free()

func _test_yaw_relative_direction(t) -> void:
	var player = _instantiate_player(t)
	if player == null:
		return
	if not player.has_method("get_yaw_relative_direction"):
		t.fail("DesktopDebugPlayer", "missing get_yaw_relative_direction")
		player.free()
		return
	player.rotation_degrees.y = 90.0
	var direction: Vector3 = player.get_yaw_relative_direction(Vector3.FORWARD)
	t.assert_true(direction.is_equal_approx(Vector3.LEFT), "forward input follows player yaw")
	player.free()

func _test_mouse_look_pitch_clamp(t) -> void:
	var player = _instantiate_player(t)
	if player == null:
		return
	if not player.has_method("apply_mouse_look"):
		t.fail("DesktopDebugPlayer", "missing apply_mouse_look")
		player.free()
		return
	player.apply_mouse_look(Vector2(10, 2000))
	var camera: Node = player.get_node_or_null("Camera3D")
	t.assert_true(camera is Camera3D, "desktop player has a Camera3D")
	if camera is Camera3D:
		t.assert_true(is_equal_approx(camera.rotation_degrees.x, -80.0), "mouse look clamps upward pitch")
	player.apply_mouse_look(Vector2(0, -4000))
	if camera is Camera3D:
		t.assert_true(is_equal_approx(camera.rotation_degrees.x, 80.0), "mouse look clamps downward pitch")
	player.free()

func _test_camera_eye_height(t) -> void:
	var player = _instantiate_player(t)
	if player == null:
		return
	var camera: Node = player.get_node_or_null("Camera3D")
	t.assert_true(camera is Camera3D, "desktop player has a Camera3D")
	if camera is Camera3D:
		t.assert_true(is_equal_approx(camera.position.y, 1.7), "desktop camera eye height is 1.7m")
	player.free()

func _test_mouse_capture_events(t) -> void:
	var player = _instantiate_player(t)
	if player == null:
		return
	if not player.has_method("_unhandled_input"):
		t.fail("DesktopDebugPlayer", "missing _unhandled_input")
		player.free()
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var cancel_event := InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	player._unhandled_input(cancel_event)
	t.assert_true(not player.mouse_capture_requested, "Esc releases mouse capture")
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	player._unhandled_input(click_event)
	t.assert_true(player.mouse_capture_requested, "left click recaptures mouse")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.free()

func _test_health_reception(t) -> void:
	var player = _instantiate_player(t)
	if player == null:
		return
	t.assert_true(player.has_method("get_health_component"), "desktop player exposes get_health_component")
	t.assert_true(player.has_method("receive_damage"), "desktop player exposes receive_damage")
	if not player.has_method("get_health_component") or not player.has_method("receive_damage"):
		player.free()
		return
	var health = player.get_health_component()
	t.assert_true(health != null and health.has_method("apply_damage"), "desktop player has HealthComponent")
	if health != null and health.has_method("apply_damage"):
		var before: int = health.current_health
		player.receive_damage(1, "lesser_demon")
		t.assert_equal(health.current_health, before - 1, "desktop player damage reduces health")
	player.free()

func _test_spell_input_actions_exist(t) -> void:
	for action in ["spell_primary", "spell_guard", "spell_seal"]:
		t.assert_true(InputMap.has_action(action), "%s input action exists" % action)

func _test_desktop_scene_has_spell_controller(t) -> void:
	var scene_path := "res://scenes/player/DesktopDebugPlayer.tscn"
	t.assert_true(ResourceLoader.exists(scene_path), "DesktopDebugPlayer scene exists")
	if not ResourceLoader.exists(scene_path):
		return
	var scene = load(scene_path).instantiate()
	t.assert_true(scene.get_node_or_null("PlayerSpellController") != null, "desktop player has PlayerSpellController")
	if scene.get_node_or_null("PlayerSpellController") != null:
		t.assert_equal(scene.get_node("PlayerSpellController").get_script(), load("res://scripts/player/PlayerSpellController.gd"), "desktop spell controller uses PlayerSpellController script")
	scene.free()

func _test_desktop_spell_methods_delegate(t) -> void:
	var scene = load("res://scenes/player/DesktopDebugPlayer.tscn").instantiate()
	var root := Node3D.new()
	root.add_child(scene)
	t.assert_true(scene.has_method("spell_id_for_action"), "desktop player maps spell actions")
	if not scene.has_method("spell_id_for_action"):
		root.free()
		return
	t.assert_equal(scene.spell_id_for_action("spell_primary"), "spirit_bolt", "primary action maps to spirit bolt")
	t.assert_equal(scene.spell_id_for_action("spell_guard"), "guard_charm", "guard action maps to guard charm")
	t.assert_equal(scene.spell_id_for_action("spell_seal"), "seal_break", "seal action maps to seal break")
	t.assert_true(scene.cast_spell_id("spirit_bolt"), "desktop player casts spirit bolt through controller")
	t.assert_true(not scene.cast_spell_id("spirit_bolt"), "desktop player respects controller cooldown")
	root.free()

func _test_spell_input_defaults(t) -> void:
	t.assert_true(_action_has_mouse_button("spell_primary", MOUSE_BUTTON_LEFT), "spell_primary defaults to left mouse button")
	t.assert_true(_action_has_key("spell_guard", KEY_Q), "spell_guard defaults to Q")
	t.assert_true(_action_has_key("spell_seal", KEY_E), "spell_seal defaults to E")

func _action_has_mouse_button(action_name: String, button_index: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return true
	return false

func _action_has_key(action_name: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false

func _instantiate_player(t):
	t.assert_true(ResourceLoader.exists(DESKTOP_PLAYER_SCENE), "DesktopDebugPlayer scene exists")
	if not ResourceLoader.exists(DESKTOP_PLAYER_SCENE):
		return null
	var scene := load(DESKTOP_PLAYER_SCENE)
	t.assert_true(scene is PackedScene, "DesktopDebugPlayer scene loads")
	if not scene is PackedScene:
		return null
	return scene.instantiate()

func _has_move_actions() -> bool:
	return InputMap.has_action("move_forward") and InputMap.has_action("move_back") and InputMap.has_action("move_left") and InputMap.has_action("move_right")
