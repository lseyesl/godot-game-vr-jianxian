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
		t.assert_equal(heightmap_scene.world_size, Vector2(900, 600), "HeightmapTerrain maps full heightmap to 900x600m")
		t.assert_true(heightmap_scene.has_method("generate_from_heightmap"), "HeightmapTerrain exposes generation method")
		var generated: bool = heightmap_scene.generate_from_heightmap()
		t.assert_true(generated, "HeightmapTerrain generates mesh from heightmap")
		var terrain_mesh := heightmap_scene.get_node_or_null("TerrainMesh")
		t.assert_true(terrain_mesh != null, "HeightmapTerrain has TerrainMesh child")
		if terrain_mesh != null:
			t.assert_true(terrain_mesh.mesh != null, "HeightmapTerrain generated mesh is assigned")
			if terrain_mesh.mesh != null:
				var mesh_aabb: AABB = terrain_mesh.mesh.get_aabb()
				t.assert_true(is_equal_approx(mesh_aabb.size.x, 900.0), "HeightmapTerrain mesh spans 900m on X")
				t.assert_true(is_equal_approx(mesh_aabb.size.z, 600.0), "HeightmapTerrain mesh spans 600m on Z")
		var collision_shape := heightmap_scene.get_node_or_null("CollisionShape3D") as CollisionShape3D
		t.assert_true(collision_shape != null, "HeightmapTerrain has CollisionShape3D child")
		if collision_shape != null:
			t.assert_true(not collision_shape.disabled, "HeightmapTerrain collision is enabled")
			t.assert_true(collision_shape.shape != null, "HeightmapTerrain collision shape is generated")
		t.assert_true(heightmap_scene.has_method("get_height_at_world_position"), "HeightmapTerrain exposes world height lookup")
		if heightmap_scene.has_method("get_height_at_world_position"):
			var spawn_height: float = heightmap_scene.get_height_at_world_position(Vector3(0, 0, 6))
			t.assert_true(spawn_height > 1.0, "HeightmapTerrain reports raised terrain at default spawn XZ")
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
		var main_heightmap := container.get_node_or_null("HeightmapTerrain")
		if main_heightmap != null:
			t.assert_equal(main_heightmap.world_size, Vector2(900, 600), "Main uses 900x600m heightmap terrain")
		var boundary := container.get_node_or_null("WorldBoundary")
		if boundary != null:
			_assert_boundary_wall(t, boundary, "NorthWall", Vector3(0, 30, -300.5), Vector3(900, 60, 1), "north boundary covers terrain width")
			_assert_boundary_wall(t, boundary, "SouthWall", Vector3(0, 30, 300.5), Vector3(900, 60, 1), "south boundary covers terrain width")
			_assert_boundary_wall(t, boundary, "WestWall", Vector3(-450.5, 30, 0), Vector3(1, 60, 600), "west boundary covers terrain depth")
			_assert_boundary_wall(t, boundary, "EastWall", Vector3(450.5, 30, 0), Vector3(1, 60, 600), "east boundary covers terrain depth")

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

	# 验证当前主场景暂时不启用雾
	var world_environment := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	t.assert_true(world_environment != null, "Main scene has WorldEnvironment")
	if world_environment != null and world_environment.environment != null:
		t.assert_true(not world_environment.environment.fog_enabled, "Main scene global fog is disabled")
	var fog_volume := scene.get_node_or_null("FogVolume")
	t.assert_true(fog_volume != null, "Main scene has FogVolume")
	if fog_volume != null:
		t.assert_true(not fog_volume.visible, "Main scene FogVolume is hidden while fog is disabled")

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


func _assert_boundary_wall(t, boundary: Node, wall_name: String, expected_position: Vector3, expected_size: Vector3, message: String) -> void:
	var wall := boundary.get_node_or_null(wall_name) as Node3D
	t.assert_true(wall != null, "%s exists" % wall_name)
	if wall == null:
		return
	t.assert_equal(wall.position, expected_position, "%s position matches expanded terrain" % wall_name)
	var collision_shape := wall.get_node_or_null("CollisionShape3D") as CollisionShape3D
	t.assert_true(collision_shape != null, "%s has collision shape" % wall_name)
	if collision_shape == null:
		return
	var box_shape := collision_shape.shape as BoxShape3D
	t.assert_true(box_shape != null, "%s uses BoxShape3D" % wall_name)
	if box_shape != null:
		t.assert_equal(box_shape.size, expected_size, message)
