extends RefCounted

const WATER_PREFABS := [
	{"path": "res://scenes/prefabs/water/Lake.tscn", "root": "Lake", "type": "lake", "audio": "AmbientAudio"},
	{"path": "res://scenes/prefabs/water/RiverStraight.tscn", "root": "RiverStraight", "type": "river", "audio": "WaterAudio"},
	{"path": "res://scenes/prefabs/water/RiverBend.tscn", "root": "RiverBend", "type": "river", "audio": "WaterAudio"},
	{"path": "res://scenes/prefabs/water/Waterfall.tscn", "root": "Waterfall", "type": "waterfall", "audio": "WaterfallAudio"},
]

func run(t) -> void:
	t.assert_true(ResourceLoader.exists("res://scripts/world/WaterBody.gd"), "WaterBody script exists")
	t.assert_true(ResourceLoader.exists("res://assets/materials/mat_water_flow.tres"), "animated water material exists")
	t.assert_true(ResourceLoader.exists("res://assets/materials/mat_water_foam.tres"), "water foam material exists")
	for prefab_info in WATER_PREFABS:
		_assert_water_prefab(t, prefab_info)

func _assert_water_prefab(t, prefab_info: Dictionary) -> void:
	var prefab_path: String = prefab_info["path"]
	var root_name: String = prefab_info["root"]
	t.assert_true(ResourceLoader.exists(prefab_path), "%s prefab scene exists" % root_name)
	if not ResourceLoader.exists(prefab_path):
		return
	var packed_scene := load(prefab_path)
	t.assert_true(packed_scene is PackedScene, "%s loads as PackedScene" % root_name)
	if not packed_scene is PackedScene:
		return
	var prefab = packed_scene.instantiate()
	t.assert_true(prefab is Node3D, "%s root is Node3D" % root_name)
	if prefab == null:
		return
	t.assert_equal(prefab.name, root_name, "%s root has expected name" % root_name)
	t.assert_true(prefab.get_script() != null, "%s root has runtime script" % root_name)
	t.assert_equal(prefab.water_type, prefab_info["type"], "%s water type is configured" % root_name)
	t.assert_true(prefab.flow_speed >= 0.0, "%s flow speed is non-negative" % root_name)
	t.assert_true(prefab.get_node_or_null(prefab_info["audio"]) is AudioStreamPlayer3D, "%s has configured 3D audio player" % root_name)
	_assert_area_with_shape(t, prefab, "WaterArea", root_name)
	t.assert_true(_has_water_surface(prefab), "%s has water surface material" % root_name)
	if root_name == "Waterfall":
		_assert_area_with_shape(t, prefab, "SplashArea", root_name)
		t.assert_true(prefab.get_node_or_null("MistParticles") is GPUParticles3D, "Waterfall has mist particles")
		t.assert_true(prefab.get_node_or_null("SplashParticles") is GPUParticles3D, "Waterfall has splash particles")
		t.assert_true(prefab.get_node("MistParticles").emitting, "Waterfall mist particles are enabled")
		t.assert_true(prefab.get_node("SplashParticles").emitting, "Waterfall splash particles are enabled")
	prefab.free()

func _assert_area_with_shape(t, prefab: Node, area_name: String, root_name: String) -> void:
	var area := prefab.get_node_or_null(area_name)
	t.assert_true(area is Area3D, "%s has %s Area3D" % [root_name, area_name])
	if area == null:
		return
	var shape := area.get_node_or_null("CollisionShape3D")
	t.assert_true(shape is CollisionShape3D, "%s %s has CollisionShape3D" % [root_name, area_name])
	if shape != null:
		t.assert_true(shape.shape != null, "%s %s collision shape is assigned" % [root_name, area_name])

func _has_water_surface(node: Node) -> bool:
	if node is MeshInstance3D:
		var material: Material = node.get_active_material(0)
		if material != null and material.resource_path == "res://assets/materials/mat_water_flow.tres":
			return true
	for child in node.get_children():
		if _has_water_surface(child):
			return true
	return false
