extends RefCounted

func run(t) -> void:
	var scene_path := "res://scenes/mountain/MountainTrial.tscn"
	t.assert_true(FileAccess.file_exists(scene_path), "MountainTrial scene exists")
	if not FileAccess.file_exists(scene_path):
		return

	var packed_scene := load(scene_path)
	t.assert_true(packed_scene is PackedScene, "MountainTrial loads as PackedScene")
	if not packed_scene is PackedScene:
		return

	var scene = packed_scene.instantiate()
	t.assert_true(scene != null, "MountainTrial instantiates")
	if scene == null:
		return

	var lesser_demons: Array = scene.find_children("LesserDemon*", "CharacterBody3D", true, false)
	t.assert_true(not lesser_demons.is_empty(), "MountainTrial has at least one LesserDemon")
	if not lesser_demons.is_empty():
		var script: Script = lesser_demons[0].get_script()
		t.assert_true(script != null and script.resource_path == "res://scripts/enemies/LesserDemon.gd", "MountainTrial demon uses LesserDemon script")
	scene.free()
