# Fix Model Dimensions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct obviously normalized 1m-scale source models under `assets/models` so town structures, bridges, boats, swords, and tree-like vegetation load at VR-appropriate meter dimensions.

**Architecture:** Add a focused model-dimension regression test that loads source GLBs directly and checks their MeshInstance3D AABB dimensions. Resize only source GLB resources, keeping prefab and scene node scale at `(1, 1, 1)` per the project grid standard.

**Tech Stack:** Godot 4.x headless, GDScript test runner, GLB source assets.

---

### Task 1: Add Dimension Regression Tests

**Files:**
- Modify: `tests/test_runner.gd`
- Create: `tests/test_model_dimensions.gd`

- [x] **Step 1: Write the failing test**

Create `tests/test_model_dimensions.gd` with helpers that load each GLB as a `PackedScene`, instantiate it, recursively compute mesh AABB bounds, and assert expected dimensions for:

```gdscript
extends RefCounted

const EXPECTED := {
	"res://assets/models/town/BellDrumTower/BellDrumTower01.glb": Vector3(5.103, 9.000, 5.711),
	"res://assets/models/town/BellDrumTower/BellDrumTower02.glb": Vector3(5.438, 9.000, 5.585),
	"res://assets/models/town/RiverBoat/RiverBoat.glb": Vector3(5.000, 1.344, 1.441),
	"res://assets/models/town/StoneBridge/StoneBridge01.glb": Vector3(6.000, 1.781, 1.743),
	"res://assets/models/town/StoneBridge/StoneBridge02.glb": Vector3(6.000, 1.578, 1.831),
	"res://assets/models/town/StoneBridge/StoneBridge03.glb": Vector3(6.000, 1.443, 2.402),
	"res://assets/models/town/StoneBridge/StoneBridge04.glb": Vector3(6.000, 1.089, 1.584),
	"res://assets/models/items/FlyingSword/FlyingSword.glb": Vector3(0.354, 0.089, 1.300),
	"res://assets/models/Vegetation/bamboo_01/bamboo_01.glb": Vector3(1.073, 4.000, 1.002),
	"res://assets/models/Vegetation/bamboo_02/bamboo_02.glb": Vector3(0.786, 4.000, 0.928),
	"res://assets/models/Vegetation/green_bamboo/green_bamboo.glb": Vector3(3.194, 4.000, 2.327),
	"res://assets/models/Vegetation/pine/pine.glb": Vector3(5.933, 5.000, 4.991),
	"res://assets/models/Vegetation/willow/willow.glb": Vector3(5.602, 6.000, 3.656),
	"res://assets/models/Vegetation/nanmu/nanmu.glb": Vector3(5.343, 5.000, 1.721),
	"res://assets/models/Vegetation/mountain_cherry/mountain_cherry.glb": Vector3(4.831, 5.000, 1.571),
	"res://assets/models/Vegetation/red_plum/red_plum.glb": Vector3(4.762, 5.000, 5.467),
}

func run(t) -> void:
	for path in EXPECTED.keys():
		_assert_model_size(t, path, EXPECTED[path])
```

- [x] **Step 2: Register the test**

Add `res://tests/test_model_dimensions.gd` to the `test_paths` array in `tests/test_runner.gd`.

- [x] **Step 3: Run test to verify it fails**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: the new model dimension assertions fail for the listed normalized assets.

### Task 2: Resize Source GLB Assets

**Files:**
- Modify: listed GLBs under `assets/models/town`, `assets/models/items`, and `assets/models/Vegetation`

- [x] **Step 1: Apply deterministic GLB root scaling**

Use a temporary local script to update each GLB JSON node transform with a uniform scale factor:

```text
BellDrumTower01: height 1.000028 -> 9.0
BellDrumTower02: height 0.995179 -> 9.0
RiverBoat: length 0.997671 -> 5.0
StoneBridge01: length 0.999599 -> 6.0
StoneBridge02: length 0.999258 -> 6.0
StoneBridge03: length 0.999686 -> 6.0
StoneBridge04: length 1.000080 -> 6.0
FlyingSword: length 0.997309 -> 1.3
bamboo_01: height 1.000989 -> 4.0
bamboo_02: height 1.000355 -> 4.0
green_bamboo: height 1.001068 -> 4.0
pine: height 0.835964 -> 5.0
willow: height 1.000762 -> 6.0
nanmu: height 0.935722 -> 5.0
mountain_cherry: height 0.999012 -> 5.0
red_plum: height 0.911136 -> 5.0
```

- [x] **Step 2: Refresh import metadata**

Run: `godot --headless --xr-mode off --path . --import`

Expected: command exits 0.

- [x] **Step 3: Run model dimension tests**

Run: `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`

Expected: model dimension assertions pass; any unrelated pre-existing failures are documented separately.

### Task 3: Validate Scenes Still Parse

**Files:**
- Read: `scenes/prefabs/models/**`
- Read: `scenes/town/Town.tscn`

- [x] **Step 1: Run syntax and scene validation**

Run: `godot --headless --xr-mode off --path . --check-only --quit`

Expected: command exits 0, ignoring known addon warnings that do not affect exit status.

- [x] **Step 2: Review changed files**

Run: `git status --short`

Expected: only intended GLBs, test files, and this plan are changed by this task, plus pre-existing unrelated workspace changes.
