extends RefCounted

# NOTE: class_names from addon scripts are NOT available at compile time in
# headless tests. Always use load() + .new() pattern to reference addon scripts.
#
# NOTE: test runner provides assert_true(value, msg) and assert_equal(actual, expected, msg).
# There is NO assert_false — use assert_true(not val, msg) instead.


func run(t) -> void:
	var ScannerScript = load("res://addons/prefab_inspector/scripts/prefab_scanner.gd")

	if ScannerScript:
		_test_scanner_exists(t)
		_test_scanner_scan_counts(t, ScannerScript)
		_test_glb_detection(t, ScannerScript)
		_test_collision_detection(t, ScannerScript)
		_test_script_detection(t, ScannerScript)
		_test_material_detection(t, ScannerScript)
		_test_audio_detection(t, ScannerScript)
		_test_particles_detection(t, ScannerScript)
		_test_root_type_extraction(t, ScannerScript)
		_test_root_name_matching(t, ScannerScript)
		_test_panel_accepts_scanner_before_ready(t, ScannerScript)

	_test_panel_exists(t)


func _test_scanner_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/prefab_inspector/scripts/prefab_scanner.gd"),
		"PrefabInspectorScanner script should exist"
	)


func _test_scanner_scan_counts(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	var entries = scanner.scan()
	t.assert_true(entries.size() >= 50,
		"should find at least 50 prefabs, got %d" % entries.size())
	for entry in entries:
		t.assert_true(entry.name.length() > 0, "entry name should not be empty: " + entry.path)
		t.assert_true(entry.path.begins_with("res://"), "entry path should start with res://: " + entry.path)


func _test_glb_detection(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	var content_has := '[ext_resource type="PackedScene" path="res://assets/models/props/lantern_01/lantern_01.glb" id="1"]'
	t.assert_true(scanner._detect_glb(content_has), "should detect .glb reference")
	t.assert_true(not scanner._detect_glb("no glb here"), "should NOT detect glb when absent")


func _test_collision_detection(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	t.assert_true(scanner._detect_collision("type=\"CollisionShape3D\""), "CollisionShape3D")
	t.assert_true(scanner._detect_collision("type=\"CollisionPolygon3D\""), "CollisionPolygon3D")
	t.assert_true(not scanner._detect_collision("no collision here"), "no collision")


func _test_script_detection(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	t.assert_true(scanner._detect_script('script = ExtResource("1")'), "script attachment")
	t.assert_true(not scanner._detect_script("no script here"), "no script")


func _test_material_detection(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	t.assert_true(scanner._detect_material_override("surface_material_override"), "material override")
	t.assert_true(not scanner._detect_material_override("no override here"), "no override")


func _test_audio_detection(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	t.assert_true(scanner._detect_audio("type=\"AudioStreamPlayer3D\""), "audio player")
	t.assert_true(not scanner._detect_audio("no audio here"), "no audio")


func _test_particles_detection(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	t.assert_true(scanner._detect_particles("type=\"GPUParticles3D\""), "GPU particles")
	t.assert_true(scanner._detect_particles("type=\"CPUParticles3D\""), "CPU particles")
	t.assert_true(not scanner._detect_particles("no particles"), "no particles")


func _test_root_type_extraction(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	var content := '[node name="lantern_01" type="Node3D"]\n'
	t.assert_equal(scanner._extract_root_type(content), "Node3D", "root type Node3D")

	content = '[node name="WorldBoundary" type="StaticBody3D"]\n'
	t.assert_equal(scanner._extract_root_type(content), "StaticBody3D", "root type StaticBody3D")

	t.assert_equal(scanner._extract_root_type("no node here"), "", "no root found")


func _test_root_name_matching(t, ScannerScript) -> void:
	var scanner = ScannerScript.new()
	var content := '[node name="lantern_01" type="Node3D"]\n'
	t.assert_true(scanner._check_root_name_matches(content, "lantern_01"), "name matches")
	t.assert_true(not scanner._check_root_name_matches(content, "wrong_name"), "name mismatch")


func _test_panel_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/prefab_inspector/panels/inspector_panel.tscn"),
		"InspectorPanel scene should exist"
	)


func _test_panel_accepts_scanner_before_ready(t, ScannerScript) -> void:
	var panel_scene := load("res://addons/prefab_inspector/panels/inspector_panel.tscn") as PackedScene
	t.assert_true(panel_scene != null, "InspectorPanel scene should load")
	if panel_scene == null:
		return

	var panel := panel_scene.instantiate() as Control
	t.assert_true(panel != null, "InspectorPanel root should be Control")
	if panel == null:
		return

	var scanner = ScannerScript.new()
	panel.scanner = scanner
	t.assert_equal(panel.scanner, scanner, "InspectorPanel should accept scanner before ready")

	panel.free()
