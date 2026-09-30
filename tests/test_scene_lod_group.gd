extends RefCounted

func run(t) -> void:
	var path := "res://scripts/world/SceneLodGroup.gd"
	t.assert_true(FileAccess.file_exists(path), "SceneLodGroup script exists")
	if not FileAccess.file_exists(path):
		return
	var SceneLodGroupScript := load(path)
	t.assert_true(SceneLodGroupScript.can_instantiate(), "SceneLodGroup can instantiate")
	if not SceneLodGroupScript.can_instantiate():
		return
	_test_near_mid_far_visibility(t, SceneLodGroupScript)
	_test_no_camera_defaults_to_near_lod(t, SceneLodGroupScript)

func _test_near_mid_far_visibility(t, SceneLodGroupScript) -> void:
	var lod_group = SceneLodGroupScript.new()
	var near := Node3D.new()
	near.name = "Near"
	var mid := Node3D.new()
	mid.name = "Mid"
	var far := Node3D.new()
	far.name = "Far"
	lod_group.add_child(near)
	lod_group.add_child(mid)
	lod_group.add_child(far)
	lod_group.near_lod_path = NodePath("Near")
	lod_group.mid_lod_path = NodePath("Mid")
	lod_group.far_lod_path = NodePath("Far")
	lod_group.mid_distance_m = 20.0
	lod_group.far_distance_m = 60.0

	lod_group.update_for_camera_position(Vector3(0, 0, 5))
	t.assert_true(near.visible, "near LOD is visible at close distance")
	t.assert_true(not mid.visible, "mid LOD is hidden at close distance")
	t.assert_true(not far.visible, "far LOD is hidden at close distance")

	lod_group.update_for_camera_position(Vector3(0, 0, 30))
	t.assert_true(not near.visible, "near LOD is hidden at mid distance")
	t.assert_true(mid.visible, "mid LOD is visible at mid distance")
	t.assert_true(not far.visible, "far LOD is hidden at mid distance")

	lod_group.update_for_camera_position(Vector3(0, 0, 80))
	t.assert_true(not near.visible, "near LOD is hidden at far distance")
	t.assert_true(not mid.visible, "mid LOD is hidden at far distance")
	t.assert_true(far.visible, "far LOD is visible at far distance")
	lod_group.free()

func _test_no_camera_defaults_to_near_lod(t, SceneLodGroupScript) -> void:
	var lod_group = SceneLodGroupScript.new()
	var near := Node3D.new()
	near.name = "Near"
	var far := Node3D.new()
	far.name = "Far"
	lod_group.add_child(near)
	lod_group.add_child(far)
	lod_group.near_lod_path = NodePath("Near")
	lod_group.far_lod_path = NodePath("Far")
	lod_group.apply_default_lod()
	t.assert_true(near.visible, "near LOD is visible without a camera")
	t.assert_true(not far.visible, "far LOD is hidden without a camera")
	lod_group.free()
