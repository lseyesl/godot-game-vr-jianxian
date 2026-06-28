# Import Town Model Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import the downloaded town model assets with English names, keep concept art in the documentation area, and create reusable Godot prefab scenes for each model.

**Architecture:** Each model gets its own purpose-named folder directly under `assets/models/`. Concept images remain under `docs/concept-art/`. Prefab scenes live under `scenes/prefabs/models/<PurposeName>/` and wrap the imported `.glb` with a `Node3D` root plus `Model` child instance.

**Tech Stack:** Godot 4.6+, binary glTF `.glb` assets, PNG concept art, text `.tscn` scene resources, headless GDScript tests.

---

### Task 1: Add Asset Import Coverage

**Files:**
- Create: `tests/test_imported_town_model_assets.gd`
- Modify: `tests/test_runner.gd`

- [x] Add a test that lists all target model, concept art, and prefab scene paths.
- [x] Register the test in `tests/test_runner.gd`.
- [x] Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` and confirm the new assertions fail because the assets are not imported yet.

### Task 2: Import and Rename Assets

**Files:**
- Create: `assets/models/WealthyResidence/WealthyResidence.glb`
- Create: `assets/models/StoneBridge/StoneBridge01.glb`
- Create: `assets/models/StoneBridge/StoneBridge02.glb`
- Create: `assets/models/StoneBridge/StoneBridge03.glb`
- Create: `assets/models/StoneBridge/StoneBridge04.glb`
- Create: `assets/models/TownHouse/TownHouse.glb`
- Create: `assets/models/WaterWheel/WaterWheel.glb`
- Create: `assets/models/RiverBoat/RiverBoat.glb`
- Create: `assets/models/BellDrumTower/BellDrumTower01.glb`
- Create: `assets/models/BellDrumTower/BellDrumTower02.glb`
- Create: `docs/concept-art/WealthyResidenceConcept.png`
- Create: `docs/concept-art/StoneBridgeConcept.png`
- Create: `docs/concept-art/TownHouseConcept.png`
- Create: `docs/concept-art/WaterWheelConcept.png`
- Create: `docs/concept-art/RiverBoatConcept.png`
- Create: `docs/concept-art/BellDrumTowerConcept.png`

- [x] Copy files from `/mnt/c/Users/Administrator/Downloads/model/` into the target paths above.
- [x] Keep imported model node scale at `(1, 1, 1)` by not applying scene-level scale in prefab scenes.
- [x] Run `godot --headless --xr-mode off --path . --import` so Godot generates `.import` metadata.

### Task 3: Create Prefab Scenes

**Files:**
- Create: `scenes/prefabs/models/WealthyResidence/WealthyResidence.tscn`
- Create: `scenes/prefabs/models/StoneBridge/StoneBridge01.tscn`
- Create: `scenes/prefabs/models/StoneBridge/StoneBridge02.tscn`
- Create: `scenes/prefabs/models/StoneBridge/StoneBridge03.tscn`
- Create: `scenes/prefabs/models/StoneBridge/StoneBridge04.tscn`
- Create: `scenes/prefabs/models/TownHouse/TownHouse.tscn`
- Create: `scenes/prefabs/models/WaterWheel/WaterWheel.tscn`
- Create: `scenes/prefabs/models/RiverBoat/RiverBoat.tscn`
- Create: `scenes/prefabs/models/BellDrumTower/BellDrumTower01.tscn`
- Create: `scenes/prefabs/models/BellDrumTower/BellDrumTower02.tscn`

- [x] Create one wrapper scene per `.glb`.
- [x] Root node name matches the prefab file stem.
- [x] Add a `Model` child that instances the matching `.glb`.
- [x] Set `metadata/source_model_path` on the `Model` child.

### Task 4: Verify

- [x] Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`.
  - Result: exit 1 from existing project failures; new imported asset assertions no longer fail.
- [x] Run `godot --headless --xr-mode off --path . --check-only --quit`.
  - Result: exit 0 with existing Terrain3D mipmap and Beehave debugger warnings.
- [x] Report any unrelated existing warnings or failures separately from this import work.
