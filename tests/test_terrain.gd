extends RefCounted

func run(t) -> void:
	# 验证地形预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/TownGround.tscn"), "TownGround should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SuburbGround.tscn"), "SuburbGround should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/MountainGround.tscn"), "MountainGround should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/WorldBoundary.tscn"), "WorldBoundary should exist")
	t.assert_true(ResourceLoader.exists("res://assets/textures/terrain/heightmaps/terrain_heightmap.png"), "Heightmap texture should exist")
	t.assert_true(ResourceLoader.exists("res://scripts/world/HeightmapTerrain.gd"), "HeightmapTerrain script should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/HeightmapTerrain.tscn"), "HeightmapTerrain prefab should exist")

	var heightmap_scene := preload("res://scenes/prefabs/terrain/HeightmapTerrain.tscn").instantiate()
	t.assert_true(heightmap_scene != null, "HeightmapTerrain scene should instantiate")
	if heightmap_scene != null:
		t.assert_true(heightmap_scene.has_method("generate_from_heightmap"), "HeightmapTerrain exposes generation method")
		var generated: bool = heightmap_scene.generate_from_heightmap()
		t.assert_true(generated, "HeightmapTerrain generates mesh from heightmap")
		var terrain_mesh := heightmap_scene.get_node_or_null("TerrainMesh")
		t.assert_true(terrain_mesh != null, "HeightmapTerrain has TerrainMesh child")
		if terrain_mesh != null:
			t.assert_true(terrain_mesh.mesh != null, "HeightmapTerrain generated mesh is assigned")
		heightmap_scene.free()

	# 验证 Phase 2 路径预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/PathSegment_3x6m.tscn"), "PathSegment should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/CliffWall_4x6m.tscn"), "CliffWall should exist")

	# 验证 Phase 3 山谷预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/ValleyPlatform_12x12m.tscn"), "ValleyPlatform should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SealPlatform_8x8m.tscn"), "SealPlatform should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SwordAltar_2x2m.tscn"), "SwordAltar should exist")

	# 验证 Main 场景可加载且包含新地形结构
	# 验证 Phase 4 建筑壳体预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/buildings/SmallBuildingShell.tscn"), "SmallBuildingShell should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/buildings/MediumBuildingShell.tscn"), "MediumBuildingShell should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/buildings/LargeBuildingShell.tscn"), "LargeBuildingShell should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/buildings/DistantBuildingShell.tscn"), "DistantBuildingShell should exist")

	# 验证 Phase 6 飞行路线预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/flight/RouteRing.tscn"), "RouteRing should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/flight/AerialLantern.tscn"), "AerialLantern should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/flight/CloudWisp.tscn"), "CloudWisp should exist")

	# 验证 Phase 5 道具预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/Lantern.tscn"), "Lantern prop should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/WoodenBox.tscn"), "WoodenBox prop should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/WineJar.tscn"), "WineJar prop should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/Signboard.tscn"), "Signboard prop should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/Tree.tscn"), "Tree prop should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/PineTree.tscn"), "PineTree prop should exist")

	# 验证 MountainTrial 场景可加载并包含山谷几何体
	var mt_scene := preload("res://scenes/mountain/MountainTrial.tscn").instantiate()
	t.assert_true(mt_scene != null, "MountainTrial scene should instantiate")
	if mt_scene != null:
		t.assert_true(mt_scene.get_node_or_null("ValleyTerrain") != null, "MountainTrial has ValleyTerrain")
		t.assert_true(mt_scene.get_node_or_null("SurroundingCliffs") != null, "MountainTrial has SurroundingCliffs")
		t.assert_true(mt_scene.get_node_or_null("SealEncounter") != null, "MountainTrial has SealEncounter")
		var seal := mt_scene.get_node_or_null("SealEncounter")
		if seal != null:
			t.assert_equal(seal.position.y, 24.0, "SealEncounter should be at Y=24")
		var sword := mt_scene.get_node_or_null("FlyingSword")
		if sword != null:
			t.assert_true(sword.position.y > 24.0, "FlyingSword should be above Y=24")
	mt_scene.free()

	var scene := preload("res://scenes/main/Main.tscn").instantiate()
	t.assert_true(scene != null, "Main scene should instantiate")
	if scene == null:
		return

	var container := scene.get_node_or_null("TerrainContainer")
	t.assert_true(container != null, "Main scene has TerrainContainer child")
	if container != null:
		t.assert_true(container.get_node_or_null("HeightmapTerrain") != null, "TerrainContainer has HeightmapTerrain")
		t.assert_true(container.get_node_or_null("TownGround") != null, "TerrainContainer has TownGround")
		t.assert_true(container.get_node_or_null("SuburbGround") != null, "TerrainContainer has SuburbGround")
		t.assert_true(container.get_node_or_null("MountainGround") != null, "TerrainContainer has MountainGround")
		t.assert_true(container.get_node_or_null("WorldBoundary") != null, "TerrainContainer has WorldBoundary")

	# 验证 ConnectionCorridor 存在且包含路径和崖壁
	var corridor := scene.get_node_or_null("ConnectionCorridor")
	t.assert_true(corridor != null, "Main scene has ConnectionCorridor")
	if corridor != null:
		t.assert_true(corridor.get_node_or_null("Path_01") != null, "ConnectionCorridor has path segments")
		t.assert_true(corridor.get_node_or_null("CliffWalls") != null, "ConnectionCorridor has cliff walls")
		t.assert_true(corridor.get_node_or_null("WaterfallVista") != null, "ConnectionCorridor has waterfall vista")

	# 验证 WaterFeatures 存在且包含水体实例
	var water := scene.get_node_or_null("WaterFeatures")
	t.assert_true(water != null, "Main scene has WaterFeatures")
	if water != null:
		t.assert_true(water.get_node_or_null("TownCanal") != null, "WaterFeatures has TownCanal")
		t.assert_true(water.get_node_or_null("TownLake") != null, "WaterFeatures has TownLake")
		t.assert_true(water.get_node_or_null("MountainStream") != null, "WaterFeatures has MountainStream")

	# 验证 FlightRoute 存在
	var flight := scene.get_node_or_null("FlightRoute")
	t.assert_true(flight != null, "Main scene has FlightRoute")
	if flight != null:
		t.assert_true(flight.get_node_or_null("Ring_01") != null, "FlightRoute has Ring_01")
		t.assert_true(flight.get_node_or_null("AerialLanterns") != null, "FlightRoute has AerialLanterns")
		t.assert_true(flight.get_node_or_null("CloudWisps") != null, "FlightRoute has CloudWisps")

	# 验证环境雾
	var fog_volume := scene.get_node_or_null("FogVolume")
	t.assert_true(fog_volume != null, "Main scene has FogVolume")
	if fog_volume != null:
		t.assert_true(fog_volume.size == Vector3(60, 15, 60), "FogVolume size should be 60x15x60")

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
