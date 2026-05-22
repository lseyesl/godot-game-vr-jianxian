extends RefCounted

func run(t) -> void:
	var path := "res://scripts/main/Main.gd"
	t.assert_true(FileAccess.file_exists(path), "Main script exists")
	if not FileAccess.file_exists(path):
		return
	var MainScript := load(path)
	t.assert_true(MainScript.can_instantiate(), "Main script can instantiate")
	if not MainScript.can_instantiate():
		return
	var main = MainScript.new()
	t.assert_equal(main.resolve_player_scene_path("desktop_simulation"), "res://scenes/player/DesktopDebugPlayer.tscn", "desktop simulation resolves desktop player scene")
	t.assert_equal(main.resolve_player_scene_path("vr"), "res://scenes/player/XRPlayer.tscn", "vr resolves XR player scene")
	t.assert_equal(main.normalize_player_mode("unknown"), "desktop_simulation", "unknown mode falls back to desktop simulation")
	var desktop_player = main.instantiate_player_for_mode("desktop_simulation")
	t.assert_true(desktop_player != null, "desktop player instantiates")
	if desktop_player != null:
		t.assert_equal(desktop_player.name, "DesktopDebugPlayer", "desktop mode instantiates desktop debug player")
		desktop_player.free()
	t.assert_true(ResourceLoader.exists(main.resolve_player_scene_path("vr")), "vr player scene exists")
	main.free()
