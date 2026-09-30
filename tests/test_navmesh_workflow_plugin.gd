extends RefCounted

# NOTE: class_names from addon scripts are NOT available at compile time in
# headless tests. Always use load() + .new() pattern to reference addon scripts.
#
# NOTE: test runner provides assert_true(value, msg) and assert_equal(actual, expected, msg).
# There is NO assert_false — use assert_true(not val, msg) instead.
#
# This plugin is @tool + editor-only. We can verify files exist and parse
# correctly, but cannot instantiate UI nodes in headless mode.


func run(t) -> void:
	_test_plugin_config_exists(t)
	_test_plugin_config_valid(t)
	_test_plugin_script_exists(t)
	_test_panel_script_exists(t)
	_test_panel_scene_exists(t)


func _test_plugin_config_exists(t) -> void:
	var path := "res://addons/navmesh_workflow/plugin.cfg"
	t.assert_true(FileAccess.file_exists(path), "NavMesh Workflow plugin config file exists")


func _test_plugin_config_valid(t) -> void:
	var path := "res://addons/navmesh_workflow/plugin.cfg"
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	t.assert_equal(err, OK, "NavMesh Workflow plugin config parses as valid ConfigFile")
	if err == OK:
		t.assert_true(cfg.has_section("plugin"), "plugin.cfg has [plugin] section")
		t.assert_true(cfg.has_section_key("plugin", "name"), "plugin.cfg has plugin.name")
		t.assert_true(cfg.has_section_key("plugin", "script"), "plugin.cfg has plugin.script")
		t.assert_equal(cfg.get_value("plugin", "script"), "plugin.gd", "plugin.cfg script points to plugin.gd")


func _test_plugin_script_exists(t) -> void:
	var path := "res://addons/navmesh_workflow/plugin.gd"
	t.assert_true(ResourceLoader.exists(path), "NavMesh Workflow plugin.gd resource exists")
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	t.assert_true(script != null, "NavMesh Workflow plugin.gd script loads")
	t.assert_true(script is GDScript, "NavMesh Workflow plugin.gd is a GDScript")


func _test_panel_script_exists(t) -> void:
	var path := "res://addons/navmesh_workflow/panels/workflow_panel.gd"
	t.assert_true(ResourceLoader.exists(path), "NavMesh Workflow panel script resource exists")
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	t.assert_true(script != null, "NavMesh Workflow panel script loads")
	t.assert_true(script is GDScript, "NavMesh Workflow panel script is a GDScript")


func _test_panel_scene_exists(t) -> void:
	var scene_path := "res://addons/navmesh_workflow/panels/workflow_panel.tscn"
	t.assert_true(ResourceLoader.exists(scene_path), "NavMesh Workflow panel scene exists")
	if not ResourceLoader.exists(scene_path):
		return
	var packed := load(scene_path)
	t.assert_true(packed is PackedScene, "NavMesh Workflow panel is a PackedScene")
