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


var scan_paths = ["res://scenes/prefabs/"]


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
