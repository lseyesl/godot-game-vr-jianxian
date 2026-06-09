# Lesser Demon Combat Design

## Goal

Add a first complete combat slice around lesser demons in the mountain trial. The system should support player health, enemy health, spell damage, enemy behavior through Beehave, and combat fixtures in debug and trial scenes. Player health can reach a critical state, but this version does not add death, failure, respawn, or game-over flow.

## Scope

In scope:
- A reusable health component for player and enemy actors.
- A lesser demon enemy scene with health, spell damage handling, attack range checks, and defeat state.
- Beehave-powered enemy behavior for idle, chase, attack, and defeated states.
- Player damage reception for `DesktopDebugPlayer` and `XRPlayer`.
- Combat signals on `EventBus` for health changes, damage, and enemy defeat.
- Integration with `PlayerTestArena` and `MountainTrial`.
- Headless tests for health, lesser demon combat logic, Beehave scene composition, and scene fixtures.

Out of scope:
- Player death, failure state, respawn, save rollback, or game-over UI.
- NavMesh pathfinding, obstacle avoidance, or squad tactics.
- Status effects, armor, elemental resistances, knockback, hit stun, loot, XP, or item drops.
- Full VR manual combat acceptance beyond existing headless checks.
- Replacing `SealEncounter`; the seal keeps its existing `receive_spell(spell_id)` behavior.

## Architecture

Use a small component-based combat core rather than embedding all behavior in one enemy script.

Create `scripts/combat/HealthComponent.gd` as a `Node` with:
- `max_health`
- `current_health`
- `minimum_health`
- `is_alive()`
- `apply_damage(amount, source_id)`
- `heal(amount)`
- signals for health changes, damage received, and death

For enemies, `minimum_health` is `0`. For the player, `minimum_health` is also `0`, but no death/failure flow is triggered in this version. Player scripts keep receiving input and movement after health reaches `0`; UI/debug listeners can treat that as a critical state.

Add `scripts/enemies/LesserDemon.gd` as the actor controller. It owns target detection, range checks, attack cooldown, damage mapping from spell IDs, and defeat state. The script exposes simple methods that Beehave leaves can call:
- `find_target()`
- `has_target()`
- `is_defeated()`
- `can_see_target()`
- `is_in_attack_range()`
- `move_toward_target(delta)`
- `try_attack_target()`
- `receive_spell(spell_id)`
- `receive_damage(amount, source_id)`

The enemy scene uses a simple built-in mesh visual in this version. A future art pass can replace it with a model without changing the combat API.

## Beehave Behavior

Beehave is present under `addons/beehave/`. Enable it in `project.godot` so editor and scene validation know the plugin is active.

The lesser demon scene includes:
- `BeehaveTree`
- `SelectorComposite`
- `SequenceComposite` branches
- project-local `ConditionLeaf` and `ActionLeaf` scripts under `scripts/enemies/ai/`

Initial behavior tree:

1. Defeated branch:
   - `IsDefeatedCondition`
   - `DefeatedAction`
2. Attack branch:
   - `HasTargetCondition`
   - `IsTargetInAttackRangeCondition`
   - `AttackTargetAction`
3. Chase branch:
   - `HasTargetCondition`
   - `CanSeeTargetCondition`
   - `ChaseTargetAction`
4. Idle branch:
   - `FindTargetAction`
   - `IdleAction`

The first version uses direct distance checks and straight-line movement. It does not require a navigation mesh. This matches the current test arena and mountain trial, which are open and sparse.

## Damage Rules

Spell damage to lesser demons:
- `spirit_bolt`: 1 damage
- `seal_break`: 3 damage
- `guard_charm`: 0 damage
- Unknown spell IDs: 0 damage

Suggested lesser demon values:
- `max_health`: 3
- `sight_range_m`: 8
- `attack_range_m`: 1.5
- `move_speed_mps`: 2
- `attack_damage`: 1
- `attack_cooldown_s`: 1.5

`SpellProjectile` keeps the existing convention: if a target has `receive_spell(spell_id)`, call it and then free the projectile. This allows the same projectile code to hit both `SealEncounter` and `LesserDemon`.

## Player Health

Both player controllers gain a health component or equivalent child node:
- `DesktopDebugPlayer`
- `XRPlayer`

Both expose:
- `receive_damage(amount, source_id)`
- `get_health_component()`

When damaged, the player emits `EventBus.player_health_changed(current, max)` if `EventBus` exists. Reaching `0` health does not disable movement, reload the scene, advance quests, or block interaction.

## Events

Add combat signals to `scripts/autoload/EventBus.gd`:
- `damage_received(target_id: String, amount: int, current_health: int, max_health: int)`
- `health_changed(target_id: String, current_health: int, max_health: int)`
- `enemy_defeated(enemy_id: String)`
- `player_health_changed(current_health: int, max_health: int)`

Scripts must keep autoload-safe access. They use `get_node_or_null("/root/EventBus")` and guard nulls so tests can run without autoloads.

## Scene Integration

Add `scenes/enemies/LesserDemon.tscn`.

Update `scenes/debug/PlayerTestArena.tscn`:
- Add one lesser demon under `TestFixtures`.
- Place it far enough from spawn to test approach and spell hits.
- Update Chinese debug label to mention小妖 combat testing.

Update `scenes/mountain/MountainTrial.tscn`:
- Add one or two lesser demons near the seal.
- Keep `SealEncounter` and `FlyingSword` positions intact unless spacing requires small offsets.

Quest progression remains controlled by `SealEncounter` in this first version. Defeating demons is part of the encounter fantasy and combat loop, but `cleanse_seal -> collect_sword` still advances only when the seal is cleansed.

## Testing

Add focused headless tests:

- `tests/test_health_component.gd`
  - health initializes to max
  - damage reduces health
  - health clamps at minimum
  - death signal/state occurs when enemy health reaches `0`

- `tests/test_lesser_demon.gd`
  - known spell IDs map to expected damage
  - `guard_charm` does not damage
  - defeated state is set after lethal damage
  - attack cooldown prevents repeated hits every frame
  - distance checks classify target in or out of attack range

- `tests/test_lesser_demon_scene.gd`
  - scene exists and instantiates
  - has `HealthComponent`
  - has `BeehaveTree`
  - has key Beehave branch nodes
  - has a visible built-in mesh visual and collision body/area

Update existing tests:
- `tests/test_player_test_arena.gd`: assert the lesser demon fixture exists.
- Add or update a mountain trial test: assert at least one lesser demon exists in `MountainTrial`.
- Register all new tests in `tests/test_runner.gd`.

Verification commands:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

If imported assets are added or changed in a future art pass, run:

```bash
godot --headless --xr-mode off --path . --import
```

## Risks

Beehave scenes may require plugin enablement in `project.godot`. If headless validation fails because custom classes are unavailable, enable `res://addons/beehave/plugin.cfg` alongside XR Tools.

Enemy movement in the first version is direct-line movement. This is acceptable for the open test arena and mountain trial, but it will not handle buildings, walls, water obstacles, or vertical navigation.

Player health has no failure loop by design. Manual testers should understand that reaching `0` means critical health, not death.
