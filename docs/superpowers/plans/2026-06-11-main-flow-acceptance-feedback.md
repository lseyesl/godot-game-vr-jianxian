# Main Flow Acceptance Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add automated main-flow acceptance coverage and explicit quest completion feedback for the playable demo.

**Architecture:** Keep `Game.advance_quest()` as the single quest transition authority. Add completion-specific `EventBus` signals, a small `CompletionFeedback` UI listener, and focused headless tests for the full quest sequence and UI scene wiring.

**Tech Stack:** Godot 4.6+, GDScript, existing headless test runner, existing EventBus/Game autoload architecture.

---

## File Structure

- Modify: `scripts/autoload/EventBus.gd`
  - Add `quest_completed` and `completion_feedback_requested(title, message)` signals.
- Modify: `scripts/autoload/Game.gd`
  - Emit completion signals exactly once when quest step reaches `complete`.
- Create: `scripts/ui/CompletionFeedback.gd`
  - Listens for completion feedback requests and updates visible UI state.
- Create: `scenes/ui/CompletionFeedback.tscn`
  - CanvasLayer with panel, title label, message label, and optional `AudioStreamPlayer`.
- Modify: `scenes/main/Main.tscn`
  - Instance `CompletionFeedback.tscn`.
- Create: `tests/test_main_flow_acceptance.gd`
  - Covers full quest event sequence and completion signal emission.
- Create: `tests/test_completion_feedback.gd`
  - Covers feedback UI behavior.
- Modify: `tests/test_runner.gd`
  - Register the new tests.
- Modify: `docs/testing/vr-demo-acceptance.md`
  - Mark automated main-flow acceptance coverage as present, while leaving manual/VR checks unchecked.

## Task 1: Main Flow Acceptance RED

**Files:**
- Create: `tests/test_main_flow_acceptance.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write failing main-flow acceptance test**

Create `tests/test_main_flow_acceptance.gd`:

```gdscript
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
	var completed_count := 0
	var feedback_count := 0
	var feedback_title := ""
	var feedback_message := ""
	event_bus.quest_completed.connect(func() -> void:
		completed_count += 1
	)
	event_bus.completion_feedback_requested.connect(func(title: String, message: String) -> void:
		feedback_count += 1
		feedback_title = title
		feedback_message = message
	)
	for event_id in ["talked_to_innkeeper", "talked_to_tavern_keeper", "entered_trial", "seal_cleansed", "sword_collected"]:
		t.assert_true(game.advance_quest(event_id), "game advances %s" % event_id)
	t.assert_true(game.advance_quest("returned_to_town"), "return event completes quest")
	t.assert_equal(completed_count, 1, "quest_completed emits once")
	t.assert_equal(feedback_count, 1, "completion feedback requested once")
	t.assert_equal(feedback_title, "试炼完成", "completion title is Chinese")
	t.assert_true(feedback_message.contains("飞剑"), "completion message mentions flying sword")
	t.assert_true(not game.advance_quest("returned_to_town"), "duplicate return is ignored")
	t.assert_equal(completed_count, 1, "duplicate return does not emit quest_completed again")
	t.assert_equal(feedback_count, 1, "duplicate return does not request feedback again")
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
	t.assert_true(scene_text.contains("[node name=\"CompletionFeedback\" parent=\".\" instance=ExtResource"), "Main scene instances CompletionFeedback")
```

- [x] **Step 2: Register failing test**

Modify `tests/test_runner.gd` and add the test after `test_quest_state.gd`:

```gdscript
"res://tests/test_quest_state.gd",
"res://tests/test_main_flow_acceptance.gd",
"res://tests/test_dialogue.gd",
```

- [x] **Step 3: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because `EventBus` lacks `quest_completed` / `completion_feedback_requested`, and `Main.tscn` lacks `CompletionFeedback`.

## Task 2: Completion Signals GREEN

**Files:**
- Modify: `scripts/autoload/EventBus.gd`
- Modify: `scripts/autoload/Game.gd`
- Test: `tests/test_main_flow_acceptance.gd`

- [x] **Step 1: Add EventBus completion signals**

Add to `scripts/autoload/EventBus.gd`:

```gdscript
signal quest_completed()
signal completion_feedback_requested(title: String, message: String)
```

- [x] **Step 2: Emit completion feedback from Game**

Modify `scripts/autoload/Game.gd`:

```gdscript
const COMPLETION_TITLE := "试炼完成"
const COMPLETION_MESSAGE := "飞剑归鞘，山谷封印已净。你已完成剑修试炼。"

var completion_feedback_emitted := false
```

Reset it in `reset_demo()`:

```gdscript
func reset_demo() -> void:
	save_state.reset()
	quest_state.current_step = save_state.quest_step
	completion_feedback_emitted = false
	comfort_settings.apply_mode("comfort")
