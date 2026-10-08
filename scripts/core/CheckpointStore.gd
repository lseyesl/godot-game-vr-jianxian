extends RefCounted
class_name CheckpointStore

const Quest = preload("res://scripts/core/QuestState.gd")
const VERSION := 1
const DEFAULT_PATH := "user://jianxian_checkpoint.json"

static func validate(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("version") != VERSION:
		return {}
	var step = data.get("quest_step")
	if not step is String or not Quest.OBJECTIVES.has(step):
		return {}
	var mode = data.get("comfort_mode", "comfort")
	if mode not in ["comfort", "immersive"]:
		mode = "comfort"
	# Derive unlock state from the FSM; never trust a stale flag in a save.
	return {
		"version": VERSION,
		"quest_step": step,
		"sword_unlocked": step in ["fly_back", "complete"],
		"comfort_mode": mode,
	}

static func read_checkpoint(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 16384:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK: return {}
	return validate(json.data)

static func write_checkpoint(data: Dictionary, path: String = DEFAULT_PATH) -> Error:
	var checked := validate(data)
	if checked.is_empty():
		return ERR_INVALID_DATA
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(checked, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
