# Qingyuan Town Replan Design

## Goal

Replan `scenes/town/Town.tscn` from a compact asset showcase into a VR-readable version of the concept map in `docs/concept-art/Town Concept Design.png`, with `GatePaifang` treated as the town gate anchor.

## Source Reading

The concept art shows Qingyuan Town as a walled riverside town built around land and water transport. The main town core contains gates, a central market, inn, medicine shop, teahouse, temple, granary, blacksmith, yamen/government gate, docks, canals, bridges, farmland, a waterwheel, forestry, and a fishing village along the eastern waterfront.

The current scene is much smaller. `Town.tscn` contains `Inn`, `Tavern`, `MarketStreet`, `GatePaifang`, `SwordPracticeYard`, `ReturnToTownTrigger`, `DistantTownShells`, and `TownAmbience`. Tests currently lock the inn, tavern, market street, and return trigger transforms, so implementation must update `tests/test_town_showcase.gd` together with the scene if those anchors move.

## Layout Approaches Considered

### Approach A: Preserve the compact showcase

Keep the existing inn, tavern, and market arrangement, then add concept-art labels as nearby dressing. This is lowest risk and keeps current tests stable, but it does not deliver the requested full town replan.

### Approach B: Full concept-map reproduction

Translate every map label into a wide explorable town with all gates, waterways, docks, fields, and outlying districts. This best matches the art, but it risks oversizing a 15-minute PCVR vertical slice and would require many placeholder assets before the town feels complete.

### Approach C: concept-aligned VR greybox town, recommended

Compress the concept map into a readable VR town without reducing it to a single north-gate route. The greybox keeps the concept map's north, south, and west gates; north-south main street; center-south market; west canal/inn/waterwheel branch; east yamen/dock branch; southeast temple; and northeast forestry/fishing-village silhouettes. This preserves the concept art's identity while keeping travel time, comfort spacing, and implementation scope under control.

## Recommended Town Structure

Use a north-facing coordinate convention matching the concept map: negative Z is north, positive Z is south, negative X is west, positive X is east.

### Core Axis

`GatePaifang` becomes the primary north gate at `(0, 0, -32)`. `SouthGatePaifang` anchors the south gate at `(0, 0, 28)`, and `WestGatePaifang` anchors the west/southwest gate at `(-24, 0, 10)`. A 4 m wide main street runs south from the north gate through the central market to the south gate. This street is the player's first read of the town and should remain the clearest VR navigation line.

The central market moves to the town center-south around `(0, 0, 8)`. Existing `MarketStreet` stalls become the first market cluster rather than the whole town. The route through the market must preserve at least 3 m of open walking space.

### West District

The inn sits west of the market near the canal route, around `(-12, 0, 6)`, with the innkeeper kept as the quest NPC. This matches the concept art's western inn placement and keeps the first NPC close to the entry route.

A new visual-only west district should contain farmland, the waterwheel, and garden-gate/canal dressing. These can initially be greybox nodes or distant shells until dedicated assets exist. The west side should feel rural and humid: fields, canal edges, a bridge, and the waterwheel establish the farming/water economy.

### East District

The tavern keeps the `tavern_keeper` quest role but shifts east/southeast of the market, around `(10, 0, 12)`, acting as the second social stop before the mountain trial route. This location reads as a commerce/teahouse district near the temple rather than a mirrored building opposite the inn.

The yamen/government marker and dock marker form the east water corridor. Even before dedicated models exist, `YamenMarker` and `DockMarker` define the waterfront direction. The northeastern edge includes forestry and fishing-village markers so the town reads as connected to both forest and water economies.

### South and Southeast Districts

The temple sits southeast of the market as a quiet visual landmark and potential future lore node. It should not block the main quest route. The south gate can be represented by a secondary gate marker or distant shell until travel through it is needed.

`ReturnToTownTrigger` stays outside the primary browsing plaza. For the replanned layout, place it near the southern or southeastern return edge, far enough from the first-view area that the player cannot complete the return quest accidentally while inspecting town.

