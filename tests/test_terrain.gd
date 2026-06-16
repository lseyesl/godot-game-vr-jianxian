extends RefCounted

func run(t) -> void:
	# 验证地形预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/TownGround.tscn"), "TownGround should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SuburbGround.tscn"), "SuburbGround should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/MountainGround.tscn"), "MountainGround should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/WorldBoundary.tscn"), "WorldBoundary should exist")

	# 验证 Main 场景可加载且包含新地形结构
	var scene := preload("res://scenes/main/Main.tscn").instantiate()
	t.assert_true(scene != null, "Main scene should instantiate")
	if scene == null:
		return

	var container := scene.get_node_or_null("TerrainContainer")
	t.assert_true(container != null, "Main scene has TerrainContainer child")
	if container != null:
		t.assert_true(container.get_node_or_null("TownGround") != null, "TerrainContainer has TownGround")
		t.assert_true(container.get_node_or_null("SuburbGround") != null, "TerrainContainer has SuburbGround")
		t.assert_true(container.get_node_or_null("MountainGround") != null, "TerrainContainer has MountainGround")
		t.assert_true(container.get_node_or_null("WorldBoundary") != null, "TerrainContainer has WorldBoundary")

	# 验证旧 Ground 节点已移除
	var old_ground := scene.get_node_or_null("Ground")
	t.assert_true(old_ground == null, "Old Ground node should be removed")

	scene.free()

	# 验证水位预置体仍可加载（未破坏已有功能）
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/Lake.tscn"), "Lake prefab should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/RiverStraight.tscn"), "RiverStraight should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/RiverBend.tscn"), "RiverBend should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/Waterfall.tscn"), "Waterfall should still exist")

	# 验证其他关键场景仍可加载
	t.assert_true(ResourceLoader.exists("res://scenes/town/Town.tscn"), "Town scene should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/mountain/MountainTrial.tscn"), "MountainTrial should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/npc/Npc.tscn"), "Npc scene should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/npc/TownNpc.tscn"), "TownNpc scene should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/interaction/SealEncounter.tscn"), "SealEncounter should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/items/FlyingSword.tscn"), "FlyingSword should still exist")
	t.assert_true(ResourceLoader.exists("res://scenes/player/DesktopDebugPlayer.tscn"), "DesktopDebugPlayer should still exist")
