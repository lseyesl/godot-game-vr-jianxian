# Player Test Arena Polish

## Goal

Improve `PlayerTestArena` interaction reliability and debug usability after making it the main scene.

## Scope

- Make repeated player spawning deterministic.
- Make flying sword collection idempotent.
- Decouple spell projectile hit handling from `SealEncounter` private method calls.
- Bind or document desktop debug interactions clearly.
- Add regression coverage for the above.

## Affected Files

- `scripts/debug/PlayerTestArena.gd`
- `scripts/items/FlyingSword.gd`
- `scripts/spells/SpellProjectile.gd`
- `scenes/spells/SpellProjectile.tscn`
- `scenes/debug/PlayerTestArena.tscn`
- `project.godot`
- `tests/test_player_test_arena.gd`
- `tests/test_flying_sword.gd`
- `tests/test_player_spell_controller.gd`
- `tests/test_desktop_debug_player.gd`

## Implementation Steps

- [x] Add regression tests for player respawn cleanup, flying sword idempotence, projectile area hits, and debug input hints.
- [x] Update player spawning to remove/free the old player immediately.
- [x] Guard duplicate flying sword collection.
- [x] Add projectile `area_entered` support through a shared hit helper.
- [x] Add default desktop `interact` / `flight_toggle` bindings and update the arena label.
- [x] Run Godot tests and scene validation.

## Verification Criteria

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exits 0.
- `godot --headless --xr-mode off --path . --check-only --quit` exits 0.
- `PlayerTestArena` can respawn without duplicate live player nodes.
- Flying sword collection emits unlock events only once.
- Projectile can call `receive_spell()` when entering an `Area3D` target.
