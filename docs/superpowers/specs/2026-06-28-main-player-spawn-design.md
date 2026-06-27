# Main Player Spawn Design

## Goal

Make the Main scene's default player spawn position editable through a visible empty `Node3D` in the scene tree.

## Design

Add a `PlayerSpawn` `Node3D` directly under the `Main` scene root. `Main.gd` will expose `player_spawn_path`, defaulting to `^"PlayerSpawn"`, and use that node's global position when spawning the player.

The existing `player_spawn_position` remains as a fallback for tests, temporary scenes, and any scene that does not define the spawn node. Terrain height adjustment remains unchanged: after choosing the base spawn point, `Main.gd` still raises the player above `terrain_spawn_path` if terrain height data is available.

## Affected Files

- `scenes/main/Main.tscn`
- `scripts/main/Main.gd`
- `tests/test_player_mode.gd`

## Verification

- Tests assert that `Main.gd` defaults to `PlayerSpawn`.
- Tests assert that Main scene contains `PlayerSpawn`.
- Tests assert that spawning uses a configured spawn node before falling back to `player_spawn_position`.
- Full Godot test runner and scene validation must exit 0.
