extends RefCounted

func run(t) -> void:
	var path := "res://scenes/town/Town.tscn"
	t.assert_true(ResourceLoader.exists(path), "Town scene exists")
	if not ResourceLoader.exists(path):
		return
	_test_town_wall_scene_does_not_serialize_generated_nodes(t, path)
	var town_scene := load(path)
	t.assert_true(town_scene is PackedScene, "Town scene loads as PackedScene")
	if not town_scene is PackedScene:
		return
	var town = town_scene.instantiate()
	t.assert_true(town != null, "Town scene instantiates")
	if town == null:
		return
	_test_showcase_models(t, town)
	_test_roof_showcase_models(t, town)
	_test_town_wall_models(t, town)
	_test_visible_town_landmarks(t, town)
	_test_npc_logic_nodes(t, town)
	_test_town_npc_ai_nodes(t, town)
	_test_street_props(t, town)
	_test_distant_building_lod(t, town)
	town.free()

func _test_showcase_models(t, town: Node) -> void:
	t.assert_true(town.has_node("Inn/InnModel"), "Inn model is placed in town")
	t.assert_true(town.has_node("Tavern/TavernModel"), "Tavern model is placed in town")
	t.assert_true(town.has_node("GatePaifang/GateModel"), "Visible gate model is attached to the gate anchor")
	t.assert_true(town.has_node("SouthGatePaifang/GateModel"), "South gate model is attached to the south gate")
	t.assert_true(town.has_node("WestGatePaifang/GateModel"), "West gate model is attached to the west gate")
	var gate_model = town.get_node_or_null("GatePaifang/GateModel")
	t.assert_true(gate_model is Node3D, "Gate model is a visible 3D node")
	t.assert_equal(_source_model_path(gate_model), "res://assets/models/town/Gate/Gate.glb", "Gate model uses the Gate source asset")
	var south_gate_model = town.get_node_or_null("SouthGatePaifang/GateModel")
	var west_gate_model = town.get_node_or_null("WestGatePaifang/GateModel")
	t.assert_equal(_source_model_path(south_gate_model), "res://assets/models/town/Gate/Gate.glb", "South gate uses the Gate source asset")
	t.assert_equal(_source_model_path(west_gate_model), "res://assets/models/town/Gate/Gate.glb", "West gate uses the Gate source asset")
	t.assert_true(town.has_node("MarketStreet/StallCenter"), "Center market stall is placed in town")
	t.assert_true(town.has_node("MarketStreet/StallLeft"), "Left market stall is placed in town")
	t.assert_true(town.has_node("MarketStreet/StallRight"), "Right market stall is placed in town")
	t.assert_equal(town.get_node("GatePaifang").position, Vector3(0, 0, -32), "GatePaifang anchors the north gate")
	t.assert_equal(town.get_node("SouthGatePaifang").position, Vector3(0, 0, 28), "SouthGatePaifang anchors the south gate")
	t.assert_equal(town.get_node("WestGatePaifang").position, Vector3(-24, 0, 10), "WestGatePaifang anchors the west gate")
	t.assert_equal(town.get_node("MarketStreet").position, Vector3(0, 0, 8), "MarketStreet anchors the central-south market")
	t.assert_equal(town.get_node("Inn").position, Vector3(-12, 0, 6), "Inn remains top-level near the west canal")
	t.assert_equal(town.get_node("Tavern").position, Vector3(10, 0, 12), "Tavern remains top-level near the southeast tea district")
	t.assert_true(town.has_node("WestDistrict"), "WestDistrict visual anchor exists")
	t.assert_true(town.has_node("EastDistrict"), "EastDistrict visual anchor exists")
	t.assert_true(town.has_node("SouthEastDistrict"), "SouthEastDistrict visual anchor exists")
	t.assert_true(town.has_node("NorthEastDistrict"), "NorthEastDistrict visual anchor exists")
	t.assert_equal(town.get_node("ReturnToTownTrigger").position, Vector3(12, 3, 24), "Return trigger sits near the southeast return edge")

func _test_town_wall_scene_does_not_serialize_generated_nodes(t, path: String) -> void:
	var scene_text := FileAccess.get_file_as_string(path)
	t.assert_true(not scene_text.contains("parent=\"TownWall/GeneratedWalls\""), "Town scene does not serialize generated wall segment instances")
	t.assert_true(not scene_text.contains("[node name=\"GeneratedWalls\""), "Town scene does not serialize generated wall preview container")

func _test_roof_showcase_models(t, town: Node) -> void:
	t.assert_true(town.has_node("RoofShowcase"), "Roof showcase anchor exists")
	for roof_index in range(1, 11):
		var roof_name := "Roof%02d" % roof_index
		var roof_path := "RoofShowcase/%s" % roof_name
		t.assert_true(town.has_node(roof_path), "%s is placed in town" % roof_path)
		var roof = town.get_node_or_null(roof_path)
		t.assert_true(roof is Node3D, "%s is a 3D roof node" % roof_path)
		t.assert_equal(_source_model_path(roof), "res://assets/models/town/Roof/%s.glb" % roof_name, "%s uses the matching Roof source asset" % roof_name)

