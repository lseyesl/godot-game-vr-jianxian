# Town Playability and Combat Feedback Polish Design

## Goal

Improve the current vertical slice's moment-to-moment readability by making the town's main quest route verifiably comfortable to traverse and by adding clear, testable feedback when player spells affect trial targets.

## Scope

This pass covers two focused polish areas:

- Town playability: route, entrance, interaction, and return landing clearance around the core quest locations.
- Combat feedback: lightweight spell-hit and target-response feedback for the mountain trial spell loop.

It does not replace placeholder art, rebuild the town layout, add final authored VFX/audio assets, complete OpenXR controller bindings, or mark headset-only acceptance checklist items as done.

## Current Context

The town already contains `Inn`, `Tavern`, `MarketStreet`, town NPC AI roles, and a `ReturnToTownTrigger`. Existing tests verify scene presence and several fixed positions, but they do not verify whether the main route, building entrances, NPC interaction points, or return landing space meet the VR comfort dimensions in `docs/art/3d-grid-size-standard.md`.

The spell loop already has `SpellCaster`, `SpellProjectile`, `PlayerSpellController`, `SealEncounter`, and demon target support. Projectiles can call `receive_spell(spell_id)` on targets, and seal cleansing advances the quest. The missing polish is an explicit feedback path that automated tests can observe without requiring final particles, sound, or headset hardware.

## Architecture

Town playability uses explicit scene markers under `scenes/town/Town.tscn`. A top-level grouping node such as `TownFlowMarkers` contains named clearance areas for the primary route, building entrances, NPC interaction positions, and return landing. These markers are test-facing and design-facing: they document required free space in the scene and give automated tests a stable way to verify dimensions.

Combat feedback keeps the existing event-driven architecture. Spell projectiles continue to call target methods through `receive_spell(spell_id)`. Target scripts or shared event code emit lightweight feedback signals through `EventBus` so UI, future VFX, and tests can observe meaningful hit outcomes without direct references between projectiles, combat targets, and presentation nodes.

## Town Playability Requirements

Add or verify clearance markers for the main flow:

- `TownFlowMarkers/MainStreetRouteClearance`
- `TownFlowMarkers/MarketRouteClearance`
- `TownFlowMarkers/InnEntranceClearance`
- `TownFlowMarkers/TavernEntranceClearance`
- `TownFlowMarkers/InnkeeperInteractionClearance`
- `TownFlowMarkers/TavernKeeperInteractionClearance`
- `TownFlowMarkers/ReturnLandingClearance`

Each marker should be an `Area3D` or equivalent `Node3D` with an inspectable `CollisionShape3D` using a `BoxShape3D`. Tests should assert that the X/Z footprint meets the intended gameplay need:

- Main route markers: at least 3 m wide.
- Market and side approach markers: at least 1.5 m wide.
- Inn and tavern entrance markers: at least 2 m wide where they represent core quest entries.
- NPC interaction and return landing markers: at least 1.5 m wide and deep.

Existing town landmarks should keep their current names and rough positions unless a small adjustment is required to keep quest interaction space from being squeezed by stalls, NPCs, or building edges.

## Combat Feedback Requirements

Add a testable spell feedback path for trial combat:

- A spell hit on a receiver emits a feedback signal with at least `spell_id`, target identifier, and outcome.
- `spirit_bolt` hitting the seal reports a damage or hit outcome.
- `seal_break` hitting the seal reports a cleanse outcome when it actually clears the seal.
- Repeated hits after the seal is already cleansed do not emit duplicate cleanse feedback.
- Unknown or ignored spells should not report a successful outcome.

The preferred signal shape is generic enough for future UI/VFX:

```gdscript
signal combat_feedback_requested(spell_id: String, target_id: String, outcome: String)
```

If implementation discovers an existing event that is a better fit, the final plan can reuse it, but the behavior must stay event-driven and testable.

## Data Flow

Town flow:

1. `Town.tscn` owns named clearance marker nodes.
2. Headless tests instantiate the town scene.
3. Tests locate the markers and inspect their `BoxShape3D.size`.
4. Tests verify that main quest locations, interaction points, and return landing all have minimum clear spaces.

Combat flow:

1. Player or test fires a `SpellProjectile` with a known spell ID.
2. Projectile calls `receive_spell(spell_id)` on a target.
3. Target applies existing gameplay behavior.
4. When the target accepts the spell, it emits `EventBus.combat_feedback_requested`.
5. Future UI/VFX listeners can react without changing projectile or target coupling.

## Error Handling

Town marker tests should fail clearly when a marker is missing, has no collision shape, uses the wrong shape type, or is undersized. These failures indicate a scene authoring regression rather than runtime game logic failure.

Combat feedback code must safely handle tests or isolated scenes where `EventBus` is not present. In that case gameplay behavior still applies, and feedback emission is skipped without errors.

Feedback must not change quest authority. `QuestState` and `Game.advance_quest()` remain responsible for quest progression. Combat feedback reports what happened; it does not advance the quest directly unless existing target behavior already does so.

## Testing

Add or extend focused headless tests:

- Town playability test for all required clearance markers and minimum dimensions.
- Seal encounter feedback test for accepted spell outcomes and duplicate cleanse prevention.
- EventBus test coverage for the new feedback signal if the signal is added.

Register any new `tests/test_*.gd` file in `tests/test_runner.gd`.

Final verification remains:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

## Documentation Updates

Update `docs/testing/vr-demo-acceptance.md` only for automated coverage that this pass actually proves. Do not mark manual headset items such as enterability feel, VR comfort, flight framing, or full headset playthrough as complete unless they are manually tested on PCVR hardware.

## Out of Scope

- Large-scale town redesign.
- Replacement of placeholder geometry with final art.
- New authored particle, shader, or sound assets.
- Spell cooldown HUD or spell selection UI.
- Enemy balance changes.
- OpenXR action binding validation.
- PCVR export.
- Manual VR acceptance checklist completion.

## Acceptance Criteria

- Town scene exposes named clearance markers for main route, inn, tavern, market, NPC interaction, and return landing.
- Automated tests verify those markers meet the project's VR comfort dimensions.
- Spell hits on the seal expose feedback through an event-driven path.
- `seal_break` emits cleanse feedback once when it actually cleanses the seal.
- Existing main quest, NPC AI, spell casting, seal encounter, and completion feedback tests continue to pass.
- Headless test runner and check-only validation both exit 0.

## Self-Review

- No placeholders remain.
- The design preserves the project's EventBus-centered architecture.
- Scope is one implementation pass with two related polish surfaces: route readability and hit feedback.
- Manual VR validation and final art polish are explicitly excluded.
