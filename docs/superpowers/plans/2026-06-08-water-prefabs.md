# Water Prefabs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build reusable Godot water prefabs for lake, river, river bend, and waterfall scenes with runtime motion, particles, audio player nodes, and collision/detection areas.

**Architecture:** A shared `WaterBody` script owns water type and runtime flow phase. Prefabs use built-in Godot meshes and a shared shader material, avoiding external model/audio dependencies while keeping audio attachment points ready for future assets.

**Tech Stack:** Godot 4.6+, GDScript, `.tscn` scenes, `ShaderMaterial`, `GPUParticles3D`, `Area3D`, `AudioStreamPlayer3D`, project headless test runner.

---

### Task 1: Water Prefab Tests

**Files:**
- Create: `tests/test_water_prefabs.gd`
- Modify: `tests/test_runner.gd`

- [x] **Step 1: Write failing tests**

Create a test that loads `Lake.tscn`, `RiverStraight.tscn`, `RiverBend.tscn`, and `Waterfall.tscn`, instantiates each scene, and verifies root script, collision areas, audio player nodes, visual water nodes, and waterfall particles.

- [x] **Step 2: Run tests to verify failure**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because the new test file references water prefabs that do not exist yet.

### Task 2: Runtime Water Body

**Files:**
- Create: `scripts/world/WaterBody.gd`
- Create: `assets/materials/water_flow.gdshader`
- Create: `assets/materials/mat_water_flow.tres`
- Create: `assets/materials/mat_water_foam.tres`

- [x] **Step 1: Implement `WaterBody`**

Add exported properties for water type, flow speed, flow direction, audio enabled, and collision enabled. In `_process(delta)`, advance `flow_phase` and set shader parameters on assigned water surfaces.

- [x] **Step 2: Add shared materials**

Add a transparent animated water shader material and a foam/mist material for waterfall details.

### Task 3: Water Scenes

**Files:**
- Create: `scenes/prefabs/water/Lake.tscn`
- Create: `scenes/prefabs/water/RiverStraight.tscn`
- Create: `scenes/prefabs/water/RiverBend.tscn`
- Create: `scenes/prefabs/water/Waterfall.tscn`

- [x] **Step 1: Build lake prefab**

Use a horizontal water mesh, `WaterArea/CollisionShape3D`, and `AmbientAudio`.

- [x] **Step 2: Build river prefabs**

Use flowing surface meshes, `WaterArea/CollisionShape3D`, and `WaterAudio`.

- [x] **Step 3: Build waterfall prefab**

Use a vertical water sheet, pool surface, `MistParticles`, `SplashParticles`, `WaterArea`, `SplashArea`, and `WaterfallAudio`.

### Task 4: Verification

**Files:**
- Verify all changed files.

- [x] **Step 1: Run full tests**

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: `TESTS PASSED: <N> assertions`

- [x] **Step 2: Run scene validation**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit code 0.
