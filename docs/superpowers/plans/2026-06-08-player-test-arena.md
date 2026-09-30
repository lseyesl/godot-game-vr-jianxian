# Player Test Arena Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one shared Godot debug arena for testing player weapons, spells, flying sword behavior, and PC/VR player spawning.

**Architecture:** Add a standalone `PlayerTestArena` scene with a small focused scene script. The script owns debug player spawning only and reuses existing `DesktopDebugPlayer`, `XRPlayer`, `SealEncounter`, and `FlyingSword` scenes without changing main quest flow.

**Tech Stack:** Godot 4.6+, GDScript, `.tscn` scenes, existing headless GDScript test runner.

---

## File Structure

- Create `scripts/debug/PlayerTestArena.gd`: standalone scene controller with exported `player_mode`, player scene path resolution, normalization, and spawn behavior.
- Create `scenes/debug/PlayerTestArena.tscn`: debug arena with floor, light, spawn marker, label, seal target, flying sword, and simple distance markers.
- Create `tests/test_player_test_arena.gd`: headless coverage for scene existence, fixture structure, and mode resolution.
- Modify `tests/test_runner.gd`: register the new test path.

## Task 1: Failing Arena Test

**Files:**
- Create: `tests/test_player_test_arena.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write the failing test**

Create `tests/test_player_test_arena.gd`:

```gdscript
extends RefCounted

func run(t) -> void:
	var scene_path := "res://scenes/debug/PlayerTestArena.tscn"
	var script_path := "res://scripts/debug/PlayerTestArena.gd"
	t.assert_true(FileAccess.file_exists(scene_path), "PlayerTestArena scene exists")
	t.assert_true(FileAccess.file_exists(script_path), "PlayerTestArena script exists")
	if not FileAccess.file_exists(scene_path) or not FileAccess.file_exists(script_path):
		return

	var ArenaScript := load(script_path)
	t.assert_true(ArenaScript.can_instantiate(), "PlayerTestArena script can instantiate")
	if not ArenaScript.can_instantiate():
		return
	var arena_script_instance = ArenaScript.new()
	t.assert_equal(arena_script_instance.resolve_player_scene_path("desktop_simulation"), "res://scenes/player/DesktopDebugPlayer.tscn", "desktop mode resolves desktop player")
	t.assert_equal(arena_script_instance.resolve_player_scene_path("vr"), "res://scenes/player/XRPlayer.tscn", "vr mode resolves XR player")
	t.assert_equal(arena_script_instance.normalize_player_mode("invalid"), "desktop_simulation", "unknown mode falls back to desktop")
	arena_script_instance.free()

	var packed_scene := load(scene_path)
	t.assert_true(packed_scene is PackedScene, "PlayerTestArena loads as PackedScene")
	if not packed_scene is PackedScene:
		return
	var scene = packed_scene.instantiate()
	t.assert_true(scene != null, "PlayerTestArena instantiates")
	if scene == null:
		return
	t.assert_true(scene.get_node_or_null("PlayerSpawn") != null, "PlayerTestArena has PlayerSpawn")
	t.assert_true(scene.get_node_or_null("Ground") is StaticBody3D, "PlayerTestArena has StaticBody3D Ground")
	t.assert_true(scene.get_node_or_null("TestFixtures/SealEncounter") != null, "PlayerTestArena has SealEncounter fixture")
	t.assert_true(scene.get_node_or_null("TestFixtures/FlyingSword") != null, "PlayerTestArena has FlyingSword fixture")
	t.assert_true(scene.get_node_or_null("DebugLabel") is Label3D, "PlayerTestArena has Chinese debug label")
	scene.free()
```

Modify `tests/test_runner.gd` by adding this path after `test_player_mode.gd`:

```gdscript
"res://tests/test_player_test_arena.gd",
```

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because `res://scenes/debug/PlayerTestArena.tscn` and `res://scripts/debug/PlayerTestArena.gd` do not exist yet.

Observed: FAIL. The runner reported the two new arena assertions for missing scene and script, plus the existing baseline failures.

## Task 2: Arena Script

**Files:**
- Create: `scripts/debug/PlayerTestArena.gd`

