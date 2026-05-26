extends RefCounted

const PREFABS := [
	{"prefab": "res://scenes/prefabs/models/Gate/Gate.tscn", "root": "Gate"},
	{"prefab": "res://scenes/prefabs/models/Inn/Inn.tscn", "root": "Inn"},
	{"prefab": "res://scenes/prefabs/models/Innkeeper/Innkeeper.tscn", "root": "Innkeeper"},
	{"prefab": "res://scenes/prefabs/models/Market_Stall/Market_Stall.tscn", "root": "Market_Stall"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof01.tscn", "root": "Roof01"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof02.tscn", "root": "Roof02"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof03.tscn", "root": "Roof03"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof04.tscn", "root": "Roof04"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof05.tscn", "root": "Roof05"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof06.tscn", "root": "Roof06"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof07.tscn", "root": "Roof07"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof08.tscn", "root": "Roof08"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof09.tscn", "root": "Roof09"},
	{"prefab": "res://scenes/prefabs/models/Roof/Roof10.tscn", "root": "Roof10"},
	{"prefab": "res://scenes/prefabs/models/Tavern/Tavern.tscn", "root": "Tavern"},
	{"prefab": "res://scenes/prefabs/models/Wall/Wall_1x3.tscn", "root": "Wall_1x3"},
	{"prefab": "res://scenes/prefabs/models/Wall/Wall_2x3.tscn", "root": "Wall_2x3"},
]

func run(t) -> void:
	for prefab_info in PREFABS:
		_assert_prefab_has_box_collider(t, prefab_info)

func _assert_prefab_has_box_collider(t, prefab_info: Dictionary) -> void:
	var prefab_path: String = prefab_info["prefab"]
	var root_name: String = prefab_info["root"]
	t.assert_true(ResourceLoader.exists(prefab_path), "%s prefab scene exists" % root_name)
	if not ResourceLoader.exists(prefab_path):
		return
	var prefab_scene := load(prefab_path)
	t.assert_true(prefab_scene is PackedScene, "%s prefab loads as PackedScene" % root_name)
	if not prefab_scene is PackedScene:
		return
	var prefab = prefab_scene.instantiate()
	t.assert_true(prefab is Node3D, "%s prefab root is Node3D" % root_name)
	if prefab == null:
		return
	var collision_body = prefab.get_node_or_null("CollisionBody")
	t.assert_true(collision_body is StaticBody3D, "%s prefab has a StaticBody3D CollisionBody" % root_name)
	if collision_body is StaticBody3D:
		var collision_shape = collision_body.get_node_or_null("CollisionShape3D")
		t.assert_true(collision_shape is CollisionShape3D, "%s CollisionBody has a CollisionShape3D" % root_name)
		if collision_shape is CollisionShape3D:
			t.assert_true(collision_shape.shape is BoxShape3D, "%s collision shape is a BoxShape3D" % root_name)
			if collision_shape.shape is BoxShape3D:
				var size := (collision_shape.shape as BoxShape3D).size
				t.assert_true(size.x > 0.0 and size.y > 0.0 and size.z > 0.0, "%s collision box has positive size" % root_name)
	prefab.free()
