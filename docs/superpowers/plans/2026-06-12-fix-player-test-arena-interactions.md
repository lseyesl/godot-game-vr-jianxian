# Fix Player Test Arena Interactions

## Goal

Make `res://scenes/debug/PlayerTestArena.tscn` spawn the desktop player at the configured spawn marker reliably so nearby fixtures can be reached and interaction/combat checks start from the intended position.

## Scope

- Fix player spawn order in `scripts/debug/PlayerTestArena.gd`.
- Add a regression assertion in `tests/test_player_test_arena.gd`.
- Keep the existing main scene setting unchanged.

## Affected Files

- `scripts/debug/PlayerTestArena.gd`
- `tests/test_player_test_arena.gd`

## Implementation Steps

- [x] Add a regression test that verifies the spawned player lands at `PlayerSpawn`.
- [x] Change spawn logic so the player is added to the tree before global transform positioning.
- [x] Run the focused test runner and project validation commands.

## Verification Criteria

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exits 0.
- `godot --headless --xr-mode off --path . --check-only --quit` exits 0.
- No `PlayerTestArena.gd:42` `!is_inside_tree()` global transform error appears.
