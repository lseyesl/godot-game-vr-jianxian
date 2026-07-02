@tool
class_name PrefabInspectorPanel
extends Control


signal prefab_selected(path: String)


var scanner: PrefabInspectorScanner:
	set(value):
		scanner = value
		if is_node_ready():
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
	_prefab_tree.hide_root = true

	_severity_filter.add_item("全部严重度")
	_severity_filter.add_item("🟢 健康")
	_severity_filter.add_item("🟡 警告")
	_severity_filter.add_item("🔴 严重")

	_search_box.text_changed.connect(_on_search_changed)
	_category_filter.item_selected.connect(_on_category_selected)
	_severity_filter.item_selected.connect(_on_severity_selected)
	_prefab_tree.column_title_pressed.connect(_on_column_title_pressed)
	_prefab_tree.item_activated.connect(_on_item_activated)
	_prefab_tree.item_mouse_selected.connect(_on_item_selected)
	_scan_btn.pressed.connect(_refresh_list)

	if scanner:
		_refresh_list()


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
	match _sort_column:
		Columns.NAME:
			_filtered_entries.sort_custom(func(a, b): return a.name < b.name)
		Columns.CATEGORY:
			_filtered_entries.sort_custom(func(a, b): return a.category < b.category)
		Columns.COLLISION:
			_filtered_entries.sort_custom(func(a, b): return a.has_collision and not b.has_collision)
		Columns.GLB:
			_filtered_entries.sort_custom(func(a, b): return a.has_glb and not b.has_glb)
		Columns.SCRIPT:
			_filtered_entries.sort_custom(func(a, b): return a.has_script and not b.has_script)
		Columns.MATERIAL:
			_filtered_entries.sort_custom(func(a, b): return a.has_material_override and not b.has_material_override)
		Columns.STATUS:
			var score := func(e): return (1 if e.has_collision else 0) + (1 if e.has_glb else 0)
			_filtered_entries.sort_custom(func(a, b): return score.call(a) > score.call(b))
		_:
			_filtered_entries.sort_custom(func(a, b): return a.name < b.name)

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
