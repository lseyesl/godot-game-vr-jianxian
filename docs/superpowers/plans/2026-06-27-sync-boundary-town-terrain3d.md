# Sync Boundary And Town Terrain3D Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `WorldBoundary.tscn` and `Town.tscn/LayoutReference` match the current `Main.tscn` Terrain3D footprint of 1536 m x 1024 m.

**Architecture:** The Terrain3D heightmap import uses a 1536 x 1024 source image and 512 m Terrain3D regions, producing a 3 x 2 region footprint. Keep the footprint centered at the world origin and update only the boundary walls and town layout reference plane that still describe the old 900 m x 600 m footprint.

**Tech Stack:** Godot 4.7, GDScript scene tests, `.tscn` scene resources.

---

### Task 1: Regression Tests

**Files:**
- Modify: `tests/test_terrain.gd`

- [x] **Step 1: Update boundary expectations**

Change the four `_assert_boundary_wall()` calls to expect:

```gdscript
_assert_boundary_wall(t, boundary, "NorthWall", Vector3(0, 30, -512.5), Vector3(1536, 60, 1), "north boundary covers Terrain3D width")
_assert_boundary_wall(t, boundary, "SouthWall", Vector3(0, 30, 512.5), Vector3(1536, 60, 1), "south boundary covers Terrain3D width")
_assert_boundary_wall(t, boundary, "WestWall", Vector3(-768.5, 30, 0), Vector3(1, 60, 1024), "west boundary covers Terrain3D depth")
_assert_boundary_wall(t, boundary, "EastWall", Vector3(768.5, 30, 0), Vector3(1, 60, 1024), "east boundary covers Terrain3D depth")
```

- [x] **Step 2: Update town layout reference expectation**

Change the layout reference mesh assertion to:

```gdscript
t.assert_equal(reference_mesh.size, Vector2(1536, 1024), "Layout reference matches Terrain3D footprint")
```

- [x] **Step 3: Run tests and verify red**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: failures for the old `WorldBoundary` wall positions/sizes and `LayoutReference` size.

### Task 2: Scene Resource Updates

**Files:**
- Modify: `scenes/prefabs/terrain/WorldBoundary.tscn`
- Modify: `scenes/town/Town.tscn`

- [x] **Step 1: Resize `WorldBoundary` collision shapes**

Set north/south collision sizes to `Vector3(1536, 60, 1)` and west/east collision sizes to `Vector3(1, 60, 1024)`.

- [x] **Step 2: Move `WorldBoundary` wall nodes**

Set north/south Z positions to `-512.5` and `512.5`, and west/east X positions to `-768.5` and `768.5`.

- [x] **Step 3: Resize `Town.tscn/LayoutReference` plane**

Set `PlaneMesh_layout_reference.size = Vector2(1536, 1024)`.

### Task 3: Verification

**Files:**
- Modify: `docs/superpowers/plans/2026-06-27-sync-boundary-town-terrain3d.md`

- [x] **Step 1: Run unit tests**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: exit 0 and `TESTS PASSED: <N> assertions`.

- [x] **Step 2: Run scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit 0.

- [x] **Step 3: Record verification notes**

Append exact command results to this plan.

Verification notes:
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 4123 assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exited 0.
- Headless logs still include existing Terrain3D mipmap warnings and Beehave debugger messages.
