# Core Playable Spell Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make desktop simulation and VR-ready player code cast spells through a shared controller that spawns spell projectiles for the mountain trial.

**Architecture:** Add `PlayerSpellController` as the single bridge between player input and existing `SpellCaster`/`SpellProjectile` logic. Desktop and XR players stay thin: they resolve an emitter node and delegate spell IDs to the controller. Tests cover the controller, scene wiring, input actions, and player delegation before implementation.

**Tech Stack:** Godot 4.6+, GDScript, existing `SpellCaster`, existing `SpellProjectile.tscn`, headless Godot tests.

---

## File Structure

- Create: `scripts/player/PlayerSpellController.gd`
  - Owns spell cooldown logic through `SpellCaster`, launches projectile spells, and records debug/test state.
- Create: `tests/test_player_spell_controller.gd`
  - Covers projectile spawn, non-projectile spell behavior, cooldown blocking, unknown spell rejection, and emitter-based casting.
- Modify: `tests/test_runner.gd`
  - Adds `res://tests/test_player_spell_controller.gd`.
- Modify: `scripts/player/DesktopDebugPlayer.gd`
  - Maps desktop spell input actions to spell IDs and delegates to `PlayerSpellController`.
- Modify: `scenes/player/DesktopDebugPlayer.tscn`
  - Adds `PlayerSpellController` child.
- Modify: `tests/test_desktop_debug_player.gd`
  - Verifies spell actions exist, scene wiring exists, and spell action mapping delegates correctly.
- Modify: `scripts/player/XRPlayer.gd`
  - Adds VR-ready `cast_spell_id()` and `cast_spell_from_emitter()` methods.
- Modify: `scenes/player/XRPlayer.tscn`
  - Adds `PlayerSpellController` and `XROrigin3D/RightHand/SpellEmitter`.
- Modify: `tests/test_xr_player.gd`
  - Verifies XR spell controller and emitter wiring plus callable spell interface.
- Modify: `project.godot`
  - Adds desktop default input events for `spell_primary`, `spell_guard`, and `spell_seal`.

## Task 1: PlayerSpellController Tests

**Files:**
- Create: `tests/test_player_spell_controller.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write failing controller tests**

Create `tests/test_player_spell_controller.gd`:

```gdscript
extends RefCounted

func run(t) -> void:
	var path := "res://scripts/player/PlayerSpellController.gd"
	t.assert_true(FileAccess.file_exists(path), "PlayerSpellController script exists")
	if not FileAccess.file_exists(path):
		return
	var Controller := load(path)
	t.assert_true(Controller.can_instantiate(), "PlayerSpellController can instantiate")
	if not Controller.can_instantiate():
		return
	_test_projectile_spell_spawns_projectile(t, Controller)
	_test_non_projectile_spell_uses_cooldown_without_projectile(t, Controller)
	_test_unknown_spell_does_not_cast(t, Controller)
	_test_cast_spell_from_node_uses_emitter_transform(t, Controller)

func _test_projectile_spell_spawns_projectile(t, Controller: Script) -> void:
	var root := Node3D.new()
	var controller = Controller.new()
	root.add_child(controller)
	t.assert_true(controller.cast_spell("spirit_bolt", Vector3(1, 2, 3), Vector3.FORWARD), "spirit_bolt casts")
	t.assert_equal(controller.get_spawned_projectile_count(), 1, "spirit_bolt spawns one projectile")
	t.assert_true(controller.last_spawned_projectile != null, "last spawned projectile is tracked")
	if controller.last_spawned_projectile != null:
		t.assert_equal(controller.last_spawned_projectile.spell_id, "spirit_bolt", "projectile keeps spell id")
		t.assert_equal(controller.last_spawned_projectile.global_position, Vector3(1, 2, 3), "projectile starts at requested origin")
	t.assert_true(not controller.cast_spell("spirit_bolt", Vector3.ZERO, Vector3.FORWARD), "cooldown blocks immediate repeat")
	root.free()

