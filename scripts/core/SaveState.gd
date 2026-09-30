extends Resource
class_name SaveState

@export var quest_step := "start"
@export var sword_unlocked := false
@export var comfort_mode := "comfort"

func reset() -> void:
	quest_step = "start"
	sword_unlocked = false
	comfort_mode = "comfort"
