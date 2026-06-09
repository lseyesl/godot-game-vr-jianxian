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
