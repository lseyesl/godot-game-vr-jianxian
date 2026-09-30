# Town Combat Feedback Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add testable town route clearance markers and event-driven combat feedback for seal spell hits.

**Architecture:** Town comfort polish is represented by explicit `Area3D` clearance markers in `Town.tscn`, verified through headless scene tests. Combat feedback remains event-driven through `EventBus`; `SealEncounter` emits accepted spell outcomes while quest progression stays owned by existing seal and `Game` behavior.

**Tech Stack:** Godot 4.6+, GDScript, PackedScene `.tscn`, headless custom GDScript test runner.

---

## File Structure

- Modify `scenes/town/Town.tscn`: add top-level `TownFlowMarkers` with seven `Area3D` marker nodes, each with a `CollisionShape3D` and `BoxShape3D`.
- Create `tests/test_town_playability.gd`: instantiate `Town.tscn` and assert marker presence, type, shape type, and minimum X/Z footprint.
- Modify `scripts/autoload/EventBus.gd`: add `combat_feedback_requested(spell_id: String, target_id: String, outcome: String)`.
- Modify `scripts/interaction/SealEncounter.gd`: emit combat feedback for accepted `spirit_bolt` and `seal_break` hits, with no duplicate cleanse feedback after the seal is cleansed.
- Modify `tests/test_seal_encounter.gd`: keep isolated no-autoload behavior tests and add in-tree EventBus signal assertions.
- Modify `tests/test_runner.gd`: register `res://tests/test_town_playability.gd`.
- Modify `docs/testing/vr-demo-acceptance.md`: document automated town clearance and seal feedback coverage without checking manual VR acceptance items.

## Task 1: Town Playability Failing Test

**Files:**
- Create: `tests/test_town_playability.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write the failing town clearance test**

Create `tests/test_town_playability.gd`:

```gdscript
extends RefCounted

const TOWN_SCENE_PATH := "res://scenes/town/Town.tscn"

func run(t) -> void:
	t.assert_true(ResourceLoader.exists(TOWN_SCENE_PATH), "Town scene exists")
	if not ResourceLoader.exists(TOWN_SCENE_PATH):
		return
	var packed_scene := load(TOWN_SCENE_PATH)
	t.assert_true(packed_scene is PackedScene, "Town scene loads as PackedScene")
	if not packed_scene is PackedScene:
		return
	var town = packed_scene.instantiate()
	t.assert_true(town != null, "Town scene instantiates for playability checks")
	if town == null:
		return

	_assert_clearance(t, town, "TownFlowMarkers/MainStreetRouteClearance", Vector2(3.0, 16.0), "main street route keeps a 3 m wide north-south path")
	_assert_clearance(t, town, "TownFlowMarkers/MarketRouteClearance", Vector2(3.0, 4.0), "market route keeps a comfortable clear aisle")
	_assert_clearance(t, town, "TownFlowMarkers/InnEntranceClearance", Vector2(2.0, 2.0), "inn entrance keeps a core quest doorway clearance")
	_assert_clearance(t, town, "TownFlowMarkers/TavernEntranceClearance", Vector2(2.0, 2.0), "tavern entrance keeps a core quest doorway clearance")
	_assert_clearance(t, town, "TownFlowMarkers/InnkeeperInteractionClearance", Vector2(1.5, 1.5), "innkeeper interaction keeps standing VR space")
	_assert_clearance(t, town, "TownFlowMarkers/TavernKeeperInteractionClearance", Vector2(1.5, 1.5), "tavern keeper interaction keeps standing VR space")
	_assert_clearance(t, town, "TownFlowMarkers/ReturnLandingClearance", Vector2(2.0, 2.0), "return landing keeps clear arrival space")

	town.free()

