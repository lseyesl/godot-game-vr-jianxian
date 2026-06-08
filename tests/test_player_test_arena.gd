extends RefCounted

func run(t) -> void:
	var scene_path := "res://scenes/debug/PlayerTestArena.tscn"
	var script_path := "res://scripts/debug/PlayerTestArena.gd"
	t.assert_true(FileAccess.file_exists(scene_path), "PlayerTestArena scene exists")
	t.assert_true(FileAccess.file_exists(script_path), "PlayerTestArena script exists")
	if not FileAccess.file_exists(scene_path) or not FileAccess.file_exists(script_path):
		return

	var ArenaScript := load(script_path)
	t.assert_true(ArenaScript.can_instantiate(), "PlayerTestArena script can instantiate")
	if not ArenaScript.can_instantiate():
		return
	var arena_script_instance = ArenaScript.new()
	t.assert_equal(arena_script_instance.resolve_player_scene_path("desktop_simulation"), "res://scenes/player/DesktopDebugPlayer.tscn", "desktop mode resolves desktop player")
	t.assert_equal(arena_script_instance.resolve_player_scene_path("vr"), "res://scenes/player/XRPlayer.tscn", "vr mode resolves XR player")
	t.assert_equal(arena_script_instance.normalize_player_mode("invalid"), "desktop_simulation", "unknown mode falls back to desktop")
	arena_script_instance.free()

	var packed_scene := load(scene_path)
	t.assert_true(packed_scene is PackedScene, "PlayerTestArena loads as PackedScene")
	if not packed_scene is PackedScene:
		return
	var scene = packed_scene.instantiate()
	t.assert_true(scene != null, "PlayerTestArena instantiates")
	if scene == null:
		return
	t.assert_true(scene.get_node_or_null("PlayerSpawn") != null, "PlayerTestArena has PlayerSpawn")
	t.assert_true(scene.get_node_or_null("Ground") is StaticBody3D, "PlayerTestArena has StaticBody3D Ground")
	t.assert_true(scene.get_node_or_null("TestFixtures/SealEncounter") != null, "PlayerTestArena has SealEncounter fixture")
	t.assert_true(scene.get_node_or_null("TestFixtures/FlyingSword") != null, "PlayerTestArena has FlyingSword fixture")
	t.assert_true(scene.get_node_or_null("DebugLabel") is Label3D, "PlayerTestArena has Chinese debug label")
	scene.free()