```

Update `advance_quest(event_id)`:

```gdscript
func advance_quest(event_id: String) -> bool:
	var advanced: bool = quest_state.advance(event_id)
	if advanced:
		save_state.quest_step = quest_state.current_step
		EventBus.quest_step_changed.emit(quest_state.current_step)
		EventBus.objective_changed.emit(quest_state.current_objective())
		if quest_state.current_step == "complete" and not completion_feedback_emitted:
			completion_feedback_emitted = true
			EventBus.quest_completed.emit()
			EventBus.completion_feedback_requested.emit(COMPLETION_TITLE, COMPLETION_MESSAGE)
	return advanced
```

- [x] **Step 3: Run tests and verify partial GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: main-flow signal assertions pass, but `Main.tscn` still fails until `CompletionFeedback` is added.

## Task 3: Completion Feedback UI RED

**Files:**
- Create: `tests/test_completion_feedback.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write failing feedback UI test**

Create `tests/test_completion_feedback.gd`:

```gdscript
extends RefCounted

const FEEDBACK_SCENE := "res://scenes/ui/CompletionFeedback.tscn"

func run(t) -> void:
	_test_completion_feedback_scene_exists(t)
	_test_completion_feedback_updates_visible_text(t)

func _test_completion_feedback_scene_exists(t) -> void:
	t.assert_true(ResourceLoader.exists(FEEDBACK_SCENE), "CompletionFeedback scene exists")
	if not ResourceLoader.exists(FEEDBACK_SCENE):
		return
	var scene := load(FEEDBACK_SCENE)
	t.assert_true(scene is PackedScene, "CompletionFeedback scene loads")
	if not scene is PackedScene:
		return
	var feedback = scene.instantiate()
	t.assert_true(feedback.get_node_or_null("Panel/TitleLabel") is Label, "feedback has title label")
	t.assert_true(feedback.get_node_or_null("Panel/MessageLabel") is Label, "feedback has message label")
	t.assert_true(feedback.get_node_or_null("CompletionAudio") is AudioStreamPlayer, "feedback has optional audio player")
	feedback.free()

func _test_completion_feedback_updates_visible_text(t) -> void:
	if not ResourceLoader.exists(FEEDBACK_SCENE):
		return
	var feedback = load(FEEDBACK_SCENE).instantiate()
	t.assert_true(feedback.has_method("show_completion"), "feedback exposes show_completion")
	if not feedback.has_method("show_completion"):
		feedback.free()
		return
	t.assert_true(not feedback.feedback_visible, "feedback starts hidden")
	feedback.show_completion("试炼完成", "飞剑归鞘")
	t.assert_true(feedback.feedback_visible, "feedback becomes visible")
	t.assert_equal(feedback.get_node("Panel/TitleLabel").text, "试炼完成", "title label updates")
	t.assert_equal(feedback.get_node("Panel/MessageLabel").text, "飞剑归鞘", "message label updates")
	feedback.show_completion("完成", "新的反馈")
	t.assert_equal(feedback.get_node("Panel/TitleLabel").text, "完成", "repeat request updates same title")
	t.assert_equal(feedback.get_node("Panel/MessageLabel").text, "新的反馈", "repeat request updates same message")
	feedback.free()
```

- [x] **Step 2: Register failing feedback test**

Modify `tests/test_runner.gd` and add the test after `test_main_flow_acceptance.gd`:

```gdscript
"res://tests/test_main_flow_acceptance.gd",
"res://tests/test_completion_feedback.gd",
"res://tests/test_dialogue.gd",
```

- [x] **Step 3: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because `CompletionFeedback.tscn` does not exist.

## Task 4: Completion Feedback UI GREEN

**Files:**
- Create: `scripts/ui/CompletionFeedback.gd`
- Create: `scenes/ui/CompletionFeedback.tscn`
- Modify: `scenes/main/Main.tscn`
- Test: `tests/test_completion_feedback.gd`, `tests/test_main_flow_acceptance.gd`

- [x] **Step 1: Add CompletionFeedback script**

Create `scripts/ui/CompletionFeedback.gd`:

