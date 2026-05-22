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
	_test_npc_logic_nodes(t, town)
	town.free()

func _test_showcase_models(t, town: Node) -> void:
	t.assert_true(town.has_node("Inn/InnModel"), "Inn model is placed in town")
	t.assert_true(town.has_node("Tavern/TavernModel"), "Tavern model is placed in town")
	t.assert_true(town.has_node("MarketStreet/StallCenter"), "Center market stall is placed in town")
	t.assert_true(town.has_node("MarketStreet/StallLeft"), "Left market stall is placed in town")
	t.assert_true(town.has_node("MarketStreet/StallRight"), "Right market stall is placed in town")
	t.assert_equal(town.get_node("Inn").position, Vector3(-5, 0, -6), "Inn is in first-view showcase position")
	t.assert_equal(town.get_node("Tavern").position, Vector3(5, 0, -6), "Tavern is in first-view showcase position")
	t.assert_equal(town.get_node("MarketStreet").position, Vector3(0, 0, -2), "Market street anchors showcase stalls")

func _test_npc_logic_nodes(t, town: Node) -> void:
	t.assert_true(town.has_node("Inn/Innkeeper"), "Innkeeper NPC remains under Inn")
	t.assert_true(town.has_node("Tavern/TavernKeeper"), "TavernKeeper NPC remains under Tavern")
	var innkeeper = town.get_node("Inn/Innkeeper")
	var tavern_keeper = town.get_node("Tavern/TavernKeeper")
	t.assert_equal(innkeeper.npc_id, "innkeeper", "Innkeeper quest id remains intact")
	t.assert_equal(tavern_keeper.npc_id, "tavern_keeper", "TavernKeeper quest id remains intact")
	t.assert_true(town.has_node("Inn/Innkeeper/Body/InnkeeperModel"), "Innkeeper visual model is attached to NPC body")
	t.assert_equal(town.get_node("ReturnToTownTrigger").position, Vector3(0, 3, 10), "Return trigger stays outside the showcase plaza")
