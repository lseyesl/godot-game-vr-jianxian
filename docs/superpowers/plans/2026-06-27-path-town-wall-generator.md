# Path Town Wall Generator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate continuous town wall model segments from `TownWall` Path3D nodes without visible leftover gaps.

**Architecture:** Add a focused `@tool` script on `TownWall` that scans direct child `Path3D` nodes, computes each curve length, divides it into an integer number of wall segments, and scales each `Wall_2x3` instance along local X so the full path length is exactly covered. Generated walls live under a `GeneratedWalls` child, so paths remain editable and generated output can be cleared or rebuilt.

**Tech Stack:** Godot 4.7, GDScript `@tool`, `Path3D`/`Curve3D`, headless test runner.

---

### Task 1: Lock Path Wall Generation Behavior

**Files:**
- Modify: `tests/test_town_showcase.gd`
- Read: `scenes/town/Town.tscn`
- Read: `scenes/prefabs/models/Wall/Wall_2x3.tscn`

- [x] **Step 1: Write the failing test**

Update the town wall showcase test so it expects `TownWall` to have a generator script, calls `generate_walls()`, verifies `GeneratedWalls` exists, verifies each direct `Path3D` gets generated wall instances, and verifies each wall records metadata for path name, segment length, segment index, and segment count.

- [x] **Step 2: Run test to verify it fails**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected before implementation: failure because `TownWall` has no generator script and no `generate_walls()` method.

Observed before implementation: failed on `TownWall can generate wall segments from paths`.

### Task 2: Implement Path Wall Generator

**Files:**
- Create: `scripts/world/PathWallGenerator.gd`
- Modify: `scenes/town/Town.tscn`
- Modify: `docs/superpowers/plans/2026-06-27-path-town-wall-generator.md`

- [x] **Step 1: Add generator script**

Create `PathWallGenerator.gd` with exports for `wall_scene`, `wall_width_m`, `generated_parent_name`, `wall_y_offset`, `auto_generate_on_ready`, and a `regenerate` editor trigger. Implement `generate_walls()` by clearing/recreating `GeneratedWalls`, scanning direct `Path3D` children, dividing each curve into `ceil(length / wall_width_m)` segments, sampling midpoints and tangents, and scaling each wall X axis by `segment_length / wall_width_m`.

- [x] **Step 2: Attach generator to `TownWall`**

Add the script as an external resource in `Town.tscn`, assign it to `TownWall`, and set `wall_scene = ExtResource("8")`.

- [x] **Step 3: Remove stale manual wall instance**

Remove the single manual `TownWall/Wall` instance so generated walls are the only wall segments under `TownWall`.

- [x] **Step 4: Run unit tests**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: exit 0 and `TESTS PASSED: <N> assertions`.

- [x] **Step 5: Run scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: exit 0.

- [x] **Step 6: Mark plan complete**

Update this plan with completed checkboxes and verification notes.

Verification notes:
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 3644 assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exited 0.
- Headless logs still include existing Terrain3D texture format warnings and Beehave debugger messages.
