# Split East Wall Segments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the east town wall nodes so north and south wall segments are represented separately in `Town.tscn`.

**Architecture:** Keep all wall instances, transforms, prefab references, and IDs intact. Rename only the east wall nodes whose Z positions are at or south of the centerline from `EastWallNorth*` to `EastWallSouth*`.

**Tech Stack:** Godot 4.6+, text `.tscn` scene resources, existing headless GDScript test runner.

---

## Scope

Affected file:
- `scenes/town/Town.tscn`

## Steps

- [x] Confirm existing red test output includes `TownWalls/EastWallSouth exists as a wall segment`.
- [x] Rename east wall nodes at non-negative Z positions:
  - `EastWallNorth17` to `EastWallSouth`
  - `EastWallNorth18` to `EastWallSouth2`
  - continue sequentially through `EastWallNorth31` to `EastWallSouth15`
- [x] Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`.
- [x] Confirm EastWallSouth failures are gone and document remaining unrelated failures.
- [x] Run `godot --headless --xr-mode off --path . --check-only --quit`.

## Verification Result

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exits 1 with 2 remaining failures.
- `TownWalls/EastWallSouth` failures are gone.
- Remaining failures are unrelated:
  - `Fishing village sits on the northeast/east waterfront`
  - `Innkeeper visual model is attached to NPC body`
- `godot --headless --xr-mode off --path . --check-only --quit` exits 0.
