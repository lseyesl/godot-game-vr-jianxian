# Desktop Simulation Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make PC `desktop_simulation` mode use WASD movement relative to player facing and mouse look for yaw/pitch.

**Architecture:** Keep runtime behavior inside `scripts/player/DesktopDebugPlayer.gd` so XR/VR controls remain untouched. Add explicit desktop `move_*` input actions to `project.godot`, and cover the control helpers plus mouse capture behavior with headless GDScript tests.

**Tech Stack:** Godot 4.6, GDScript, `CharacterBody3D`, `InputMap`, custom headless test runner.

---

### Task 1: Add Failing Desktop Control Tests

**Files:**
- Create: `tests/test_desktop_debug_player.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write the failing test**

Add tests for `move_forward/back/left/right` input actions, local movement vector mapping, yaw-relative direction, mouse-look pitch clamp, Esc release, and left-click recapture.

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: FAIL because `DesktopDebugPlayer` does not expose the control helpers and `project.godot` does not define the `move_*` actions yet.

### Task 2: Implement Desktop Player Controls

**Files:**
- Modify: `scripts/player/DesktopDebugPlayer.gd`

- [ ] **Step 1: Add testable helpers**

Add `get_movement_input_vector()`, `get_yaw_relative_direction(local_input)`, and `apply_mouse_look(relative)`.

- [ ] **Step 2: Wire runtime controls**

Use the helpers from `_physics_process()` and `_unhandled_input()`. Capture mouse in `_ready()`, release on `ui_cancel`, recapture on left click, and only apply mouse motion while captured.

### Task 3: Add WASD Input Actions

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: Add input actions**

Add `move_forward` = W, `move_back` = S, `move_left` = A, `move_right` = D. Do not remove existing actions or change XR input.

### Task 4: Verify

**Files:**
- Validate: `scripts/player/DesktopDebugPlayer.gd`
- Validate: `project.godot`
- Validate: `tests/test_desktop_debug_player.gd`
- Validate: `tests/test_runner.gd`

- [ ] **Step 1: Run full tests**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: `TESTS PASSED: <N> assertions`.

- [ ] **Step 2: Run scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: exit code 0.