func _test_town_wall_models(t, town: Node) -> void:
	t.assert_true(town.has_node("TownWall"), "Town wall path anchor exists")
	var wall_generator := town.get_node_or_null("TownWall")
	t.assert_true(wall_generator != null and wall_generator.has_method("generate_walls"), "TownWall can generate wall segments from paths")
	if wall_generator == null or not wall_generator.has_method("generate_walls"):
		return

	var path_count := 0
	var expected_wall_count := 0
	var expected_lengths := {}
	for child in wall_generator.get_children():
		if child is Path3D and child.curve != null:
			var length: float = child.curve.get_baked_length()
			if length > 0.0:
				path_count += 1
				expected_lengths[child.name] = length
				expected_wall_count += ceili(length / 2.0)
	t.assert_true(path_count >= 1, "TownWall has editable Path3D wall routes")

	wall_generator.generate_walls()
	var generated := wall_generator.get_node_or_null("GeneratedWalls")
	t.assert_true(generated != null, "TownWall creates GeneratedWalls container")
	if generated == null:
		return
	t.assert_equal(generated.owner, null, "GeneratedWalls remains unsaved runtime/editor preview data")
	t.assert_equal(generated.get_child_count(), expected_wall_count, "Generated wall count covers all path lengths")

	var covered_lengths := {}
	for path_name in expected_lengths.keys():
		covered_lengths[path_name] = 0.0
	for wall in generated.get_children():
		t.assert_true(wall is Node3D, "%s is a generated 3D wall segment" % wall.name)
		t.assert_equal(wall.owner, null, "%s remains unsaved runtime/editor preview data" % wall.name)
		t.assert_equal(_source_model_path(wall), "res://assets/models/town/Wall/Wall_2x3.glb", "%s uses the Wall_2x3 model" % wall.name)
		var path_name: String = wall.get_meta("path_name", "")
		t.assert_true(expected_lengths.has(path_name), "%s records a source path name" % wall.name)
		t.assert_true(wall.has_meta("segment_length_m"), "%s records segment length" % wall.name)
		t.assert_true(wall.has_meta("segment_index"), "%s records segment index" % wall.name)
		t.assert_true(wall.has_meta("segment_count"), "%s records segment count" % wall.name)
		if expected_lengths.has(path_name):
			covered_lengths[path_name] += float(wall.get_meta("segment_length_m", 0.0))
	for path_name in expected_lengths.keys():
		var gap: float = abs(float(expected_lengths[path_name]) - float(covered_lengths[path_name]))
		t.assert_true(gap <= 0.01, "%s generated wall lengths leave no measurable gap" % path_name)

func _source_model_path(node: Node) -> String:
	if node == null:
		return ""
	if node.scene_file_path.begins_with("res://assets/models/"):
		return node.scene_file_path
	var model = node.get_node_or_null("Model")
	if model != null:
		if model.scene_file_path.begins_with("res://assets/models/"):
			return model.scene_file_path
		var model_metadata: Variant = model.get_meta("source_model_path", "")
		if model_metadata is String:
			return model_metadata
	var metadata: Variant = node.get_meta("source_model_path", "")
	return metadata if metadata is String else ""

func _test_visible_town_landmarks(t, town: Node) -> void:
	var building_paths := {
		"WestDistrict/WaterwheelBuilding": Vector3(-18, 0, 10),
		"WestDistrict/Farmhouse_01": Vector3(-20, 0, 4),
		"WestDistrict/Farmhouse_02": Vector3(-22, 0, 2),
		"EastDistrict/YamenBuilding": Vector3(16, 0, 2),
		"EastDistrict/DockBuilding": Vector3(22, 0, 10),
		"SouthEastDistrict/TempleBuilding": Vector3(12, 0, 18),
		"NorthEastDistrict/GranaryBuilding": Vector3(8, 0, -16),
		"NorthEastDistrict/BlacksmithBuilding": Vector3(14, 0, -12),
		"NorthEastDistrict/FishingHut_01": Vector3(24, 0, -16),
	}
	for building_path in building_paths.keys():
		t.assert_true(town.has_node(building_path), "%s exists as a building shell" % building_path)
		var building = town.get_node(building_path)
		t.assert_true(building is StaticBody3D, "%s is a StaticBody3D" % building_path)
		_assert_marker_position(t, town, building_path, building_paths[building_path], "%s sits at expected position" % building_path)
	t.assert_true(town.has_node("WestDistrict/CanalMarkerPlaceholder"), "CanalMarkerPlaceholder exists as a canal marker")

func _assert_marker_position(t, town: Node, marker_path: String, expected_position: Vector3, message: String) -> void:
	var marker = town.get_node_or_null(marker_path)
	var actual_position := Vector3.INF
	if marker is Node3D:
		actual_position = marker.position
	t.assert_equal(actual_position, expected_position, message)

