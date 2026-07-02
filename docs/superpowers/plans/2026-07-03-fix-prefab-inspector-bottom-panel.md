# Fix Prefab Inspector Bottom Panel

## Goal

Fix the Prefab Inspector editor plugin so enabling it reliably registers and shows its bottom panel.

## Scope

- Keep the existing `EditorPlugin` and panel scene structure.
- Fix the initialization order between `plugin.gd` and `inspector_panel.gd`.
- Add a regression test for assigning the scanner before the panel enters the scene tree.

## Affected Files

- `addons/prefab_inspector/plugin.gd`
- `addons/prefab_inspector/panels/inspector_panel.gd`
- `tests/test_prefab_inspector.gd`

## Implementation Steps

- [x] Add a failing test that instantiates `inspector_panel.tscn`, assigns `scanner` before `_ready()`, then adds it to the tree and checks the panel refreshes.
- [x] Update `PrefabInspectorPanel.scanner` setter to defer refresh until the node is ready.
- [x] Refresh from `_ready()` when a scanner was assigned before ready.
- [x] Mark the panel script as `@tool` for editor-plugin UI execution.
- [x] After registering the bottom panel, call `make_bottom_panel_item_visible(bottom_panel)` so enabling the plugin opens the tab.

## Verification

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`
- `godot --headless --xr-mode off --path . --check-only --quit`
