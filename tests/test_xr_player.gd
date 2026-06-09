extends RefCounted

const ComfortSettingsScript := preload("res://scripts/core/ComfortSettings.gd")
const XRPlayerScript := preload("res://scripts/player/XRPlayer.gd")
const HealthComponentScript := preload("res://scripts/combat/HealthComponent.gd")

class MockProvider:
	extends Node3D
	var enabled := true
	var turn_mode := 0
	var max_speed := 0.0
	var speed_scale := 0.0
	var auto_adjust := true
	var auto_velocity_limit := 0.0
	var set_flying_calls := 0
	var last_flying := true

	func set_flying(active: bool) -> void:
		set_flying_calls += 1
		last_flying = active

func run(t) -> void:
	_test_scene_wires_xr_tools_nodes(t)
	_test_comfort_mode_configures_provider_nodes(t)
	_test_immersive_mode_configures_provider_nodes(t)
	_test_flight_state_controls_flight_provider_and_vignette(t)
	_test_health_reception(t)

func _test_scene_wires_xr_tools_nodes(t) -> void:
	var file := FileAccess.open("res://scenes/player/XRPlayer.tscn", FileAccess.READ)
	t.assert_true(file != null, "XRPlayer scene file opens")
	if file == null:
		return
	var scene_text := file.get_as_text()
	t.assert_true(scene_text.contains("res://addons/godot-xr-tools/player/player_body.tscn"), "XR scene references XR Tools PlayerBody")
	t.assert_true(scene_text.contains("res://addons/godot-xr-tools/functions/function_teleport.tscn"), "XR scene references teleport function")
	t.assert_true(scene_text.contains("res://addons/godot-xr-tools/functions/movement_direct.tscn"), "XR scene references direct movement")
	t.assert_true(scene_text.contains("res://addons/godot-xr-tools/functions/movement_turn.tscn"), "XR scene references turn provider")
	t.assert_true(scene_text.contains("res://addons/godot-xr-tools/functions/movement_flight.tscn"), "XR scene references flight provider")
	t.assert_true(scene_text.contains("res://addons/godot-xr-tools/effects/vignette.tscn"), "XR scene references vignette")
	t.assert_true(scene_text.contains("parent=\"XROrigin3D/LeftHand\" instance=ExtResource"), "teleport is under left hand")
	t.assert_true(scene_text.contains("parent=\"XROrigin3D/RightHand\" instance=ExtResource"), "movement providers are under right hand")
	t.assert_true(scene_text.contains("parent=\"XROrigin3D/XRCamera3D\" instance=ExtResource"), "vignette is under camera")
	t.assert_true(scene_text.contains("[node name=\"PlayerBody\" parent=\"XROrigin3D\" groups=[\"player\"] instance=ExtResource"), "XR PlayerBody is in player group for gameplay triggers")
	t.assert_true(scene_text.contains("[node name=\"HealthComponent\""), "XR scene includes HealthComponent")

func _test_comfort_mode_configures_provider_nodes(t) -> void:
	var player = _make_player_with_mock_providers()
	var settings = ComfortSettingsScript.new()
	settings.apply_mode("comfort")
	player._on_comfort_settings_changed(settings)
	t.assert_true(not player.get_node("XROrigin3D/RightHand/MovementDirect").enabled, "comfort disables direct smooth movement")
	t.assert_true(player.get_node("XROrigin3D/LeftHand/FunctionTeleport").enabled, "comfort enables teleport")
	t.assert_equal(player.get_node("XROrigin3D/RightHand/MovementTurn").turn_mode, 1, "comfort selects snap turn")
	t.assert_equal(player.get_node("XROrigin3D/RightHand/MovementDirect").max_speed, settings.flight_speed_limit_mps, "direct movement speed follows comfort speed limit")
	t.assert_equal(player.get_node("XROrigin3D/MovementFlight").speed_scale, settings.flight_speed_limit_mps, "flight speed follows comfort speed limit")
	player.free()

