# Fix Player Spawn On Heightmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent the player from spawning inside the scaled heightmap terrain collision, which blocks movement.

**Architecture:** Expose a world-position height query on `HeightmapTerrain`, then have `Main.spawn_player()` resolve the configured X/Z spawn position against that terrain. CharacterBody players use their lowest collision-shape offset so the capsule starts just above the ground; XR players without a root collision shape spawn directly on the terrain surface.

**Tech Stack:** Godot 4.7, GDScript, existing headless test runner.

---

### Task 1: Add Failing Spawn Regression Tests

**Files:**
- Modify: `tests/test_terrain.gd`
- Modify: `tests/test_player_mode.gd`

- [x] **Step 1: Assert heightmap height lookup exists**

Add a test that instantiates `HeightmapTerrain.tscn`, calls `generate_from_heightmap()`, and asserts `get_height_at_world_position(Vector3(0, 0, 6))` returns a value above `1.0`.

- [x] **Step 2: Assert Main raises desktop spawn above terrain**

Add a test that creates `Main`, adds `TerrainContainer/HeightmapTerrain`, spawns the desktop player at `Vector3(0, 0, 6)`, and asserts the spawned player's Y is higher than the configured Y and above the terrain height minus the player's collision bottom offset.

- [x] **Step 3: Run tests and verify they fail**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected before implementation: failures for missing `get_height_at_world_position` and unresolved player spawn height.

### Task 2: Implement Terrain-Aware Spawn

**Files:**
- Modify: `scripts/world/HeightmapTerrain.gd`
- Modify: `scripts/main/Main.gd`

- [x] **Step 1: Add `HeightmapTerrain.get_height_at_world_position()`**

Convert world position to heightmap local X/Z, sample the loaded heightmap using the same grayscale formula as mesh generation, and return the height in world Y.

- [x] **Step 2: Add `Main.resolve_player_spawn_position()`**

Find `TerrainContainer/HeightmapTerrain`, query its height, calculate the player root's lowest collision offset, and return a non-penetrating spawn position.

- [x] **Step 3: Use resolved spawn in `spawn_player()`**

Replace direct assignment of `player_spawn_position` with the resolved position.

### Task 3: Verify

**Files:**
- Modify: `docs/superpowers/plans/2026-06-26-fix-player-spawn-on-heightmap.md`

- [x] **Step 1: Run full tests**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: exit 0 and `TESTS PASSED: <N> assertions`.

- [x] **Step 2: Run scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: exit 0. Existing Beehave no-debugger output may still appear in headless mode.

- [x] **Step 3: Mark this plan complete**

Update this plan after verification.
