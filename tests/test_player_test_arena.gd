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
	t.assert_true(scene.get_node_or_null("TestFixtures/LesserDemon") != null, "PlayerTestArena has LesserDemon combat fixture")
	t.assert_true(scene.get_node_or_null("DebugLabel") is Label3D, "PlayerTestArena has Chinese debug label")
	var debug_label := scene.get_node_or_null("DebugLabel") as Label3D
	if debug_label != null:
		t.assert_true(debug_label.text.contains("左键"), "debug label explains primary spell input")
		t.assert_true(debug_label.text.contains("Q") and debug_label.text.contains("E"), "debug label explains keyboard spell inputs")
		t.assert_true(debug_label.text.contains("自动拾取"), "debug label explains sword auto pickup")
	scene.free()

	var live_scene = packed_scene.instantiate()
	t.root.add_child(live_scene)
	live_scene.spawn_player()
	var spawned_player := live_scene.player_node as Node3D
	var spawn_marker := live_scene.get_node_or_null("PlayerSpawn") as Node3D
	t.assert_true(spawned_player != null, "PlayerTestArena spawns a player when entering the tree")
	t.assert_true(spawn_marker != null, "PlayerTestArena spawn marker is available in live scene")
	if spawned_player != null and spawn_marker != null:
		if spawned_player.is_inside_tree() and spawn_marker.is_inside_tree():
			t.assert_true(spawned_player.global_position.is_equal_approx(spawn_marker.global_position), "spawned player starts at PlayerSpawn global position")
		else:
			t.assert_true(spawned_player.position.is_equal_approx(spawn_marker.position), "spawned player starts at PlayerSpawn local position in offline tests")
	var first_player: Node = live_scene.player_node
	live_scene.spawn_player()
	t.assert_true(first_player != live_scene.player_node, "respawn replaces the player node")
	t.assert_true(not is_instance_valid(first_player), "respawn frees old player immediately")
	live_scene.free()
