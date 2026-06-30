# Asset Placer Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Godot 4.6+ editor plugin that lists prefab assets in a bottom panel and lets users click to place them in the 3D viewport.

**Architecture:** Standard Godot EditorPlugin with `_forward_3d_gui_input` for viewport click interception. A bottom panel (Control) for asset browsing. Separate scanner, preview, and placer modules.

**Tech Stack:** GDScript, Godot 4.6+ EditorPlugin API

**Spec:** `docs/superpowers/specs/2026-06-30-asset-placer-plugin-design.md`

## Global Constraints

- All source files under `addons/asset_placer/`
- GDScript only (no C#)
- Compatible with Godot 4.6+
- File names: PascalCase for scripts
- Must pass: `godot --headless --xr-mode off --path . --check-only --quit`
- Tests `extends RefCounted` with `run(t)` method, registered in `tests/test_runner.gd`
- Type safety: typed @onready var, no suppressed errors

## File Structure

### New files:
```
addons/asset_placer/
├── plugin.cfg
├── plugin.gd
├── icons/icon.png
├── panels/
│   ├── asset_browser_panel.tscn
│   └── asset_browser_panel.gd
└── scripts/
    ├── asset_scanner.gd
    ├── asset_placer.gd
    └── ghost_preview.gd

tests/test_asset_placer.gd
```

### Modified files:
```
tests/test_runner.gd
```

### Interface contracts:

| Component | Exports | Consumes |
|---|---|---|
| `AssetScanner` | `PrefabEntry[]` | File system paths |
| `AssetBrowserPanel` | signals: `prefab_selected(path)`, `start_placing(path)`, `stop_placing()` | `PrefabEntry[]` |
| `AssetPlacer` | `handle_input(camera, event) -> int` | Prefab path, Camera3D |
| `GhostPreview` | `show_at(pos, normal)`, `hide_preview()` | PackedScene |
| `plugin.gd` | EditorPlugin lifecycle | Wires all components |

---

### Task 1: Plugin scaffold

**Files:**
- Create: `addons/asset_placer/plugin.cfg`
- Create: `addons/asset_placer/plugin.gd`
- Create: `addons/asset_placer/icons/icon.png`

- [ ] **Step 1: Create directories**

```
mkdir -p addons/asset_placer/icons addons/asset_placer/panels addons/asset_placer/scripts
```

- [ ] **Step 2: Create plugin.cfg**

```
[plugin]
name="Asset Placer"
description="Browse and place prefab assets in the 3D viewport"
author="Project"
version="1.0"
script="plugin.gd"
```

- [ ] **Step 3: Create plugin.gd skeleton**

```gdscript
@tool
extends EditorPlugin

const PANEL_NAME := "Asset Placer"

var bottom_panel: Control


func _enter_tree() -> void:
	bottom_panel = Panel.new()
	bottom_panel.custom_minimum_size = Vector2(0, 200)
	add_control_to_bottom_panel(bottom_panel, PANEL_NAME)


func _exit_tree() -> void:
	if bottom_panel:
		remove_control_from_bottom_panel(bottom_panel)
		bottom_panel.queue_free()
		bottom_panel = null
```

- [ ] **Step 4: Verify syntax**

```
godot --headless --xr-mode off --path . --check-only --quit
```

---

### Task 2: AssetScanner

**Files:**
- Create: `addons/asset_placer/scripts/asset_scanner.gd`

- [ ] **Step 1: Create AssetScanner**

```gdscript
class_name AssetScanner
extends RefCounted


class PrefabEntry:
	var name: String
	var path: String
	var category: String
	var subcategory: String
	var has_glb: bool

	func _init(p_name: String, p_path: String, p_category: String, p_subcategory: String, p_has_glb: bool) -> void:
		name = p_name
		path = p_path
		category = p_category
		subcategory = p_subcategory
		has_glb = p_has_glb


var scan_paths: Array[String] = ["res://scenes/prefabs/"]


func scan() -> Array[PrefabEntry]:
	var result: Array[PrefabEntry] = []
	for dir_path in scan_paths:
		_scan_directory(dir_path, "", result)
	return result


func _scan_directory(dir_path: String, parent_category: String, result: Array[PrefabEntry]) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		var full_path := dir_path.path_join(entry_name)
		if dir.current_is_dir():
			if not entry_name.begins_with("."):
				var cat := entry_name if parent_category.is_empty() else parent_category + "/" + entry_name
				_scan_directory(full_path, cat, result)
		elif entry_name.ends_with(".tscn"):
			_parse_prefab(full_path, parent_category, result)
		entry_name = dir.get_next()
	dir.list_dir_end()


func _parse_prefab(full_path: String, category: String, result: Array[PrefabEntry]) -> void:
	var name := full_path.get_file().trim_suffix(".tscn")
	var main_category := category
	var subcategory := ""

	var parts := full_path.trim_prefix("res://").split("/")
	if parts.size() >= 4:
		main_category = parts[2]
		var sub_parts := parts.slice(3, -1)
		if sub_parts.size() > 0:
			subcategory = "/".join(sub_parts)

	var has_glb := _detect_glb_reference(full_path)
	result.append(PrefabEntry.new(name, full_path, main_category, subcategory, has_glb))


func _detect_glb_reference(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var content := file.get_as_text()
	file.close()
	return content.contains(".glb")
```

- [ ] **Step 2: Verify syntax**

```
godot --headless --xr-mode off --path . --check-only --quit
```

---

### Task 3: GhostPreview

**Files:**
- Create: `addons/asset_placer/scripts/ghost_preview.gd`

- [ ] **Step 1: Create GhostPreview**

```gdscript
class_name GhostPreview
extends Node3D


var source_scene: PackedScene:
	set(value):
		source_scene = value
		_rebuild_preview()


func _rebuild_preview() -> void:
	for child in get_children():
		child.queue_free()

	if not source_scene:
		return

	var instance := source_scene.instantiate()
	add_child(instance)
	_make_transparent(instance, 0.35)


func _make_transparent(node: Node, alpha: float) -> void:
	for child in node.get_children(false):
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.mesh:
				for i in mi.mesh.get_surface_count():
					var mat := mi.mesh.surface_get_material(i)
					if mat and mat is BaseMaterial3D:
						var ghost_mat := mat.duplicate() as BaseMaterial3D
						ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						ghost_mat.albedo_color.a = alpha
						ghost_mat.disable_ambient_light = true
						mi.set_surface_override_material(i, ghost_mat)
		_make_transparent(child, alpha)


func show_at(position: Vector3, normal: Vector3 = Vector3.UP) -> void:
	global_position = position
	visible = true


func hide_preview() -> void:
	visible = false
```

- [ ] **Step 2: Verify syntax**

```
godot --headless --xr-mode off --path . --check-only --quit
```

---

### Task 4: AssetBrowserPanel UI

**Files:**
- Create: `addons/asset_placer/panels/asset_browser_panel.gd`
- Create: `addons/asset_placer/panels/asset_browser_panel.tscn`
- Modify: `addons/asset_placer/plugin.gd` (wire panel)

- [ ] **Step 1: Create panel script**

```gdscript
class_name AssetBrowserPanel
extends Control


signal prefab_selected(path: String)
signal start_placing(path: String)
signal stop_placing()


var scanner: AssetScanner:
	set(value):
		scanner = value
		_refresh_list()

var _all_entries: Array[AssetScanner.PrefabEntry] = []
var _filtered_entries: Array[AssetScanner.PrefabEntry] = []
var _current_category: String = ""
var _selected_path: String = ""

@onready var _search_box: LineEdit = %SearchBox
@onready var _category_filter: OptionButton = %CategoryFilter
@onready var _prefab_list: ItemList = %PrefabList
@onready var _status_label: Label = %StatusLabel
@onready var _place_btn: Button = %PlaceButton


func _ready() -> void:
	_place_btn.disabled = true
	_place_btn.toggle_mode = true
	_place_btn.text = "放置"

	_search_box.text_changed.connect(_on_search_changed)
	_category_filter.item_selected.connect(_on_category_selected)
	_prefab_list.item_selected.connect(_on_prefab_selected)
	_prefab_list.item_activated.connect(_on_prefab_activated)
	_place_btn.toggled.connect(_on_place_toggled)


func _refresh_list() -> void:
	if not scanner:
		return
	_all_entries = scanner.scan()
	_build_category_filter()
	_apply_filters()


func _build_category_filter() -> void:
	_category_filter.clear()
	_category_filter.add_item("全部", 0)
	var categories: Array[String] = []
	for entry in _all_entries:
		if entry.category not in categories:
			categories.append(entry.category)
	categories.sort()
	for cat in categories:
		_category_filter.add_item(cat)


func _apply_filters() -> void:
	var search_text := _search_box.text.strip_edges().to_lower()
	_filtered_entries = []
	for entry in _all_entries:
		if _current_category != "" and entry.category != _current_category:
			continue
		if search_text != "" and not entry.name.to_lower().contains(search_text):
			continue
		_filtered_entries.append(entry)

	_prefab_list.clear()
	for entry in _filtered_entries:
		var label := entry.name
		if entry.subcategory != "":
			label += "  [" + entry.subcategory + "]"
		_prefab_list.add_item(label)

	_status_label.text = "共 %d 个预制体，显示 %d 个" % [_all_entries.size(), _filtered_entries.size()]


func _on_search_changed(_new_text: String) -> void:
	_apply_filters()


func _on_category_selected(index: int) -> void:
	if index == 0:
		_current_category = ""
	else:
		_current_category = _category_filter.get_item_text(index)
	_apply_filters()


func _on_prefab_selected(index: int) -> void:
	if index < 0 or index >= _filtered_entries.size():
		return
	_selected_path = _filtered_entries[index].path
	_place_btn.disabled = false
	prefab_selected.emit(_selected_path)


func _on_prefab_activated(index: int) -> void:
	_on_prefab_selected(index)
	if _selected_path != "":
		_place_btn.button_pressed = true
		start_placing.emit(_selected_path)


func _on_place_toggled(button_pressed: bool) -> void:
	if button_pressed and _selected_path != "":
		start_placing.emit(_selected_path)
	else:
		stop_placing.emit()
```

- [ ] **Step 2: Create the panel scene**

```gdscene
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/asset_placer/panels/asset_browser_panel.gd" id="1"]

[node name="AssetBrowserPanel" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="HBox" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="LeftPanel" type="VBoxContainer" parent="HBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Toolbar" type="HBoxContainer" parent="HBox/LeftPanel"]
layout_mode = 2

[node name="SearchBox" type="LineEdit" parent="HBox/LeftPanel/Toolbar"]
layout_mode = 2
size_flags_horizontal = 3
placeholder_text = "搜索预制体..."
unique_name_in_owner = true

[node name="CategoryFilter" type="OptionButton" parent="HBox/LeftPanel/Toolbar"]
layout_mode = 2
unique_name_in_owner = true

[node name="PrefabList" type="ItemList" parent="HBox/LeftPanel"]
layout_mode = 2
size_flags_vertical = 3
unique_name_in_owner = true

[node name="StatusLabel" type="Label" parent="HBox/LeftPanel"]
layout_mode = 2
unique_name_in_owner = true

[node name="RightPanel" type="VBoxContainer" parent="HBox"]
layout_mode = 2
size_flags_horizontal = 1

[node name="SelectedLabel" type="Label" parent="HBox/RightPanel"]
layout_mode = 2
text = "选中："

[node name="PlaceButton" type="Button" parent="HBox/RightPanel"]
layout_mode = 2
unique_name_in_owner = true
```

- [ ] **Step 3: Update plugin.gd to use the panel**

```gdscript
@tool
extends EditorPlugin

const PANEL_NAME := "Asset Placer"

var bottom_panel: Control
var browser_panel: AssetBrowserPanel
var scanner: AssetScanner


func _enter_tree() -> void:
	scanner = AssetScanner.new()

	var panel_scene := load("res://addons/asset_placer/panels/asset_browser_panel.tscn") as PackedScene
	bottom_panel = panel_scene.instantiate() as Control
	browser_panel = bottom_panel as AssetBrowserPanel
	browser_panel.scanner = scanner

	add_control_to_bottom_panel(bottom_panel, PANEL_NAME)


func _exit_tree() -> void:
	if bottom_panel:
		remove_control_from_bottom_panel(bottom_panel)
		bottom_panel.queue_free()
		bottom_panel = null
		browser_panel = null
	scanner = null
```

- [ ] **Step 4: Verify syntax**

```
godot --headless --xr-mode off --path . --check-only --quit
```

---

### Task 5: AssetPlacer + full integration

**Files:**
- Create: `addons/asset_placer/scripts/asset_placer.gd`
- Modify: `addons/asset_placer/plugin.gd` (wire placer + forward_3d_gui_input)

- [ ] **Step 1: Create AssetPlacer**

```gdscript
class_name AssetPlacer
extends RefCounted


enum State { IDLE, PLACING }

var state: int = State.IDLE
var active_prefab_path: String = ""
var _ghost: GhostPreview


func enter_placing_mode(prefab_path: String) -> void:
	state = State.PLACING
	active_prefab_path = prefab_path

	if not _ghost:
		_ghost = GhostPreview.new()

	var prefab := load(prefab_path) as PackedScene
	if prefab:
		_ghost.source_scene = prefab

	var root := EditorInterface.get_edited_scene_root()
	if root and not _ghost.is_inside_tree():
		root.add_child(_ghost)
		_ghost.show_at(Vector3.ZERO)


func exit_placing_mode() -> void:
	state = State.IDLE
	active_prefab_path = ""
	if _ghost:
		_ghost.hide_preview()


func is_placing() -> bool:
	return state == State.PLACING


func handle_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if state != State.PLACING:
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventMouseMotion:
		_update_ghost(viewport_camera, event.position)
		return EditorPlugin.AFTER_GUI_INPUT_STOP

	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_place(viewport_camera, event.position)
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			MOUSE_BUTTON_RIGHT:
				exit_placing_mode()
				return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _update_ghost(camera: Camera3D, mouse_pos: Vector2) -> void:
	var result := _raycast(camera, mouse_pos)
	if result.is_empty():
		_ghost.hide_preview()
		return
	_ghost.show_at(result.position, result.normal)


func _raycast(camera: Camera3D, mouse_pos: Vector2) -> Dictionary:
	var space := camera.get_world_3d().direct_space_state
	if not space:
		return {}

	var origin := camera.project_ray_origin(mouse_pos)
	var normal := camera.project_ray_normal(mouse_pos)
	var end := origin + normal * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	if _ghost:
		query.exclude = [_ghost]
	return space.intersect_ray(query)


func _place(camera: Camera3D, mouse_pos: Vector2) -> void:
	var result := _raycast(camera, mouse_pos)
	if result.is_empty():
		return

	var prefab := load(active_prefab_path) as PackedScene
	if not prefab:
		return

	var instance := prefab.instantiate() as Node3D
	if not instance:
		return

	instance.global_position = result.position

	var root := EditorInterface.get_edited_scene_root()
	if not root:
		instance.queue_free()
		return

	root.add_child(instance, true)
	instance.owner = root

	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(instance)
```

- [ ] **Step 2: Update plugin.gd to wire everything**

```gdscript
@tool
extends EditorPlugin

const PANEL_NAME := "Asset Placer"

var bottom_panel: Control
var browser_panel: AssetBrowserPanel
var scanner: AssetScanner
var placer: AssetPlacer


func _enter_tree() -> void:
	scanner = AssetScanner.new()
	placer = AssetPlacer.new()

	var panel_scene := load("res://addons/asset_placer/panels/asset_browser_panel.tscn") as PackedScene
	bottom_panel = panel_scene.instantiate() as Control
	browser_panel = bottom_panel as AssetBrowserPanel
	browser_panel.scanner = scanner
	browser_panel.start_placing.connect(_on_start_placing)
	browser_panel.stop_placing.connect(_on_stop_placing)

	add_control_to_bottom_panel(bottom_panel, PANEL_NAME)


func _exit_tree() -> void:
	if bottom_panel:
		remove_control_from_bottom_panel(bottom_panel)
		bottom_panel.queue_free()
		bottom_panel = null
		browser_panel = null

	placer = null
	scanner = null


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if placer and placer.is_placing():
		return placer.handle_input(viewport_camera, event)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _on_start_placing(path: String) -> void:
	placer.enter_placing_mode(path)


func _on_stop_placing() -> void:
	placer.exit_placing_mode()
```

- [ ] **Step 3: Verify syntax**

```
godot --headless --xr-mode off --path . --check-only --quit
```

---

### Task 6: Tests

**Files:**
- Create: `tests/test_asset_placer.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Create test file**

```gdscript
extends RefCounted


func run(t) -> void:
	_test_scanner_exists(t)
	_test_scanner_scan_props(t)
	_test_scanner_glb_detection(t)
	_test_ghost_preview_exists(t)
	_test_asset_placer_exists(t)


func _test_scanner_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/asset_placer/scripts/asset_scanner.gd"),
		"AssetScanner script should exist"
	)


