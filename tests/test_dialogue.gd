extends RefCounted

func run(t) -> void:
	var path := "res://scripts/npc/NpcDialogue.gd"
	t.assert_true(FileAccess.file_exists(path), "NpcDialogue script exists")
	if not FileAccess.file_exists(path):
		return
	var NpcDialogue := load(path)
	t.assert_true(NpcDialogue.can_instantiate(), "NpcDialogue can instantiate")
	if not NpcDialogue.can_instantiate():
		return
	var inn = NpcDialogue.new()
	inn.npc_id = "innkeeper"
	t.assert_true(inn.line_for_step("start").contains("飞剑"), "innkeeper mentions sword at start")
	t.assert_equal(inn.quest_event_for_step("start"), "talked_to_innkeeper", "innkeeper advances start")
	var tavern = NpcDialogue.new()
	tavern.npc_id = "tavern_keeper"
	t.assert_true(tavern.line_for_step("ask_tavern").contains("山谷"), "tavern keeper points to mountain")
	t.assert_equal(tavern.quest_event_for_step("ask_tavern"), "talked_to_tavern_keeper", "tavern advances ask_tavern")
	inn.free()
	tavern.free()
