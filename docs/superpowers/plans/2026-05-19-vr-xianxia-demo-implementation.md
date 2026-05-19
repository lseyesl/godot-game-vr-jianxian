# VR Xianxia Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a polished, playable Godot 4.6+ PCVR vertical slice where a novice sword cultivator explores a large-feeling town, receives clues from inn/tavern NPCs, completes a mountain trial with standing spellcasting, recovers a flying sword, and flies back to town.

**Architecture:** The project is split into small Godot scenes and GDScript modules: quest state, dialogue, comfort settings, spellcasting, seal encounter, flying sword, XR/player control, UI, and world composition. Core gameplay logic is tested with a lightweight headless GDScript test runner before being wired into scenes. XR-specific scenes wrap the same gameplay modules so the demo remains testable without a headset.

**Tech Stack:** Godot 4.6+, GDScript, OpenXR, Godot XR Tools, PCVR/SteamVR first, future Quest performance profile.

---

## File Structure Map

Create this structure from an empty repo:

```text
project.godot                         # Godot project settings, input map, autoloads
addons/                               # Godot XR Tools addon copied/imported through Godot AssetLib or git submodule
assets/audio/                         # Licensed or generated audio clips
assets/materials/                     # Stylized materials
assets/models/                        # Low-poly modular town/mountain models
assets/textures/                      # Stylized textures
docs/superpowers/specs/               # Existing design spec
docs/superpowers/plans/               # This implementation plan
export_presets.cfg                    # PCVR export preset after project setup
scenes/main/Main.tscn                 # Runtime entry scene after menu
scenes/menu/MainMenu.tscn             # Start/reset/settings menu
scenes/player/XRPlayer.tscn           # VR player rig wrapper
scenes/player/DesktopDebugPlayer.tscn # Non-VR debug player for automated/manual testing
scenes/town/Town.tscn                 # Town graybox and town props
scenes/mountain/MountainTrial.tscn    # Mountain route, seal, demon, sword altar
scenes/npc/Npc.tscn                   # Reusable NPC scene
scenes/interaction/SealEncounter.tscn # Seal + demon encounter scene
scenes/items/FlyingSword.tscn         # Sword visual and interaction scene
scenes/spells/SpellProjectile.tscn    # Reusable projectile visual
scenes/ui/TaskHud.tscn                # VR/world-space task HUD
scenes/ui/ComfortSettingsPanel.tscn   # Comfort options UI
scripts/autoload/Game.gd              # Global runtime state and scene transition API
scripts/autoload/EventBus.gd          # Signals shared across modules
scripts/core/ComfortSettings.gd       # Comfort mode data and validation
scripts/core/QuestState.gd            # Quest finite state machine
scripts/core/SaveState.gd             # Continue/reset demo state resource
scripts/npc/NpcDialogue.gd            # Dialogue selection by quest state
scripts/spells/SpellCaster.gd         # Standing spellcasting input and cooldowns
scripts/spells/SpellProjectile.gd     # Projectile movement and hit callback
scripts/interaction/SealEncounter.gd  # Seal/demon encounter rules
scripts/items/FlyingSword.gd          # Sword unlock, recall, hover state
scripts/player/XRPlayer.gd            # XR locomotion and flight bridge
scripts/player/DesktopDebugPlayer.gd  # Keyboard/mouse debug controls
scripts/ui/TaskHud.gd                 # Quest objective display
scripts/ui/ComfortSettingsPanel.gd    # Settings UI bindings
tests/test_runner.gd                  # Lightweight headless test runner
tests/test_quest_state.gd             # Quest state tests
tests/test_comfort_settings.gd        # Comfort setting tests
tests/test_dialogue.gd                # Dialogue selection tests
tests/test_spell_caster.gd            # Spell cooldown/cast tests
tests/test_seal_encounter.gd          # Encounter completion tests
tests/test_flying_sword.gd            # Sword unlock/flight tests
```

## Verification Commands Used Throughout

Use these commands after relevant tasks:

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
GIT_MASTER=1 git status --short
```

Expected successful test output:

```text
TESTS PASSED: <number> assertions
```

If `godot` is unavailable on the machine, install Godot 4.6+ or run the same commands through the Godot editor command line. Do not mark a task complete without running the verification command in the implementation environment.

---

### Task 1: Godot Project Scaffold and Test Harness

**Files:**
- Create: `project.godot`
- Create: `tests/test_runner.gd`
- Create: `.gitignore`

- [ ] **Step 1: Create `.gitignore`**

```gitignore
.godot/
*.tmp
*.import
export_presets.cfg.bak
*.translation
```

- [ ] **Step 2: Create `project.godot` with OpenXR-ready settings**

```ini
; Engine configuration file.
; Godot 4.6+ project for VR Xianxia Demo.

config_version=5

[application]
config/name="VR Xianxia Demo"
run/main_scene="res://scenes/menu/MainMenu.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")

[autoload]
EventBus="*res://scripts/autoload/EventBus.gd"
Game="*res://scripts/autoload/Game.gd"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/vsync/vsync_mode=0