func _test_scanner_scan_props(t) -> void:
	var scanner := AssetScanner.new()
	scanner.scan_paths = ["res://scenes/prefabs/props/"]
	var entries := scanner.scan()
	t.assert_true(entries.size() >= 6, "props directory should have at least 6 prefabs, got %d" % entries.size())

	if entries.size() > 0:
		var entry := entries[0]
		t.assert_true(entry.name.length() > 0, "entry name should not be empty")
		t.assert_true(entry.path.begins_with("res://"), "entry path should start with res://")
		t.assert_true(entry.category.length() > 0, "entry category should not be empty")


func _test_scanner_glb_detection(t) -> void:
	var scanner := AssetScanner.new()
	scanner.scan_paths = ["res://scenes/prefabs/models/props/lantern_01/"]
	var entries := scanner.scan()
	if entries.size() > 0:
		t.assert_true(entries[0].has_glb, "lantern_01.tscn should reference a .glb")


func _test_ghost_preview_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/asset_placer/scripts/ghost_preview.gd"),
		"GhostPreview script should exist"
	)


func _test_asset_placer_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/asset_placer/scripts/asset_placer.gd"),
		"AssetPlacer script should exist"
	)
```

- [ ] **Step 2: Register in test_runner.gd**

Add `"res://tests/test_asset_placer.gd"` to the `test_paths` array in `tests/test_runner.gd`.

- [ ] **Step 3: Run tests**

```
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: PASS

---

### Task 7: Final verification

- [ ] **Step 1: Syntax check**

```
godot --headless --xr-mode off --path . --check-only --quit
```
Expected: exit code 0

- [ ] **Step 2: Run all tests**

```
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: "TESTS PASSED: N assertions"
