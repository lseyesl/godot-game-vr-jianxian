# Core Playable Spell Flow Design

## Goal

Make the mountain-trial core loop playable in both desktop simulation and VR-ready code paths: the player can trigger spells, shared spell logic checks cooldowns, projectile spells spawn from a player emitter, projectiles can hit seal and demon targets, and non-projectile guard charm still uses the same cooldown/event path.

## Scope

Included:

- Add a shared player spell controller used by both `DesktopDebugPlayer` and `XRPlayer`.
- Use existing input actions `spell_primary`, `spell_guard`, and `spell_seal` for desktop simulation.
- Spawn `SpellProjectile.tscn` for `spirit_bolt` and `seal_break`.
- Keep `guard_charm` as a cooldown/event spell with no projectile in this pass.
- Add player scene emitter nodes so desktop and VR scenes have explicit spell origins.
- Add headless tests for the shared controller, scene wiring, and desktop input dispatch.

Not included:

- Final XR controller action-map binding and headset validation.
- Gesture recognition or standing spellcasting pose detection.
- Spell selection wheel, mana UI, cooldown UI, VFX polish, or sound effects.
- Rebalancing enemy/seal health beyond existing spell damage behavior.

## Current Context

The project already has:

- `scripts/spells/SpellCaster.gd`, which validates known spell IDs and cooldowns.
- `scripts/spells/SpellProjectile.gd`, which moves forward and calls `receive_spell(spell_id)` on bodies it enters.
- `scenes/spells/SpellProjectile.tscn`, a simple projectile scene.
- `SealEncounter` and `LesserDemon`, both supporting `receive_spell(spell_id)`.
- `DesktopDebugPlayer` and `XRPlayer`, but neither currently owns spell input or projectile spawning.
- Input actions in `project.godot`: `spell_primary`, `spell_guard`, `spell_seal`, `interact`, and `flight_toggle`, currently with no default key events.

## Architecture

Add `scripts/player/PlayerSpellController.gd` as the shared spell bridge. It owns or references a `SpellCaster`, knows which spells create projectiles, and exposes methods that players can call from input or XR action hooks.

Core methods:

- `cast_spell(spell_id: String, origin: Vector3, forward: Vector3) -> bool`
- `cast_spell_from_node(spell_id: String, emitter: Node3D) -> bool`
- `is_projectile_spell(spell_id: String) -> bool`
- `get_spawned_projectile_count() -> int`
- `tick_cooldowns(delta: float) -> void`

`PlayerSpellController` should not depend on `Game`, `EventBus`, or a specific player class. It may instantiate projectiles only when inside the scene tree and when the spell passes `SpellCaster.cast(spell_id)`.

Desktop and VR player scripts should be thin callers:

- `DesktopDebugPlayer` maps input actions to spell IDs and uses `Camera3D` or `SpellEmitter` as the source.
- `XRPlayer` exposes callable methods that cast from an exported `spell_emitter_path`, defaulting to a right-hand child emitter.

## Components

### `PlayerSpellController.gd`

Responsibilities:

- Create a `SpellCaster` if one is not assigned.
- Store `projectile_scene_path = "res://scenes/spells/SpellProjectile.tscn"`.
- Spawn projectiles for:
  - `spirit_bolt`
  - `seal_break`
- Do not spawn projectiles for:
  - `guard_charm`
- Launch projectiles from the provided origin and forward vector.
- Add spawned projectiles to the current scene root or the controller's parent when available.
- Record `last_cast_spell_id` and `last_spawned_projectile` for tests and debugging.
- Tick spell cooldowns from the owning player each frame.

### Desktop Player

`DesktopDebugPlayer` gains:

- `spell_controller_path = ^"PlayerSpellController"`
- `spell_emitter_path = ^"Camera3D"`
- `cast_spell_action(action_name: String) -> bool`
- `cast_spell_id(spell_id: String) -> bool`

Input mapping:

- `spell_primary` -> `spirit_bolt`
- `spell_guard` -> `guard_charm`
- `spell_seal` -> `seal_break`

