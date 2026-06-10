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
	var EventBusScript := load(EVENT_BUS_SCRIPT_PATH)
	var event_bus = EventBusScript.new()
	event_bus.name = "EventBus"
	var root := Node.new()
	root.add_child(event_bus)
	var encounter = SealEncounter.new()
	root.add_child(encounter)
	var feedback_events: Array = []
	t.assert_true(event_bus.has_signal("combat_feedback_requested"), "EventBus exposes combat_feedback_requested signal")
	if not event_bus.has_signal("combat_feedback_requested"):
		root.free()
		return
	event_bus.combat_feedback_requested.connect(func(spell_id: String, target_id: String, outcome: String) -> void:
		feedback_events.append({
			"spell_id": spell_id,
			"target_id": target_id,
			"outcome": outcome,
		})
	)

	encounter.receive_spell("guard_charm")
	t.assert_equal(feedback_events.size(), 0, "ignored guard charm emits no combat feedback")

	encounter.receive_spell("spirit_bolt")
	t.assert_equal(feedback_events.size(), 1, "accepted spirit bolt emits one feedback event")
	t.assert_equal(feedback_events[0]["spell_id"], "spirit_bolt", "spirit bolt feedback records spell id")
	t.assert_equal(feedback_events[0]["target_id"], "seal", "spirit bolt feedback records seal target")
	t.assert_equal(feedback_events[0]["outcome"], "hit", "spirit bolt feedback records hit outcome")

	encounter.receive_spell("seal_break")
	t.assert_equal(feedback_events.size(), 2, "seal break emits one cleanse feedback event")
	t.assert_equal(feedback_events[1]["spell_id"], "seal_break", "seal break feedback records spell id")
	t.assert_equal(feedback_events[1]["target_id"], "seal", "seal break feedback records seal target")
	t.assert_equal(feedback_events[1]["outcome"], "cleanse", "seal break feedback records cleanse outcome")

	encounter.receive_spell("seal_break")
	t.assert_equal(feedback_events.size(), 2, "cleansed seal does not emit duplicate cleanse feedback")

	root.free()
