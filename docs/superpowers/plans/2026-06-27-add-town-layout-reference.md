# Add Town Layout Reference Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the concept layout image to `Town.tscn` as a correctly scaled 900m x 600m editor placement reference.

**Architecture:** `Town.tscn` is instanced at the `Main.tscn` origin, so a root-level horizontal `MeshInstance3D` can use the same coordinate frame as the Terrain3D footprint. The reference uses `docs/concept-art/布局.png`, a 1536x1024 image matching the heightmap aspect ratio, on a 900m x 600m plane with no collision and no shadows.

**Tech Stack:** Godot 4.7 scene resources, GDScript headless tests.

---

### Task 1: Lock Reference Layer Contract

**Files:**
- Modify: `tests/test_terrain.gd`
- Read: `scenes/town/Town.tscn`
- Read: `docs/concept-art/布局.png`

- [x] **Step 1: Write the failing test**

Add assertions in `tests/test_terrain.gd` that instantiate `Town.tscn` and verify `LayoutReference` exists, is a `MeshInstance3D`, uses a `PlaneMesh` sized `Vector2(900, 600)`, sits slightly above the ground at `Vector3(0, 0.05, 0)`, casts no shadows, and uses `res://docs/concept-art/布局.png` as its material texture.

- [x] **Step 2: Run test to verify it fails**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected before implementation: failure because `Town.tscn/LayoutReference` does not exist.

Observed before implementation: failed on `Town has layout reference plane`, confirming the test caught the missing reference layer.

### Task 2: Add Town Layout Reference Plane

**Files:**
- Modify: `scenes/town/Town.tscn`
- Modify: `docs/superpowers/plans/2026-06-27-add-town-layout-reference.md`

- [x] **Step 1: Add scene resources**

Add an external texture resource for `res://docs/concept-art/布局.png`, a `PlaneMesh` subresource with `size = Vector2(900, 600)`, and an unshaded transparent `StandardMaterial3D` that uses that texture.

- [x] **Step 2: Add `LayoutReference` node**

Add a root child `MeshInstance3D` named `LayoutReference` with `position = Vector3(0, 0.05, 0)`, `cast_shadow = 0`, the new plane mesh, and the new material override.

- [x] **Step 3: Run unit tests**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: exit 0 and `TESTS PASSED: <N> assertions`.

- [x] **Step 4: Run scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: exit 0.

- [x] **Step 5: Mark plan complete**

Update this plan with completed checkboxes and verification notes.

Verification notes:
- `godot --headless --xr-mode off --path . --import` exited 0 after adding the concept-art texture reference.
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 970 assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exited 0.
- While verifying, `tests/test_main_flow_acceptance.gd` was adjusted to instantiate `Main.tscn` and check `CompletionFeedback` as a real node instead of relying on brittle `.tscn` attribute ordering.
- Headless logs still include existing Terrain3D texture format warnings and Beehave debugger messages.