Default key events can be added to `project.godot`:

- Left mouse button for `spell_primary`.
- Keyboard `Q` for `spell_guard`.
- Keyboard `E` for `spell_seal`.

The existing left mouse click currently requests mouse capture. That behavior should remain useful: if the mouse is not captured, left click captures the mouse; if already captured, `spell_primary` can cast.

### XR Player

`XRPlayer` gains:

- `spell_controller_path = ^"PlayerSpellController"`
- `spell_emitter_path = ^"XROrigin3D/RightHand/SpellEmitter"`
- `cast_spell_id(spell_id: String) -> bool`
- `cast_spell_from_emitter(spell_id: String, emitter_path: NodePath = spell_emitter_path) -> bool`

The scene should add:

- `PlayerSpellController` under `XRPlayer`.
- `SpellEmitter` under `XROrigin3D/RightHand`.

This does not complete final OpenXR action binding; it creates the stable interface the binding will call.

### Scenes

Modify:

- `scenes/player/DesktopDebugPlayer.tscn`: add `PlayerSpellController`.
- `scenes/player/XRPlayer.tscn`: add `PlayerSpellController` and `RightHand/SpellEmitter`.

No changes are required to `SpellProjectile.tscn` for this pass unless tests reveal a scene wiring problem.

## Data Flow

Desktop:

1. User presses `spell_primary`, `spell_guard`, or `spell_seal`.
2. `DesktopDebugPlayer._unhandled_input()` maps the action to a spell ID.
3. `DesktopDebugPlayer.cast_spell_id()` calls `PlayerSpellController.cast_spell_from_node()`.
4. `PlayerSpellController` calls `SpellCaster.cast(spell_id)`.
5. If the spell is projectile-based, the controller instantiates and launches `SpellProjectile`.
6. Projectile collision calls `receive_spell(spell_id)` on the seal or demon.

VR-ready:

1. XR action binding or future hand gesture calls `XRPlayer.cast_spell_id(spell_id)`.
2. `XRPlayer` delegates to the same `PlayerSpellController`.
3. Projectile behavior is identical to desktop.

## Testing

Add `tests/test_player_spell_controller.gd`:

- Script exists and instantiates.
- `spirit_bolt` casts and spawns one projectile when inside a scene tree.
- Immediate repeat cast is blocked by cooldown.
- `guard_charm` casts but does not spawn a projectile.
- Unknown spell returns `false`.
- `cast_spell_from_node()` uses the emitter transform.

Extend `tests/test_desktop_debug_player.gd`:

- Required spell input actions exist.
- Desktop scene has `PlayerSpellController`.
- `cast_spell_id("spirit_bolt")` delegates to the controller.
- `cast_spell_action("spell_seal")` maps to `seal_break`.

Extend `tests/test_xr_player.gd`:

- XR scene has `PlayerSpellController`.
- XR scene has `XROrigin3D/RightHand/SpellEmitter`.
- `cast_spell_id("spirit_bolt")` can call the shared controller without headset hardware.

Extend `tests/test_runner.gd`:

- Add `res://tests/test_player_spell_controller.gd`.

Verification:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

## Risks

- Input action defaults may overlap with existing mouse capture behavior. Keep capture on first click and spellcast once capture is active.
- `SpellCaster.cast()` emits EventBus only when inside tree, so controller tests should verify projectile spawn directly rather than relying on EventBus.
- Projectiles spawned under the wrong parent could miss scene targets. Add them to the current scene root when available so world-space launch positions remain stable.

## Acceptance Criteria

- Desktop simulation can trigger `spirit_bolt`, `guard_charm`, and `seal_break` through input actions.
- `spirit_bolt` and `seal_break` spawn projectiles from the player view/emitter.
- `guard_charm` respects cooldown and emits the normal spell cast event path without spawning a projectile.
- XR player scene has a callable spellcasting interface and emitter node for later OpenXR binding.
- Existing seal and demon `receive_spell()` behavior remains unchanged.
- Headless tests and check-only validation pass.
