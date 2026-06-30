extends RefCounted


# NOTE: class_names from addon scripts are NOT available at compile time in
# headless tests. Always use load() + .new() pattern to reference addon scripts.


func run(t) -> void:
	var ScannerScript = load("res://addons/asset_placer/scripts/asset_scanner.gd")
	var PlacerScript = load("res://addons/asset_placer/scripts/asset_placer.gd")

	if ScannerScript:
		_test_scanner_exists(t)
		_test_scanner_scan_props(t, ScannerScript)
		_test_scanner_glb_detection(t, ScannerScript)

	if PlacerScript:
		_test_placer_state(t, PlacerScript)


func _test_scanner_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/asset_placer/scripts/asset_scanner.gd"),
		"AssetScanner script should exist"
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
