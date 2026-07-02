extends RefCounted

const TOLERANCE_M := 0.025

const EXPECTED_SIZES := {
	"res://assets/models/town/BellDrumTower/BellDrumTower01.glb": Vector3(5.103, 9.0, 5.711),
	"res://assets/models/town/BellDrumTower/BellDrumTower02.glb": Vector3(5.438, 9.0, 5.585),
	"res://assets/models/town/RiverBoat/RiverBoat.glb": Vector3(5.0, 1.344, 1.441),
	"res://assets/models/town/StoneBridge/StoneBridge01.glb": Vector3(6.0, 1.781, 1.743),
	"res://assets/models/town/StoneBridge/StoneBridge02.glb": Vector3(6.0, 1.578, 1.831),
	"res://assets/models/town/StoneBridge/StoneBridge03.glb": Vector3(6.0, 1.443, 2.402),
	"res://assets/models/town/StoneBridge/StoneBridge04.glb": Vector3(6.0, 1.089, 1.584),
	"res://assets/models/items/FlyingSword/FlyingSword.glb": Vector3(0.354, 0.089, 1.3),
	"res://assets/models/Vegetation/bamboo_01/bamboo_01.glb": Vector3(1.073, 4.0, 1.002),
	"res://assets/models/Vegetation/bamboo_02/bamboo_02.glb": Vector3(0.786, 4.0, 0.928),
	"res://assets/models/Vegetation/green_bamboo/green_bamboo.glb": Vector3(3.19, 4.0, 2.327),
	"res://assets/models/Vegetation/pine/pine.glb": Vector3(5.933, 5.0, 4.991),
	"res://assets/models/Vegetation/willow/willow.glb": Vector3(5.602, 6.0, 3.656),
	"res://assets/models/Vegetation/nanmu/nanmu.glb": Vector3(5.343, 5.0, 1.722),
	"res://assets/models/Vegetation/mountain_cherry/mountain_cherry.glb": Vector3(4.831, 5.0, 1.571),
	"res://assets/models/Vegetation/red_plum/red_plum.glb": Vector3(4.762, 5.0, 5.467),
}

func run(t) -> void:
	for path in EXPECTED_SIZES.keys():
		_assert_model_size(t, path, EXPECTED_SIZES[path])

func _assert_model_size(t, path: String, expected: Vector3) -> void:
	t.assert_true(FileAccess.file_exists(path), "%s exists" % path)
	if not FileAccess.file_exists(path):
		return
	var packed := load(path)
	t.assert_true(packed is PackedScene, "%s loads as PackedScene" % path)
	if not packed is PackedScene:
		return
	var root = packed.instantiate()
	var bounds := _node_bounds(root, Transform3D.IDENTITY)
	root.free()
	t.assert_true(bounds.size != Vector3.ZERO, "%s has mesh bounds" % path)
	if bounds.size == Vector3.ZERO:
		return
	t.assert_true(_vector3_is_close(bounds.size, expected, TOLERANCE_M),
		"%s size is %s within %.3fm of %s" % [path, bounds.size, TOLERANCE_M, expected])

func _node_bounds(node: Node, parent_transform: Transform3D) -> AABB:
	var local_transform := Transform3D.IDENTITY
	if node is Node3D:
		local_transform = (node as Node3D).transform
	var world_transform := parent_transform * local_transform
	var has_bounds := false
	var bounds := AABB()
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			bounds = world_transform * mesh.get_aabb()
			has_bounds = true
	for child in node.get_children():
		var child_bounds := _node_bounds(child, world_transform)
		if child_bounds.size == Vector3.ZERO:
			continue
		if has_bounds:
			bounds = bounds.merge(child_bounds)
		else:
			bounds = child_bounds
			has_bounds = true
	return bounds if has_bounds else AABB()

func _vector3_is_close(actual: Vector3, expected: Vector3, tolerance: float) -> bool:
	return absf(actual.x - expected.x) <= tolerance \
		and absf(actual.y - expected.y) <= tolerance \
		and absf(actual.z - expected.z) <= tolerance
