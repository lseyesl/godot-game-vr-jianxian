# Roof Prefab Town Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the newly created Roof prefab scenes visible from the main playable scene by instancing them into `scenes/town/Town.tscn`.

**Architecture:** `Main.tscn` loads `Town.tscn`, so model prefabs that should appear in the main scene must be instanced inside `Town.tscn` or another scene already loaded by `Main.tscn`. The Roof prefabs already exist and pass prefab-load tests; the missing piece is a town-level `RoofShowcase` anchor with instances of `Roof01` through `Roof10`.

**Tech Stack:** Godot 4.6 scene files (`.tscn`), GDScript headless tests, existing custom test runner.

---

### Task 1: Reproduce Missing Roof Integration

**Files:**
- Modify: `tests/test_town_showcase.gd`

- [ ] **Step 1: Write the failing test**

Add a `_test_roof_showcase_models(t, town)` helper and call it from `run(t)` after `_test_showcase_models(t, town)`. The helper must assert that `Town.tscn` contains `RoofShowcase/Roof01` through `RoofShowcase/Roof10`, that each node is a `Node3D`, and that each node resolves to its matching `res://assets/models/Roof/RoofNN.glb` source path through `_source_model_path()`.

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: FAIL on missing `RoofShowcase/Roof01`, proving the prefabs exist but are not instanced into the loaded town scene.

### Task 2: Instance Roof Prefabs In Town

**Files:**
- Modify: `scenes/town/Town.tscn`

- [ ] **Step 1: Add Roof prefab resources**

Add `ext_resource` entries for `res://scenes/prefabs/models/Roof/Roof01.tscn` through `Roof10.tscn`, and increase `load_steps` from `11` to `21`.

- [ ] **Step 2: Add visible RoofShowcase anchor**

Add a `RoofShowcase` `Node3D` under `Town`, then add `Roof01` through `Roof10` as instances. Place them in a compact two-row showcase near `SwordPracticeYard` so they are visible when `Main.tscn` loads `Town.tscn`.

- [ ] **Step 3: Run test to verify it passes**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: `TESTS PASSED: <N> assertions`.

### Task 3: Final Validation

**Files:**
- Validate: `tests/test_town_showcase.gd`
- Validate: `scenes/town/Town.tscn`

- [ ] **Step 1: Run syntax and scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: exit code 0.

- [ ] **Step 2: Summarize root cause**

Report that the Roof prefab scenes were created and covered by prefab-load tests, but `Main.tscn` only loads `Town.tscn`; because `Town.tscn` had no Roof instances, the new prefabs could not appear in the main scene.
