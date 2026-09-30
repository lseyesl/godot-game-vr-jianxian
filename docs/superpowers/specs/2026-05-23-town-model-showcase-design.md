# Town Model Showcase Design

## Goal

Use the newly added Inn, Tavern, Market_Stall, and Innkeeper models to turn the town scene from placeholder nodes into a compact showcase town area.

## Scope

- Modify the town scene layout in `scenes/town/Town.tscn`.
- Reference these model assets:
  - `res://assets/models/Inn/Inn.glb`
  - `res://assets/models/Tavern/Tavern.glb`
  - `res://assets/models/Market_Stall/Market_Stall.glb`
  - `res://assets/models/Innkeeper/Innkeeper.glb`
- Keep existing quest NPC logic intact by preserving `scenes/npc/Npc.tscn` instances and their `npc_id` values.
- Do not add new gameplay systems, scripts, quests, dialogue, or imported model edits.

## Layout

The town uses a compact showcase plaza. The Inn and Tavern sit in the player's first-view area on opposite sides of a central path, both rotated toward the plaza center. Market stalls fill the foreground and street edges so all newly added environment models are visible quickly after entering the main scene.

The central pedestrian route remains at least 3 meters wide for VR comfort. Secondary spacing around NPCs and stalls remains at least 1.5 meters where the player is expected to pass. The scene favors immediate model visibility over a realistic town footprint.

## Node Structure

`Town.tscn` keeps the existing high-level nodes:

- `Inn`
- `Tavern`
- `MarketStreet`
- `GatePaifang`
- `SwordPracticeYard`
- `ReturnToTownTrigger`
- `DistantTownShells`
- `TownAmbience`

The Inn and Tavern nodes receive visual model child nodes. `MarketStreet` receives multiple `Market_Stall` model instances. The existing `Innkeeper` NPC remains under `Inn`; its visual `Body` node receives an Innkeeper model instance while keeping the NPC script and interaction area from `scenes/npc/Npc.tscn`. The `TavernKeeper` NPC remains under `Tavern` with its existing placeholder body unless a tavern keeper model is later added.

## Constraints

- Imported model node scale should stay at `(1, 1, 1)` unless validation shows the GLB dimensions are unusable.
- Placement uses 1 meter or 0.5 meter grid-aligned positions where practical.
- NPC interaction nodes remain outside any visual-only LOD group.
- `ReturnToTownTrigger` stays outside the showcase plaza so it does not accidentally complete the return quest while inspecting the town.

## Testing

Verification requires both commands to exit 0:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

Expected unit test output includes `TESTS PASSED: <N> assertions`.
