# Add Main Ground Plane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a simple collidable ground plane to `scenes/main/Main.tscn` so the player no longer falls through the gameplay scene.

**Architecture:** Add one local static ground body directly under the main scene root. Cover it with a large visual plane and a matching shallow box collision shape at y=0 so both desktop and XR player bodies have a stable floor.

**Tech Stack:** Godot 4.6+, GDScript scene tests, `.tscn` scene resources.

---

## Scope

- Create a focused scene test for the main ground node.
- Register the test in `tests/test_runner.gd`.
- Add `Ground` to `scenes/main/Main.tscn` with visual mesh and collision shape.
- Verify with the project headless test and check-only commands.

## Affected Files

- Create: `tests/test_main_ground.gd`
- Modify: `tests/test_runner.gd`
- Modify: `scenes/main/Main.tscn`

## Steps

- [x] **Step 1: Add failing ground scene test**

Create `tests/test_main_ground.gd` that instantiates `res://scenes/main/Main.tscn` and asserts a `Ground` `StaticBody3D` exists with direct `MeshInstance3D` and `CollisionShape3D` children.

- [x] **Step 2: Register the new test**

Add `res://tests/test_main_ground.gd` to the `test_paths` array in `tests/test_runner.gd`.

- [x] **Step 3: Run RED verification**

Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`. Expected: non-zero exit because `Main.tscn` has no `Ground` node yet.

- [x] **Step 4: Add main scene ground**

In `scenes/main/Main.tscn`, increase `load_steps`, add a `PlaneMesh` and `BoxShape3D` subresource, then add a root child `Ground` of type `StaticBody3D` with `MeshInstance3D` and `CollisionShape3D` children.

- [x] **Step 5: Run GREEN verification**

Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` and `godot --headless --xr-mode off --path . --check-only --quit`. Expected: both exit 0.

## Verification Criteria

- `tests/test_main_ground.gd` fails before the scene edit for the expected missing `Ground` node.
- `scenes/main/Main.tscn` contains exactly one `StaticBody3D` named `Ground`.
- `Ground` has direct `MeshInstance3D` and `CollisionShape3D` children.
- Headless tests print `TESTS PASSED: <N> assertions`.
- Godot check-only exits 0 with `--xr-mode off`.
