extends RefCounted

const Store = preload("res://scripts/core/CheckpointStore.gd")
const GameScript = preload("res://scripts/autoload/Game.gd")
const TEST_PATH := "user://test_jianxian_checkpoint.json"

func run(t) -> void:
	for invalid in [null, [], "bad", {}, {"version": 9, "quest_step": "start"}, {"version": 1, "quest_step": "invalid"}]:
		t.assert_true(Store.validate(invalid).is_empty(), "malformed checkpoint is rejected")
	var game := GameScript.new()
	game.checkpoint_path = TEST_PATH
	game.quest_state.current_step = "fly_back"
	game.apply_comfort_mode("immersive")
	t.assert_true(game.save_checkpoint(), "checkpoint writes atomically")
	game.reset_demo()
	t.assert_true(game.load_checkpoint(), "checkpoint loads")
	t.assert_equal(game.quest_state.current_step, "fly_back", "quest restores")
	t.assert_true(game.save_state.sword_unlocked, "flight unlock derives from quest")
	t.assert_equal(game.comfort_settings.movement_mode, "immersive", "comfort choice restores")
	var early := Store.validate({"version": 1, "quest_step": "start", "sword_unlocked": true, "comfort_mode": "bad"})
	t.assert_true(not early.sword_unlocked, "early save cannot grant sword")
	t.assert_equal(early.comfort_mode, "comfort", "bad settings fall back safely")
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{truncated")
	file.close()
	t.assert_true(not game.load_checkpoint(), "corrupt save cannot replace current state")
	t.assert_equal(game.quest_state.current_step, "fly_back", "failed load preserves live state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	game.free()