[input]
spell_primary={"deadzone":0.5,"events":[]}
spell_guard={"deadzone":0.5,"events":[]}
spell_seal={"deadzone":0.5,"events":[]}
interact={"deadzone":0.5,"events":[]}
flight_toggle={"deadzone":0.5,"events":[]}

[rendering]
renderer/rendering_method="mobile"
anti_aliasing/quality/msaa_3d=2
environment/defaults/default_clear_color=Color(0.46, 0.55, 0.62, 1)

[xr]
openxr/enabled=true
```

- [ ] **Step 3: Create `tests/test_runner.gd`**

```gdscript
extends SceneTree

var assertions := 0
var failures: Array[String] = []

func _init() -> void:
	var test_paths := [
		"res://tests/test_comfort_settings.gd",
		"res://tests/test_quest_state.gd",
		"res://tests/test_dialogue.gd",
		"res://tests/test_spell_caster.gd",
		"res://tests/test_seal_encounter.gd",
		"res://tests/test_flying_sword.gd",
	]
	for path in test_paths:
		if ResourceLoader.exists(path):
			_run_test_script(path)
	if failures.is_empty():
		print("TESTS PASSED: %d assertions" % assertions)
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		printerr("TESTS FAILED: %d failure(s), %d assertion(s)" % [failures.size(), assertions])
		quit(1)

func _run_test_script(path: String) -> void:
	var script := load(path)
	var instance: Object = script.new()
	if instance.has_method("run"):
		instance.run(self)
	else:
		fail(path, "missing run(test_runner) method")

