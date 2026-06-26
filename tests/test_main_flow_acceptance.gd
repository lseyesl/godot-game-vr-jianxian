extends RefCounted

const QuestStateScript := preload("res://scripts/core/QuestState.gd")
const EventBusScript := preload("res://scripts/autoload/EventBus.gd")
const GameScript := preload("res://scripts/autoload/Game.gd")

func run(t) -> void:
	_test_quest_sequence_reaches_complete(t)
	_test_game_emits_completion_feedback_once(t)
	_test_main_scene_has_completion_feedback(t)

func _test_quest_sequence_reaches_complete(t) -> void:
	var quest = QuestStateScript.new()
	var sequence := [
		{"event": "talked_to_innkeeper", "step": "ask_tavern"},
		{"event": "talked_to_tavern_keeper", "step": "go_to_mountain"},
		{"event": "entered_trial", "step": "cleanse_seal"},
		{"event": "seal_cleansed", "step": "collect_sword"},
		{"event": "sword_collected", "step": "fly_back"},
		{"event": "returned_to_town", "step": "complete"},
	]
	for item in sequence:
		t.assert_true(quest.advance(item["event"]), "quest advances on %s" % item["event"])
		t.assert_equal(quest.current_step, item["step"], "quest reaches %s" % item["step"])
	t.assert_equal(quest.current_objective(), "试炼完成，飞剑已归鞘", "complete objective is final completion text")
	t.assert_true(not quest.advance("returned_to_town"), "duplicate return event does not advance complete quest")

func _test_game_emits_completion_feedback_once(t) -> void:
	var root := Node.new()
	var event_bus = EventBusScript.new()
	event_bus.name = "EventBus"
	var game = GameScript.new()
	game.name = "Game"
	root.add_child(event_bus)
	root.add_child(game)
	t.assert_true(event_bus.has_signal("quest_completed"), "EventBus exposes quest_completed")
	t.assert_true(event_bus.has_signal("completion_feedback_requested"), "EventBus exposes completion_feedback_requested")
	if not event_bus.has_signal("quest_completed") or not event_bus.has_signal("completion_feedback_requested"):
		root.free()
		return
	game.quest_state.current_step = "start"
	game.save_state.quest_step = "start"
	if "completion_feedback_emitted" in game:
		game.completion_feedback_emitted = false
	var signal_state := {
		"completed_count": 0,
		"feedback_count": 0,
		"feedback_title": "",
		"feedback_message": "",
	}
	event_bus.quest_completed.connect(func() -> void:
		signal_state["completed_count"] += 1
	, CONNECT_ONE_SHOT)
	event_bus.completion_feedback_requested.connect(func(title: String, message: String) -> void:
		signal_state["feedback_count"] += 1
		signal_state["feedback_title"] = title
		signal_state["feedback_message"] = message
	)
	for event_id in ["talked_to_innkeeper", "talked_to_tavern_keeper", "entered_trial", "seal_cleansed", "sword_collected"]:
		t.assert_true(game.advance_quest(event_id), "game advances %s" % event_id)
	t.assert_true(game.advance_quest("returned_to_town"), "return event completes quest")
	t.assert_equal(signal_state["completed_count"], 1, "quest_completed emits once")
	t.assert_equal(signal_state["feedback_count"], 1, "completion feedback requested once")
	t.assert_equal(signal_state["feedback_title"], "试炼完成", "completion title is Chinese")
	t.assert_true(signal_state["feedback_message"].contains("飞剑"), "completion message mentions flying sword")
	t.assert_true(not game.advance_quest("returned_to_town"), "duplicate return is ignored")
	t.assert_equal(signal_state["completed_count"], 1, "duplicate return does not emit quest_completed again")
	t.assert_equal(signal_state["feedback_count"], 1, "duplicate return does not request feedback again")
	root.free()

func _test_main_scene_has_completion_feedback(t) -> void:
	var path := "res://scenes/main/Main.tscn"
	t.assert_true(ResourceLoader.exists(path), "Main scene exists")
	if not ResourceLoader.exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	t.assert_true(file != null, "Main scene opens as text")
	if file == null:
		return
	var scene_text := file.get_as_text()
	t.assert_true(scene_text.contains("res://scenes/ui/CompletionFeedback.tscn"), "Main scene references CompletionFeedback scene")
	var scene := load(path) as PackedScene
	t.assert_true(scene != null, "Main scene loads as PackedScene")
	if scene == null:
		return
	var main := scene.instantiate()
	t.assert_true(main.get_node_or_null("CompletionFeedback") != null, "Main scene instances CompletionFeedback")
	main.free()
