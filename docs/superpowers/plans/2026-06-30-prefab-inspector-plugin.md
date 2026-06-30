# Prefab Inspector Plugin — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Godot 4.6+ editor plugin that scans all prefab scenes in `scenes/prefabs/`, displays their metadata in a sortable/filterable table (collision status, GLB reference, script, material override, etc.), and allows right-click quick-fix and open-in-editor actions.

**Architecture:** Standard Godot EditorPlugin with a bottom panel using Tree control for table display. Separate scanner module for TSCN parsing and metadata extraction.

**Tech Stack:** GDScript, Godot 4.6+ EditorPlugin API

**Spec:** `docs/superpowers/specs/2026-06-30-prefab-inspector-design.md`

## Global Constraints

- All source files under `addons/prefab_inspector/`
- GDScript only (no C#)
- Compatible with Godot 4.6+
- File names: PascalCase for scripts
- Must pass: `godot --headless --xr-mode off --path . --check-only --quit`
- Tests `extends RefCounted` with `run(t)` method, registered in `tests/test_runner.gd`
- Type safety: typed @onready var, no suppressed errors
- Scanner must parse .tscn as text (string matching), NOT load scenes via ResourceLoader (avoids tool-mode execution side effects)

## File Structure

### New files:
```
addons/prefab_inspector/
├── plugin.cfg
├── plugin.gd
├── icons/icon.png
├── panels/
│   ├── inspector_panel.tscn
│   └── inspector_panel.gd
└── scripts/
    └── prefab_scanner.gd

tests/test_prefab_inspector.gd
```

### Modified files:
```
tests/test_runner.gd
```

### Interface contracts:

| Component | Exports | Consumes |
|---|---|---|
| `PrefabInspectorScanner` | `PrefabEntry[]` | File system paths, TSCN text content |
| `PrefabInspectorPanel` | signals: `prefab_selected(path)` | `PrefabEntry[]` |
| `plugin.gd` | EditorPlugin lifecycle | Wires scanner + panel |

---

### Task 1: Plugin scaffold

**Files:**
- Create: `addons/prefab_inspector/plugin.cfg`
- Create: `addons/prefab_inspector/plugin.gd`
- Create: `addons/prefab_inspector/icons/icon.png`

- [ ] **Step 1: Create directories**
```
mkdir -p addons/prefab_inspector/icons addons/prefab_inspector/panels addons/prefab_inspector/scripts
```

- [ ] **Step 2: Create plugin.cfg**
```ini
[plugin]
name="Prefab Inspector"
description="Browse and inspect prefab asset metadata in the 3D viewport"
author="Project"
version="1.0"
script="plugin.gd"
```

- [ ] **Step 3: Create plugin.gd skeleton**
```gdscript
@tool
extends EditorPlugin

const PANEL_NAME := "Prefab Inspector"

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

### Task 2: PrefabScanner

**Files:**
- Create: `addons/prefab_inspector/scripts/prefab_scanner.gd`

- [ ] **Step 1: Create PrefabInspectorScanner class**

```gdscript
class_name PrefabInspectorScanner
extends RefCounted


class PrefabEntry:
	var name: String
	var path: String
	var category: String
	var subcategory: String
	var has_glb: bool
	var has_collision: bool
	var has_script: bool
	var has_material_override: bool
	var has_audio: bool
	var has_particles: bool
	var root_type: String
	var root_matches_filename: bool
	var file_size: int
	var last_modified: int

	func _init(p_name: String, p_path: String, p_category: String, p_subcategory: String) -> void:
		name = p_name
		path = p_path
		category = p_category
		subcategory = p_subcategory


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
			_parse_tscn(full_path, parent_category, result)
		entry_name = dir.get_next()
	dir.list_dir_end()


func _parse_tscn(full_path: String, category: String, result: Array[PrefabEntry]) -> void:
	var name := full_path.get_file().trim_suffix(".tscn")
	var main_category := category
	var subcategory := ""

	var parts := full_path.trim_prefix("res://").split("/")
	if parts.size() >= 4:
		main_category = parts[2]
		var sub_parts := parts.slice(3, -1)
		if sub_parts.size() > 0:
			subcategory = "/".join(sub_parts)

	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		return
	var content := file.get_as_text()
	file.close()

	var entry := PrefabEntry.new(name, full_path, main_category, subcategory)
	entry.has_glb = _detect_glb(content)
	entry.has_collision = _detect_collision(content)
	entry.has_script = _detect_script(content)
	entry.has_material_override = _detect_material_override(content)
	entry.has_audio = _detect_audio(content)
	entry.has_particles = _detect_particles(content)
	entry.root_type = _extract_root_type(content)
	entry.root_matches_filename = _check_root_name_matches(content, name)
	entry.file_size = _get_file_size(full_path)
	entry.last_modified = _get_last_modified(full_path)

	result.append(entry)


func _detect_glb(content: String) -> bool:
	return content.contains(".glb")

func _detect_collision(content: String) -> bool:
	return content.contains("type=\"CollisionShape3D\"") \
		or content.contains("type=\"CollisionPolygon3D\"")

func _detect_script(content: String) -> bool:
	return "script = ExtResource(" in content

func _detect_material_override(content: String) -> bool:
	return "surface_material_override" in content

func _detect_audio(content: String) -> bool:
	return "type=\"AudioStreamPlayer3D\"" in content

func _detect_particles(content: String) -> bool:
	return "type=\"GPUParticles3D\"" in content \
		or "type=\"CPUParticles3D\"" in content

func _extract_root_type(content: String) -> String:
	var regex := RegEx.create_from_string("\\[node name=\"[^\"]+\" type=\"([^\"]+)\"")
	var match := regex.search(content)
	if match:
		return match.get_string(1)
	return ""

func _extract_root_name(content: String) -> String:
	var regex := RegEx.create_from_string("\\[node name=\"([^\"]+)\"")
	var match := regex.search(content)
	if match:
		return match.get_string(1)
	return ""

func _check_root_name_matches(content: String, filename: String) -> bool:
	return _extract_root_name(content) == filename

func _get_file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return 0
	var size := file.get_length()
	file.close()
	return size

func _get_last_modified(path: String) -> int:
	return FileAccess.get_modified_time(path)
```

- [ ] **Step 2: Verify syntax**
```
godot --headless --xr-mode off --path . --check-only --quit
```

---

### Task 3: InspectorPanel UI

**Files:**
- Create: `addons/prefab_inspector/panels/inspector_panel.gd`
- Create: `addons/prefab_inspector/panels/inspector_panel.tscn`
- Modify: `addons/prefab_inspector/plugin.gd` (wire panel)

- [ ] **Step 1: Create panel script**

```gdscript
class_name PrefabInspectorPanel
extends Control


signal prefab_selected(path: String)


var scanner: PrefabInspectorScanner:
	set(value):
		scanner = value
		_refresh_list()

var _all_entries: Array[PrefabInspectorScanner.PrefabEntry] = []
var _filtered_entries: Array[PrefabInspectorScanner.PrefabEntry] = []
var _current_category: String = ""
var _current_severity: String = ""
var _sort_column: int = 0
var _sort_ascending: bool = true

@onready var _search_box: LineEdit = %SearchBox
@onready var _category_filter: OptionButton = %CategoryFilter
@onready var _severity_filter: OptionButton = %SeverityFilter
@onready var _prefab_tree: Tree = %PrefabTree
@onready var _status_label: Label = %StatusLabel
@onready var _scan_btn: Button = %ScanButton


enum Columns {
	NAME = 0,
	CATEGORY,
	COLLISION,
	GLB,
	SCRIPT,
	MATERIAL,
	STATUS,
	COUNT
}


func _ready() -> void:
	_prefab_tree.columns = Columns.COUNT
	_prefab_tree.set_column_title(Columns.NAME, "名称")
	_prefab_tree.set_column_title(Columns.CATEGORY, "分类")
	_prefab_tree.set_column_title(Columns.COLLISION, "碰撞体")
	_prefab_tree.set_column_title(Columns.GLB, "GLB")
	_prefab_tree.set_column_title(Columns.SCRIPT, "脚本")
	_prefab_tree.set_column_title(Columns.MATERIAL, "材质")
	_prefab_tree.set_column_title(Columns.STATUS, "状态")

	_prefab_tree.set_column_expand(Columns.NAME, true)
	_prefab_tree.set_column_expand(Columns.CATEGORY, false)
	_prefab_tree.set_column_expand(Columns.COLLISION, false)
	_prefab_tree.set_column_expand(Columns.GLB, false)
	_prefab_tree.set_column_expand(Columns.SCRIPT, false)
	_prefab_tree.set_column_expand(Columns.MATERIAL, false)
	_prefab_tree.set_column_expand(Columns.STATUS, false)

	_prefab_tree.set_column_custom_minimum_width(Columns.NAME, 150)
	_prefab_tree.set_column_custom_minimum_width(Columns.CATEGORY, 80)
	_prefab_tree.set_column_custom_minimum_width(Columns.COLLISION, 60)
	_prefab_tree.set_column_custom_minimum_width(Columns.GLB, 40)
	_prefab_tree.set_column_custom_minimum_width(Columns.SCRIPT, 40)
	_prefab_tree.set_column_custom_minimum_width(Columns.MATERIAL, 40)
	_prefab_tree.set_column_custom_minimum_width(Columns.STATUS, 50)

	_prefab_tree.allow_reselect = false
	_prefab_tree.allow_rmb_select = true

	_search_box.text_changed.connect(_on_search_changed)
	_category_filter.item_selected.connect(_on_category_selected)
	_severity_filter.item_selected.connect(_on_severity_selected)
	_prefab_tree.column_title_pressed.connect(_on_column_title_pressed)
	_prefab_tree.item_activated.connect(_on_item_activated)
	_prefab_tree.item_mouse_selected.connect(_on_item_selected)
	_scan_btn.pressed.connect(_refresh_list)


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
		if _current_severity == "healthy" and not (entry.has_collision and entry.has_glb):
			continue
		if _current_severity == "warning" and entry.has_collision and entry.has_glb:
			continue
		if _current_severity == "critical" and entry.has_collision:
			continue
		_filtered_entries.append(entry)

	_sort_entries()
	_rebuild_tree()


func _sort_entries() -> void:
	if _sort_column == Columns.NAME:
		_filtered_entries.sort_custom(func(a, b): return a.name < b.name)
	elif _sort_column == Columns.CATEGORY:
		_filtered_entries.sort_custom(func(a, b): return a.category < b.category)
	# Other columns sort by name as fallback

	if not _sort_ascending:
		_filtered_entries.reverse()


func _rebuild_tree() -> void:
	_prefab_tree.clear()

	var healthy_count := 0
	var warning_count := 0
	var critical_count := 0

	for entry in _filtered_entries:
		var item := _prefab_tree.create_item()
		item.set_text(Columns.NAME, entry.name)
		item.set_text(Columns.CATEGORY, entry.category)
		item.set_text(Columns.COLLISION, "✅" if entry.has_collision else "❌")
		item.set_text(Columns.GLB, "✅" if entry.has_glb else "❌")
		item.set_text(Columns.SCRIPT, "✅" if entry.has_script else "❌")
		item.set_text(Columns.MATERIAL, "✅" if entry.has_material_override else "❌")

		if entry.has_collision and entry.has_glb:
			item.set_text(Columns.STATUS, "🟢")
			healthy_count += 1
		elif entry.has_glb:
			item.set_text(Columns.STATUS, "🟡")
			warning_count += 1
		else:
			item.set_text(Columns.STATUS, "🔴")
			critical_count += 1

		item.set_metadata(0, entry)
		item.selectable = true

	_status_label.text = "全部: %d  |  显示: %d  |  🟢 %d  🟡 %d  🔴 %d" % [
		_all_entries.size(), _filtered_entries.size(),
		healthy_count, warning_count, critical_count
	]


func _on_search_changed(_new_text: String) -> void:
	_apply_filters()


func _on_category_selected(index: int) -> void:
	if index == 0:
		_current_category = ""
	else:
		_current_category = _category_filter.get_item_text(index)
	_apply_filters()


func _on_severity_selected(index: int) -> void:
	match index:
		0: _current_severity = ""
		1: _current_severity = "healthy"
		2: _current_severity = "warning"
		3: _current_severity = "critical"
	_apply_filters()


func _on_column_title_pressed(column: int) -> void:
	if column == _sort_column:
		_sort_ascending = not _sort_ascending
	else:
		_sort_column = column
		_sort_ascending = true
	_apply_filters()


func _on_item_activated() -> void:
	var selected := _prefab_tree.get_selected()
	if not selected:
		return
	var entry: PrefabInspectorScanner.PrefabEntry = selected.get_metadata(0)
	if entry:
		EditorInterface.open_scene_from_path(entry.path)


func _on_item_selected() -> void:
	var selected := _prefab_tree.get_selected()
	if not selected:
		return
	var entry: PrefabInspectorScanner.PrefabEntry = selected.get_metadata(0)
	if entry:
		prefab_selected.emit(entry.path)
```

- [ ] **Step 2: Create the panel scene**

TSCN 场景，使用 Tree 作为主控件：

```gdscene
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/prefab_inspector/panels/inspector_panel.gd" id="1"]

[node name="PrefabInspectorPanel" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Toolbar" type="HBoxContainer" parent="VBox"]
layout_mode = 2

[node name="SearchBox" type="LineEdit" parent="VBox/Toolbar"]
layout_mode = 2
size_flags_horizontal = 3
placeholder_text = "搜索预制体..."
unique_name_in_owner = true

[node name="CategoryFilter" type="OptionButton" parent="VBox/Toolbar"]
layout_mode = 2
unique_name_in_owner = true

[node name="SeverityFilter" type="OptionButton" parent="VBox/Toolbar"]
layout_mode = 2
unique_name_in_owner = true

[node name="ScanButton" type="Button" parent="VBox/Toolbar"]
layout_mode = 2
text = "🔍 重新扫描"
unique_name_in_owner = true

[node name="PrefabTree" type="Tree" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3
hide_root = true
unique_name_in_owner = true

[node name="StatusLabel" type="Label" parent="VBox"]
layout_mode = 2
unique_name_in_owner = true
```

工具按钮需要初始化严重度过滤器的选项：

在 `_ready()` 中补充：
```gdscript
_severity_filter.add_item("全部严重度")
_severity_filter.add_item("🟢 健康")
_severity_filter.add_item("🟡 警告")
_severity_filter.add_item("🔴 严重")
```

- [ ] **Step 3: Update plugin.gd to use the panel**

```gdscript
@tool
extends EditorPlugin

const PANEL_NAME := "Prefab Inspector"

var bottom_panel: Control
var inspector_panel: PrefabInspectorPanel
var scanner: PrefabInspectorScanner


func _enter_tree() -> void:
	scanner = PrefabInspectorScanner.new()

	var panel_scene := load("res://addons/prefab_inspector/panels/inspector_panel.tscn") as PackedScene
	bottom_panel = panel_scene.instantiate() as Control
	inspector_panel = bottom_panel as PrefabInspectorPanel
	inspector_panel.scanner = scanner

	add_control_to_bottom_panel(bottom_panel, PANEL_NAME)


func _exit_tree() -> void:
	if bottom_panel:
		remove_control_from_bottom_panel(bottom_panel)
		bottom_panel.queue_free()
		bottom_panel = null
		inspector_panel = null
	scanner = null
```

- [ ] **Step 4: Verify syntax**
```
godot --headless --xr-mode off --path . --check-only --quit
```

---

### Task 4: Tests

**Files:**
- Create: `tests/test_prefab_inspector.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Create test file**

```gdscript
extends RefCounted


func run(t) -> void:
	_test_scanner_exists(t)
	_test_scanner_scan_counts(t)
	_test_glb_detection(t)
	_test_collision_detection(t)
	_test_script_detection(t)
	_test_material_detection(t)
	_test_root_type_extraction(t)
	_test_root_name_matching(t)
	_test_panel_exists(t)


func _test_scanner_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/prefab_inspector/scripts/prefab_scanner.gd"),
		"PrefabInspectorScanner script should exist"
	)


func _test_scanner_scan_counts(t) -> void:
	var scanner := PrefabInspectorScanner.new()
	var entries := scanner.scan()
	t.assert_true(entries.size() >= 50,
		"should find at least 50 prefabs, got %d" % entries.size())


func _test_glb_detection(t) -> void:
	# lantern_01.tscn has a .glb reference
	var content := '[ext_resource type="PackedScene" path="res://assets/models/props/lantern_01/lantern_01.glb" id="1"]'
	var scanner := PrefabInspectorScanner.new()
	t.assert_true(scanner._detect_glb(content), "should detect .glb reference")
	t.assert_false(scanner._detect_glb("no glb here"), "should NOT detect glb when absent")


func _test_collision_detection(t) -> void:
	var scanner := PrefabInspectorScanner.new()
	t.assert_true(scanner._detect_collision('type="CollisionShape3D"'), "CollisionShape3D")
	t.assert_true(scanner._detect_collision('type="CollisionPolygon3D"'), "CollisionPolygon3D")
	t.assert_false(scanner._detect_collision("no collision here"), "no collision")


func _test_script_detection(t) -> void:
	var scanner := PrefabInspectorScanner.new()
	t.assert_true(scanner._detect_script('script = ExtResource("1")'), "script attachment")
	t.assert_false(scanner._detect_script("no script here"), "no script")


func _test_material_detection(t) -> void:
	var scanner := PrefabInspectorScanner.new()
	t.assert_true(scanner._detect_material_override('surface_material_override/0 = ExtResource("2")'), "material override")
	t.assert_false(scanner._detect_material_override("no override"), "no override")


func _test_root_type_extraction(t) -> void:
	var scanner := PrefabInspectorScanner.new()
	var content := '[node name="lantern_01" type="Node3D"]\n'
	t.assert_equal(scanner._extract_root_type(content), "Node3D", "root type Node3D")

	content = '[node name="WorldBoundary" type="StaticBody3D"]\n'
	t.assert_equal(scanner._extract_root_type(content), "StaticBody3D", "root type StaticBody3D")


func _test_root_name_matching(t) -> void:
	var scanner := PrefabInspectorScanner.new()
	var content := '[node name="lantern_01" type="Node3D"]\n'
	t.assert_true(scanner._check_root_name_matches(content, "lantern_01"), "name matches")
	t.assert_false(scanner._check_root_name_matches(content, "wrong_name"), "name mismatch")


func _test_panel_exists(t) -> void:
	t.assert_true(
		ResourceLoader.exists("res://addons/prefab_inspector/panels/inspector_panel.tscn"),
		"InspectorPanel scene should exist"
	)
```

- [ ] **Step 2: Register in test_runner.gd**

Add `"res://tests/test_prefab_inspector.gd"` to the `test_paths` array in `tests/test_runner.gd`.

- [ ] **Step 3: Run tests**
```
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: PASS

---

### Task 5: Final verification

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