func _assert_clearance(t, town: Node, marker_path: String, minimum_xz: Vector2, message: String) -> void:
	t.assert_true(town.has_node(marker_path), "%s exists" % marker_path)
	var marker = town.get_node_or_null(marker_path)
	t.assert_true(marker is Area3D, "%s is an Area3D" % marker_path)
	if not marker is Area3D:
		return
	var shape_node = marker.get_node_or_null("CollisionShape3D")
	t.assert_true(shape_node is CollisionShape3D, "%s has CollisionShape3D" % marker_path)
	if not shape_node is CollisionShape3D:
		return
	t.assert_true(shape_node.shape is BoxShape3D, "%s uses BoxShape3D" % marker_path)
	if not shape_node.shape is BoxShape3D:
		return
	var shape: BoxShape3D = shape_node.shape
	t.assert_true(shape.size.x >= minimum_xz.x, "%s width is at least %.1f m" % [message, minimum_xz.x])
	t.assert_true(shape.size.z >= minimum_xz.y, "%s depth is at least %.1f m" % [message, minimum_xz.y])
```

- [x] **Step 2: Register the test**

Add the new path near `test_town_showcase.gd` in `tests/test_runner.gd`:

```gdscript
		"res://tests/test_town_playability.gd",
		"res://tests/test_town_showcase.gd",
```

- [x] **Step 3: Run tests and verify the new test fails**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: exit 1 with failures mentioning missing `TownFlowMarkers/MainStreetRouteClearance` and other clearance marker paths.

- [x] **Step 4: Commit the failing test**

```bash
git add tests/test_town_playability.gd tests/test_runner.gd
git commit -m "test: cover town playability clearances"
```

## Task 2: Town Clearance Markers

**Files:**
- Modify: `scenes/town/Town.tscn`
- Test: `tests/test_town_playability.gd`

- [x] **Step 1: Add BoxShape3D sub-resources**

Open `scenes/town/Town.tscn` and add these sub-resources after the existing `BoxShape3D_1` block. Use fresh IDs if any of these IDs already exist in the file.

```gdscene
[sub_resource type="BoxShape3D" id="BoxShape3D_MainStreetRouteClearance"]
size = Vector3(3, 2.4, 36)

[sub_resource type="BoxShape3D" id="BoxShape3D_MarketRouteClearance"]
size = Vector3(3, 2.4, 6)

[sub_resource type="BoxShape3D" id="BoxShape3D_InnEntranceClearance"]
size = Vector3(2, 2.5, 2.5)

[sub_resource type="BoxShape3D" id="BoxShape3D_TavernEntranceClearance"]
size = Vector3(2, 2.5, 2.5)

[sub_resource type="BoxShape3D" id="BoxShape3D_InnkeeperInteractionClearance"]
size = Vector3(1.5, 2.4, 1.5)

[sub_resource type="BoxShape3D" id="BoxShape3D_TavernKeeperInteractionClearance"]
size = Vector3(1.5, 2.4, 1.5)

[sub_resource type="BoxShape3D" id="BoxShape3D_ReturnLandingClearance"]
size = Vector3(2, 2.4, 2)
```

- [x] **Step 2: Add `TownFlowMarkers` nodes**

Append this node block near other top-level gameplay/marker nodes in `scenes/town/Town.tscn`. Keep current landmark nodes and positions unchanged.

```gdscene
[node name="TownFlowMarkers" type="Node3D" parent="."]

[node name="MainStreetRouteClearance" type="Area3D" parent="TownFlowMarkers"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, -8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="TownFlowMarkers/MainStreetRouteClearance"]
shape = SubResource("BoxShape3D_MainStreetRouteClearance")

[node name="MarketRouteClearance" type="Area3D" parent="TownFlowMarkers"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="TownFlowMarkers/MarketRouteClearance"]
shape = SubResource("BoxShape3D_MarketRouteClearance")

[node name="InnEntranceClearance" type="Area3D" parent="TownFlowMarkers"]
transform = Transform3D(0.9393727, 0, 0.3428978, 0, 1, 0, -0.3428978, 0, 0.9393727, -11.15, 1.25, 9.05)

[node name="CollisionShape3D" type="CollisionShape3D" parent="TownFlowMarkers/InnEntranceClearance"]
shape = SubResource("BoxShape3D_InnEntranceClearance")

