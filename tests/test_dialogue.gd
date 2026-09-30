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
	_test_explicit_interact_required(t, NpcDialogue)
	inn.free()
	tavern.free()

func _test_explicit_interact_required(t, NpcDialogue: Script) -> void:
	var npc = NpcDialogue.new()
	npc.npc_id = "innkeeper"
	var player := Node3D.new()
	player.add_to_group("player")
	npc._on_interact_area_body_entered(player)
	t.assert_true(npc.has_nearby_player(), "entering interact area stores nearby player")
	t.assert_equal(npc.last_line, "", "entering interact area does not auto-run dialogue")
	var interact_event := InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	npc._unhandled_input(interact_event)
	t.assert_true(npc.last_line.contains("飞剑"), "pressing interact runs dialogue for nearby player")
	npc._on_interact_area_body_exited(player)
	t.assert_true(not npc.has_nearby_player(), "exiting interact area clears nearby player")
	npc.free()
	player.free()