func assert_true(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		fail("assert_true", message)

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	assertions += 1
	if actual != expected:
		fail("assert_equal", "%s | actual=%s expected=%s" % [message, str(actual), str(expected)])

func fail(source: String, message: String) -> void:
	failures.append("%s: %s" % [source, message])
```

- [ ] **Step 4: Run empty harness**

Run:

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

Expected:

```text
TESTS PASSED: 0 assertions
```

- [ ] **Step 5: Commit**

```bash
GIT_MASTER=1 git add .gitignore project.godot tests/test_runner.gd
GIT_MASTER=1 git commit -m "Add Godot project scaffold"
```

---

### Task 2: Autoloads and Core Settings

**Files:**
- Create: `scripts/autoload/EventBus.gd`
- Create: `scripts/autoload/Game.gd`
- Create: `scripts/core/ComfortSettings.gd`
- Create: `scripts/core/SaveState.gd`
- Create: `tests/test_comfort_settings.gd`

- [ ] **Step 1: Write failing comfort settings tests**

```gdscript
extends RefCounted

func run(t) -> void:
	var ComfortSettings := load("res://scripts/core/ComfortSettings.gd")
	var settings = ComfortSettings.new()
	t.assert_equal(settings.movement_mode, "comfort", "default movement mode is comfort")
	t.assert_equal(settings.turn_mode, "snap", "default turn mode is snap")
	t.assert_true(settings.flight_vignette_enabled, "flight vignette is enabled by default")
	settings.apply_mode("immersive")
	t.assert_equal(settings.movement_mode, "immersive", "immersive mode changes movement mode")
	t.assert_equal(settings.turn_mode, "smooth", "immersive mode changes turn mode")
	t.assert_true(settings.flight_speed_limit_mps > 0.0, "speed limit remains positive")
	settings.apply_mode("unknown")
	t.assert_equal(settings.movement_mode, "comfort", "unknown mode falls back to comfort")
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

Expected: fails because `scripts/core/ComfortSettings.gd` does not exist.

- [ ] **Step 3: Implement `scripts/core/ComfortSettings.gd`**

```gdscript
extends Resource
class_name ComfortSettings

@export var movement_mode := "comfort"
@export var turn_mode := "snap"
@export var flight_vignette_enabled := true
@export var flight_speed_limit_mps := 6.0
@export var flight_height_limit_m := 45.0

func apply_mode(mode: String) -> void:
	if mode == "immersive":
		movement_mode = "immersive"
		turn_mode = "smooth"
		flight_vignette_enabled = false
		flight_speed_limit_mps = 9.0
		flight_height_limit_m = 60.0
	else:
		movement_mode = "comfort"
		turn_mode = "snap"
		flight_vignette_enabled = true
		flight_speed_limit_mps = 6.0
		flight_height_limit_m = 45.0
```

- [ ] **Step 4: Implement `scripts/core/SaveState.gd`**

```gdscript
extends Resource
class_name SaveState

@export var quest_step := "start"
@export var sword_unlocked := false
@export var comfort_mode := "comfort"

func reset() -> void:
	quest_step = "start"
	sword_unlocked = false
	comfort_mode = "comfort"
```

- [ ] **Step 5: Implement autoloads**

`scripts/autoload/EventBus.gd`:

```gdscript
extends Node

signal quest_step_changed(step: String)
signal objective_changed(text: String)
signal dialogue_requested(npc_id: String)
signal spell_cast(spell_id: String)
signal seal_weakened(remaining_hits: int)
signal seal_cleansed()
signal sword_unlocked()
signal flight_mode_changed(enabled: bool)
signal comfort_settings_changed(settings: ComfortSettings)
```

`scripts/autoload/Game.gd`:

```gdscript
extends Node

var save_state := SaveState.new()
var comfort_settings := ComfortSettings.new()

func reset_demo() -> void:
	save_state.reset()
	comfort_settings.apply_mode("comfort")

func apply_comfort_mode(mode: String) -> void:
	comfort_settings.apply_mode(mode)
	save_state.comfort_mode = comfort_settings.movement_mode
	EventBus.comfort_settings_changed.emit(comfort_settings)
```

- [ ] **Step 6: Run tests and syntax check**

Run:

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
```

Expected: tests pass and check-only exits 0.

- [ ] **Step 7: Commit**

```bash
GIT_MASTER=1 git add scripts/autoload scripts/core tests/test_comfort_settings.gd project.godot
GIT_MASTER=1 git commit -m "Add core game settings"
```

---

### Task 3: Quest State Machine

**Files:**
- Create: `scripts/core/QuestState.gd`
- Create: `tests/test_quest_state.gd`

- [ ] **Step 1: Write failing quest tests**

```gdscript
extends RefCounted

func run(t) -> void:
	var QuestState := load("res://scripts/core/QuestState.gd")
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
```

- [ ] **Step 2: Run tests and verify failure**

Expected: fails because `QuestState.gd` is missing.

- [ ] **Step 3: Implement `scripts/core/QuestState.gd`**

```gdscript
extends RefCounted
class_name QuestState

const OBJECTIVES := {
	"start": "前往客栈，询问遗失飞剑的线索",
	"ask_tavern": "前往酒馆，打听山谷异动",
	"go_to_mountain": "穿过镇门，前往山谷试炼地",
	"cleanse_seal": "站立施法，驱散小妖并破除封印",
	"collect_sword": "取回祭台上的飞剑",
	"fly_back": "御剑飞回小镇高台",
	"complete": "试炼完成，飞剑已归鞘",
}

const TRANSITIONS := {
	"start": {"talked_to_innkeeper": "ask_tavern"},
	"ask_tavern": {"talked_to_tavern_keeper": "go_to_mountain"},
	"go_to_mountain": {"entered_trial": "cleanse_seal"},
	"cleanse_seal": {"seal_cleansed": "collect_sword"},
	"collect_sword": {"sword_collected": "fly_back"},
	"fly_back": {"returned_to_town": "complete"},
	"complete": {},
}

var current_step := "start"

func current_objective() -> String:
	return OBJECTIVES.get(current_step, "")

func advance(event_id: String) -> bool:
	var options: Dictionary = TRANSITIONS.get(current_step, {})
	if not options.has(event_id):
		return false
	current_step = options[event_id]
	return true
```

- [ ] **Step 4: Wire quest into `Game.gd`**

Add to `scripts/autoload/Game.gd`:

```gdscript
var quest_state := QuestState.new()

func advance_quest(event_id: String) -> bool:
	var advanced := quest_state.advance(event_id)
	if advanced:
		save_state.quest_step = quest_state.current_step
		EventBus.quest_step_changed.emit(quest_state.current_step)
		EventBus.objective_changed.emit(quest_state.current_objective())
	return advanced
```

- [ ] **Step 5: Run tests**

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
GIT_MASTER=1 git add scripts/core/QuestState.gd scripts/autoload/Game.gd tests/test_quest_state.gd
GIT_MASTER=1 git commit -m "Add quest state machine"
```

---

### Task 4: NPC Dialogue System

**Files:**
- Create: `scripts/npc/NpcDialogue.gd`
- Create: `scenes/npc/Npc.tscn`
- Create: `tests/test_dialogue.gd`

- [ ] **Step 1: Write failing dialogue tests**

```gdscript
extends RefCounted

func run(t) -> void:
	var NpcDialogue := load("res://scripts/npc/NpcDialogue.gd")
	var inn = NpcDialogue.new()
	inn.npc_id = "innkeeper"
	t.assert_true(inn.line_for_step("start").contains("飞剑"), "innkeeper mentions sword at start")
	t.assert_equal(inn.quest_event_for_step("start"), "talked_to_innkeeper", "innkeeper advances start")
	var tavern = NpcDialogue.new()
	tavern.npc_id = "tavern_keeper"
	t.assert_true(tavern.line_for_step("ask_tavern").contains("山谷"), "tavern keeper points to mountain")
	t.assert_equal(tavern.quest_event_for_step("ask_tavern"), "talked_to_tavern_keeper", "tavern advances ask_tavern")
```

- [ ] **Step 2: Implement `scripts/npc/NpcDialogue.gd`**

```gdscript
extends Node
class_name NpcDialogue

@export var npc_id := "townsperson"

const LINES := {
	"innkeeper": {
		"start": "少侠，你的飞剑昨夜化作青光飞向山谷。先去酒馆问问，说书人见过那道光。",
		"complete": "飞剑归来，气息也稳了。你已踏出剑仙第一步。",
		"default": "客栈有热茶，也有远行人的消息。",
	},
	"tavern_keeper": {
		"ask_tavern": "山谷旧祭台有妖气盘旋。沿镇门外的石阶走，看到瀑布就到了。",
		"default": "酒香压不住山里的怪风，今夜少往山里去。",
	},
	"trial_spirit": {
		"cleanse_seal": "凝神，立定，掌心聚灵。以灵光破妖，以破封诀开阵。",
		"default": "试炼只认心定之人。",
	},
}

const EVENTS := {
	"innkeeper": {"start": "talked_to_innkeeper"},
	"tavern_keeper": {"ask_tavern": "talked_to_tavern_keeper"},
}

func line_for_step(step: String) -> String:
	var npc_lines: Dictionary = LINES.get(npc_id, {})
	return npc_lines.get(step, npc_lines.get("default", "……"))

func quest_event_for_step(step: String) -> String:
	var npc_events: Dictionary = EVENTS.get(npc_id, {})
	return npc_events.get(step, "")

func interact(current_step: String) -> String:
	var event_id := quest_event_for_step(current_step)
	if event_id != "":
		Game.advance_quest(event_id)
	return line_for_step(current_step)
```

- [ ] **Step 3: Create `scenes/npc/Npc.tscn`**

Use Godot editor or write a minimal scene:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/npc/NpcDialogue.gd" id="1"]

[node name="Npc" type="Node3D"]
script = ExtResource("1")

[node name="Body" type="MeshInstance3D" parent="."]

[node name="InteractArea" type="Area3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="InteractArea"]
```

- [ ] **Step 4: Run tests and check project**

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
```

Expected: dialogue tests pass.

- [ ] **Step 5: Commit**

```bash
GIT_MASTER=1 git add scripts/npc scenes/npc tests/test_dialogue.gd
GIT_MASTER=1 git commit -m "Add NPC dialogue system"
```

---

### Task 5: Standing Spellcasting System

**Files:**
- Create: `scripts/spells/SpellCaster.gd`
- Create: `scripts/spells/SpellProjectile.gd`
- Create: `scenes/spells/SpellProjectile.tscn`
- Create: `tests/test_spell_caster.gd`

- [ ] **Step 1: Write failing spell tests**

```gdscript
extends RefCounted

func run(t) -> void:
	var SpellCaster := load("res://scripts/spells/SpellCaster.gd")
	var caster = SpellCaster.new()
	t.assert_true(caster.can_cast("spirit_bolt"), "spirit bolt starts ready")
	t.assert_true(caster.cast("spirit_bolt"), "spirit bolt casts")
	t.assert_true(not caster.can_cast("spirit_bolt"), "cooldown starts after cast")
	caster.tick_cooldowns(2.0)
	t.assert_true(caster.can_cast("spirit_bolt"), "spirit bolt returns after cooldown")
	t.assert_true(caster.cast("seal_break"), "seal break casts")
	t.assert_true(not caster.cast("unknown"), "unknown spell does not cast")
```

- [ ] **Step 2: Implement `scripts/spells/SpellCaster.gd`**

```gdscript
extends Node
class_name SpellCaster

const SPELLS := {
	"spirit_bolt": {"cooldown": 1.0, "label": "灵光弹"},
	"guard_charm": {"cooldown": 4.0, "label": "护身诀"},
	"seal_break": {"cooldown": 2.0, "label": "破封印"},
}

var cooldowns: Dictionary = {}

func can_cast(spell_id: String) -> bool:
	return SPELLS.has(spell_id) and float(cooldowns.get(spell_id, 0.0)) <= 0.0

func cast(spell_id: String) -> bool:
	if not can_cast(spell_id):
		return false
	cooldowns[spell_id] = SPELLS[spell_id]["cooldown"]
	EventBus.spell_cast.emit(spell_id)
	return true

func tick_cooldowns(delta: float) -> void:
	for spell_id in cooldowns.keys():
		cooldowns[spell_id] = maxf(0.0, float(cooldowns[spell_id]) - delta)
```

- [ ] **Step 3: Implement `scripts/spells/SpellProjectile.gd`**

```gdscript
extends Area3D
class_name SpellProjectile

@export var spell_id := "spirit_bolt"
@export var speed_mps := 16.0
@export var lifetime_s := 3.0

var direction := Vector3.FORWARD
var age := 0.0

func launch(origin: Vector3, forward: Vector3) -> void:
	global_position = origin
	direction = forward.normalized()
	age = 0.0

func _physics_process(delta: float) -> void:
	global_position += direction * speed_mps * delta
	age += delta
	if age >= lifetime_s:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("receive_spell"):
		body.receive_spell(spell_id)
	queue_free()
```

- [ ] **Step 4: Create projectile scene**

`scenes/spells/SpellProjectile.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/spells/SpellProjectile.gd" id="1"]

[node name="SpellProjectile" type="Area3D"]
script = ExtResource("1")

[node name="Visual" type="MeshInstance3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
```

- [ ] **Step 5: Run tests and commit**

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
GIT_MASTER=1 git add scripts/spells scenes/spells tests/test_spell_caster.gd
GIT_MASTER=1 git commit -m "Add standing spellcasting"
```

---

### Task 6: Seal and Demon Trial Encounter

**Files:**
- Create: `scripts/interaction/SealEncounter.gd`
- Create: `scenes/interaction/SealEncounter.tscn`
- Create: `tests/test_seal_encounter.gd`

- [ ] **Step 1: Write failing encounter tests**

```gdscript
extends RefCounted

func run(t) -> void:
	var SealEncounter := load("res://scripts/interaction/SealEncounter.gd")
	var encounter = SealEncounter.new()
	t.assert_equal(encounter.remaining_hits, 3, "seal starts with three hits")
	encounter.receive_spell("spirit_bolt")
	t.assert_equal(encounter.remaining_hits, 2, "spirit bolt weakens demon seal")
	encounter.receive_spell("guard_charm")
	t.assert_equal(encounter.remaining_hits, 2, "guard charm does not weaken seal")
	encounter.receive_spell("seal_break")
	t.assert_equal(encounter.remaining_hits, 0, "seal break finishes encounter")
	t.assert_true(encounter.cleansed, "encounter is cleansed")
```

- [ ] **Step 2: Implement `scripts/interaction/SealEncounter.gd`**

```gdscript
extends Node3D
class_name SealEncounter

@export var remaining_hits := 3
var cleansed := false

func receive_spell(spell_id: String) -> void:
	if cleansed:
		return
	if spell_id == "spirit_bolt":
		remaining_hits = max(0, remaining_hits - 1)
	elif spell_id == "seal_break":
		remaining_hits = 0
	else:
		return
	EventBus.seal_weakened.emit(remaining_hits)
	if remaining_hits == 0:
		_cleanse()

func _cleanse() -> void:
	if cleansed:
		return
	cleansed = true
	EventBus.seal_cleansed.emit()
	Game.advance_quest("seal_cleansed")
```

- [ ] **Step 3: Create encounter scene**

`scenes/interaction/SealEncounter.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/interaction/SealEncounter.gd" id="1"]

[node name="SealEncounter" type="Node3D"]
script = ExtResource("1")

[node name="SealVisual" type="MeshInstance3D" parent="."]

[node name="DemonVisual" type="MeshInstance3D" parent="."]

[node name="HitArea" type="Area3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="HitArea"]
```

- [ ] **Step 4: Run tests and commit**

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
GIT_MASTER=1 git add scripts/interaction scenes/interaction tests/test_seal_encounter.gd
GIT_MASTER=1 git commit -m "Add mountain seal encounter"
```

---

### Task 7: Flying Sword Unlock and Flight State

**Files:**
- Create: `scripts/items/FlyingSword.gd`
- Create: `scenes/items/FlyingSword.tscn`
- Create: `tests/test_flying_sword.gd`

- [ ] **Step 1: Write failing sword tests**

```gdscript
extends RefCounted

func run(t) -> void:
	var FlyingSword := load("res://scripts/items/FlyingSword.gd")
	var sword = FlyingSword.new()
	t.assert_true(not sword.unlocked, "sword starts locked")
	t.assert_true(not sword.flight_enabled, "flight starts disabled")
	sword.collect()
	t.assert_true(sword.unlocked, "collect unlocks sword")
	t.assert_true(sword.flight_enabled, "collect enables flight")
	t.assert_equal(sword.hover_height_m, 0.8, "sword hover height is stable")
	sword.set_flight_enabled(false)
	t.assert_true(not sword.flight_enabled, "flight can be disabled")
```

- [ ] **Step 2: Implement `scripts/items/FlyingSword.gd`**

```gdscript
extends Node3D
class_name FlyingSword

@export var hover_height_m := 0.8
var unlocked := false
var flight_enabled := false

func collect() -> void:
	unlocked = true
	set_flight_enabled(true)
	EventBus.sword_unlocked.emit()
	Game.save_state.sword_unlocked = true
	Game.advance_quest("sword_collected")

func set_flight_enabled(enabled: bool) -> void:
	flight_enabled = enabled and unlocked
	EventBus.flight_mode_changed.emit(flight_enabled)

func recall_to_hand(hand_position: Vector3) -> void:
	if not unlocked:
		return
	global_position = hand_position + Vector3.UP * hover_height_m
```

- [ ] **Step 3: Create sword scene**

`scenes/items/FlyingSword.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/items/FlyingSword.gd" id="1"]

[node name="FlyingSword" type="Node3D"]
script = ExtResource("1")

[node name="Blade" type="MeshInstance3D" parent="."]

[node name="CollectArea" type="Area3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="CollectArea"]
```

- [ ] **Step 4: Run tests and commit**

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
GIT_MASTER=1 git add scripts/items scenes/items tests/test_flying_sword.gd
GIT_MASTER=1 git commit -m "Add flying sword unlock"
```

---

### Task 8: Player Controllers and XR Locomotion Bridge

**Files:**
- Create: `scripts/player/DesktopDebugPlayer.gd`
- Create: `scripts/player/XRPlayer.gd`
- Create: `scenes/player/DesktopDebugPlayer.tscn`
- Create: `scenes/player/XRPlayer.tscn`

- [ ] **Step 1: Implement desktop debug controller**

```gdscript
extends CharacterBody3D
class_name DesktopDebugPlayer

@export var walk_speed_mps := 4.0
@export var flight_speed_mps := 6.0
var flight_enabled := false

func _ready() -> void:
	EventBus.flight_mode_changed.connect(_on_flight_mode_changed)

func _physics_process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var speed := flight_speed_mps if flight_enabled else walk_speed_mps
	velocity = input.normalized() * speed
	if flight_enabled:
		velocity.y = Input.get_action_strength("ui_accept") * speed
	else:
		velocity.y -= 9.8 * delta
	move_and_slide()

func _on_flight_mode_changed(enabled: bool) -> void:
	flight_enabled = enabled
```

- [ ] **Step 2: Implement XR player bridge**

```gdscript
extends Node3D
class_name XRPlayer

@export var comfort_settings: ComfortSettings
var flight_enabled := false

func _ready() -> void:
	if comfort_settings == null:
		comfort_settings = Game.comfort_settings
	EventBus.flight_mode_changed.connect(_on_flight_mode_changed)
	EventBus.comfort_settings_changed.connect(_on_comfort_settings_changed)

func _on_flight_mode_changed(enabled: bool) -> void:
	flight_enabled = enabled
	# Connect this flag to Godot XR Tools flight provider during scene assembly.

func _on_comfort_settings_changed(settings: ComfortSettings) -> void:
	comfort_settings = settings
	# Apply snap/smooth turn, teleport/smooth movement, speed limit, and vignette values to XR Tools nodes.
```

- [ ] **Step 3: Create player scenes**

`scenes/player/DesktopDebugPlayer.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/player/DesktopDebugPlayer.gd" id="1"]

[node name="DesktopDebugPlayer" type="CharacterBody3D"]
script = ExtResource("1")

[node name="Camera3D" type="Camera3D" parent="."]
current = true
```

`scenes/player/XRPlayer.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/player/XRPlayer.gd" id="1"]

[node name="XRPlayer" type="Node3D"]
script = ExtResource("1")

[node name="XROrigin3D" type="XROrigin3D" parent="."]

[node name="XRCamera3D" type="XRCamera3D" parent="XROrigin3D"]

[node name="LeftHand" type="XRController3D" parent="XROrigin3D"]
tracker = &"left_hand"

[node name="RightHand" type="XRController3D" parent="XROrigin3D"]
tracker = &"right_hand"
```

- [ ] **Step 4: Import Godot XR Tools**

Use one of these paths:

```bash
# Preferred when internet access is available
GIT_MASTER=1 git submodule add https://github.com/GodotVR/godot-xr-tools.git addons/godot-xr-tools
```

or install through Godot AssetLib into `addons/godot-xr-tools`. After import, enable the plugin in Project Settings.

- [ ] **Step 5: Run project checks and commit**

```bash
godot --headless --path . --check-only
GIT_MASTER=1 git add scripts/player scenes/player addons/godot-xr-tools .gitmodules
GIT_MASTER=1 git commit -m "Add player locomotion scaffolding"
```

---

### Task 9: Menu, Task HUD, and Comfort Settings UI

**Files:**
- Create: `scripts/ui/TaskHud.gd`
- Create: `scripts/ui/ComfortSettingsPanel.gd`
- Create: `scenes/ui/TaskHud.tscn`
- Create: `scenes/ui/ComfortSettingsPanel.tscn`
- Create: `scenes/menu/MainMenu.tscn`

- [ ] **Step 1: Implement task HUD script**

```gdscript
extends CanvasLayer
class_name TaskHud

@onready var objective_label: Label = %ObjectiveLabel

func _ready() -> void:
	EventBus.objective_changed.connect(_on_objective_changed)
	_on_objective_changed(Game.quest_state.current_objective())

func _on_objective_changed(text: String) -> void:
	objective_label.text = text
```

- [ ] **Step 2: Implement comfort panel script**

```gdscript
extends Control
class_name ComfortSettingsPanel

func set_comfort_mode() -> void:
	Game.apply_comfort_mode("comfort")

func set_immersive_mode() -> void:
	Game.apply_comfort_mode("immersive")
```

- [ ] **Step 3: Create UI scenes in Godot editor**

Create `TaskHud.tscn` with this node tree:

```text
TaskHud (CanvasLayer, script TaskHud.gd)
└── ObjectivePanel (Panel)
    └── ObjectiveLabel (Label, unique name enabled)
```

Create `ComfortSettingsPanel.tscn` with this node tree:

```text
ComfortSettingsPanel (Control, script ComfortSettingsPanel.gd)
├── ComfortButton (Button, text: 舒适模式)
└── ImmersiveButton (Button, text: 沉浸模式)
```

Connect `ComfortButton.pressed` to `set_comfort_mode()` and `ImmersiveButton.pressed` to `set_immersive_mode()`.

Create `MainMenu.tscn` with:

```text
MainMenu (Control)
├── TitleLabel (Label, text: 剑仙小镇 VR Demo)
├── StartButton (Button, text: 开始试炼)
├── ResetButton (Button, text: 重置进度)
└── ComfortSettingsPanel (instance)
```

- [ ] **Step 4: Add menu navigation script**

Create `scripts/ui/MainMenu.gd`:

```gdscript
extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_reset_button_pressed() -> void:
	Game.reset_demo()
```

Attach it to `MainMenu.tscn` and connect buttons.

- [ ] **Step 5: Check and commit**

```bash
godot --headless --path . --check-only
GIT_MASTER=1 git add scripts/ui scenes/ui scenes/menu
GIT_MASTER=1 git commit -m "Add menu and VR task UI"
```

---

### Task 10: Town, Mountain, and Main Scene Graybox

**Files:**
- Create: `scenes/town/Town.tscn`
- Create: `scenes/mountain/MountainTrial.tscn`
- Create: `scenes/main/Main.tscn`
- Create: `scripts/world/TrialTrigger.gd`
- Create: `scripts/world/ReturnToTownTrigger.gd`

- [ ] **Step 1: Create trial trigger scripts**

`scripts/world/TrialTrigger.gd`:

```gdscript
extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Game.advance_quest("entered_trial")
```

`scripts/world/ReturnToTownTrigger.gd`:

```gdscript
extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Game.advance_quest("returned_to_town")
```

- [ ] **Step 2: Create `Town.tscn` graybox**

Build this scene in the editor using MeshInstance3D boxes/cylinders and simple materials:

```text
Town (Node3D)
├── Inn (Node3D)                    # enterable core building
│   └── Innkeeper (Npc instance, npc_id=innkeeper)
├── Tavern (Node3D)                 # enterable core building
│   └── TavernKeeper (Npc instance, npc_id=tavern_keeper)
├── MarketStreet (Node3D)           # stalls, lanterns, signs
├── GatePaifang (Node3D)            # route to mountain
├── SwordPracticeYard (Node3D)      # teaching/return space
├── ReturnToTownTrigger (Area3D, script ReturnToTownTrigger.gd)
└── DistantTownShells (Node3D)      # non-enterable roofs/streets for scale
```

Use at least 18 building shell meshes: 6 core shells, 12 distant shells. Keep collisions only on reachable paths and building interiors.

- [ ] **Step 3: Create `MountainTrial.tscn` graybox**

Build this scene:

```text
MountainTrial (Node3D)
├── MountainPath (Node3D)           # stone steps and cliffs
├── WaterfallVista (Node3D)         # visible landmark
├── TrialTrigger (Area3D, script TrialTrigger.gd)
├── SealEncounter (SealEncounter instance)
├── FlyingSword (FlyingSword instance)
├── FlightRouteMarkers (Node3D)     # visible rings/lanterns/cloud wisps
└── DistantMountains (Node3D)       # layered silhouettes
```

- [ ] **Step 4: Create `Main.tscn` composition**

```text
Main (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── XRPlayer or DesktopDebugPlayer
├── Town (instance)
├── MountainTrial (instance)
└── TaskHud (instance)
```

Use `DesktopDebugPlayer` as the default instance until XR runtime testing begins; keep `XRPlayer` saved and ready for headset testing.

- [ ] **Step 5: Manual acceptance check**

Run:

```bash
godot --path .
```

Expected manual result: Start menu opens, Start loads the world, the player can navigate from town to mountain in desktop debug mode, and the objective text updates after NPC interactions/triggers.

- [ ] **Step 6: Commit**

```bash
GIT_MASTER=1 git add scenes/town scenes/mountain scenes/main scripts/world
GIT_MASTER=1 git commit -m "Add town and mountain graybox"
```

---

### Task 11: Art, Audio, and Performance Pass

**Files:**
- Create/Modify: `assets/materials/*.tres`
- Create/Modify: `assets/audio/*.ogg`
- Modify: `scenes/town/Town.tscn`
- Modify: `scenes/mountain/MountainTrial.tscn`
- Modify: `scenes/spells/SpellProjectile.tscn`
- Modify: `scenes/items/FlyingSword.tscn`

- [ ] **Step 1: Create core stylized material resources**

Create these materials in Godot:

```text
assets/materials/mat_warm_wood.tres       # inn/tavern beams
assets/materials/mat_dark_roof_tile.tres  # layered roofs
assets/materials/mat_lantern_red.tres     # lanterns and signs
assets/materials/mat_mountain_rock.tres   # cliffs and distant mountains
assets/materials/mat_mist_blue.tres       # transparent mist planes
assets/materials/mat_spell_cyan.tres      # spells and seal feedback
```

- [ ] **Step 2: Apply art direction to reachable areas**

Polish these exact locations:

```text
Town/Inn
Town/Tavern
Town/MarketStreet
Town/GatePaifang
MountainTrial/MountainPath
MountainTrial/WaterfallVista
MountainTrial/SealEncounter
MountainTrial/DistantMountains
```

Keep dense detail near the player and use low-detail silhouettes for far scenery.

- [ ] **Step 3: Add audio nodes**

Add these AudioStreamPlayer3D or AudioStreamPlayer nodes:

```text
Town ambience: crowd murmur, wood creak, tavern room tone
Mountain ambience: wind, birds, water stream, distant waterfall
Spell effects: cast start, projectile release, hit, seal break
Sword effects: reveal, hover, flight wind
Completion cue: short success chime
```

- [ ] **Step 4: Performance check**

Run the demo in Godot editor and record these numbers in `progress.md`:

```text
Desktop debug FPS in town:
Desktop debug FPS in mountain:
PCVR headset FPS in town:
PCVR headset FPS in mountain:
Worst visible stutter location:
Largest suspected cost:
```

Acceptance target: PCVR should feel stable enough for a demo pass before adding more content. If headset testing is unavailable, mark headset numbers as not measured in `progress.md` and do not claim PCVR performance is verified.

- [ ] **Step 5: Commit**

```bash
GIT_MASTER=1 git add assets scenes/town scenes/mountain scenes/spells scenes/items progress.md
GIT_MASTER=1 git commit -m "Polish town and mountain presentation"
```

---

### Task 12: Full Demo Integration and Release Checklist

**Files:**
- Create: `docs/testing/vr-demo-acceptance.md`
- Modify: `export_presets.cfg`
- Modify: any scene/script that fails the checklist

- [ ] **Step 1: Create acceptance checklist**

`docs/testing/vr-demo-acceptance.md`:

```markdown
# VR Demo Acceptance Checklist

## Automated

- [ ] `godot --headless --path . --script res://tests/test_runner.gd` passes.
- [ ] `godot --headless --path . --check-only` exits 0.

## Main Flow

- [ ] Main menu opens.
- [ ] Comfort mode is default.
- [ ] Immersive mode can be selected.
- [ ] Player can enter town.
- [ ] Inn NPC advances objective to tavern.
- [ ] Tavern NPC advances objective to mountain.
- [ ] Trial trigger advances objective to seal encounter.
- [ ] Spirit bolt weakens the seal/demon encounter.
- [ ] Seal break finishes the seal encounter.
- [ ] Flying sword can be collected.
- [ ] Flight mode unlocks only after sword collection.
- [ ] Player can fly back to town.
- [ ] Return trigger completes the quest.
- [ ] Completion feedback appears and plays sound.

## VR Comfort

- [ ] Snap turn is active in comfort mode.
- [ ] Teleport or comfort movement is active in town.
- [ ] Flight speed is limited in comfort mode.
- [ ] Flight vignette or equivalent comfort effect is active.
- [ ] Smooth movement/turning is available in immersive mode.

## Scene Quality

- [ ] Inn and tavern are enterable.
- [ ] Town looks large from ground level.
- [ ] Town looks large from flight view.
- [ ] Mountain route has visible distant scenery.
- [ ] Flying route frames the town and mountains.
- [ ] No blocking collision traps were found during one full playthrough.
```

- [ ] **Step 2: Configure export preset for PCVR**

Use Godot editor to create a desktop export preset. Keep the preset named:

```text
PCVR Demo
```

Export output path:

```text
builds/pcvr/VRXianxiaDemo.exe
```

- [ ] **Step 3: Run automated verification**

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --check-only
```

Expected: tests pass and check-only exits 0.

- [ ] **Step 4: Run manual full playthrough**

Follow every checklist item in `docs/testing/vr-demo-acceptance.md`. Update each checkbox based on observed behavior. If a checklist item fails, fix the relevant script or scene, then repeat the full playthrough.

- [ ] **Step 5: Build PCVR demo**

```bash
godot --headless --path . --export-release "PCVR Demo" builds/pcvr/VRXianxiaDemo.exe
```

Expected: export exits 0 and creates `builds/pcvr/VRXianxiaDemo.exe`.

- [ ] **Step 6: Commit release readiness**

```bash
GIT_MASTER=1 git add docs/testing export_presets.cfg scenes scripts assets project.godot progress.md
GIT_MASTER=1 git commit -m "Prepare playable PCVR demo build"
```

---

## Plan Self-Review

### Spec Coverage

- Godot 4.6+ / OpenXR / XR Tools: covered by Tasks 1 and 8.
- PCVR first, Quest later: covered by project settings, performance pass, and no Quest-first commitment.
- Main flow from town to mountain to sword recovery to flight return: covered by Tasks 3, 4, 6, 7, 10, and 12.
- Inn and tavern with NPCs: covered by Tasks 4 and 10.
- Large town and mountains: covered by Tasks 10 and 11.
- Standing spellcasting: covered by Task 5.
- Small demon/seal encounter: covered by Task 6.
- Flying sword and comfort flight: covered by Tasks 7 and 8.
- Menu, settings, task hints, audio, completion feedback: covered by Tasks 9, 11, and 12.
- Formal verification: covered by the test runner and acceptance checklist.

### Placeholder Scan

The plan contains no intentionally deferred implementation sections. Where editor-created scenes are required, exact node trees, scripts, paths, and acceptance checks are specified.

### Type and Name Consistency

The plan consistently uses these IDs and names: `ComfortSettings`, `QuestState`, `NpcDialogue`, `SpellCaster`, `SealEncounter`, `FlyingSword`, `spirit_bolt`, `guard_charm`, `seal_break`, `start`, `ask_tavern`, `go_to_mountain`, `cleanse_seal`, `collect_sword`, `fly_back`, and `complete`.