### North and Northeast Districts

The granary and blacksmith cluster north/east of the market, between the gate and waterfront direction. These can start as named placeholder anchors or shell nodes. The forestry area sits beyond them as a northeastern backdrop, helping the town feel connected to mountain and river resources.

## Proposed Node Plan

Keep existing quest-critical nodes where possible, but regroup them under clearer layout anchors during implementation:

```text
Town
├── GatePaifang
│   └── GateModel
├── SouthGatePaifang
│   └── GateModel
├── WestGatePaifang
│   └── GateModel
├── TownWalls
├── MarketStreet
│   ├── StallCenter
│   ├── StallLeft
│   └── StallRight
├── WestDistrict
│   ├── CanalMarker
│   ├── WaterwheelMarker
│   ├── FarmlandWestMarker
│   ├── FarmlandNorthWestMarker
│   └── FarmlandSouthWestMarker
├── EastDistrict
│   ├── YamenMarker
│   └── DockMarker
├── SouthEastDistrict
│   └── TempleMarker
├── NorthEastDistrict
│   ├── GranaryMarker
│   ├── BlacksmithMarker
│   ├── ForestryMarker
│   └── FishingVillageMarker
├── Inn
│   ├── InnModel
│   └── Innkeeper
├── Tavern
│   ├── TavernModel
│   └── TavernKeeper
├── SwordPracticeYard
├── ReturnToTownTrigger
├── DistantTownShells
└── TownAmbience
```

If implementation risk is high, preserve current top-level `Inn` and `Tavern` paths for one pass and add district nodes around them later. If implementation prioritizes clean structure, update tests to expect the new nested district paths.

## Scale and Comfort Rules

- Godot 1 unit remains 1 meter.
- Main quest paths must be at least 3 m wide.
- Secondary paths, bridges, and NPC approach zones must be at least 1.5 m wide.
- Building and district anchors should align to 1 m or 0.5 m coordinates.
- Imported model node scale should stay `(1, 1, 1)` unless asset validation proves a model is unusable at native scale.
- Core NPC and trigger nodes must stay outside visual-only LOD groups.

## Quest Flow

The town should support this readable route:

1. Player enters from `GatePaifang` / north gate.
2. Player sees market activity directly ahead.
3. Player turns west to the inn and speaks to `innkeeper`.
4. Player returns through market toward the east/southeast tavern district.
5. Player speaks to `tavern_keeper`.
6. Player exits toward the mountain/trial route.
7. After returning with the flying sword, player reaches `ReturnToTownTrigger` on the town return edge.

This keeps the concept-map fantasy while limiting mandatory travel to a simple loop.

## Implementation Impact

Expected modified files for a first greybox pass:

- `scenes/town/Town.tscn`: reposition existing nodes and add district anchors/shells.
- `tests/test_town_showcase.gd`: update transform and node-path expectations for the replanned layout.
- `docs/superpowers/plans/YYYY-MM-DD-qingyuan-town-replan.md`: implementation plan required before scene edits.

No new gameplay systems, quest events, or dialogue are required for the first pass.

`assets/models/Gate/Gate.glb` is the intended visible model for `GatePaifang/GateModel`. If that asset ever fails headless scene validation, temporarily fall back to a greybox gate and fix the imported asset separately.

## Verification Criteria

The implementation plan should require:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

Expected result: both commands exit 0, and the test runner prints `TESTS PASSED: <N> assertions`.

Manual VR/editor review should confirm that the north gate, central market, west inn/canal district, east tavern/dock direction, and distant waterfront/field silhouettes are visually readable from the main street.

## Open Review Points

- Confirm whether `GatePaifang` should represent the north gate specifically, or a generic main gate facing the player's spawn.
- Confirm whether the first implementation should preserve existing top-level `Inn` and `Tavern` paths, or move them under `WestDistrict` and `EastDistrict` immediately.
- Confirm whether greybox shells are acceptable for temple, yamen, docks, farmland, and waterwheel until dedicated assets are available.
