# Town NPC AI Design

## Goal

Add behavior-tree-driven town NPC AI for the town slice, covering market vendors, the tavern owner, the inn owner, and wandering pedestrians. The feature should make the town feel inhabited without changing the main quest FSM or requiring VR hardware to verify.

## Scope

This pass adds a reusable town NPC behavior layer and wires representative NPCs into `scenes/town/Town.tscn`.

Included:

- Market vendors that stay near stalls, face nearby players, and speak short Chinese ambient lines.
- Tavern and inn owners that keep their existing quest dialogue IDs while also exposing ambient town behavior.
- Wandering pedestrians that patrol short waypoint loops, pause near the player, and resume walking.
- Thin Beehave action and condition nodes that call a focused `TownNpc` script API.
- Headless tests for core NPC behavior and town scene placement.

Not included:

- New quest steps, quest events, save data, or comfort settings.
- Complex crowd avoidance, navmesh generation, or long-distance pathfinding.
- New character models or imported assets.
- UI dialogue presentation changes beyond testable ambient-line state.

## Current Context

The project already has:

- `scripts/npc/NpcDialogue.gd`, which selects quest dialogue and advances valid quest events for `innkeeper` and `tavern_keeper`.
- `scenes/npc/Npc.tscn`, a reusable quest NPC scene with an interaction area and an Innkeeper visual model.
- `scenes/town/Town.tscn`, with top-level `Inn`, `Tavern`, and `MarketStreet` anchors, plus three market stall instances.
- Beehave installed under `addons/beehave/`, currently used by combat-oriented AI.
- Headless GDScript tests in `tests/`, with `tests/test_town_showcase.gd` already locking key town structure.

The new town AI must preserve existing paths and IDs:

- `Inn/Innkeeper.npc_id == "innkeeper"`
- `Tavern/TavernKeeper.npc_id == "tavern_keeper"`
- `Town/MarketStreet` remains the central-south market anchor.

## Architecture

Use a hybrid approach: keep behavior-tree nodes as orchestration and put the behavior rules in a reusable NPC script.

`scripts/npc/TownNpc.gd` is the primary behavior unit. It should be testable without autoloads and expose methods such as:

- `line_for_role()`
- `speak_context_line()`
- `set_nearby_player(player)`
- `clear_nearby_player(player)`
- `has_nearby_player()`
- `move_to_next_waypoint(delta)`
- `is_at_waypoint()`
- `start_waiting()`
- `tick_wait(delta)`
- `look_at_player()`

Beehave condition/action scripts under `scripts/npc/ai/` should stay thin. They should call methods on the owning `TownNpc` node and return success/failure/running according to Beehave conventions.

This keeps the scene behavior editable while keeping the logic easy to unit test.

## Components

### `TownNpc.gd`

Responsibilities:

- Store the role:
  - `vendor`
  - `tavern_owner`
  - `inn_owner`
  - `pedestrian`
- Store a Chinese ambient line pool per role.
- Track optional local waypoint positions for pedestrian patrols.
- Track nearby player state from an `Area3D`.
- Move slowly between waypoints for pedestrian NPCs.
- Rotate toward a nearby player when greeting or speaking.
- Record `last_spoken_line` so tests can verify behavior without UI.

Defaults:

- `npc_role = "pedestrian"`
- `move_speed_mps = 1.0`
- `player_sense_radius_m = 2.5`
- `wait_duration_s = 1.5`
- Unknown roles fall back to pedestrian lines.

### Beehave Nodes

The implementation should add only the minimal nodes needed:

- `HasNearbyPlayerCondition.gd`
- `IsAtWaypointCondition.gd`
- `MoveToWaypointAction.gd`
- `WaitAtWaypointAction.gd`
- `LookAtPlayerAction.gd`
- `SpeakAmbientLineAction.gd`

These nodes should not own line tables, quest IDs, or town-specific positions.

### `TownNpc.tscn`

Reusable town NPC scene:

- Root node uses `TownNpc.gd`.
- Includes a visible model or simple placeholder mesh.
- Includes a body collision shape suitable for a standing person.
- Includes a `SenseArea` with a collision shape for player detection.
- Connects `body_entered` and `body_exited` to `TownNpc`.
- Includes a Beehave tree using the thin scripts above.

