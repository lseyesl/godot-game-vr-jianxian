extends RefCounted

func run(t) -> void:
	var path := "res://scripts/core/QuestState.gd"
	t.assert_true(ResourceLoader.exists(path), "QuestState script exists")
	if not ResourceLoader.exists(path):
		return
	var QuestState := load(path)
	var quest = QuestState.new()
	t.assert_equal(quest.current_step, "start", "quest starts at start")
	t.assert_equal(quest.current_objective(), "前往客栈，询问遗失飞剑的线索", "start objective")
	t.assert_true(quest.advance("talked_to_innkeeper"), "innkeeper event advances quest")
	t.assert_equal(quest.current_step, "ask_tavern", "after innkeeper go to tavern")
	t.assert_true(quest.advance("talked_to_tavern_keeper"), "tavern event advances quest")
	t.assert_equal(quest.current_step, "go_to_mountain", "after tavern go to mountain")
	t.assert_true(quest.advance("entered_trial"), "entering trial advances quest")
	t.assert_true(quest.advance("seal_cleansed"), "cleansing seal advances quest")
	t.assert_true(quest.advance("sword_collected"), "collecting sword advances quest")
	t.assert_true(quest.advance("returned_to_town"), "returning to town completes quest")
	t.assert_equal(quest.current_step, "complete", "quest completes")
	t.assert_true(not quest.advance("seal_cleansed"), "invalid event does not advance complete quest")
