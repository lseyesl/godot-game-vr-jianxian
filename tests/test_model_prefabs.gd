extends RefCounted

const PREFABS := [
	{"source": "res://assets/models/town/Gate/Gate.glb", "prefab": "res://scenes/prefabs/models/Gate/Gate.tscn", "root": "Gate"},
	{"source": "res://assets/models/town/Inn/Inn.glb", "prefab": "res://scenes/prefabs/models/Inn/Inn.tscn", "root": "Inn"},
	{"source": "res://assets/models/npc/Innkeeper/Innkeeper.glb", "prefab": "res://scenes/prefabs/models/Innkeeper/Innkeeper.tscn", "root": "Innkeeper"},
	{"source": "res://assets/models/town/Market_Stall/Market_Stall.glb", "prefab": "res://scenes/prefabs/models/Market_Stall/Market_Stall.tscn", "root": "Market_Stall"},
	{"source": "res://assets/models/town/Roof/Roof01.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof01.tscn", "root": "Roof01"},
	{"source": "res://assets/models/town/Roof/Roof02.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof02.tscn", "root": "Roof02"},
	{"source": "res://assets/models/town/Roof/Roof03.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof03.tscn", "root": "Roof03"},
	{"source": "res://assets/models/town/Roof/Roof04.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof04.tscn", "root": "Roof04"},
	{"source": "res://assets/models/town/Roof/Roof05.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof05.tscn", "root": "Roof05"},
	{"source": "res://assets/models/town/Roof/Roof06.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof06.tscn", "root": "Roof06"},
	{"source": "res://assets/models/town/Roof/Roof07.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof07.tscn", "root": "Roof07"},
	{"source": "res://assets/models/town/Roof/Roof08.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof08.tscn", "root": "Roof08"},
	{"source": "res://assets/models/town/Roof/Roof09.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof09.tscn", "root": "Roof09"},
	{"source": "res://assets/models/town/Roof/Roof10.glb", "prefab": "res://scenes/prefabs/models/Roof/Roof10.tscn", "root": "Roof10"},
	{"source": "res://assets/models/town/Tavern/Tavern.glb", "prefab": "res://scenes/prefabs/models/Tavern/Tavern.tscn", "root": "Tavern"},
	{"source": "res://assets/models/town/Wall/Wall_1x3.glb", "prefab": "res://scenes/prefabs/models/Wall/Wall_1x3.tscn", "root": "Wall_1x3"},
	{"source": "res://assets/models/town/Wall/Wall_2x3.glb", "prefab": "res://scenes/prefabs/models/Wall/Wall_2x3.tscn", "root": "Wall_2x3"},
]

func run(t) -> void:
	for prefab_info in PREFABS:
		_assert_prefab_wraps_model(t, prefab_info)

func _assert_prefab_wraps_model(t, prefab_info: Dictionary) -> void:
	var source_path: String = prefab_info["source"]
	var prefab_path: String = prefab_info["prefab"]
	var root_name: String = prefab_info["root"]
	t.assert_true(FileAccess.file_exists(source_path), "%s source model exists" % root_name)
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
	t.assert_equal(prefab.name, root_name, "%s prefab root name matches model name" % root_name)
	var model = prefab.get_node_or_null("Model")
	t.assert_true(model is Node3D, "%s prefab has a 3D Model child" % root_name)
	if model != null:
		t.assert_equal(_source_model_path(model), source_path, "%s Model child tracks the source GLB" % root_name)
	prefab.free()

func _source_model_path(model: Node) -> String:
	if model.scene_file_path != "":
		return model.scene_file_path
	var metadata: Variant = model.get_meta("source_model_path", "")
	return metadata if metadata is String else ""
