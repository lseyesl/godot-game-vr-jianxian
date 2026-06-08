# Player Test Arena Design

## Goal

Add one shared debug scene for testing player weapons, spells, flying sword behavior, and related combat/trial interactions. The scene should support both desktop simulation and VR player controllers through a single mode setting, with desktop simulation as the default for fast local iteration.

## Scope

In scope:
- A new debug scene under `scenes/debug/`.
- A small scene script that spawns either `DesktopDebugPlayer.tscn` or `XRPlayer.tscn` from an exported `player_mode`.
- Shared test fixtures: ground, lighting, spell/seal target, flying sword, spawn marker, distance/reference markers, and Chinese debug labels.
- Headless tests that verify the debug scene exists, instantiates, exposes the expected mode setting, and contains the shared gameplay fixtures.

Out of scope:
- New weapon systems or new spells.
- Full VR acceptance validation in headless mode.
- Changes to the main quest flow or main menu.
- Runtime UI for switching modes inside the debug scene.

## Architecture

Create `scenes/debug/PlayerTestArena.tscn` as a standalone `Node3D` scene. Attach `scripts/debug/PlayerTestArena.gd`.

`PlayerTestArena.gd` mirrors the existing player mode resolution used by `scripts/main/Main.gd`:
- `desktop_simulation` loads `res://scenes/player/DesktopDebugPlayer.tscn`.
- `vr` loads `res://scenes/player/XRPlayer.tscn`.
- Unknown values normalize to `desktop_simulation`.

The arena owns only debug-scene setup. It does not alter global quest progression, main scene spawning, or core gameplay modules.

## Scene Content

The scene should include:
- `WorldEnvironment` and `DirectionalLight3D`.
- `Ground` as a simple collision floor sized for movement and short flight checks.
- `PlayerSpawn` as a `Marker3D`.
- `TestFixtures` as a grouping node for reusable gameplay objects.
- `SealEncounter` instance positioned ahead of spawn for spell testing.
- `FlyingSword` instance near the player for unlock and flight testing.
- Lightweight visual markers at practical distances, using built-in meshes only.
- A Chinese debug label using a `Label3D`, with concise controls/status notes.

## Data Flow

The player mode is local to the arena:

1. `_ready()` calls `spawn_player()`.
2. `spawn_player()` loads the scene path resolved from `player_mode`.
3. The player instance is placed at `PlayerSpawn.global_position`.
4. Gameplay objects continue using existing EventBus/Game conventions when autoloads are available.

No direct gameplay coupling is added between player, spells, sword, and seal beyond existing scene instances and signals.

## Testing

Add `tests/test_player_test_arena.gd` and register it in `tests/test_runner.gd`.

The test should verify:
- `scenes/debug/PlayerTestArena.tscn` exists and instantiates.
- The scene script can instantiate.
- The arena resolves desktop and VR scene paths correctly.
- Unknown mode falls back to desktop simulation.
- The scene contains `PlayerSpawn`, `Ground`, `TestFixtures/SealEncounter`, and `TestFixtures/FlyingSword`.

Verification commands:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

