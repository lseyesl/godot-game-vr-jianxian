extends RefCounted

const SEAL_SCRIPT_PATH := "res://scripts/interaction/SealEncounter.gd"
const EVENT_BUS_SCRIPT_PATH := "res://scripts/autoload/EventBus.gd"

func run(t) -> void:
	t.assert_true(FileAccess.file_exists(SEAL_SCRIPT_PATH), "SealEncounter script exists")
	if not FileAccess.file_exists(SEAL_SCRIPT_PATH):
		return
	var SealEncounter := load(SEAL_SCRIPT_PATH)
	t.assert_true(SealEncounter.can_instantiate(), "SealEncounter can instantiate")
	if not SealEncounter.can_instantiate():
		return
	_test_basic_spell_rules(t, SealEncounter)
	_test_combat_feedback_signal(t, SealEncounter)

func _test_basic_spell_rules(t, SealEncounter: Script) -> void:
	var encounter = SealEncounter.new()
	t.assert_equal(encounter.remaining_hits, 3, "seal starts with three hits")
	encounter.receive_spell("spirit_bolt")
	t.assert_equal(encounter.remaining_hits, 2, "spirit bolt weakens demon seal")
	encounter.receive_spell("guard_charm")
	t.assert_equal(encounter.remaining_hits, 2, "guard charm does not weaken seal")
	encounter.receive_spell("seal_break")
	t.assert_equal(encounter.remaining_hits, 0, "seal break finishes encounter")
	t.assert_true(encounter.cleansed, "encounter is cleansed")
	encounter.free()

func _test_combat_feedback_signal(t, SealEncounter: Script) -> void:
	t.assert_true(FileAccess.file_exists(EVENT_BUS_SCRIPT_PATH), "EventBus script exists for feedback test")
	if not FileAccess.file_exists(EVENT_BUS_SCRIPT_PATH):
		return
	var scene_tree := t as SceneTree
	t.assert_true(scene_tree != null, "SceneTree is available for feedback test")
	if scene_tree == null:
		return
	var EventBusScript := load(EVENT_BUS_SCRIPT_PATH)
	var created_event_bus := false
	var event_bus = scene_tree.root.get_node_or_null("EventBus")
	if event_bus == null:
		event_bus = EventBusScript.new()
		event_bus.name = "EventBus"
		scene_tree.root.add_child(event_bus)
		created_event_bus = true
	var encounter = SealEncounter.new()
	scene_tree.root.add_child(encounter)
	var feedback_events: Array = []
	t.assert_true(event_bus.has_signal("combat_feedback_requested"), "EventBus exposes combat_feedback_requested signal")
	if not event_bus.has_signal("combat_feedback_requested"):
		encounter.free()
		if created_event_bus:
			event_bus.free()
		return
	var feedback_callback := func(spell_id: String, target_id: String, outcome: String) -> void:
		feedback_events.append({
			"spell_id": spell_id,
			"target_id": target_id,
			"outcome": outcome,
		})
	event_bus.combat_feedback_requested.connect(feedback_callback)

	encounter.receive_spell("guard_charm")
	t.assert_equal(feedback_events.size(), 0, "ignored guard charm emits no combat feedback")

	encounter.receive_spell("spirit_bolt")
	t.assert_equal(feedback_events.size(), 1, "accepted spirit bolt emits one feedback event")
	if feedback_events.size() >= 1:
		t.assert_equal(feedback_events[0]["spell_id"], "spirit_bolt", "spirit bolt feedback records spell id")
		t.assert_equal(feedback_events[0]["target_id"], "seal", "spirit bolt feedback records seal target")
		t.assert_equal(feedback_events[0]["outcome"], "hit", "spirit bolt feedback records hit outcome")

	encounter.receive_spell("seal_break")
	t.assert_equal(feedback_events.size(), 2, "seal break emits one cleanse feedback event")
	if feedback_events.size() >= 2:
		t.assert_equal(feedback_events[1]["spell_id"], "seal_break", "seal break feedback records spell id")
		t.assert_equal(feedback_events[1]["target_id"], "seal", "seal break feedback records seal target")
		t.assert_equal(feedback_events[1]["outcome"], "cleanse", "seal break feedback records cleanse outcome")

	encounter.receive_spell("seal_break")
	t.assert_equal(feedback_events.size(), 2, "cleansed seal does not emit duplicate cleanse feedback")

	if event_bus.combat_feedback_requested.is_connected(feedback_callback):
		event_bus.combat_feedback_requested.disconnect(feedback_callback)
	encounter.free()
	if created_event_bus:
		event_bus.free()