[node name="TavernEntranceClearance" type="Area3D" parent="TownFlowMarkers"]
transform = Transform3D(0.9393727, 0, -0.3428978, 0, 1, 0, 0.3428978, 0, 0.9393727, 9.15, 1.25, 15.05)

[node name="CollisionShape3D" type="CollisionShape3D" parent="TownFlowMarkers/TavernEntranceClearance"]
shape = SubResource("BoxShape3D_TavernEntranceClearance")

[node name="InnkeeperInteractionClearance" type="Area3D" parent="TownFlowMarkers"]
transform = Transform3D(0.9393727, 0, 0.3428978, 0, 1, 0, -0.3428978, 0, 0.9393727, -9.45, 1.2, 7.85)

[node name="CollisionShape3D" type="CollisionShape3D" parent="TownFlowMarkers/InnkeeperInteractionClearance"]
shape = SubResource("BoxShape3D_InnkeeperInteractionClearance")

[node name="TavernKeeperInteractionClearance" type="Area3D" parent="TownFlowMarkers"]
transform = Transform3D(0.9393727, 0, -0.3428978, 0, 1, 0, 0.3428978, 0, 0.9393727, 8.55, 1.2, 14.85)

[node name="CollisionShape3D" type="CollisionShape3D" parent="TownFlowMarkers/TavernKeeperInteractionClearance"]
shape = SubResource("BoxShape3D_TavernKeeperInteractionClearance")

[node name="ReturnLandingClearance" type="Area3D" parent="TownFlowMarkers"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 12, 3.2, 24)

[node name="CollisionShape3D" type="CollisionShape3D" parent="TownFlowMarkers/ReturnLandingClearance"]
shape = SubResource("BoxShape3D_ReturnLandingClearance")
```

- [x] **Step 3: Run the focused town tests**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass or no failures remain from `test_town_playability.gd`. If another unrelated test fails because the scene edit has a syntax error, fix the `.tscn` resource IDs and rerun.

- [x] **Step 4: Commit town markers**

```bash
git add scenes/town/Town.tscn
git commit -m "feat: add town playability clearance markers"
```

## Task 3: Combat Feedback Failing Test

**Files:**
- Modify: `tests/test_seal_encounter.gd`

- [x] **Step 1: Extend the seal encounter test**

Replace `tests/test_seal_encounter.gd` with:

```gdscript
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
```

- [x] **Step 2: Run tests and verify failure**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: exit 1 because `EventBus` does not yet expose `combat_feedback_requested`, or `SealEncounter` does not emit it.

- [x] **Step 3: Commit the failing combat feedback test**

```bash
git add tests/test_seal_encounter.gd
git commit -m "test: cover seal combat feedback"
```

## Task 4: EventBus Combat Feedback Signal

**Files:**
- Modify: `scripts/autoload/EventBus.gd`
- Test: `tests/test_seal_encounter.gd`

- [x] **Step 1: Add the signal**

Add this line to `scripts/autoload/EventBus.gd` near the other combat and feedback signals:

```gdscript
signal combat_feedback_requested(spell_id: String, target_id: String, outcome: String)
```

The surrounding signal section should include:

```gdscript
signal damage_received(target_id: String, amount: int, current_health: int, max_health: int)
signal health_changed(target_id: String, current_health: int, max_health: int)
signal enemy_defeated(enemy_id: String)
signal combat_feedback_requested(spell_id: String, target_id: String, outcome: String)
signal player_health_changed(current_health: int, max_health: int)
```

- [x] **Step 2: Run tests and verify remaining failure**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: the signal exists, but `test_seal_encounter.gd` still fails because no feedback events are emitted.

- [x] **Step 3: Commit the EventBus signal**

```bash
git add scripts/autoload/EventBus.gd
git commit -m "feat: add combat feedback event"
```

## Task 5: Seal Encounter Feedback Emission

**Files:**
- Modify: `scripts/interaction/SealEncounter.gd`
- Test: `tests/test_seal_encounter.gd`

- [x] **Step 1: Add a target identifier and feedback helper**

Update the top of `scripts/interaction/SealEncounter.gd`:

```gdscript
extends Node3D
class_name SealEncounter

