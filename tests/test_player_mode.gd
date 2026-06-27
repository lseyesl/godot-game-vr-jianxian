extends RefCounted

func run(t) -> void:
	var path := "res://scripts/main/Main.gd"
	t.assert_true(FileAccess.file_exists(path), "Main script exists")
	if not FileAccess.file_exists(path):
		return
	var MainScript := load(path)
	t.assert_true(MainScript.can_instantiate(), "Main script can instantiate")
	if not MainScript.can_instantiate():
		return
	var main = MainScript.new()
	t.assert_equal(main.resolve_player_scene_path("desktop_simulation"), "res://scenes/player/DesktopDebugPlayer.tscn", "desktop simulation resolves desktop player scene")
	t.assert_equal(main.resolve_player_scene_path("vr"), "res://scenes/player/XRPlayer.tscn", "vr resolves XR player scene")
	t.assert_equal(main.normalize_player_mode("unknown"), "desktop_simulation", "unknown mode falls back to desktop simulation")
	t.assert_equal(main.terrain_spawn_path, NodePath("TerrainContainer/Terrain3D"), "Main resolves spawn height from the Terrain3D node by default")
	var desktop_player = main.instantiate_player_for_mode("desktop_simulation")
	t.assert_true(desktop_player != null, "desktop player instantiates")
	if desktop_player != null:
		t.assert_equal(desktop_player.name, "DesktopDebugPlayer", "desktop mode instantiates desktop debug player")
		desktop_player.free()
	t.assert_true(ResourceLoader.exists(main.resolve_player_scene_path("vr")), "vr player scene exists")
	main.free()

	var live_main = MainScript.new()
	t.root.add_child(live_main)
	live_main.player_spawn_position = Vector3(3, 0, 4)
	live_main.spawn_player()
	var spawned_player := live_main.player_node as Node3D
	t.assert_true(spawned_player != null, "Main spawns a player")
	if spawned_player != null:
		if spawned_player.is_inside_tree() and live_main.is_inside_tree():
			t.assert_true(spawned_player.global_position.is_equal_approx(live_main.player_spawn_position), "Main spawns player at configured global position")
		else:
			t.assert_true(spawned_player.position.is_equal_approx(live_main.player_spawn_position), "Main spawns player at configured local position in offline tests")
	var first_player: Node = live_main.player_node
	live_main.spawn_player()
	t.assert_true(first_player != live_main.player_node, "Main respawn replaces the player node")
	t.assert_true(not is_instance_valid(first_player), "Main respawn frees old player immediately")
	live_main.free()

	var terrain_main = MainScript.new()
	terrain_main.player_spawn_position = Vector3(0, 0, 6)
	terrain_main.terrain_spawn_path = NodePath("TerrainContainer/HeightmapTerrain")
	var terrain_container := Node3D.new()
	terrain_container.name = "TerrainContainer"
	terrain_main.add_child(terrain_container)
	var heightmap = preload("res://scenes/prefabs/terrain/HeightmapTerrain.tscn").instantiate()
	terrain_container.add_child(heightmap)
	t.root.add_child(terrain_main)
	terrain_main.spawn_player()
	t.assert_true(heightmap.has_method("get_height_at_world_position"), "HeightmapTerrain can report terrain height for player spawn")
	if heightmap.has_method("get_height_at_world_position"):
		var terrain_height: float = heightmap.get_height_at_world_position(terrain_main.player_spawn_position)
		var terrain_player := terrain_main.player_node as Node3D
		t.assert_true(terrain_player != null, "Main spawns player with terrain present")
		if terrain_player != null:
			var actual_position := terrain_player.global_position if terrain_player.is_inside_tree() else terrain_player.position
			t.assert_true(actual_position.y > terrain_main.player_spawn_position.y, "Main raises player above configured Y when terrain is higher")
			t.assert_true(actual_position.y >= terrain_height - 0.3, "Main does not spawn desktop player inside terrain collision")
	terrain_main.free()
