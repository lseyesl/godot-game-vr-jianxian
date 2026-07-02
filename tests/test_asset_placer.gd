extends RefCounted


# NOTE: class_names from addon scripts are NOT available at compile time in
# headless tests. Always use load() + .new() pattern to reference addon scripts.


func run(t) -> void:
	var ScannerScript = load("res://addons/asset_placer/scripts/asset_scanner.gd")
	var PlacerScript = load("res://addons/asset_placer/scripts/asset_placer.gd")

	_test_plugin_enables_viewport_input_forwarding(t)

	if ScannerScript:
		_test_scanner_exists(t)
		_test_scanner_scan_props(t, ScannerScript)
		_test_scanner_glb_detection(t, ScannerScript)
		_test_panel_accepts_scanner_before_ready(t, ScannerScript)

	if PlacerScript:
		_test_placer_state(t, PlacerScript)
		_test_placer_ground_plane_intersection(t, PlacerScript)


func _test_scanner_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/asset_placer/scripts/asset_scanner.gd"),
		"AssetScanner script should exist"
	)


func _test_plugin_enables_viewport_input_forwarding(t) -> void:
	var plugin_path := "res://addons/asset_placer/plugin.gd"
	t.assert_true(FileAccess.file_exists(plugin_path), "Asset Placer plugin script should exist")
	var file := FileAccess.open(plugin_path, FileAccess.READ)
	if not file:
		return
	var content := file.get_as_text()
	file.close()
	t.assert_true(
		content.contains("set_input_event_forwarding_always_enabled"),
		"Asset Placer should always receive 3D viewport input while placing"
	)


func _test_scanner_scan_props(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	scanner.scan_paths = ["res://scenes/prefabs/props/"]
	var entries = scanner.scan()
	t.assert_true(entries.size() >= 6, "props directory should have at least 6 prefabs, got %d" % entries.size())

	if entries.size() > 0:
		var entry = entries[0]
		t.assert_true(entry.name.length() > 0, "entry name should not be empty")
		t.assert_true(entry.path.begins_with("res://"), "entry path should start with res://")
		t.assert_true(entry.category.length() > 0, "entry category should not be empty")


func _test_scanner_glb_detection(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	scanner.scan_paths = ["res://scenes/prefabs/models/props/lantern_01/"]
	var entries = scanner.scan()
	if entries.size() > 0:
		t.assert_true(entries[0].has_glb, "lantern_01.tscn should reference a .glb")


func _test_placer_state(t, PlacerScript) -> void:
	var placer = PlacerScript.new()
	t.assert_true(placer != null, "AssetPlacer should instantiate")
	t.assert_true(not placer.is_placing(), "new placer should be idle")
	t.assert_equal(placer.state, 0, "default state should be IDLE (0)")


func _test_panel_accepts_scanner_before_ready(t, ScannerScript) -> void:
	var panel_scene := load("res://addons/asset_placer/panels/asset_browser_panel.tscn") as PackedScene
	t.assert_true(panel_scene != null, "AssetBrowserPanel scene should load")
	if panel_scene == null:
		return

	var panel := panel_scene.instantiate() as Control
	t.assert_true(panel != null, "AssetBrowserPanel root should be Control")
	if panel == null:
		return

	var scanner = ScannerScript.new()
	panel.scanner = scanner
	t.assert_equal(panel.scanner, scanner, "AssetBrowserPanel should accept scanner before ready")

	panel.free()


func _test_placer_ground_plane_intersection(t, PlacerScript) -> void:
	var placer = PlacerScript.new()
	t.assert_true(
		placer.has_method("_intersect_ground_plane"),
		"AssetPlacer should provide ground-plane fallback intersection"
	)
	if not placer.has_method("_intersect_ground_plane"):
		return

	var result: Dictionary = placer._intersect_ground_plane(Vector3(0, 10, 0), Vector3(0, -1, 0))
	t.assert_true(not result.is_empty(), "downward ray should hit y=0 ground plane")
	t.assert_equal(result.position, Vector3.ZERO, "ground-plane hit should be at origin")
	t.assert_equal(result.normal, Vector3.UP, "ground-plane normal should face up")

	var parallel: Dictionary = placer._intersect_ground_plane(Vector3(0, 10, 0), Vector3.RIGHT)
	t.assert_true(parallel.is_empty(), "parallel ray should not hit y=0 ground plane")
