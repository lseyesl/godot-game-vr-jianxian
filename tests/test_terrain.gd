extends RefCounted

func run(t) -> void:
	# 验证 Terrain3D 所需资源可加载
	t.assert_true(ResourceLoader.exists("res://assets/textures/terrain/terrain_assets.tres"), "Terrain3DAssets should exist")
	t.assert_true(ResourceLoader.exists("res://assets/materials/terrain3d_material.tres"), "Terrain3DMaterial should exist")
	t.assert_true(ResourceLoader.exists("res://assets/textures/terrain/heightmaps/terrain_heightmap.png"), "Heightmap texture should exist")
	t.assert_true(ResourceLoader.exists("res://assets/textures/terrain/grassland/rocky_terrain/rocky_terrain_alb_ht.png"), "Grass albedo texture should exist")
	t.assert_true(ResourceLoader.exists("res://assets/textures/terrain/grassland/rocky_terrain/rocky_terrain_nrm_rgh.png"), "Grass normal texture should exist")

	# 验证 Terrain3D 区域文件存在
	t.assert_true(ResourceLoader.exists("res://assets/terrain3d/data/terrain3d_00_00.res"), "Terrain3D region 00_00 should exist")
	t.assert_true(ResourceLoader.exists("res://assets/terrain3d/data/terrain3d-01_00.res"), "Terrain3D region -1_0 should exist")
	t.assert_true(ResourceLoader.exists("res://assets/terrain3d/data/terrain3d-02_00.res"), "Terrain3D region -2_0 should exist")

	# 验证 Phase 2 路径预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/PathSegment_3x6m.tscn"), "PathSegment should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/CliffWall_4x6m.tscn"), "CliffWall should exist")

	# 验证 Phase 3 山谷预置体可加载
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/ValleyPlatform_12x12m.tscn"), "ValleyPlatform should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SealPlatform_8x8m.tscn"), "SealPlatform should exist")
	t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SwordAltar_2x2m.tscn"), "SwordAltar should exist")

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

	# 验证 Main 场景加载和地形结构
	var scene := preload("res://scenes/main/Main.tscn").instantiate()
	t.assert_true(scene != null, "Main scene should instantiate")
	if scene == null:
		return

	var container := scene.get_node_or_null("TerrainContainer")
	t.assert_true(container != null, "Main scene has TerrainContainer child")
	if container != null:
		# Terrain3D 替代了 HeightmapTerrain
		var terrain3d := container.get_node_or_null("NavigationRegion3D/Terrain3D")
		t.assert_true(terrain3d != null, "TerrainContainer has Terrain3D")
		if terrain3d != null:
			t.assert_true(terrain3d is Terrain3D, "Terrain3D node is of type Terrain3D")
			t.assert_true(terrain3d.assets != null, "Terrain3D has assets assigned")
			t.assert_true(terrain3d.material != null, "Terrain3D has material assigned")
			t.assert_equal(terrain3d.data_directory, "res://assets/terrain3d/data/", "Terrain3D data_directory is set")
			_assert_terrain3d_texture_formats_match(t, terrain3d.assets)

		# WorldBoundary 保留
		t.assert_true(container.get_node_or_null("WorldBoundary") != null, "TerrainContainer has WorldBoundary")

		# 旧地面预置体已被移除
		t.assert_true(container.get_node_or_null("TownGround") == null, "TerrainContainer does not instance old TownGround")
		t.assert_true(container.get_node_or_null("SuburbGround") == null, "TerrainContainer does not instance old SuburbGround")
		t.assert_true(container.get_node_or_null("MountainGround") == null, "TerrainContainer does not instance old MountainGround")

		var boundary := container.get_node_or_null("WorldBoundary")
		if boundary != null:
			_assert_boundary_wall(t, boundary, "NorthWall", Vector3(0, 30, -512.5), Vector3(1536, 60, 1), "north boundary covers Terrain3D width")
			_assert_boundary_wall(t, boundary, "SouthWall", Vector3(0, 30, 512.5), Vector3(1536, 60, 1), "south boundary covers Terrain3D width")
			_assert_boundary_wall(t, boundary, "WestWall", Vector3(-768.5, 30, 0), Vector3(1, 60, 1024), "west boundary covers Terrain3D depth")
			_assert_boundary_wall(t, boundary, "EastWall", Vector3(768.5, 30, 0), Vector3(1, 60, 1024), "east boundary covers Terrain3D depth")

	# 验证概念图布局占位组存在
	var concept_layout := scene.get_node_or_null("ConceptLayout")
	t.assert_true(concept_layout != null, "Main scene has ConceptLayout")
	if concept_layout != null:
		t.assert_true(concept_layout.get_node_or_null("TownWallPlaceholders/NorthWallRun") != null, "ConceptLayout has town wall placeholders")
		t.assert_true(concept_layout.get_node_or_null("TownDistrictPlaceholders/CentralMarketBlocks") != null, "ConceptLayout has town district placeholders")
		t.assert_true(concept_layout.get_node_or_null("FieldPlaceholders/NorthwestTerracedFields") != null, "ConceptLayout has field placeholders")
		t.assert_true(concept_layout.get_node_or_null("WaterfrontPlaceholders/EastHarborDocks") != null, "ConceptLayout has waterfront placeholders")
		t.assert_true(concept_layout.get_node_or_null("RiverbankAndBedPlaceholders/EastRiverBed") != null, "ConceptLayout has riverbed placeholders")
		t.assert_true(concept_layout.get_node_or_null("MountainBackdropPlaceholders/WestMountainMass") != null, "ConceptLayout has mountain backdrop placeholders")
		t.assert_true(concept_layout.get_node_or_null("TrialRoutePlaceholders/MountainGateRoute") != null, "ConceptLayout has trial route placeholders")
		t.assert_true(concept_layout.get_node_or_null("TrialRoutePlaceholders/WaterfallVista") != null, "ConceptLayout has waterfall vista")
	var corridor := scene.get_node_or_null("ConnectionCorridor")
	t.assert_true(corridor == null, "Main scene does not keep old ConnectionCorridor")

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
	var town_scene := preload("res://scenes/town/Town.tscn").instantiate()
	t.assert_true(town_scene != null, "Town scene should instantiate")
	if town_scene != null:
		var layout_reference := town_scene.get_node_or_null("LayoutReference") as MeshInstance3D
		t.assert_true(layout_reference != null, "Town has layout reference plane")
		if layout_reference != null:
			t.assert_equal(layout_reference.position, Vector3(0, 0.05, 0), "Layout reference aligns to terrain center and sits above ground")
			t.assert_equal(layout_reference.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Layout reference casts no shadows")
			var reference_mesh := layout_reference.mesh as PlaneMesh
			t.assert_true(reference_mesh != null, "Layout reference uses PlaneMesh")
			if reference_mesh != null:
				t.assert_equal(reference_mesh.size, Vector2(1536, 1024), "Layout reference matches Terrain3D footprint")
			var reference_material := layout_reference.material_override as StandardMaterial3D
			t.assert_true(reference_material != null, "Layout reference has StandardMaterial3D override")
			if reference_material != null:
				t.assert_true(reference_material.albedo_texture != null, "Layout reference material uses concept texture")
				if reference_material.albedo_texture != null:
					t.assert_equal(reference_material.albedo_texture.resource_path, "res://docs/concept-art/布局.png", "Layout reference uses concept layout image")
		town_scene.free()
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


func _assert_terrain3d_texture_formats_match(t, assets: Terrain3DAssets) -> void:
	t.assert_true(assets != null, "Terrain3D texture assets are available")
	if assets == null:
		return
	var expected_albedo_format := -1
	var expected_normal_format := -1
	for texture_index in range(assets.get_texture_count()):
		var texture_asset := assets.get_texture(texture_index)
		t.assert_true(texture_asset != null, "Terrain3D texture asset %d exists" % texture_index)
		if texture_asset == null:
			continue
		expected_albedo_format = _assert_texture_format_matches(t, texture_asset.albedo_texture, expected_albedo_format, "albedo", texture_index)
		expected_normal_format = _assert_texture_format_matches(t, texture_asset.normal_texture, expected_normal_format, "normal", texture_index)


func _assert_texture_format_matches(t, texture: Texture2D, expected_format: int, channel_name: String, texture_index: int) -> int:
	t.assert_true(texture != null, "Terrain3D %s texture %d is assigned" % [channel_name, texture_index])
	if texture == null:
		return expected_format
	var image := texture.get_image()
	t.assert_true(image != null, "Terrain3D %s texture %d can expose image data" % [channel_name, texture_index])
	if image == null:
		return expected_format
	var image_format := image.get_format()
	if expected_format < 0:
		return image_format
	t.assert_equal(image_format, expected_format, "Terrain3D %s texture %d uses the same imported format as texture 0" % [channel_name, texture_index])
	return expected_format
