# Town Model Showcase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Place the newly added Inn, Tavern, Market_Stall, and Innkeeper models into the town scene as a compact first-view showcase area.

**Architecture:** This is a scene-only layout change in `scenes/town/Town.tscn`. Existing quest NPC instances remain responsible for interaction and quest progression; imported GLB assets are added as visual children without adding gameplay scripts.

**Tech Stack:** Godot 4.6+, `.tscn` scene resources, imported GLB `PackedScene` resources, existing `NpcDialogue` scene logic.

---

## Files

- Modify: `scenes/town/Town.tscn`
- Modify: `tests/test_runner.gd`
- Create: `tests/test_town_showcase.gd`
- Reference: `assets/models/Inn/Inn.glb`
- Reference: `assets/models/Tavern/Tavern.glb`
- Reference: `assets/models/Market_Stall/Market_Stall.glb`
- Reference: `assets/models/Innkeeper/Innkeeper.glb`
- Verify: `tests/test_runner.gd`

## Task 1: Add Town Model Resources

**Files:**
- Modify: `scenes/town/Town.tscn`

- [x] **Step 1: Add external resources for imported models**

In `scenes/town/Town.tscn`, increase `load_steps` and add these resources near the existing `ext_resource` entries:

```ini
[gd_scene load_steps=8 format=3]

[ext_resource type="PackedScene" path="res://scenes/npc/Npc.tscn" id="1"]
[ext_resource type="Script" path="res://scripts/world/ReturnToTownTrigger.gd" id="2"]
[ext_resource type="PackedScene" path="res://assets/models/Inn/Inn.glb" id="3"]
[ext_resource type="PackedScene" path="res://assets/models/Tavern/Tavern.glb" id="4"]
[ext_resource type="PackedScene" path="res://assets/models/Market_Stall/Market_Stall.glb" id="5"]
[ext_resource type="PackedScene" path="res://assets/models/Innkeeper/Innkeeper.glb" id="6"]
```

- [x] **Step 2: Run scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: command exits 0. If Godot reports a missing resource id or invalid scene parse, fix the `ext_resource` ids before continuing.

## Task 2: Build Compact Showcase Plaza

**Files:**
- Modify: `scenes/town/Town.tscn`

- [x] **Step 1: Replace placeholder transforms with showcase layout**

Set the main layout nodes to these positions:

```ini
[node name="Inn" type="Node3D" parent="."]
position = Vector3(-5, 0, -6)
rotation = Vector3(0, 0.35, 0)

[node name="Tavern" type="Node3D" parent="."]
position = Vector3(5, 0, -6)
rotation = Vector3(0, -0.35, 0)

[node name="MarketStreet" type="Node3D" parent="."]
position = Vector3(0, 0, -2)

[node name="GatePaifang" type="Node3D" parent="."]
position = Vector3(0, 0, -18)

[node name="SwordPracticeYard" type="Node3D" parent="."]
position = Vector3(-10, 0, 4)
```

This keeps the center lane around X = 0 clear and puts the two major buildings in the first-view area.

- [x] **Step 2: Add visual model instances**

Add these child nodes:

```ini
[node name="InnModel" parent="Inn" instance=ExtResource("3")]

[node name="TavernModel" parent="Tavern" instance=ExtResource("4")]

[node name="StallCenter" parent="MarketStreet" instance=ExtResource("5")]
position = Vector3(0, 0, -2)

[node name="StallLeft" parent="MarketStreet" instance=ExtResource("5")]
position = Vector3(-3, 0, 1.5)
rotation = Vector3(0, 0.45, 0)

[node name="StallRight" parent="MarketStreet" instance=ExtResource("5")]
position = Vector3(3, 0, 1.5)
rotation = Vector3(0, -0.45, 0)
```

- [x] **Step 3: Keep return trigger away from showcase plaza**

Use this trigger placement:

```ini
[node name="ReturnToTownTrigger" type="Area3D" parent="."]
position = Vector3(0, 3, 10)
script = ExtResource("2")
```

- [x] **Step 4: Run scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: command exits 0.

## Task 3: Preserve NPC Quest Logic and Add Innkeeper Visual

**Files:**
- Modify: `scenes/town/Town.tscn`

- [x] **Step 1: Reposition existing NPCs**

Keep the existing NPC instances and set their local positions:

```ini
[node name="Innkeeper" parent="Inn" instance=ExtResource("1")]
position = Vector3(1.5, 0, 2.5)
rotation = Vector3(0, 2.8, 0)
npc_id = "innkeeper"

[node name="TavernKeeper" parent="Tavern" instance=ExtResource("1")]
position = Vector3(-1.5, 0, 2.5)
rotation = Vector3(0, -2.8, 0)
npc_id = "tavern_keeper"
```

- [x] **Step 2: Add Innkeeper GLB as the visual body child**

Add the visual model beneath the inherited `Body` node:

```ini
[node name="InnkeeperModel" parent="Inn/Innkeeper/Body" instance=ExtResource("6")]
```

Leave `TavernKeeper/Body` as the existing placeholder because no tavern keeper model is in scope.

- [x] **Step 3: Run unit tests and scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: both commands exit 0, and unit tests print `TESTS PASSED: <N> assertions`.

## Task 4: Record Completion State

**Files:**
- Modify: `docs/superpowers/plans/2026-05-23-town-model-showcase.md`

- [x] **Step 1: Mark completed steps**

After implementation and verification, update this plan by changing each completed checkbox from `- [ ]` to `- [x]`.

- [x] **Step 2: Attempt Git status**

Run:

```bash
git status --short
```

Expected in a writable Git environment: output lists the modified scene plus the new spec and plan files. In the current environment, Git may fail because `.git` is read-only; if so, record that in the final response.

Result in this environment: `git status --short` failed because Git LFS could not write to `.git/lfs/tmp` on a read-only filesystem.

## Self-Review

- Spec coverage: The plan adds the four approved model resources, places Inn/Tavern/Market stalls in a compact showcase plaza, keeps NPC quest instances, keeps the return trigger outside the showcase area, and uses the required verification commands.
- Placeholder scan: The only use of placeholder is descriptive for the existing TavernKeeper body; no implementation step is left open.
- Type consistency: Resource ids `1` and `2` preserve existing scene references; new ids `3` through `6` are used consistently by the added model instance nodes.

## Implementation Note

TDD added `tests/test_town_showcase.gd` and registered it in `tests/test_runner.gd` before scene edits. The test failed before implementation on missing showcase nodes and outdated transforms, then passed after `Town.tscn` was updated.
