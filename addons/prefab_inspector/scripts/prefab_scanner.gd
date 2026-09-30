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
	var time := FileAccess.get_modified_time(path)
	return time if time > 0 else 0
