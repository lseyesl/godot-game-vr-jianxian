# Qingyuan Town Replan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the first greybox pass of `scenes/town/Town.tscn` into a VR-readable Qingyuan Town layout based on `docs/concept-art/Town Concept Design.png`.

**Architecture:** This pass keeps `Inn` and `Tavern` as top-level quest anchors to reduce scene/test churn, moves existing anchors to concept-map-inspired positions, adds visible greybox markers to the district anchors, and uses the imported `Gate.glb` model for the town gate. The town remains scene-only; no new scripts, quest events, or dialogue are introduced.

**Tech Stack:** Godot 4.6+, `.tscn` scene resources, GDScript headless tests, existing `Npc.tscn` quest NPC instances.

---

## Files

- Modify: `tests/test_town_showcase.gd`
- Modify: `scenes/town/Town.tscn`
- Reference: `docs/superpowers/specs/2026-05-24-qingyuan-town-replan-design.md`
- Verify: `tests/test_runner.gd`

## Task 1: Update Town Layout Tests

**Files:**
- Modify: `tests/test_town_showcase.gd`

- [x] **Step 1: Replace the existing showcase model test with replanned layout assertions**

In `tests/test_town_showcase.gd`, replace the current `_test_showcase_models()` body with:

```gdscript
func _test_showcase_models(t, town: Node) -> void:
	t.assert_true(town.has_node("Inn/InnModel"), "Inn model is placed in town")
	t.assert_true(town.has_node("Tavern/TavernModel"), "Tavern model is placed in town")
	t.assert_true(town.has_node("GatePaifang/GateModel"), "Visible north gate model is attached")
	t.assert_true(town.has_node("SouthGatePaifang/GateModel"), "Visible south gate model is attached")
	t.assert_true(town.has_node("WestGatePaifang/GateModel"), "Visible west gate model is attached")
	t.assert_equal(town.get_node("GatePaifang").position, Vector3(0, 0, -32), "GatePaifang anchors the north gate")
	t.assert_equal(town.get_node("SouthGatePaifang").position, Vector3(0, 0, 28), "SouthGatePaifang anchors the south gate")
	t.assert_equal(town.get_node("WestGatePaifang").position, Vector3(-24, 0, 10), "WestGatePaifang anchors the west gate")
	t.assert_equal(town.get_node("MarketStreet").position, Vector3(0, 0, 8), "MarketStreet anchors the central-south market")
	t.assert_equal(town.get_node("Inn").position, Vector3(-12, 0, 6), "Inn remains top-level near the west canal")
	t.assert_equal(town.get_node("Tavern").position, Vector3(10, 0, 12), "Tavern remains top-level near the southeast tea district")
```

- [x] **Step 2: Replace the existing NPC logic test with quest preservation assertions**

In `tests/test_town_showcase.gd`, replace the current `_test_npc_logic_nodes()` body with:

```gdscript
func _test_npc_logic_nodes(t, town: Node) -> void:
	t.assert_true(town.has_node("Inn"), "Inn remains a top-level quest anchor")
	t.assert_true(town.has_node("Tavern"), "Tavern remains a top-level quest anchor")
	t.assert_true(not town.has_node("WestDistrict/Inn"), "Inn is not nested under WestDistrict in this pass")
	t.assert_true(not town.has_node("EastDistrict/Tavern"), "Tavern is not nested under EastDistrict in this pass")
	t.assert_true(town.has_node("Inn/Innkeeper"), "Innkeeper NPC remains under Inn")
	t.assert_true(town.has_node("Tavern/TavernKeeper"), "TavernKeeper NPC remains under Tavern")
	var innkeeper = town.get_node("Inn/Innkeeper")
	var tavern_keeper = town.get_node("Tavern/TavernKeeper")
	t.assert_equal(innkeeper.npc_id, "innkeeper", "Innkeeper quest id remains intact")
	t.assert_equal(tavern_keeper.npc_id, "tavern_keeper", "TavernKeeper quest id remains intact")
	t.assert_true(town.has_node("Inn/Innkeeper/Body/InnkeeperModel"), "Innkeeper visual model is attached to NPC body")
	t.assert_equal(town.get_node("ReturnToTownTrigger").position, Vector3(12, 3, 24), "Return trigger sits on the southeast return edge")
```

- [x] **Step 3: Run the test suite to verify the red state**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: the command exits non-zero before implementation because the scene lacks the concept-aligned south/west gates, expanded wall segments, and final marker paths.

## Task 2: Reposition Existing Town Anchors

**Files:**
- Modify: `scenes/town/Town.tscn`

- [x] **Step 1: Move the inn to the western district position**

In `scenes/town/Town.tscn`, change the `Inn` node to:

