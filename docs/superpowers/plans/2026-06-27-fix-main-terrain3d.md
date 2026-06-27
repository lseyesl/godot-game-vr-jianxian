# Fix Main Terrain3D Plan

## Goal

Fix the current Main scene Terrain3D integration so scene validation does not report Terrain3D texture format errors and player spawn height resolution works with the Terrain3D node.

## Scope

- Keep `Main.tscn` using `TerrainContainer/Terrain3D`.
- Do not modify unrelated town scene changes or untracked Terrain3D DLL files.
- Avoid changing generated Terrain3D region data unless evidence shows the data is the root cause.

## Affected Files

- `scripts/main/Main.gd`
- `tests/test_terrain.gd`
- `assets/textures/terrain/terrain_assets.tres` or Terrain3D texture import settings if needed
- This plan file

## Implementation Steps

- [x] Diagnose imported Terrain3D texture formats and identify the mismatched asset entries.
- [x] Add failing regression tests for Main's Terrain3D spawn path and Terrain3D texture format consistency.
- [x] Update `Main.gd` to resolve spawn height from Terrain3D data while preserving old heightmap support.
- [x] Fix the Terrain3D texture asset set/import settings so all albedo textures used by `terrain_assets.tres` share a compatible imported format.
- [x] Run unit tests and scene validation.

## Verification Notes

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 4123 assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exited 0.
- The previous Terrain3D albedo texture format errors are gone. Headless logs still include existing Beehave debugger messages and Terrain3D mipmap warnings for the replacement texture set.

## Verification Criteria

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exits 0 and prints `TESTS PASSED: <N> assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exits 0 without Terrain3D texture format errors.