### `Town.tscn`

Add `TownNpcGroup` under `Town`.

Representative instances:

- `TownNpcGroup/MarketVendorCenter`, near `MarketStreet/StallCenter`, role `vendor`.
- `TownNpcGroup/MarketVendorLeft`, near `MarketStreet/StallLeft`, role `vendor`.
- `TownNpcGroup/InnOwnerAmbient`, near or attached to the inn owner path, role `inn_owner`.
- `TownNpcGroup/TavernOwnerAmbient`, near or attached to the tavern owner path, role `tavern_owner`.
- `TownNpcGroup/PedestrianA`, short loop along the market street.
- `TownNpcGroup/PedestrianB`, short loop between market and south gate.

The inn and tavern owner ambient behavior must not remove or rename the existing quest NPC nodes. If the owner behavior is implemented as separate ambient nodes for this pass, they should be placed close to the existing owner NPCs and named clearly so later work can merge visuals if needed.

## Behavior

Vendor and owner NPCs:

- Stay close to their home position.
- Detect player bodies in the `player` group.
- Face the player while nearby.
- Speak one ambient Chinese line through `last_spoken_line`.
- Do not advance quests or call `Game.advance_quest()`.

Pedestrian NPCs:

- Patrol their configured waypoint loop.
- Move at low speed for VR comfort.
- Pause briefly when reaching a waypoint.
- Pause and face the player when the player enters the sense radius.
- Resume patrol after the player leaves.

All NPCs:

- Must work without autoloads.
- Must avoid direct references to `Game` and `EventBus` in the ambient AI layer for this pass.
- Must not chase the player.
- Must not block the required 3 m main route through town.

## Dialogue Content

Ambient lines are short Chinese lines that reinforce town life and the mountain-trial premise.

Example vendor lines:

- `新摘的灵草，熬汤最养气。`
- `少侠慢走，摊上的符纸都压过香灰。`

Example inn owner lines:

- `客栈还有热茶，出镇前歇一口气。`
- `昨夜剑光从屋脊掠过，镇里人都看见了。`

Example tavern owner lines:

- `山风带妖气，酒也压不住。`
- `听说北边旧祭台又亮了。`

Example pedestrian lines:

- `今天集市比往常热闹。`
- `有人说山里传来钟声。`

## Testing

Add `tests/test_town_npc.gd`:

- `TownNpc.gd` exists and can instantiate.
- Unknown role falls back to pedestrian ambient lines.
- Vendor, inn owner, tavern owner, and pedestrian roles each return a non-empty Chinese line.
- `set_nearby_player()` and `clear_nearby_player()` update `has_nearby_player()`.
- A pedestrian with two waypoints can advance toward a waypoint with `move_to_next_waypoint(delta)`.
- `speak_context_line()` records `last_spoken_line`.

Extend `tests/test_town_showcase.gd`:

- `TownNpcGroup` exists.
- Required NPC nodes exist under `TownNpcGroup`.
- Role exports match expected values.
- Existing quest NPC IDs remain unchanged.

Extend `tests/test_runner.gd`:

- Add `res://tests/test_town_npc.gd` to `test_paths`.

Verification commands:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

Expected result:

- Unit tests exit 0 and print `TESTS PASSED: <N> assertions`.
- Scene and script validation exits 0.

## Risks

- Beehave API expectations may differ from combat AI assumptions. Keep the first behavior-tree nodes small and verify syntax with `--check-only`.
- `Town.tscn` is large and hand-editing it can be error-prone. Keep scene edits minimal and validate with `test_town_showcase.gd`.
- Reusing the same Innkeeper model for every town NPC may look repetitive. This pass prioritizes behavior and testability over visual variety.

## Acceptance Criteria

- The town scene contains market vendors, inn owner ambient behavior, tavern owner ambient behavior, and at least two pedestrians.
- Pedestrians have configured short waypoint loops.
- Vendor and owner NPCs can speak role-specific ambient lines.
- Existing quest dialogue and quest advancement IDs remain intact.
- Headless tests and Godot check-only validation pass.