```ini
[node name="Inn" type="Node3D" parent="."]
position = Vector3(-12, 0, 6)
rotation = Vector3(0, 0.35, 0)
```

- [x] **Step 2: Move the tavern to the east/southeast district position**

Change the `Tavern` node to:

```ini
[node name="Tavern" type="Node3D" parent="."]
position = Vector3(10, 0, 12)
rotation = Vector3(0, -0.35, 0)
```

- [x] **Step 3: Move the market to the central town position**

Change the `MarketStreet` node to:

```ini
[node name="MarketStreet" type="Node3D" parent="."]
position = Vector3(0, 0, 8)
```

Keep the existing stall child transforms:

```ini
[node name="StallCenter" parent="MarketStreet" instance=ExtResource("5")]
position = Vector3(0, 0, -2)

[node name="StallLeft" parent="MarketStreet" instance=ExtResource("5")]
position = Vector3(-3, 0, 1.5)
rotation = Vector3(0, 0.45, 0)

[node name="StallRight" parent="MarketStreet" instance=ExtResource("5")]
position = Vector3(3, 0, 1.5)
rotation = Vector3(0, -0.45, 0)
```

- [x] **Step 4: Move the gate to the north gate position**

Change the `GatePaifang` node to:

```ini
[node name="GatePaifang" type="Node3D" parent="."]
position = Vector3(0, 0, -32)
```

- [x] **Step 5: Move the return trigger to the southeast return edge**

Change the `ReturnToTownTrigger` node to:

```ini
[node name="ReturnToTownTrigger" type="Area3D" parent="."]
position = Vector3(12, 3, 24)
script = ExtResource("2")
```

Keep its collision child unchanged:

```ini
[node name="CollisionShape3D" type="CollisionShape3D" parent="ReturnToTownTrigger"]
shape = SubResource("BoxShape3D_1")
```

## Task 3: Add District Anchors and Landmark Shells

**Files:**
- Modify: `scenes/town/Town.tscn`

- [x] **Step 1: Add the western district anchor and children**

Insert these nodes after `SwordPracticeYard` and before `ReturnToTownTrigger`:

```ini
[node name="WestDistrict" type="Node3D" parent="."]
position = Vector3(0, 0, 0)

[node name="CanalMarker" type="MeshInstance3D" parent="WestDistrict"]
position = Vector3(-10, 0, 8)

[node name="WaterwheelMarker" type="MeshInstance3D" parent="WestDistrict"]
position = Vector3(-18, 0, 10)

[node name="FarmlandWestMarker" type="MeshInstance3D" parent="WestDistrict"]
position = Vector3(-20, 0, 2)

[node name="FarmlandNorthWestMarker" type="MeshInstance3D" parent="WestDistrict"]
position = Vector3(-22, 0, -14)

[node name="FarmlandSouthWestMarker" type="MeshInstance3D" parent="WestDistrict"]
position = Vector3(-24, 0, 20)
```

- [x] **Step 2: Add the eastern district anchor and children**

Add these nodes after the western district block:

```ini
[node name="EastDistrict" type="Node3D" parent="."]
position = Vector3(0, 0, 0)

[node name="YamenMarker" type="MeshInstance3D" parent="EastDistrict"]
position = Vector3(16, 0, 2)

[node name="DockMarker" type="MeshInstance3D" parent="EastDistrict"]
position = Vector3(22, 0, 10)
```

- [x] **Step 3: Add the southeast temple anchor**

Add these nodes after the eastern district block:

```ini
[node name="SouthEastDistrict" type="Node3D" parent="."]
position = Vector3(0, 0, 0)

[node name="TempleMarker" type="MeshInstance3D" parent="SouthEastDistrict"]
position = Vector3(12, 0, 18)
```

- [x] **Step 4: Add the northeast resource district anchor and children**

Add these nodes after the southeast district block:

```ini
[node name="NorthEastDistrict" type="Node3D" parent="."]
position = Vector3(0, 0, 0)

[node name="GranaryMarker" type="MeshInstance3D" parent="NorthEastDistrict"]
position = Vector3(8, 0, -16)

[node name="BlacksmithMarker" type="MeshInstance3D" parent="NorthEastDistrict"]
position = Vector3(14, 0, -12)

[node name="ForestryMarker" type="MeshInstance3D" parent="NorthEastDistrict"]
position = Vector3(18, 0, -24)

[node name="FishingVillageMarker" type="MeshInstance3D" parent="NorthEastDistrict"]
position = Vector3(24, 0, -18)
```

- [x] **Step 5: Confirm quest nodes were not nested into district anchors**

