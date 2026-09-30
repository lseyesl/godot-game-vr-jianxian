# Regenerate Terrain3D Heightmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the tracked Terrain3D region resources from the current `terrain_heightmap.png`.

**Architecture:** Keep the existing `Main.tscn` Terrain3D node, material, assets, and data directory contract. Use the existing Terrain3D import API with the current 1536x1024 heightmap, `HEIGHT_OFFSET = -0.5`, `HEIGHT_SCALE = 32.0`, and `REGION_SIZE = 512`, replacing stale region files in `assets/terrain3d/data/`.

**Tech Stack:** Godot 4.7/GDScript, Terrain3D addon, headless Godot verification.

---

### Task 1: Regenerate Terrain3D Data

**Files:**
- Modify: `assets/terrain3d/data/*.res`
- Read: `tools/setup_terrain3d_from_heightmap.gd`
- Read: `assets/textures/terrain/heightmaps/terrain_heightmap.png`

- [x] **Step 1: Run the Terrain3D heightmap import**

Use a temporary headless GDScript importer with the same constants as `tools/setup_terrain3d_from_heightmap.gd`. The script removes existing `terrain3d*.res` files in `assets/terrain3d/data/`, imports `terrain_heightmap.png`, and saves fresh region resources.

Note: Direct `--script` Terrain3D initialization crashed when setting `region_size`, so the successful import used the existing `tools/setup_terrain3d_from_heightmap.tscn` in headless editor mode.

- [x] **Step 2: Check the generated region set**

Run: `find assets/terrain3d/data -maxdepth 1 -type f -name 'terrain3d*.res' | sort`

Expected: region files are present under `assets/terrain3d/data/` and match the import footprint.

### Task 2: Verify Project Integrity

**Files:**
- Modify: `docs/superpowers/plans/2026-06-27-regenerate-terrain3d-heightmap.md`

- [x] **Step 1: Run unit tests**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: exit 0 and `TESTS PASSED: <N> assertions`.

- [x] **Step 2: Run scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: exit 0.

- [x] **Step 3: Mark plan complete**

Update this plan after verification with completed checkboxes and any relevant notes.

Verification notes:
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 960 assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exited 0.
- Headless logs still include existing Terrain3D texture format warnings and Beehave debugger messages.
