extends RefCounted

func run(t) -> void:
	var path := "res://scripts/npc/TownNpc.gd"
	t.assert_true(FileAccess.file_exists(path), "TownNpc script exists")
	if not FileAccess.file_exists(path):
		return
	var TownNpc := load(path)
	t.assert_true(TownNpc.can_instantiate(), "TownNpc can instantiate")
	if not TownNpc.can_instantiate():
		return

	var vendor = TownNpc.new()
	vendor.npc_role = "vendor"
	t.assert_true(vendor.line_for_role().contains("灵草") or vendor.line_for_role().contains("符纸"), "vendor has market ambient line")
	t.assert_equal(vendor.speak_context_line(), vendor.last_spoken_line, "speaking records last spoken line")

	var inn_owner = TownNpc.new()
	inn_owner.npc_role = "inn_owner"
	t.assert_true(inn_owner.line_for_role().contains("客栈") or inn_owner.line_for_role().contains("剑光"), "inn owner has inn ambient line")

	var tavern_owner = TownNpc.new()
	tavern_owner.npc_role = "tavern_owner"
	t.assert_true(tavern_owner.line_for_role().contains("山风") or tavern_owner.line_for_role().contains("祭台"), "tavern owner has tavern ambient line")

	var pedestrian = TownNpc.new()
	pedestrian.npc_role = "unknown_role"
	t.assert_true(pedestrian.line_for_role().length() > 0, "unknown role falls back to pedestrian line")

	var player := Node3D.new()
	player.add_to_group("player")
	vendor.set_nearby_player(player)
	t.assert_true(vendor.has_nearby_player(), "nearby player is tracked")
	vendor.clear_nearby_player(player)
	t.assert_true(not vendor.has_nearby_player(), "nearby player is cleared")

	var walker = TownNpc.new()
	walker.waypoints = [Vector3.ZERO, Vector3(2, 0, 0)]
	walker.current_waypoint_index = 1
	walker.move_speed_mps = 1.0
	walker.position = Vector3.ZERO
	t.assert_true(walker.move_to_next_waypoint(0.5), "walker moves toward waypoint")
	t.assert_true(walker.position.x > 0.0, "walker advances on x axis")

	walker.start_waiting()
	t.assert_true(walker.tick_wait(0.25), "wait is running before duration")
	t.assert_true(not walker.tick_wait(walker.wait_duration_s), "wait completes after duration")

	_test_town_npc_scene(t)

	vendor.free()
	inn_owner.free()
	tavern_owner.free()
	pedestrian.free()
	player.free()
	walker.free()

func _test_town_npc_scene(t) -> void:
	var scene_path := "res://scenes/npc/TownNpc.tscn"
	t.assert_true(ResourceLoader.exists(scene_path), "TownNpc scene exists")
	if not ResourceLoader.exists(scene_path):
		return
	var packed_scene := load(scene_path)
	t.assert_true(packed_scene is PackedScene, "TownNpc scene loads")
	if not packed_scene is PackedScene:
		return
	var scene = packed_scene.instantiate()
	var town_npc_script := load("res://scripts/npc/TownNpc.gd")
	t.assert_equal(scene.get_script(), town_npc_script, "TownNpc scene root uses TownNpc script")
	t.assert_true(scene.get_node_or_null("CollisionShape3D") is CollisionShape3D, "TownNpc has collision shape")
	t.assert_true(scene.get_node_or_null("Visual") is MeshInstance3D, "TownNpc has visible mesh")
	t.assert_true(scene.get_node_or_null("SenseArea") is Area3D, "TownNpc has sense area")
	t.assert_true(scene.get_node_or_null("BehaviorTree") != null, "TownNpc has Beehave tree")
	scene.free()