Inspect `scenes/town/Town.tscn` and confirm these node headers still use `parent="."` or their original quest parents:

```ini
[node name="Inn" type="Node3D" parent="."]
[node name="Innkeeper" parent="Inn" instance=ExtResource("1")]
[node name="Tavern" type="Node3D" parent="."]
[node name="TavernKeeper" parent="Tavern" instance=ExtResource("1")]
```

## Task 4: Verify Layout Tests and Scene Syntax

**Files:**
- Verify: `tests/test_runner.gd`
- Verify: `scenes/town/Town.tscn`

- [x] **Step 1: Run the full headless test suite**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: command exits 0 and prints `TESTS PASSED: <N> assertions`.

- [x] **Step 2: Run Godot scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: command exits 0.

- [x] **Step 3: Review the changed files for scope control**

Confirm the implementation stays within scene, tests, documentation, and referenced art/model assets:

```text
tests/test_town_showcase.gd
scenes/town/Town.tscn
docs/art/town-layout.md
docs/superpowers/specs/2026-05-24-qingyuan-town-replan-design.md
docs/superpowers/plans/2026-05-24-qingyuan-town-replan.md
docs/concept-art/Town Concept Design.png
assets/models/Gate/Gate.glb
assets/models/Gate/Gate_Image_0.png
assets/models/Gate/textures/
assets/models/Wall/Wall_2x3.glb
```

Confirm no new scripts, quest events, dialogue files, or Godot addon files were added. The Gate and Wall model assets are scene dependencies and must be included with any commit/PR that includes `Town.tscn`.

## Success Criteria

- `Town/GatePaifang` is at `Vector3(0, 0, -32)` and uses `res://assets/models/Gate/Gate.glb`.
- `Town/SouthGatePaifang` is at `Vector3(0, 0, 28)` and uses `res://assets/models/Gate/Gate.glb`.
- `Town/WestGatePaifang` is at `Vector3(-24, 0, 10)` and uses `res://assets/models/Gate/Gate.glb`.
- `Town/MarketStreet` is at `Vector3(0, 0, 8)`.
- `Town/Inn` remains top-level at `Vector3(-12, 0, 6)`.
- `Town/Tavern` remains top-level at `Vector3(10, 0, 12)`.
- `Town/ReturnToTownTrigger` is at `Vector3(12, 3, 24)`.
- `TownWalls` includes north, south, west, and east wall segment nodes using `res://assets/models/Wall/Wall_2x3.glb`.
- `WestDistrict`, `EastDistrict`, `SouthEastDistrict`, and `NorthEastDistrict` exist as visual-only top-level anchors.
- West farmland coverage includes `WestDistrict/FarmlandWestMarker`, `WestDistrict/FarmlandNorthWestMarker`, and `WestDistrict/FarmlandSouthWestMarker`.
- East/southeast/northeast concept anchors include `EastDistrict/YamenMarker`, `EastDistrict/DockMarker`, `SouthEastDistrict/TempleMarker`, `NorthEastDistrict/GranaryMarker`, `NorthEastDistrict/BlacksmithMarker`, `NorthEastDistrict/ForestryMarker`, and `NorthEastDistrict/FishingVillageMarker`.
- All concept landmark markers are visible `MeshInstance3D` nodes.
- `Inn/Innkeeper.npc_id` remains `"innkeeper"`.
- `Tavern/TavernKeeper.npc_id` remains `"tavern_keeper"`.
- `Inn/Innkeeper/Body/InnkeeperModel` remains present.
- Both Godot verification commands pass with `--xr-mode off`.

## Commit Policy

Do not commit during implementation unless the user explicitly requests a commit. If the user later requests a commit, first inspect `git status`, `git diff`, and `git log --oneline -10`, then commit only the intended files after both verification commands pass.

## Self-Review

- Spec coverage: Tasks cover the approved VR task-route town, top-level `Inn`/`Tavern` preservation, gate/market/inn/tavern/return-trigger repositioning, district anchors, quest NPC preservation, and required Godot verification.
- Placeholder scan: This plan contains no unresolved task content or deferred implementation sections.
- Type consistency: All paths use existing Godot node naming from `Town.tscn`; all positions are `Vector3` values aligned to 1 m coordinates.

## Review Follow-Up

- [x] **Step 1: Add tests for visible gate and landmark markers**

`tests/test_town_showcase.gd` now checks `GatePaifang/GateModel` is a `MeshInstance3D` and each district landmark has a `Marker` child that is a `MeshInstance3D`.

- [x] **Step 2: Verify the new tests fail before implementation**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Result: failed with 21 expected failures for missing `GatePaifang/GateModel` and missing landmark `Marker` nodes.

- [x] **Step 3: Add visible greybox meshes**

