# Fix Asset Placer Bottom Panel

## Goal

Fix the Asset Placer editor plugin so enabling it reliably registers and shows its bottom panel.

## Scope

- Keep the existing Asset Placer plugin architecture.
- Fix scanner assignment before panel `_ready()`.
- Open the bottom panel tab after registration.
- Add a regression test matching the Prefab Inspector lifecycle case.

## Affected Files

- `addons/asset_placer/plugin.gd`
- `addons/asset_placer/panels/asset_browser_panel.gd`
- `tests/test_asset_placer.gd`

## Implementation Steps

- [x] Add a failing test that assigns `scanner` before `AssetBrowserPanel` is ready.
- [x] Update `AssetBrowserPanel.scanner` setter to defer refresh until ready.
- [x] Refresh in `_ready()` if scanner was assigned before ready.
- [x] Mark `AssetBrowserPanel` as `@tool`.
- [x] Call `make_bottom_panel_item_visible(bottom_panel)` after registration.

## Verification

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`
- `godot --headless --xr-mode off --path . --check-only --quit`
