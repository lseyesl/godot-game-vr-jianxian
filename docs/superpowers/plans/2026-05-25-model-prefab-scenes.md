# Model Prefab Scenes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create reusable Godot scene prefabs for every currently imported `.glb` model so future scene development can instance stable `.tscn` resources instead of raw model imports.

**Architecture:** Add a `scenes/prefabs/models/` library that mirrors the existing `assets/models/` categories. Each prefab is a `Node3D` wrapper with one visual child that instances the matching `.glb`, preserving model scale at `(1, 1, 1)` and avoiding gameplay logic or collision assumptions.

**Tech Stack:** Godot 4.6+, text `.tscn` scene resources, imported GLB `PackedScene` resources, headless GDScript resource tests.

---

## Files

- Create: `scenes/prefabs/models/Gate/Gate.tscn`
- Create: `scenes/prefabs/models/Inn/Inn.tscn`
- Create: `scenes/prefabs/models/Innkeeper/Innkeeper.tscn`
- Create: `scenes/prefabs/models/Market_Stall/Market_Stall.tscn`
- Create: `scenes/prefabs/models/Roof/Roof01.tscn` through `Roof10.tscn`
- Create: `scenes/prefabs/models/Tavern/Tavern.tscn`
- Create: `scenes/prefabs/models/Wall/Wall_1x3.tscn`
- Create: `scenes/prefabs/models/Wall/Wall_2x3.tscn`
- Create: `tests/test_model_prefabs.gd`
- Modify: `tests/test_runner.gd`

## Task 1: Add prefab resource test

- [x] Create `tests/test_model_prefabs.gd` with an explicit manifest of the 17 current GLB-to-prefab mappings.
- [x] The test asserts every `.glb` source file exists, every `.tscn` prefab exists, each prefab loads as `PackedScene`, instantiates as `Node3D`, and has a child named `Model` that tracks the source `.glb` path through either `scene_file_path` or `source_model_path` metadata.
- [x] Add `res://tests/test_model_prefabs.gd` to `tests/test_runner.gd`.
- [x] Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` and confirm the new test fails before prefabs exist.

## Task 2: Create model prefab scenes

- [x] Create category folders under `scenes/prefabs/models/` matching the existing `assets/models/` category folders.
- [x] For each current `.glb`, create a wrapper `.tscn` with root node named after the model file and a single child named `Model`; models with available Godot import metadata instance the `.glb`, while currently unimported GLBs use an instantiable placeholder that records `source_model_path`.
- [x] Keep wrapper transforms implicit/default unless a future asset-specific need is documented; do not add gameplay scripts, collision shapes, or visual scale compensation in this pass.

## Task 3: Verify prefab library

- [x] Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`; output: `TESTS PASSED: 342 assertions`.
- [x] Run `godot --headless --xr-mode off --path . --check-only --quit`; exit code 0.
- [x] Run diagnostics on modified GDScript test files. Godot LSP initialization timed out in this headless environment, so GDScript parse and scene validation were covered by the Godot test runner and `--check-only` commands.
