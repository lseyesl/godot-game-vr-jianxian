# Main Scene Layout From Concept

Source reference: `docs/concept-art/布局.png`

This document records the current `scenes/main/Main.tscn` layout pass. The scene now uses the heightmap terrain as the only large ground surface. Extra ground panels that fought the terrain shape were removed, and missing art is represented by named box placeholders.

## Coordinate Intent

- Town center stays near world origin so existing `Town.tscn` gameplay nodes remain usable.
- Positive X is the eastern waterfront and harbor side.
- Negative X is the western mountain and terraced-field side.
- Negative Z is the northern gate and mountain trial approach.
- Positive Z is the southern gate, canal mouth, and lower waterfront.

## Main Groups

All temporary layout boxes live under `Main/ConceptLayout`.

| Group | Concept role | Current nodes | Replacement target |
| --- | --- | --- | --- |
| `TownWallPlaceholders` | Walled town boundary and north/south gates | `NorthWallRun`, `SouthWallRun`, `WestWallRun`, `EastCanalWallRun`, `NorthGate`, `SouthGate` | Modular wall, gate, corner tower, and canal-side wall scenes |
| `TownDistrictPlaceholders` | Dense town blocks around market, inn, tavern, and courtyard | `CentralMarketBlocks`, `InnDistrictBlocks`, `TavernDistrictBlocks`, `TempleCourtyardBlocks` | Building clusters, roof kits, street props, NPC path markers |
| `FieldPlaceholders` | Terraced farmland outside the west wall | `NorthwestTerracedFields`, `SouthwestRiceFields` | Low crop beds, field ridges, irrigation ditches, farm props |
| `WaterfrontPlaceholders` | Eastern harbor and southern dock | `EastHarborDocks`, `SouthDock` | Pier modules, boats, retaining walls, market-on-water props |
| `RiverbankAndBedPlaceholders` | Visible riverbed/canal bed underneath water surfaces | `EastRiverBed`, `SouthCanalBed` | Riverbed mesh using dry riverbed rock material and sculpted banks |
| `MountainBackdropPlaceholders` | Large surrounding mountain masses from the concept border | `WestMountainMass`, `NorthMountainMass`, `SoutheastMountainMass` | Distant mountain mesh or LOD group; should not block VR paths |
| `TrialRoutePlaceholders` | Northward mountain route and trial approach | `MountainGateRoute`, `TrialApproachBridge`, `WaterfallVista` | Trail mesh, bridge/steps, cliffs, waterfall vista, route signage |

## Replacement Rules

1. Keep placeholder node names stable until the replacement scene is committed.
2. Replace a placeholder by changing its `instance=ExtResource(...)` to the final prefab when dimensions and origin match.
3. If the final asset needs a different origin, keep the placeholder as a sibling named `<NodeName>_Guide` until placement is verified, then remove it in the same change.
4. Do not add collision to layout placeholders. Collision should come from the final gameplay-ready prefab or from explicit invisible collision nodes.
5. When replacing riverbed placeholders, align the mesh below the water plane and update water transforms in the same change.
6. After adding imported models or textures, run:

```bash
godot --headless --xr-mode off --path . --import
godot --headless --xr-mode off --path . --check-only --quit
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

## Removed Conflict Nodes

The following old nodes were removed from `Main.tscn` because they visually contradicted the heightmap layout or duplicated large surfaces:

- `TerrainContainer/TownGround`
- `TerrainContainer/SuburbGround`
- `TerrainContainer/MountainGround`
- `ConnectionCorridor`
- `ConnectionCorridor/Path_*`
- `ConnectionCorridor/CliffWalls`

`TerrainContainer/HeightmapTerrain` and `TerrainContainer/WorldBoundary` remain the base terrain and bounds.
