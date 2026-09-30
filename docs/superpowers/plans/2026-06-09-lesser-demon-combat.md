# Lesser Demon Combat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first complete combat slice with reusable health, player damage reception, Beehave-driven lesser demons, and debug/trial scene integration.

**Architecture:** Add a small `scripts/combat/HealthComponent.gd` and keep actor-specific combat in player scripts and `scripts/enemies/LesserDemon.gd`. The lesser demon scene uses Beehave nodes with project-local leaf scripts that call public methods on the actor. Existing spell projectile targeting remains method-based through `receive_spell(spell_id)`.

**Tech Stack:** Godot 4.6 GDScript, Beehave behavior trees, `.tscn` scenes, headless GDScript tests.

---

## Files

- Create: `scripts/combat/HealthComponent.gd`
- Create: `scripts/enemies/LesserDemon.gd`
- Create: `scripts/enemies/ai/IsDefeatedCondition.gd`
- Create: `scripts/enemies/ai/HasTargetCondition.gd`
- Create: `scripts/enemies/ai/CanSeeTargetCondition.gd`
- Create: `scripts/enemies/ai/IsTargetInAttackRangeCondition.gd`
- Create: `scripts/enemies/ai/DefeatedAction.gd`
- Create: `scripts/enemies/ai/AttackTargetAction.gd`
- Create: `scripts/enemies/ai/ChaseTargetAction.gd`
- Create: `scripts/enemies/ai/FindTargetAction.gd`
- Create: `scripts/enemies/ai/IdleAction.gd`
- Create: `scenes/enemies/LesserDemon.tscn`
- Create: `tests/test_health_component.gd`
- Create: `tests/test_lesser_demon.gd`
- Create: `tests/test_lesser_demon_scene.gd`
- Create: `tests/test_mountain_trial_combat.gd`
- Modify: `scripts/autoload/EventBus.gd`
- Modify: `scripts/player/DesktopDebugPlayer.gd`
- Modify: `scripts/player/XRPlayer.gd`
- Modify: `scenes/player/DesktopDebugPlayer.tscn`
- Modify: `scenes/player/XRPlayer.tscn`
- Modify: `scenes/debug/PlayerTestArena.tscn`
- Modify: `scenes/mountain/MountainTrial.tscn`
- Modify: `tests/test_runner.gd`
- Modify: `tests/test_player_test_arena.gd`
- Modify: `project.godot`

## Task 1: Health Component

- [x] **Step 1: Write failing tests**

Create `tests/test_health_component.gd`:

```gdscript
extends RefCounted

func run(t) -> void:
	var path := "res://scripts/combat/HealthComponent.gd"
	t.assert_true(FileAccess.file_exists(path), "HealthComponent script exists")
	if not FileAccess.file_exists(path):
		return
	var HealthComponent := load(path)
	t.assert_true(HealthComponent.can_instantiate(), "HealthComponent can instantiate")
	if not HealthComponent.can_instantiate():
		return
	var health = HealthComponent.new()
	health.max_health = 5
	health.minimum_health = 0
	health.reset()
	t.assert_equal(health.current_health, 5, "health resets to max")
	t.assert_true(health.is_alive(), "health starts alive")
	t.assert_equal(health.apply_damage(2, "test"), 3, "damage lowers health")
	t.assert_equal(health.current_health, 3, "current health tracks damage")
	t.assert_equal(health.apply_damage(99, "test"), 0, "damage clamps at minimum")
	t.assert_true(not health.is_alive(), "zero health is not alive")
	t.assert_equal(health.heal(2), 2, "heal restores from minimum")
	t.assert_true(health.is_alive(), "positive health is alive")
	health.free()
```

Register it in `tests/test_runner.gd` after `test_environment_controller.gd`.

- [x] **Step 2: Verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL with `HealthComponent script exists`.

- [x] **Step 3: Implement `HealthComponent.gd`**

Create `scripts/combat/HealthComponent.gd` with `class_name HealthComponent`, exported `max_health`, `current_health`, `minimum_health`, `target_id`, signals `health_changed`, `damage_received`, and `died`, plus `reset()`, `is_alive()`, `apply_damage()`, and `heal()`.

- [x] **Step 4: Verify GREEN**

Run the full test command. Expected: `TESTS PASSED`.

