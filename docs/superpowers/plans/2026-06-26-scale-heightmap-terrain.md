# Scale Heightmap Terrain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resize the imported heightmap terrain so the visible town area is at least 400 m wide while preserving the source image aspect ratio.

**Architecture:** The heightmap image is 1536x1024 pixels, a 3:2 aspect ratio. The scene will map the full image to 900x600 m, giving about 0.586 m per pixel and making the central town area roughly 400 m wide. World boundary and fog coverage are scaled to match the expanded terrain footprint.

**Tech Stack:** Godot 4.7/GDScript scenes, headless Godot test runner, existing `HeightmapTerrain` prefab.

---

### Task 1: Lock Terrain Scale in Tests

**Files:**
- Modify: `tests/test_terrain.gd`

- [x] **Step 1: Write the failing test**

Add assertions that `HeightmapTerrain.world_size == Vector2(900, 600)` after instantiation, that the generated mesh spans 900 m on X and 600 m on Z, and that the `WorldBoundary` prefab surrounds the same footprint.

- [x] **Step 2: Run test to verify it fails**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected before implementation: failure on terrain world size and boundary dimensions because the current terrain is still 120x80 m and the boundary is 120x120 m.

### Task 2: Resize Terrain, Boundary, and Fog

**Files:**
- Modify: `scenes/prefabs/terrain/HeightmapTerrain.tscn`
- Modify: `scenes/prefabs/terrain/WorldBoundary.tscn`
- Modify: `scenes/main/Main.tscn`

- [x] **Step 1: Resize heightmap terrain**

Set `world_size = Vector2(900, 600)` in `HeightmapTerrain.tscn`.

- [x] **Step 2: Resize world boundary**

Set north/south wall collision size to `Vector3(900, 60, 1)`, west/east wall collision size to `Vector3(1, 60, 600)`, north/south wall Z positions to `-300.5` and `300.5`, and west/east wall X positions to `-450.5` and `450.5`.

- [x] **Step 3: Resize main fog volume**

Set `Main.tscn/FogVolume.size` to `Vector3(900, 80, 600)` and keep its center near the world center.

### Task 3: Verify

**Files:**
- Modify: `docs/superpowers/plans/2026-06-26-scale-heightmap-terrain.md`

- [x] **Step 1: Run unit tests**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: exit 0 and `TESTS PASSED: <N> assertions`.

- [x] **Step 2: Run scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: exit 0. Existing headless Beehave debugger noise may still be printed.

- [x] **Step 3: Update this plan**

Mark all steps complete after verification.
