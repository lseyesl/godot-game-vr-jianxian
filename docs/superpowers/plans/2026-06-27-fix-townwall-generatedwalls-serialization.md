# Fix TownWall GeneratedWalls Serialization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent generated TownWall wall preview nodes from being serialized into `Town.tscn` and causing nested `Model` path conflicts when Main loads the town.

**Architecture:** `TownWall` remains a path-driven generator. Generated wall nodes are runtime/editor preview children only and intentionally have no scene owner, so the scene stores editable `Path3D` routes and generator settings, not thousands of generated model subnodes.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scene text, existing headless test runner.

---

### Task 1: Reproduce Serialized GeneratedWalls Conflict

**Files:**
- Modify: `tests/test_town_showcase.gd`

- [x] **Step 1: Add a failing scene text test**

Add assertions that `scenes/town/Town.tscn` does not contain serialized `TownWall/GeneratedWalls` node sections.

- [x] **Step 2: Run the test and verify it fails**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`
Expected: FAIL while current scene still contains `[node name="GeneratedWalls" ...]`.

### Task 2: Keep Generated Walls Unsaved

**Files:**
- Modify: `scripts/world/PathWallGenerator.gd`
- Modify: `scenes/town/Town.tscn`

- [x] **Step 1: Stop assigning scene owner to generated nodes**

Remove recursive owner assignment from generated wall nodes so editor preview children are not saved into `Town.tscn`.

- [x] **Step 2: Remove existing serialized GeneratedWalls block**

Delete the current `TownWall/GeneratedWalls` node sections from `scenes/town/Town.tscn`, leaving the editable Path3D routes and existing connection intact.

- [x] **Step 3: Run tests and scene validation**

Run:
`godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`
`godot --headless --xr-mode off --path . --check-only --quit`
Expected: both exit 0.

Verification:
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 4095 assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exited 0.