func _test_non_projectile_spell_uses_cooldown_without_projectile(t, Controller: Script) -> void:
	var root := Node3D.new()
	var controller = Controller.new()
	root.add_child(controller)
	t.assert_true(controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard_charm casts")
	t.assert_equal(controller.last_cast_spell_id, "guard_charm", "guard_charm records last cast")
	t.assert_equal(controller.get_spawned_projectile_count(), 0, "guard_charm does not spawn projectile")
	t.assert_true(not controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard_charm cooldown blocks repeat")
	root.free()

func _test_unknown_spell_does_not_cast(t, Controller: Script) -> void:
	var root := Node3D.new()
	var controller = Controller.new()
	root.add_child(controller)
	t.assert_true(not controller.cast_spell("unknown_spell", Vector3.ZERO, Vector3.FORWARD), "unknown spell does not cast")
	t.assert_equal(controller.last_cast_spell_id, "", "unknown spell does not record last cast")
	t.assert_equal(controller.get_spawned_projectile_count(), 0, "unknown spell does not spawn projectile")
	root.free()

func _test_cast_spell_from_node_uses_emitter_transform(t, Controller: Script) -> void:
	var root := Node3D.new()
	var controller = Controller.new()
	var emitter := Node3D.new()
	root.add_child(controller)
	root.add_child(emitter)
	emitter.global_position = Vector3(4, 5, 6)
	emitter.look_at(Vector3(4, 5, 5), Vector3.UP)
	t.assert_true(controller.cast_spell_from_node("seal_break", emitter), "seal_break casts from emitter")
	t.assert_equal(controller.get_spawned_projectile_count(), 1, "seal_break spawns projectile")
	t.assert_equal(controller.last_spawned_projectile.global_position, emitter.global_position, "projectile uses emitter position")
	root.free()
```

- [x] **Step 2: Register failing controller tests**

Modify `tests/test_runner.gd` and insert the new test after `test_spell_caster.gd`:

```gdscript
"res://tests/test_spell_caster.gd",
"res://tests/test_player_spell_controller.gd",
"res://tests/test_lesser_demon.gd",
```

- [x] **Step 3: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL with `PlayerSpellController script exists`.

## Task 2: Implement PlayerSpellController

**Files:**
- Create: `scripts/player/PlayerSpellController.gd`
- Test: `tests/test_player_spell_controller.gd`

- [x] **Step 1: Add controller implementation**

Create `scripts/player/PlayerSpellController.gd`:

```gdscript
extends Node
class_name PlayerSpellController

const SpellCasterScript := preload("res://scripts/spells/SpellCaster.gd")

@export var projectile_scene_path := "res://scenes/spells/SpellProjectile.tscn"

var spell_caster: SpellCaster
var last_cast_spell_id := ""
var last_spawned_projectile: Node
var spawned_projectiles: Array[Node] = []

func _ready() -> void:
	_ensure_spell_caster()

func _physics_process(delta: float) -> void:
	tick_cooldowns(delta)

func cast_spell(spell_id: String, origin: Vector3, forward: Vector3) -> bool:
	_ensure_spell_caster()
	if spell_caster == null or not spell_caster.cast(spell_id):
		return false
	last_cast_spell_id = spell_id
	if is_projectile_spell(spell_id):
		var projectile := _spawn_projectile(spell_id, origin, forward)
		if projectile == null:
			return false
	return true

func cast_spell_from_node(spell_id: String, emitter: Node3D) -> bool:
	if emitter == null:
		return false
	return cast_spell(spell_id, emitter.global_position, -emitter.global_transform.basis.z)

func is_projectile_spell(spell_id: String) -> bool:
	return spell_id == "spirit_bolt" or spell_id == "seal_break"

func get_spawned_projectile_count() -> int:
	return spawned_projectiles.size()

func tick_cooldowns(delta: float) -> void:
	_ensure_spell_caster()
	if spell_caster != null:
		spell_caster.tick_cooldowns(delta)

func _ensure_spell_caster() -> void:
	if spell_caster == null:
		spell_caster = SpellCasterScript.new()
		add_child(spell_caster)

func _spawn_projectile(spell_id: String, origin: Vector3, forward: Vector3) -> Node:
	if not is_inside_tree():
		return null
	var packed_scene := load(projectile_scene_path)
	if packed_scene == null or not packed_scene is PackedScene:
		return null
	var projectile = packed_scene.instantiate()
	if "spell_id" in projectile:
		projectile.spell_id = spell_id
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return null
	parent.add_child(projectile)
	if projectile.has_method("launch"):
		projectile.launch(origin, forward)
	last_spawned_projectile = projectile
	spawned_projectiles.append(projectile)
	return projectile
```

- [x] **Step 2: Run tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass, including `test_player_spell_controller.gd`.

## Task 3: Desktop Player Spell Input

**Files:**
- Modify: `tests/test_desktop_debug_player.gd`
- Modify: `scripts/player/DesktopDebugPlayer.gd`
- Modify: `scenes/player/DesktopDebugPlayer.tscn`

- [x] **Step 1: Write failing desktop spell tests**

Append these calls inside `tests/test_desktop_debug_player.gd` `run(t)` after existing setup checks:

```gdscript
	_test_spell_input_actions_exist(t)
	_test_desktop_scene_has_spell_controller(t)
	_test_desktop_spell_methods_delegate(t)
```

Add these helper functions:

```gdscript
func _test_spell_input_actions_exist(t) -> void:
	for action in ["spell_primary", "spell_guard", "spell_seal"]:
		t.assert_true(InputMap.has_action(action), "%s input action exists" % action)

func _test_desktop_scene_has_spell_controller(t) -> void:
	var scene_path := "res://scenes/player/DesktopDebugPlayer.tscn"
	t.assert_true(ResourceLoader.exists(scene_path), "DesktopDebugPlayer scene exists")
	if not ResourceLoader.exists(scene_path):
		return
	var scene = load(scene_path).instantiate()
	t.assert_true(scene.get_node_or_null("PlayerSpellController") != null, "desktop player has PlayerSpellController")
	if scene.get_node_or_null("PlayerSpellController") != null:
		t.assert_equal(scene.get_node("PlayerSpellController").get_script(), load("res://scripts/player/PlayerSpellController.gd"), "desktop spell controller uses PlayerSpellController script")
	scene.free()

func _test_desktop_spell_methods_delegate(t) -> void:
	var scene = load("res://scenes/player/DesktopDebugPlayer.tscn").instantiate()
	var root := Node3D.new()
	root.add_child(scene)
	t.assert_true(scene.has_method("spell_id_for_action"), "desktop player maps spell actions")
	t.assert_equal(scene.spell_id_for_action("spell_primary"), "spirit_bolt", "primary action maps to spirit bolt")
	t.assert_equal(scene.spell_id_for_action("spell_guard"), "guard_charm", "guard action maps to guard charm")
	t.assert_equal(scene.spell_id_for_action("spell_seal"), "seal_break", "seal action maps to seal break")
	t.assert_true(scene.cast_spell_id("spirit_bolt"), "desktop player casts spirit bolt through controller")
	t.assert_true(not scene.cast_spell_id("spirit_bolt"), "desktop player respects controller cooldown")
	root.free()
```

- [x] **Step 2: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because `DesktopDebugPlayer` lacks `PlayerSpellController` and spell mapping methods.

- [x] **Step 3: Add desktop spell methods**

Modify `scripts/player/DesktopDebugPlayer.gd`:

```gdscript
@export var spell_controller_path: NodePath = ^"PlayerSpellController"
@export var spell_emitter_path: NodePath = ^"Camera3D"
```

Add this to `_physics_process(delta)` after movement:

```gdscript
	var controller := get_spell_controller()
	if controller != null and controller.has_method("tick_cooldowns"):
		controller.tick_cooldowns(delta)
```

Add this to `_unhandled_input(event)` before mouse capture handling:

```gdscript
	for action in ["spell_primary", "spell_guard", "spell_seal"]:
		if event.is_action_pressed(action):
			if action == "spell_primary" and not mouse_capture_requested:
				request_mouse_capture()
				return
			cast_spell_action(action)
			return
```

Add helper methods:

```gdscript
func spell_id_for_action(action_name: String) -> String:
	match action_name:
		"spell_primary":
			return "spirit_bolt"
		"spell_guard":
			return "guard_charm"
		"spell_seal":
			return "seal_break"
		_:
			return ""

func cast_spell_action(action_name: String) -> bool:
	var spell_id := spell_id_for_action(action_name)
	if spell_id == "":
		return false
	return cast_spell_id(spell_id)

func cast_spell_id(spell_id: String) -> bool:
	var controller := get_spell_controller()
	var emitter := get_spell_emitter()
	if controller == null or emitter == null:
		return false
	if controller.has_method("cast_spell_from_node"):
		return controller.cast_spell_from_node(spell_id, emitter)
	return false

func get_spell_controller() -> Node:
	return get_node_or_null(spell_controller_path)

func get_spell_emitter() -> Node3D:
	return get_node_or_null(spell_emitter_path) as Node3D
```

- [x] **Step 4: Add desktop scene controller**

Modify `scenes/player/DesktopDebugPlayer.tscn`:

```ini
[ext_resource type="Script" path="res://scripts/player/PlayerSpellController.gd" id="3"]

[node name="PlayerSpellController" type="Node" parent="."]
script = ExtResource("3")
```

- [x] **Step 5: Run tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass.

## Task 4: XR Player Spell Interface

**Files:**
- Modify: `tests/test_xr_player.gd`
- Modify: `scripts/player/XRPlayer.gd`
- Modify: `scenes/player/XRPlayer.tscn`

- [x] **Step 1: Write failing XR spell tests**

Append this call inside `tests/test_xr_player.gd` `run(t)`:

```gdscript
	_test_xr_spell_interface(t)
```

Add helper:

```gdscript
func _test_xr_spell_interface(t) -> void:
	var scene_path := "res://scenes/player/XRPlayer.tscn"
	t.assert_true(ResourceLoader.exists(scene_path), "XRPlayer scene exists")
	if not ResourceLoader.exists(scene_path):
		return
	var player = load(scene_path).instantiate()
	var root := Node3D.new()
	root.add_child(player)
	t.assert_true(player.get_node_or_null("PlayerSpellController") != null, "XRPlayer has PlayerSpellController")
	t.assert_true(player.get_node_or_null("XROrigin3D/RightHand/SpellEmitter") is Node3D, "XRPlayer has right hand spell emitter")
	t.assert_true(player.has_method("cast_spell_id"), "XRPlayer exposes cast_spell_id")
	t.assert_true(player.cast_spell_id("spirit_bolt"), "XRPlayer can cast spirit bolt through shared controller")
	root.free()
```

- [x] **Step 2: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because XR scene lacks `PlayerSpellController`, `SpellEmitter`, and spell interface methods.

- [x] **Step 3: Add XR spell methods**

Modify `scripts/player/XRPlayer.gd`:

```gdscript
@export var spell_controller_path: NodePath = ^"PlayerSpellController"
@export var spell_emitter_path: NodePath = ^"XROrigin3D/RightHand/SpellEmitter"
```

Add this to `_physics_process(delta)`:

```gdscript
func _physics_process(delta: float) -> void:
	var controller := get_spell_controller()
	if controller != null and controller.has_method("tick_cooldowns"):
		controller.tick_cooldowns(delta)
```

Add helper methods:

```gdscript
func cast_spell_id(spell_id: String) -> bool:
	return cast_spell_from_emitter(spell_id, spell_emitter_path)

func cast_spell_from_emitter(spell_id: String, emitter_path: NodePath = spell_emitter_path) -> bool:
	var controller := get_spell_controller()
	var emitter := get_node_or_null(emitter_path) as Node3D
	if controller == null or emitter == null:
		return false
	if controller.has_method("cast_spell_from_node"):
		return controller.cast_spell_from_node(spell_id, emitter)
	return false

func get_spell_controller() -> Node:
	return get_node_or_null(spell_controller_path)
```

- [x] **Step 4: Add XR scene controller and emitter**

Modify `scenes/player/XRPlayer.tscn`:

```ini
[ext_resource type="Script" path="res://scripts/player/PlayerSpellController.gd" id="9"]

[node name="PlayerSpellController" type="Node" parent="."]
script = ExtResource("9")

[node name="SpellEmitter" type="Node3D" parent="XROrigin3D/RightHand"]
position = Vector3(0, 0, -0.08)
```

- [x] **Step 5: Run tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass.

## Task 5: Desktop Spell Input Defaults

**Files:**
- Modify: `project.godot`
- Modify: `tests/test_desktop_debug_player.gd`

- [x] **Step 1: Add failing default input event tests**

Add this helper call to `tests/test_desktop_debug_player.gd` `run(t)`:

```gdscript
	_test_spell_input_defaults(t)
```

Add helper:

```gdscript
func _test_spell_input_defaults(t) -> void:
	t.assert_true(_action_has_mouse_button("spell_primary", MOUSE_BUTTON_LEFT), "spell_primary defaults to left mouse button")
	t.assert_true(_action_has_key("spell_guard", KEY_Q), "spell_guard defaults to Q")
	t.assert_true(_action_has_key("spell_seal", KEY_E), "spell_seal defaults to E")

func _action_has_mouse_button(action_name: String, button_index: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return true
	return false

func _action_has_key(action_name: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false
```

- [x] **Step 2: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because spell input actions currently have empty event arrays.

- [x] **Step 3: Add default input events**

Modify the existing spell input blocks in `project.godot`:

```ini
spell_primary={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":false,"double_click":false,"script":null)
]
}
spell_guard={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":81,"physical_keycode":0,"key_label":0,"unicode":113,"location":0,"echo":false,"script":null)
]
}
spell_seal={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":69,"physical_keycode":0,"key_label":0,"unicode":101,"location":0,"echo":false,"script":null)
]
}
```

- [x] **Step 4: Run tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass.

## Task 6: Final Validation and Commit

**Files:**
- Review all touched files.

- [x] **Step 1: Run full test suite**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: exit 0 with `TESTS PASSED: <N> assertions`.

- [x] **Step 2: Run Godot syntax and scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit 0.

- [x] **Step 3: Inspect git diff**

Run:

```bash
git diff -- project.godot scripts/player scenes/player tests/test_runner.gd tests/test_player_spell_controller.gd tests/test_desktop_debug_player.gd tests/test_xr_player.gd docs/superpowers/plans/2026-06-10-core-playable-spell-flow.md
```

Expected:

- `PlayerSpellController.gd` owns spell spawn/cooldown bridging.
- `DesktopDebugPlayer.gd` only maps input and delegates.
- `XRPlayer.gd` only exposes spell methods and delegates.
- Player scenes include controller and emitter nodes.
- No changes to `SealEncounter`, `LesserDemon`, `SpellCaster`, or `SpellProjectile` unless a test failure exposed a necessary compatibility fix.

- [x] **Step 4: Commit implementation**

Run:

```bash
git add project.godot scripts/player/PlayerSpellController.gd scripts/player/DesktopDebugPlayer.gd scripts/player/XRPlayer.gd scenes/player/DesktopDebugPlayer.tscn scenes/player/XRPlayer.tscn tests/test_runner.gd tests/test_player_spell_controller.gd tests/test_desktop_debug_player.gd tests/test_xr_player.gd docs/superpowers/plans/2026-06-10-core-playable-spell-flow.md
git commit -m "feat: add core playable spell flow"
```

Expected: commit succeeds after verification passes.

## Self-Review

- Spec coverage: Tasks cover shared controller, desktop input dispatch, XR-ready callable interface, scene emitters, projectile spawn, guard charm non-projectile behavior, input defaults, and final Godot verification.
- Placeholder scan: No incomplete steps remain; every test and implementation step includes concrete code or exact commands.
- Type consistency: The plan consistently uses `PlayerSpellController`, `cast_spell`, `cast_spell_from_node`, `cast_spell_id`, `spell_controller_path`, `spell_emitter_path`, `last_cast_spell_id`, and `last_spawned_projectile`.