func _test_immersive_mode_configures_provider_nodes(t) -> void:
	var player = _make_player_with_mock_providers()
	var settings = ComfortSettingsScript.new()
	settings.apply_mode("immersive")
	player._on_comfort_settings_changed(settings)
	t.assert_true(player.get_node("XROrigin3D/RightHand/MovementDirect").enabled, "immersive enables direct movement")
	t.assert_true(not player.get_node("XROrigin3D/LeftHand/FunctionTeleport").enabled, "immersive disables teleport")
	t.assert_equal(player.get_node("XROrigin3D/RightHand/MovementTurn").turn_mode, 2, "immersive selects smooth turn")
	t.assert_equal(player.get_node("XROrigin3D/MovementFlight").speed_scale, settings.flight_speed_limit_mps, "flight speed follows immersive speed limit")
	player.free()

func _test_flight_state_controls_flight_provider_and_vignette(t) -> void:
	var player = _make_player_with_mock_providers()
	var settings = ComfortSettingsScript.new()
	settings.apply_mode("comfort")
	player._on_comfort_settings_changed(settings)
	player._on_flight_mode_changed(true)
	t.assert_true(player.get_node("XROrigin3D/MovementFlight").enabled, "flight provider enables after sword unlock")
	t.assert_true(player.get_node("XROrigin3D/XRCamera3D/Vignette").auto_adjust, "comfort flight enables vignette auto adjust")
	t.assert_equal(player.get_node("XROrigin3D/XRCamera3D/Vignette").auto_velocity_limit, settings.flight_speed_limit_mps, "vignette velocity limit follows comfort speed")
	player._on_flight_mode_changed(false)
	t.assert_true(not player.get_node("XROrigin3D/MovementFlight").enabled, "flight provider disables when flight state is off")
	t.assert_true(not player.get_node("XROrigin3D/XRCamera3D/Vignette").auto_adjust, "vignette disables when flight state is off")
	t.assert_equal(player.get_node("XROrigin3D/MovementFlight").set_flying_calls, 2, "disabling flight stops active XR Tools flight")
	t.assert_true(not player.get_node("XROrigin3D/MovementFlight").last_flying, "flight provider receives set_flying false")
	player.free()

func _test_health_reception(t) -> void:
	var player = XRPlayerScript.new()
	var health = HealthComponentScript.new()
	health.name = "HealthComponent"
	health.max_health = 5
	health.current_health = 5
	player.add_child(health)
	t.assert_true(player.has_method("get_health_component"), "XR player exposes get_health_component")
	t.assert_true(player.has_method("receive_damage"), "XR player exposes receive_damage")
	if player.has_method("get_health_component") and player.has_method("receive_damage"):
		t.assert_true(player.get_health_component() == health, "XR player returns HealthComponent")
		player.receive_damage(1, "lesser_demon")
		t.assert_equal(health.current_health, 4, "XR player damage reduces health")
	player.free()

func _make_player_with_mock_providers():
	var player = XRPlayerScript.new()
	var origin := Node3D.new()
	origin.name = "XROrigin3D"
	player.add_child(origin)
	var camera := Node3D.new()
	camera.name = "XRCamera3D"
	origin.add_child(camera)
	var left := Node3D.new()
	left.name = "LeftHand"
	origin.add_child(left)
	var right := Node3D.new()
	right.name = "RightHand"
	origin.add_child(right)
	_add_mock(left, "FunctionTeleport")
	_add_mock(right, "MovementDirect")
	_add_mock(right, "MovementTurn")
	_add_mock(origin, "MovementFlight")
	_add_mock(camera, "Vignette")
	return player

func _add_mock(parent: Node, node_name: String) -> MockProvider:
	var provider := MockProvider.new()
	provider.name = node_name
	parent.add_child(provider)
	return provider