@export var remaining_hits := 3
@export var target_id := "seal"
var cleansed := false
```

Add this helper below `receive_spell()` and above `_cleanse()`:

```gdscript
func _emit_combat_feedback(spell_id: String, outcome: String) -> void:
	if not is_inside_tree():
		return
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("combat_feedback_requested"):
		event_bus.combat_feedback_requested.emit(spell_id, target_id, outcome)
```

- [x] **Step 2: Emit accepted spell outcomes**

Replace `receive_spell()` with:

```gdscript
func receive_spell(spell_id: String) -> void:
	if cleansed:
		return
	var outcome := ""
	if spell_id == "spirit_bolt":
		remaining_hits = max(0, remaining_hits - 1)
		outcome = "hit"
	elif spell_id == "seal_break":
		remaining_hits = 0
		outcome = "cleanse"
	else:
		return
	if is_inside_tree():
		var event_bus := get_node_or_null("/root/EventBus")
		if event_bus != null:
			event_bus.seal_weakened.emit(remaining_hits)
	if remaining_hits == 0:
		outcome = "cleanse"
	_emit_combat_feedback(spell_id, outcome)
	if remaining_hits == 0:
		_cleanse()
```

This preserves existing seal weakening and cleanse behavior while reporting accepted spell outcomes before `_cleanse()` can change tree state or quest state.

- [x] **Step 3: Run the test suite**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass with `TESTS PASSED: <N> assertions`.

- [x] **Step 4: Commit seal feedback behavior**

```bash
git add scripts/interaction/SealEncounter.gd
git commit -m "feat: emit seal combat feedback"
```

## Task 6: Acceptance Documentation

**Files:**
- Modify: `docs/testing/vr-demo-acceptance.md`

- [x] **Step 1: Add automated coverage notes without checking manual VR items**

In `docs/testing/vr-demo-acceptance.md`, add an automated coverage note in the existing automated or notes section. If no automated section exists, add this section near the test command documentation:

```markdown
## Automated Coverage

- [x] Headless tests verify town main-flow clearance markers for main street, market route, inn entrance, tavern entrance, NPC interaction spaces, and return landing.
- [x] Headless tests verify seal combat feedback for accepted spell hits and prevent duplicate cleanse feedback after the seal is cleansed.
```

Do not change unchecked manual headset checklist lines such as inn/tavern enterability feel, full VR playthrough, flight framing, or no blocking collision traps.

- [x] **Step 2: Review the diff**

Run:

```bash
git diff -- docs/testing/vr-demo-acceptance.md
```

Expected: diff only adds or updates automated coverage wording; it does not mark manual VR acceptance items complete.

- [x] **Step 3: Commit documentation**

```bash
git add docs/testing/vr-demo-acceptance.md
git commit -m "docs: note town combat automated coverage"
```

## Task 7: Final Verification

**Files:**
- Verify: all modified files

- [x] **Step 1: Check working tree**

Run:

```bash
git status --short
```

Expected: no unexpected unrelated changes. If `.uid` sidecars appear and were generated by Godot import only, leave them untracked unless they correspond to an intentionally created tracked resource.

- [x] **Step 2: Run the full headless test suite**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: exit 0 and output `TESTS PASSED: <N> assertions`.

- [x] **Step 3: Run syntax and scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit 0.

- [x] **Step 4: Commit any final plan checkbox updates**

If this plan file is updated during execution, commit the final checked state:

```bash
git add docs/superpowers/plans/2026-06-11-town-combat-feedback-polish.md
git commit -m "docs: update town combat feedback polish plan"
```

## Self-Review

- Spec coverage: Task 1 and Task 2 cover all named town clearance markers and minimum dimensions. Task 3 through Task 5 cover combat feedback signal shape, accepted outcomes, and duplicate cleanse prevention. Task 6 covers acceptance documentation without manual VR claims. Task 7 covers required verification.
- Completeness scan: no unfinished implementation wording or unowned test expectations remain.
- Type consistency: marker paths, signal name, signal argument types, `target_id`, and outcome strings are consistent across test and implementation steps.
