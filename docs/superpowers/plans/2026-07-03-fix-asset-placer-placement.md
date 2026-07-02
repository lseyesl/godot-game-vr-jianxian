# Fix Asset Placer Placement

## Goal

Make Asset Placer create a prefab instance when the user selects a prefab, clicks Place, then clicks in the 3D viewport, even when the clicked scene area has no physics collider.

## Scope

- Keep the existing bottom-panel workflow.
- Preserve physics raycast placement when a collider is hit.
- Add a y=0 ground-plane fallback when physics raycast misses.
- Keep receiving 3D viewport input while placement mode is active, regardless of the selected editor node.
- Mark editor-helper scripts as `@tool`.
- Add focused regression coverage for the fallback math.

## Affected Files

- `addons/asset_placer/scripts/asset_placer.gd`
- `addons/asset_placer/scripts/ghost_preview.gd`
- `addons/asset_placer/plugin.gd`
- `tests/test_asset_placer.gd`

## Implementation Steps

- [x] Add a failing test for ground-plane ray intersection.
- [x] Add a helper that intersects the viewport ray with a horizontal ground plane.
- [x] Use the helper as fallback from `_raycast()`.
- [x] Mark placement helper scripts as `@tool`.
- [x] Add a regression check that the plugin enables constant 3D viewport input forwarding.
- [x] Enable constant input forwarding from the editor plugin.
- [x] Verify with Godot test runner and check-only.

## Verification

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`
- `godot --headless --xr-mode off --path . --check-only --quit`
