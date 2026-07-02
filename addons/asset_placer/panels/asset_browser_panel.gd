@tool
class_name AssetBrowserPanel
extends Control


signal prefab_selected(path: String)
signal start_placing(path: String)
signal stop_placing()


var scanner: AssetScanner:
	set(value):
		scanner = value
		if is_node_ready():
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
