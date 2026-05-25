extends RefCounted

func run(t) -> void:
	var path := "res://scenes/town/Town.tscn"
	t.assert_true(ResourceLoader.exists(path), "Town scene exists")
	if not ResourceLoader.exists(path):
		return
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
	town.free()

func _test_showcase_models(t, town: Node) -> void:
	t.assert_true(town.has_node("Inn/InnModel"), "Inn model is placed in town")
	t.assert_true(town.has_node("Tavern/TavernModel"), "Tavern model is placed in town")
	t.assert_true(town.has_node("GatePaifang/GateModel"), "Visible gate model is attached to the gate anchor")
	t.assert_true(town.has_node("SouthGatePaifang/GateModel"), "South gate model is attached to the south gate")
	t.assert_true(town.has_node("WestGatePaifang/GateModel"), "West gate model is attached to the west gate")
	var gate_model = town.get_node_or_null("GatePaifang/GateModel")
	t.assert_true(gate_model is Node3D, "Gate model is a visible 3D node")
	t.assert_equal(_source_model_path(gate_model), "res://assets/models/Gate/Gate.glb", "Gate model uses the Gate source asset")
	var south_gate_model = town.get_node_or_null("SouthGatePaifang/GateModel")
	var west_gate_model = town.get_node_or_null("WestGatePaifang/GateModel")
	t.assert_equal(_source_model_path(south_gate_model), "res://assets/models/Gate/Gate.glb", "South gate uses the Gate source asset")
	t.assert_equal(_source_model_path(west_gate_model), "res://assets/models/Gate/Gate.glb", "West gate uses the Gate source asset")
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

func _test_roof_showcase_models(t, town: Node) -> void:
	t.assert_true(town.has_node("RoofShowcase"), "Roof showcase anchor exists")
	for roof_index in range(1, 11):
		var roof_name := "Roof%02d" % roof_index
		var roof_path := "RoofShowcase/%s" % roof_name
		t.assert_true(town.has_node(roof_path), "%s is placed in town" % roof_path)
		var roof = town.get_node_or_null(roof_path)
		t.assert_true(roof is Node3D, "%s is a 3D roof node" % roof_path)
		t.assert_equal(_source_model_path(roof), "res://assets/models/Roof/%s.glb" % roof_name, "%s uses the matching Roof source asset" % roof_name)

func _test_town_wall_models(t, town: Node) -> void:
	t.assert_true(town.has_node("TownWalls"), "Town wall anchor exists")
	var wall_paths := [
		"TownWalls/NorthWallWest",
		"TownWalls/NorthWallEast",
		"TownWalls/SouthWallWest",
		"TownWalls/SouthWallEast",
		"TownWalls/WestWallNorth",
		"TownWalls/WestWallSouth",
		"TownWalls/EastWallNorth",
		"TownWalls/EastWallSouth",
	]
	for wall_path in wall_paths:
		t.assert_true(town.has_node(wall_path), "%s exists as a wall segment" % wall_path)
		var wall = town.get_node_or_null(wall_path)
		t.assert_true(wall is Node3D, "%s is a 3D wall node" % wall_path)
		var scene_path := ""
		if wall != null:
			scene_path = _source_model_path(wall)
		t.assert_equal(scene_path, "res://assets/models/Wall/Wall_2x3.glb", "%s uses the Wall_2x3 model" % wall_path)

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
	var marker_paths := [
		"WestDistrict/CanalMarker",
		"WestDistrict/WaterwheelMarker",
		"WestDistrict/FarmlandWestMarker",
		"WestDistrict/FarmlandNorthWestMarker",
		"WestDistrict/FarmlandSouthWestMarker",
		"EastDistrict/YamenMarker",
		"EastDistrict/DockMarker",
		"SouthEastDistrict/TempleMarker",
		"NorthEastDistrict/GranaryMarker",
		"NorthEastDistrict/BlacksmithMarker",
		"NorthEastDistrict/ForestryMarker",
		"NorthEastDistrict/FishingVillageMarker",
	]
	for marker_path in marker_paths:
		t.assert_true(town.has_node(marker_path), "%s exists as a visible greybox marker" % marker_path)
		var marker = town.get_node_or_null(marker_path)
		t.assert_true(marker is MeshInstance3D, "%s is a MeshInstance3D" % marker_path)
	_assert_marker_position(t, town, "WestDistrict/CanalMarker", Vector3(-10, 0, 8), "Canal runs through west-center town")
	_assert_marker_position(t, town, "WestDistrict/WaterwheelMarker", Vector3(-18, 0, 10), "Waterwheel sits near the west gate canal")
	_assert_marker_position(t, town, "WestDistrict/FarmlandWestMarker", Vector3(-20, 0, 2), "West farmland fills the west edge near the canal")
	_assert_marker_position(t, town, "WestDistrict/FarmlandNorthWestMarker", Vector3(-22, 0, -14), "Northwest farmland matches concept map")
	_assert_marker_position(t, town, "WestDistrict/FarmlandSouthWestMarker", Vector3(-24, 0, 20), "Southwest farmland matches concept map")
	_assert_marker_position(t, town, "EastDistrict/YamenMarker", Vector3(16, 0, 2), "Yamen sits east-center near water access")
	_assert_marker_position(t, town, "EastDistrict/DockMarker", Vector3(22, 0, 10), "Dock sits on the east/southeast water edge")
	_assert_marker_position(t, town, "SouthEastDistrict/TempleMarker", Vector3(12, 0, 18), "Temple sits southeast near water")
	_assert_marker_position(t, town, "NorthEastDistrict/GranaryMarker", Vector3(8, 0, -16), "Granary sits northeast of the main road")
	_assert_marker_position(t, town, "NorthEastDistrict/BlacksmithMarker", Vector3(14, 0, -12), "Blacksmith sits northeast of the main road")
	_assert_marker_position(t, town, "NorthEastDistrict/ForestryMarker", Vector3(18, 0, -24), "Forestry sits in the northeast")
	_assert_marker_position(t, town, "NorthEastDistrict/FishingVillageMarker", Vector3(24, 0, -18), "Fishing village sits on the northeast/east waterfront")

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
	t.assert_true(town.has_node("Inn/Innkeeper/Body/InnkeeperModel"), "Innkeeper visual model is attached to NPC body")
	t.assert_equal(town.get_node("ReturnToTownTrigger").position, Vector3(12, 3, 24), "Return trigger sits on the southeast return edge")
