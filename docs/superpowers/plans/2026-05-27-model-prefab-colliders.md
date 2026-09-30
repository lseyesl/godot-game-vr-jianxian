# Model Prefab Colliders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add static box collision bodies to every model prefab under `scenes/prefabs/models/`.

**Architecture:** Each prefab remains a lightweight `Node3D` wrapper around its `Model` child. Add one sibling `StaticBody3D` named `CollisionBody`, with one `CollisionShape3D` child using a `BoxShape3D` sized and positioned from the visual model's combined mesh AABB.

**Tech Stack:** Godot 4.6 GDScript, `.tscn` prefab scenes, headless Godot verification.

---

### Task 1: Add Collision Coverage Tests

**Files:**
- Create: `tests/test_model_prefab_colliders.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write the failing test**

Create `tests/test_model_prefab_colliders.gd` with a copy of the prefab list from `tests/test_model_prefabs.gd`. For each prefab, instantiate the scene and assert:

```gdscript
var collision_body = prefab.get_node_or_null("CollisionBody")
t.assert_true(collision_body is StaticBody3D, "%s prefab has a StaticBody3D CollisionBody" % root_name)
if collision_body is StaticBody3D:
	var collision_shape = collision_body.get_node_or_null("CollisionShape3D")
	t.assert_true(collision_shape is CollisionShape3D, "%s CollisionBody has a CollisionShape3D" % root_name)
	if collision_shape is CollisionShape3D:
		t.assert_true(collision_shape.shape is BoxShape3D, "%s collision shape is a BoxShape3D" % root_name)
		if collision_shape.shape is BoxShape3D:
			var size := (collision_shape.shape as BoxShape3D).size
			t.assert_true(size.x > 0.0 and size.y > 0.0 and size.z > 0.0, "%s collision box has positive size" % root_name)
```

Add `"res://tests/test_model_prefab_colliders.gd"` to `test_paths` in `tests/test_runner.gd`.

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL with missing `CollisionBody` assertions for model prefabs. Existing unrelated model/town failures may also appear.

### Task 2: Add Box Colliders To Prefab Scenes

**Files:**
- Modify: all 17 `.tscn` files under `scenes/prefabs/models/`

- [x] **Step 1: Generate collider nodes**

For each prefab, compute the combined local-space AABB of all nested `MeshInstance3D` nodes under the prefab and append:

```gdscene
[sub_resource type="BoxShape3D" id="BoxShape3D_collision"]
size = Vector3(<aabb_size_x>, <aabb_size_y>, <aabb_size_z>)

[node name="CollisionBody" type="StaticBody3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="CollisionBody"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, <aabb_center_x>, <aabb_center_y>, <aabb_center_z>)
shape = SubResource("BoxShape3D_collision")
```

Update each scene `load_steps` when needed so the new subresource is counted.

- [x] **Step 2: Run collision test to verify it passes**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: no failures from `test_model_prefab_colliders.gd`. Existing unrelated model/town failures may remain.

### Task 3: Project Verification

**Files:**
- No additional files.

- [x] **Step 1: Run scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit 0.

- [x] **Step 2: Review diff**

Run:

```bash
git diff --stat
git diff -- tests/test_model_prefab_colliders.gd tests/test_runner.gd scenes/prefabs/models
```

Expected: only prefab scene files, the new collider test, the test runner, and this plan are changed.