## Task 2: Player Health Reception

- [x] **Step 1: Write failing player health tests**

Update `tests/test_desktop_debug_player.gd` and `tests/test_xr_player.gd` to instantiate each player scene, assert `get_health_component()` exists, call `receive_damage(1, "lesser_demon")`, and assert current health decreased while movement scripts remain instantiable.

- [x] **Step 2: Verify RED**

Run the full test command. Expected: FAIL because player scripts lack `receive_damage()` and `get_health_component()`.

- [x] **Step 3: Implement player health**

Add a `HealthComponent` child named `HealthComponent` to both player scenes. Add `receive_damage(amount, source_id)` and `get_health_component()` to `DesktopDebugPlayer.gd` and `XRPlayer.gd`. Emit `EventBus.player_health_changed` when available.

- [x] **Step 4: Verify GREEN**

Run the full test command. Expected: `TESTS PASSED`.

## Task 3: Lesser Demon Logic

- [x] **Step 1: Write failing logic tests**

Create `tests/test_lesser_demon.gd` covering spell damage mapping, defeat state, range checks, and attack cooldown against a simple `Node3D` target with `receive_damage()`.

- [x] **Step 2: Verify RED**

Run the full test command. Expected: FAIL because `LesserDemon.gd` does not exist.

- [x] **Step 3: Implement `LesserDemon.gd`**

Create `scripts/enemies/LesserDemon.gd` with exported values from the spec, a health component lookup, `receive_spell()`, `receive_damage()`, `find_target()`, `has_target()`, `can_see_target()`, `is_in_attack_range()`, `move_toward_target(delta)`, `try_attack_target()`, `tick_attack_cooldown(delta)`, and `is_defeated()`.

- [x] **Step 4: Verify GREEN**

Run the full test command. Expected: `TESTS PASSED`.

## Task 4: Beehave AI and Enemy Scene

- [x] **Step 1: Write failing scene tests**

Create `tests/test_lesser_demon_scene.gd` asserting `scenes/enemies/LesserDemon.tscn` exists, instantiates, has `HealthComponent`, `BeehaveTree`, branch nodes, visible mesh, and collision nodes.

- [x] **Step 2: Verify RED**

Run the full test command. Expected: FAIL because the scene and AI leaf scripts do not exist.

- [x] **Step 3: Implement AI leaf scripts**

Create condition/action scripts under `scripts/enemies/ai/`. Each `tick(actor, blackboard)` calls the corresponding public method on `LesserDemon` and returns `SUCCESS`, `FAILURE`, or `RUNNING` from Beehave constants.

- [x] **Step 4: Create `LesserDemon.tscn`**

Create a `CharacterBody3D` root named `LesserDemon` with script, `HealthComponent`, `BeehaveTree`, `SelectorComposite` branches, a built-in mesh visual, and collision shape.

- [x] **Step 5: Verify GREEN**

Run the full test command. Expected: `TESTS PASSED`.

## Task 5: Scene Integration and Events

- [x] **Step 1: Write failing integration tests**

Update `tests/test_player_test_arena.gd` to require `TestFixtures/LesserDemon`. Create `tests/test_mountain_trial_combat.gd` to require at least one lesser demon in `MountainTrial`. Register the new test.

- [x] **Step 2: Verify RED**

Run the full test command. Expected: FAIL because fixtures are not present.

- [x] **Step 3: Update EventBus**

Add `damage_received`, `health_changed`, `enemy_defeated`, and `player_health_changed` signals to `scripts/autoload/EventBus.gd`.

- [x] **Step 4: Update scenes**

Add `LesserDemon` instances to `PlayerTestArena.tscn` and `MountainTrial.tscn`. Update the Player Test Arena Chinese debug label to include小妖 combat testing.

- [x] **Step 5: Verify GREEN**

Run the full test command. Expected: `TESTS PASSED`.

## Task 6: Final Verification

- [x] **Step 1: Enable Beehave plugin if needed**

Ensure `project.godot` includes `res://addons/beehave/plugin.cfg` in `[editor_plugins] enabled`.

- [x] **Step 2: Run full verification**

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: tests pass and check-only exits 0.

- [x] **Step 3: Review git status**

```bash
git status --short
```

Expected: only combat feature files, scenes, tests, `project.godot`, and this plan are changed.
