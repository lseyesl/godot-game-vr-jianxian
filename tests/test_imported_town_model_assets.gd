extends RefCounted

const IMPORTED_PREFABS := [
	{
		"source": "res://assets/models/town/WealthyResidence/WealthyResidence.glb",
		"prefab": "res://scenes/prefabs/models/WealthyResidence/WealthyResidence.tscn",
		"root": "WealthyResidence",
	},
	{
		"source": "res://assets/models/town/StoneBridge/StoneBridge01.glb",
		"prefab": "res://scenes/prefabs/models/StoneBridge/StoneBridge01.tscn",
		"root": "StoneBridge01",
	},
	{
		"source": "res://assets/models/town/StoneBridge/StoneBridge02.glb",
		"prefab": "res://scenes/prefabs/models/StoneBridge/StoneBridge02.tscn",
		"root": "StoneBridge02",
	},
	{
		"source": "res://assets/models/town/StoneBridge/StoneBridge03.glb",
		"prefab": "res://scenes/prefabs/models/StoneBridge/StoneBridge03.tscn",
		"root": "StoneBridge03",
	},
	{
		"source": "res://assets/models/town/StoneBridge/StoneBridge04.glb",
		"prefab": "res://scenes/prefabs/models/StoneBridge/StoneBridge04.tscn",
		"root": "StoneBridge04",
	},
	{
		"source": "res://assets/models/town/TownHouse/TownHouse.glb",
		"prefab": "res://scenes/prefabs/models/TownHouse/TownHouse.tscn",
		"root": "TownHouse",
	},
	{
		"source": "res://assets/models/town/WaterWheel/WaterWheel.glb",
		"prefab": "res://scenes/prefabs/models/WaterWheel/WaterWheel.tscn",
		"root": "WaterWheel",
	},
	{
		"source": "res://assets/models/town/RiverBoat/RiverBoat.glb",
		"prefab": "res://scenes/prefabs/models/RiverBoat/RiverBoat.tscn",
		"root": "RiverBoat",
	},
	{
		"source": "res://assets/models/town/BellDrumTower/BellDrumTower01.glb",
		"prefab": "res://scenes/prefabs/models/BellDrumTower/BellDrumTower01.tscn",
		"root": "BellDrumTower01",
	},
	{
		"source": "res://assets/models/town/BellDrumTower/BellDrumTower02.glb",
		"prefab": "res://scenes/prefabs/models/BellDrumTower/BellDrumTower02.tscn",
		"root": "BellDrumTower02",
	},
]

const CONCEPT_ART_PATHS := [
	"res://docs/concept-art/WealthyResidenceConcept.png",
	"res://docs/concept-art/StoneBridgeConcept.png",
	"res://docs/concept-art/TownHouseConcept.png",
	"res://docs/concept-art/WaterWheelConcept.png",
	"res://docs/concept-art/RiverBoatConcept.png",
	"res://docs/concept-art/BellDrumTowerConcept.png",
]

func run(t) -> void:
	for concept_path in CONCEPT_ART_PATHS:
		t.assert_true(FileAccess.file_exists(concept_path), "%s concept art exists" % concept_path.get_file())
	for prefab_info in IMPORTED_PREFABS:
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
	t.assert_equal(prefab.name, root_name, "%s prefab root name matches" % root_name)
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