func _test_npc_logic_nodes(t, town: Node) -> void:
	t.assert_true(town.has_node("Inn"), "Inn remains a top-level quest anchor")
	t.assert_true(town.has_node("Tavern"), "Tavern remains a top-level quest anchor")
	t.assert_true(not town.has_node("WestDistrict/Inn"), "Inn is not nested under WestDistrict in this pass")
	t.assert_true(not town.has_node("EastDistrict/Tavern"), "Tavern is not nested under EastDistrict in this pass")
	t.assert_true(town.has_node("Inn/Innkeeper"), "Innkeeper NPC remains under Inn")
	t.assert_true(town.has_node("Tavern/TavernKeeper"), "TavernKeeper NPC remains under Tavern")
	var innkeeper = town.get_node("Inn/Innkeeper")
	var tavern_keeper = town.get_node("Tavern/TavernKeeper")
	t.assert_equal(innkeeper.npc_id, "innkeeper", "Innkeeper quest id remains intact")
	t.assert_equal(tavern_keeper.npc_id, "tavern_keeper", "TavernKeeper quest id remains intact")
	t.assert_true(town.has_node("Inn/Innkeeper/Model"), "Innkeeper visual model is attached to NPC")
	t.assert_equal(town.get_node("ReturnToTownTrigger").position, Vector3(12, 3, 24), "Return trigger sits on the southeast return edge")

func _test_town_npc_ai_nodes(t, town: Node) -> void:
	t.assert_true(town.has_node("TownNpcGroup"), "TownNpcGroup exists")
	var town_npc_script := load("res://scripts/npc/TownNpc.gd")
	var expected_roles := {
		"TownNpcGroup/MarketVendorCenter": "vendor",
		"TownNpcGroup/MarketVendorLeft": "vendor",
		"TownNpcGroup/InnOwnerAmbient": "inn_owner",
		"TownNpcGroup/TavernOwnerAmbient": "tavern_owner",
		"TownNpcGroup/PedestrianA": "pedestrian",
		"TownNpcGroup/PedestrianB": "pedestrian",
	}
	for npc_path in expected_roles.keys():
		t.assert_true(town.has_node(npc_path), "%s exists" % npc_path)
		var npc = town.get_node_or_null(npc_path)
		t.assert_equal(npc.get_script() if npc != null else null, town_npc_script, "%s uses TownNpc script" % npc_path)
		if npc != null:
			t.assert_equal(npc.npc_role, expected_roles[npc_path], "%s has expected role" % npc_path)
	t.assert_equal(town.get_node("Inn/Innkeeper").npc_id, "innkeeper", "Innkeeper quest id remains intact after town AI placement")
	t.assert_equal(town.get_node("Tavern/TavernKeeper").npc_id, "tavern_keeper", "TavernKeeper quest id remains intact after town AI placement")

func _test_distant_building_lod(t, town: Node) -> void:
	t.assert_true(town.has_node("DistantTownShells"), "DistantTownShells exists")
	var lod_group = town.get_node_or_null("DistantTownShells")
	t.assert_true(lod_group != null, "DistantTownShells node exists")
	if lod_group != null:
		t.assert_true(lod_group.has_method("update_for_camera_position"), "DistantTownShells has SceneLodGroup methods")
		t.assert_true(lod_group.has_node("Near"), "SceneLodGroup has Near LOD")
		t.assert_true(lod_group.has_node("Mid"), "SceneLodGroup has Mid LOD")
		t.assert_true(lod_group.has_node("Far"), "SceneLodGroup has Far LOD")
		var near_node := lod_group.get_node_or_null("Near")
		if near_node != null:
			t.assert_true(near_node.get_child_count() == 12, "Near LOD has 12 distant shells")
		var mid_node := lod_group.get_node_or_null("Mid")
		if mid_node != null:
			t.assert_true(mid_node.get_child_count() == 0, "Mid LOD is empty (can be populated later)")

func _test_street_props(t, town: Node) -> void:
	t.assert_true(town.has_node("TownProps"), "TownProps node exists")
	t.assert_true(town.has_node("TownProps/StreetLanterns"), "Street lanterns exist")
	t.assert_true(town.has_node("TownProps/MarketProps"), "Market props exist")
	t.assert_true(town.has_node("TownProps/InnProps"), "Inn props exist")
	t.assert_true(town.has_node("TownProps/TavernProps"), "Tavern props exist")
	t.assert_true(town.has_node("TownProps/TownTrees"), "Town trees exist")
	var street_lanterns := town.get_node("TownProps/StreetLanterns")
	t.assert_true(street_lanterns.get_child_count() > 0, "StreetLanterns has at least 1 child")
	t.assert_true(town.has_node("TownProps/TownTrees/Tree_01"), "Tree_01 exists")
	t.assert_true(town.has_node("TownProps/MarketProps/Box_01"), "MarketBox_01 exists")
	t.assert_true(town.has_node("TownProps/MarketProps/Jar_01"), "MarketJar_01 exists")