`scenes/town/Town.tscn` now uses `BoxMesh` subresources for each landmark `Marker`. `GatePaifang/GateModel` has been replaced with the imported `assets/models/Gate/Gate.glb` scene instance after the asset import became available to headless Godot.

- [x] **Step 4: Re-run verification**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

Result: test runner passed with `TESTS PASSED: 184 assertions`; scene validation exited 0.

- [x] **Step 5: Replace greybox gate with imported Gate asset**

`tests/test_town_showcase.gd` now asserts `GatePaifang/GateModel.scene_file_path == "res://assets/models/Gate/Gate.glb"`. The test failed against the greybox gate, then passed after `scenes/town/Town.tscn` added:

```ini
[ext_resource type="PackedScene" path="res://assets/models/Gate/Gate.glb" id="7"]

[node name="GateModel" parent="GatePaifang" instance=ExtResource("7")]
```

Verification after this replacement:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

Result: test runner passed with `TESTS PASSED: 185 assertions`; scene validation exited 0.

- [x] **Step 6: Add imported wall segments around the north gate**

`tests/test_town_showcase.gd` now asserts `TownWalls/NorthWallWest` and `TownWalls/NorthWallEast` exist and use `res://assets/models/Wall/Wall_2x3.glb`. The test failed against the scene without wall nodes, then passed after `scenes/town/Town.tscn` added:

```ini
[ext_resource type="PackedScene" path="res://assets/models/Wall/Wall_2x3.glb" id="8"]

[node name="TownWalls" type="Node3D" parent="."]
position = Vector3(0, 0, 0)

[node name="NorthWallWest" parent="TownWalls" instance=ExtResource("8")]
position = Vector3(-4, 0, -32)

[node name="NorthWallEast" parent="TownWalls" instance=ExtResource("8")]
position = Vector3(4, 0, -32)
```

Verification after this replacement:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Result: test runner passed with `TESTS PASSED: 192 assertions`.

## Concept-Map Alignment Follow-Up

The first implemented layout over-compressed the concept art into a simple north-gate route. This follow-up realigns the greybox with `docs/concept-art/Town Concept Design.png`: three gates, a north-south main street, center-south market, west canal/inn/waterwheel branch, east yamen/dock branch, southeast temple, northeast forestry/fishing village, and farmland in the west/northwest/southwest.

- [x] **Step 1: Update tests to require the concept-map layout**

`tests/test_town_showcase.gd` now checks:

```gdscript
t.assert_equal(town.get_node("GatePaifang").position, Vector3(0, 0, -32), "GatePaifang anchors the north gate")
t.assert_equal(town.get_node("SouthGatePaifang").position, Vector3(0, 0, 28), "SouthGatePaifang anchors the south gate")
t.assert_equal(town.get_node("WestGatePaifang").position, Vector3(-24, 0, 10), "WestGatePaifang anchors the west gate")
t.assert_equal(town.get_node("MarketStreet").position, Vector3(0, 0, 8), "MarketStreet anchors the central-south market")
t.assert_equal(town.get_node("Inn").position, Vector3(-12, 0, 6), "Inn remains top-level near the west canal")
t.assert_equal(town.get_node("Tavern").position, Vector3(10, 0, 12), "Tavern remains top-level near the southeast tea district")
```

It also checks the expanded `TownWalls` segments and the final concept marker coordinates listed in `docs/art/town-layout.md`.

- [x] **Step 2: Verify the tests fail before scene changes**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Result: failed with expected missing south/west gate nodes, missing expanded wall segments, old coordinates, and old marker paths.

- [x] **Step 3: Update `Town.tscn` to match the concept map**

`scenes/town/Town.tscn` now uses:

```text
GatePaifang: (0, 0, -32)
SouthGatePaifang: (0, 0, 28)
WestGatePaifang: (-24, 0, 10)
MarketStreet: (0, 0, 8)
Inn: (-12, 0, 6)
Tavern: (10, 0, 12)
ReturnToTownTrigger: (12, 3, 24)
```

District markers now use the final paths and coordinates documented in `docs/art/town-layout.md`.

- [x] **Step 4: Document the final coordinate map**

Created `docs/art/town-layout.md` with the gate, wall, quest-anchor, and district marker coordinates that match the scene.

- [x] **Step 5: Add distinct west farmland coverage**

Context review found that the concept requirement called for farmland west/northwest/southwest, while the scene only had northwest and southwest farmland markers. `tests/test_town_showcase.gd` now requires `WestDistrict/FarmlandWestMarker` at `Vector3(-20, 0, 2)`. The test failed against the scene without that marker, then passed after `scenes/town/Town.tscn` added it.
