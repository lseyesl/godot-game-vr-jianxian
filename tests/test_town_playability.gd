extends RefCounted

const TOWN_SCENE_PATH := "res://scenes/town/Town.tscn"

func run(t) -> void:
	t.assert_true(ResourceLoader.exists(TOWN_SCENE_PATH), "Town scene exists")
	if not ResourceLoader.exists(TOWN_SCENE_PATH):
		return
	var packed_scene := load(TOWN_SCENE_PATH)
	t.assert_true(packed_scene is PackedScene, "Town scene loads as PackedScene")
	if not packed_scene is PackedScene:
		return
	var town = packed_scene.instantiate()
	t.assert_true(town != null, "Town scene instantiates for playability checks")
	if town == null:
		return

	_assert_clearance(t, town, "TownFlowMarkers/MainStreetRouteClearance", Vector2(3.0, 16.0), "main street route keeps a 3 m wide north-south path")
	_assert_clearance(t, town, "TownFlowMarkers/MarketRouteClearance", Vector2(3.0, 4.0), "market route keeps a comfortable clear aisle")
	_assert_clearance(t, town, "TownFlowMarkers/InnEntranceClearance", Vector2(2.0, 2.0), "inn entrance keeps a core quest doorway clearance")
	_assert_clearance(t, town, "TownFlowMarkers/TavernEntranceClearance", Vector2(2.0, 2.0), "tavern entrance keeps a core quest doorway clearance")
	_assert_clearance(t, town, "TownFlowMarkers/InnkeeperInteractionClearance", Vector2(1.5, 1.5), "innkeeper interaction keeps standing VR space")
	_assert_clearance(t, town, "TownFlowMarkers/TavernKeeperInteractionClearance", Vector2(1.5, 1.5), "tavern keeper interaction keeps standing VR space")
	_assert_clearance(t, town, "TownFlowMarkers/ReturnLandingClearance", Vector2(2.0, 2.0), "return landing keeps clear arrival space")

	town.free()

func _assert_clearance(t, town: Node, marker_path: String, minimum_xz: Vector2, message: String) -> void:
	t.assert_true(town.has_node(marker_path), "%s exists" % marker_path)
	var marker = town.get_node_or_null(marker_path)
	t.assert_true(marker is Area3D, "%s is an Area3D" % marker_path)
	if not marker is Area3D:
		return
	var shape_node = marker.get_node_or_null("CollisionShape3D")
	t.assert_true(shape_node is CollisionShape3D, "%s has CollisionShape3D" % marker_path)
	if not shape_node is CollisionShape3D:
		return
	t.assert_true(shape_node.shape is BoxShape3D, "%s uses BoxShape3D" % marker_path)
	if not shape_node.shape is BoxShape3D:
		return
	var shape: BoxShape3D = shape_node.shape
	t.assert_true(shape.size.x >= minimum_xz.x, "%s width is at least %.1f m" % [message, minimum_xz.x])
	t.assert_true(shape.size.z >= minimum_xz.y, "%s depth is at least %.1f m" % [message, minimum_xz.y])
