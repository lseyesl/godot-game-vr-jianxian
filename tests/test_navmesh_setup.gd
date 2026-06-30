extends RefCounted

func run(t) -> void:
	# Test that Main.tscn has NavigationRegion3D for terrain
	var scene_path := "res://scenes/main/Main.tscn"
	t.assert_true(ResourceLoader.exists(scene_path), "Main.tscn exists")
	if not ResourceLoader.exists(scene_path):
		return
	var main_scene := load(scene_path) as PackedScene
	t.assert_true(main_scene != null, "Main.tscn is a valid PackedScene")
	if main_scene == null:
		return
	var main := main_scene.instantiate()
	t.assert_true(main != null, "Main.tscn instantiates")
	if main == null:
		return

	# Find NavigationRegion3D in TerrainContainer
	var terrain_container := main.get_node_or_null("TerrainContainer") as Node3D
	t.assert_true(terrain_container != null, "TerrainContainer exists")
	if terrain_container == null:
		main.free()
		return

	var nav_regions: Array = []
	for child in terrain_container.get_children():
		if child is NavigationRegion3D:
			nav_regions.append(child)
	t.assert_true(nav_regions.size() >= 1, "TerrainContainer has at least 1 NavigationRegion3D")

	if nav_regions.size() > 0:
		var nav_region := nav_regions[0] as NavigationRegion3D
		t.assert_true(nav_region.navigation_mesh != null, "NavigationRegion3D has navigation_mesh")
		if nav_region.navigation_mesh:
			t.assert_true(absf(nav_region.navigation_mesh.agent_radius - 0.3) < 0.001, "NavMesh agent_radius ~0.3")
			t.assert_true(absf(nav_region.navigation_mesh.agent_height - 1.55) < 0.001, "NavMesh agent_height ~1.55")

	# Test Town.tscn has NavigationRegion3D
	var town_path := "res://scenes/town/Town.tscn"
	if ResourceLoader.exists(town_path):
		var town_scene := load(town_path) as PackedScene
		if town_scene != null:
			var town := town_scene.instantiate()
			if town != null:
				var ground_nav := town.get_node_or_null("TownGroundNav") as NavigationRegion3D
				if ground_nav:
					t.assert_true(ground_nav.navigation_mesh != null, "TownGroundNav has navigation_mesh")
					if ground_nav.navigation_mesh:
						t.assert_true(absf(ground_nav.navigation_mesh.agent_radius - 0.3) < 0.001, "Town navmesh agent_radius ~0.3")
				town.free()

	main.free()