```gdscript
extends CanvasLayer
class_name CompletionFeedback

@export var panel_path: NodePath = ^"Panel"
@export var title_label_path: NodePath = ^"Panel/TitleLabel"
@export var message_label_path: NodePath = ^"Panel/MessageLabel"
@export var audio_player_path: NodePath = ^"CompletionAudio"

var feedback_visible := false

func _ready() -> void:
	_set_panel_visible(false)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("completion_feedback_requested"):
		event_bus.completion_feedback_requested.connect(show_completion)

func show_completion(title: String, message: String) -> void:
	var title_label := get_node_or_null(title_label_path) as Label
	var message_label := get_node_or_null(message_label_path) as Label
	if title_label != null:
		title_label.text = title
	if message_label != null:
		message_label.text = message
	feedback_visible = true
	_set_panel_visible(true)
	var audio_player := get_node_or_null(audio_player_path) as AudioStreamPlayer
	if audio_player != null and audio_player.stream != null:
		audio_player.play()

func _set_panel_visible(visible: bool) -> void:
	var panel := get_node_or_null(panel_path) as CanvasItem
	if panel != null:
		panel.visible = visible
```

- [x] **Step 2: Add CompletionFeedback scene**

Create `scenes/ui/CompletionFeedback.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/CompletionFeedback.gd" id="1"]

[node name="CompletionFeedback" type="CanvasLayer"]
script = ExtResource("1")

[node name="Panel" type="Panel" parent="."]
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -260.0
offset_top = -80.0
offset_right = 260.0
offset_bottom = 80.0
grow_horizontal = 2
grow_vertical = 2

[node name="TitleLabel" type="Label" parent="Panel"]
anchors_preset = 10
anchor_right = 1.0
offset_left = 24.0
offset_top = 24.0
offset_right = -24.0
offset_bottom = 58.0
grow_horizontal = 2
text = "试炼完成"
horizontal_alignment = 1

[node name="MessageLabel" type="Label" parent="Panel"]
anchors_preset = 10
anchor_right = 1.0
offset_left = 24.0
offset_top = 72.0
offset_right = -24.0
offset_bottom = 132.0
grow_horizontal = 2
text = "飞剑归鞘"
horizontal_alignment = 1
autowrap_mode = 2

[node name="CompletionAudio" type="AudioStreamPlayer" parent="."]
```

- [x] **Step 3: Instance CompletionFeedback in Main**

Modify `scenes/main/Main.tscn`:

```ini
[gd_scene load_steps=9 format=3]

[ext_resource type="PackedScene" path="res://scenes/ui/CompletionFeedback.tscn" id="6"]

[node name="CompletionFeedback" parent="." instance=ExtResource("6")]
```

Keep existing ext_resource IDs intact; use the next available ID if `6` is already taken.

- [x] **Step 4: Run tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass.

## Task 5: Acceptance Checklist and Final Validation

**Files:**
- Modify: `docs/testing/vr-demo-acceptance.md`
- Modify: `docs/superpowers/plans/2026-06-11-main-flow-acceptance-feedback.md`

- [x] **Step 1: Update acceptance checklist**

Modify `docs/testing/vr-demo-acceptance.md` automated section to include:

```markdown
- [x] Automated main-flow acceptance covers quest event sequence through completion.
- [x] Completion feedback is covered by headless UI tests.
```

Do not check manual or VR headset items in this pass.

- [x] **Step 2: Run full test suite**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: exit 0 with `TESTS PASSED: <N> assertions`.

- [x] **Step 3: Run Godot syntax and scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit 0.

- [x] **Step 4: Inspect git diff**

Run:

```bash
git diff -- scripts/autoload scripts/ui scenes/ui scenes/main tests docs/testing/vr-demo-acceptance.md docs/superpowers/plans/2026-06-11-main-flow-acceptance-feedback.md
```

Expected:

- `EventBus` has explicit completion signals.
- `Game` emits completion signals only when reaching `complete`.
- `CompletionFeedback` is UI-only and null-safe.
- `Main.tscn` instances `CompletionFeedback`.
- Tests cover full event sequence, completion events, and feedback UI.

- [x] **Step 5: Commit implementation**

Run:

```bash
git add scripts/autoload/EventBus.gd scripts/autoload/Game.gd scripts/ui/CompletionFeedback.gd scenes/ui/CompletionFeedback.tscn scenes/main/Main.tscn tests/test_main_flow_acceptance.gd tests/test_completion_feedback.gd tests/test_runner.gd docs/testing/vr-demo-acceptance.md docs/superpowers/plans/2026-06-11-main-flow-acceptance-feedback.md
git commit -m "feat: add main flow completion feedback"
```

Expected: commit succeeds after verification passes.

## Self-Review

- Spec coverage: Tasks cover main-flow acceptance, completion-specific EventBus signals, exactly-once completion feedback, feedback UI behavior, main-scene wiring, acceptance checklist updates, and final Godot verification.
- Placeholder scan: No TBD/TODO placeholders remain; all code and commands are explicit.
- Type consistency: Signal names, method names, paths, and scene node names are consistent across tests, scripts, and scene snippets.
