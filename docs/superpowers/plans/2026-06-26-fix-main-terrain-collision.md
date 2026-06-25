# Fix Main Terrain Collision

## Goal

Fix the player falling through or below the modified Main scene terrain by ensuring the heightmap terrain used in `Main.tscn` has runtime collision.

## Scope

- Keep the fix focused on terrain collision/spawn stability.
- Do not refactor unrelated player movement or town layout.
- Preserve the existing graybox terrain instances unless a test proves they must change.

## Affected Files

- `scenes/prefabs/terrain/HeightmapTerrain.tscn`
- `tests/test_terrain.gd`
- Possibly `scripts/world/HeightmapTerrain.gd` if collision generation needs a script adjustment.

## Implementation Steps

- [x] Confirm root cause from scene/script inspection.
- [x] Add a failing regression test that requires heightmap terrain collision to be generated and enabled.
- [x] Enable or fix heightmap collision with the smallest scene/script change.
- [x] Run the targeted test command.
- [x] Run full project verification commands required by `AGENTS.md`.

## Verification Criteria

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exits 0 and prints `TESTS PASSED: <N> assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exits 0.
- The regression test asserts `HeightmapTerrain` has an enabled `CollisionShape3D` with a generated shape.
