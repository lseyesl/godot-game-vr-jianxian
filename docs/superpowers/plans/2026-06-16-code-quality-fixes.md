# Code Quality Fixes Implementation Plan

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all identified code quality issues from code review — P0 real bug, P1 potential bugs, P3 logic flaws, and style inconsistencies.

**Architecture:** Each fix is an isolated single-file change. No cross-file dependencies. Execute in parallel where possible.

**Tech Stack:** Godot 4.6+ GDScript

---

### Task 1: Fix P0 — PlayerSpellController double cooldown tick

**Files:**
- Modify: `scripts/player/PlayerSpellController.gd:16-17`

**Problem:** `_physics_process(delta)` calls `tick_cooldowns(delta)`, but XRPlayer and DesktopDebugPlayer ALSO call `controller.tick_cooldowns(delta)` in their own `_physics_process`. This halves cooldown times.

**Fix:** Remove `_physics_process` from PlayerSpellController — cooldown tick is the parent player controller's responsibility.

- [ ] **Delete `_physics_process` override** in PlayerSpellController

### Task 2: Fix P1 — LesserDemon duplicate `_on_health_died` call

**Files:**
- Modify: `scripts/enemies/LesserDemon.gd:41-48`

**Problem:** `receive_damage()` manually calls `_on_health_died(source_id)` on line 47, but `_ready()` already connected `health.died` signal → `_on_health_died`. Double invocation guarded by `defeated` flag, but fragile.

**Fix:** Remove the manual `_on_health_died` call in `receive_damage()`. The signal path handles it.

- [ ] **Remove line 47** `_on_health_died(source_id)` call

### Task 3: Fix P1 — Projectile memory leak in spawned_projectiles array

**Files:**
- Modify: `scripts/player/PlayerSpellController.gd`

**Problem:** `spawned_projectiles.append(projectile)` but projectiles are never removed from the array when they `queue_free()`. Array grows unbounded.

**Fix:** Connect to projectile's `tree_exited` signal to remove from array, or use a weak-ref approach. Simplest: connect and remove on free.

- [ ] **Add cleanup** — when projectile is added, connect its `tree_exited` signal to remove it from array

### Task 4: Fix P3 — DesktopDebugPlayer first-click no-cast UX

**Files:**
- Modify: `scripts/player/DesktopDebugPlayer.gd:41-45`

**Problem:** First left-click only captures mouse, doesn't cast spell. User must click twice.

**Fix:** Cast the spell AND capture mouse in the same action for `spell_primary`.

- [ ] **Change logic** so mouse capture doesn't block spell cast

### Task 5: Fix P3 — XRPlayer comfort_settings type declaration

**Files:**
- Modify: `scripts/player/XRPlayer.gd:7`

**Problem:** `@export var comfort_settings: Resource` — generic type, loses editor auto-complete.

**Fix:** Change to `@export var comfort_settings: ComfortSettings` (with preload or class_name).

- [ ] **Change type** from `Resource` to `ComfortSettings`

### Task 6: Fix P3 — MainMenu missing class_name

**Files:**
- Modify: `scripts/ui/MainMenu.gd:1`

**Problem:** Other UI scripts have `class_name` but MainMenu doesn't.

**Fix:** Add `class_name MainMenu`.

- [ ] **Add class_name** declaration

### Task 7: Fix style — SealEncounter redundant remaining_hits checks

**Files:**
- Modify: `scripts/interaction/SealEncounter.gd:24-28`

**Problem:** `remaining_hits == 0` checked twice (line 24 for outcome, line 27 for cleanse). Can merge.

**Fix:** Combine into single conditional block.

- [ ] **Merge duplicate checks** into one block

### Task 8: Fix P3 — EventBus signal type hint

**Files:**
- Modify: `scripts/autoload/EventBus.gd:11`

**Problem:** `comfort_settings_changed(settings)` missing type hint.

**Fix:** Add `ComfortSettings` type.

- [ ] **Add type hint** to signal parameter

---

## Verification

After all tasks:
- [ ] `godot --headless --xr-mode off --path . --check-only --quit` passes
- [ ] `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` passes
