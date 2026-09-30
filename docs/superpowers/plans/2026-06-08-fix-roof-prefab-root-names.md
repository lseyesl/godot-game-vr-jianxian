# Fix Roof Prefab Root Names Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Roof02-Roof10 prefab root node names so they match their model/prefab names.

**Architecture:** Keep the existing prefab structure intact. Update only the root node `name` in each affected `.tscn`; model references, metadata, collider shapes, and transforms remain unchanged.

**Tech Stack:** Godot 4.6+, text `.tscn` scene resources, existing headless GDScript test runner.

---

## Scope

Affected files:
- `scenes/prefabs/models/Roof/Roof02.tscn`
- `scenes/prefabs/models/Roof/Roof03.tscn`
- `scenes/prefabs/models/Roof/Roof04.tscn`
- `scenes/prefabs/models/Roof/Roof05.tscn`
- `scenes/prefabs/models/Roof/Roof06.tscn`
- `scenes/prefabs/models/Roof/Roof07.tscn`
- `scenes/prefabs/models/Roof/Roof08.tscn`
- `scenes/prefabs/models/Roof/Roof09.tscn`
- `scenes/prefabs/models/Roof/Roof10.tscn`

## Steps

- [x] Confirm existing red test output includes `Roof02-Roof10 prefab root name matches model name`.
- [x] Change each root node declaration from `Roof01` to its matching file/model name.
- [x] Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`.
- [x] Confirm Roof02-Roof10 root-name failures are gone and document any remaining unrelated failures.

## Verification Result

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exits 1 with 5 remaining failures.
- Roof02-Roof10 root-name failures are gone.
- Remaining failures are unrelated town layout/NPC visual assertions:
  - `TownWalls/EastWallSouth exists as a wall segment`
  - `TownWalls/EastWallSouth is a 3D wall node`
  - `TownWalls/EastWallSouth uses the Wall_2x3 model`
  - `Fishing village sits on the northeast/east waterfront`
  - `Innkeeper visual model is attached to NPC body`
- `godot --headless --xr-mode off --path . --check-only --quit` exits 0.