- [x] **Step 1: Write minimal implementation**

Create `scripts/debug/PlayerTestArena.gd`:

```gdscript
extends Node3D
class_name PlayerTestArena

const PLAYER_MODE_DESKTOP_SIMULATION := "desktop_simulation"
const PLAYER_MODE_VR := "vr"
const DESKTOP_PLAYER_SCENE_PATH := "res://scenes/player/DesktopDebugPlayer.tscn"
const VR_PLAYER_SCENE_PATH := "res://scenes/player/XRPlayer.tscn"

@export_enum("desktop_simulation", "vr") var player_mode := PLAYER_MODE_DESKTOP_SIMULATION

var player_node: Node

func _ready() -> void:
	spawn_player()

func normalize_player_mode(mode: String) -> String:
	if mode == PLAYER_MODE_VR:
		return PLAYER_MODE_VR
	return PLAYER_MODE_DESKTOP_SIMULATION

func resolve_player_scene_path(mode: String = player_mode) -> String:
	if normalize_player_mode(mode) == PLAYER_MODE_VR:
		return VR_PLAYER_SCENE_PATH
	return DESKTOP_PLAYER_SCENE_PATH

func instantiate_player_for_mode(mode: String) -> Node:
	var scene_path := resolve_player_scene_path(mode)
	var packed_scene := load(scene_path)
	if packed_scene == null or not packed_scene is PackedScene:
		push_error("Unable to load player scene: %s" % scene_path)
		return null
	return packed_scene.instantiate()

func spawn_player() -> Node:
	if player_node != null:
		player_node.queue_free()
	player_node = instantiate_player_for_mode(player_mode)
	if player_node == null:
		return null
	var spawn := get_node_or_null("PlayerSpawn") as Node3D
	if player_node is Node3D and spawn != null:
		player_node.global_position = spawn.global_position
	add_child(player_node)
	return player_node
```

- [x] **Step 2: Run test to verify partial progress**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Observed: Skipped the intermediate run and implemented the scene in the next task before the next verification, because the baseline suite already fails loudly and the next run verifies all arena assertions together.

## Task 3: Arena Scene

**Files:**
- Create: `scenes/debug/PlayerTestArena.tscn`

- [x] **Step 1: Create the debug arena scene**

Create `scenes/debug/PlayerTestArena.tscn` with a `PlayerTestArena` root, `WorldEnvironment`, `DirectionalLight3D`, `Ground`, `PlayerSpawn`, `DebugLabel`, `TestFixtures/SealEncounter`, `TestFixtures/FlyingSword`, and distance marker meshes.

- [x] **Step 2: Run test to verify it passes**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: the new arena assertions pass. The full suite may still report unrelated pre-existing model prefab failures if model `.glb` files are unavailable.

Observed: The new arena failures disappeared and assertion count increased to 307. The full runner still exits 1 with the same 36 pre-existing failures from desktop camera height and model prefab assets.

## Task 4: Full Verification

**Files:**
- Read: `docs/superpowers/specs/2026-06-08-player-test-arena-design.md`
- Read: `docs/superpowers/plans/2026-06-08-player-test-arena.md`

- [x] **Step 1: Run headless unit tests**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected when baseline assets are present: exit 0 and output includes `TESTS PASSED: <N> assertions`.

Observed: exit 1. New arena assertions pass, but the existing suite still reports 36 failures unrelated to this change.

- [x] **Step 2: Run syntax and scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected when baseline assets are present: exit 0.

Observed: exit 0. Godot printed existing autoload resource warnings, but no check-only failure.

- [x] **Step 3: Confirm requirement coverage**

Check these conditions before final response:
- `scenes/debug/PlayerTestArena.tscn` exists.
- `scripts/debug/PlayerTestArena.gd` exists.
- `tests/test_player_test_arena.gd` is registered in `tests/test_runner.gd`.
- Arena defaults to `desktop_simulation`.
- Arena can resolve `vr` to `res://scenes/player/XRPlayer.tscn`.
- Arena contains `Ground`, `PlayerSpawn`, `DebugLabel`, `TestFixtures/SealEncounter`, and `TestFixtures/FlyingSword`.
