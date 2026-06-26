# Rebuild Main Layout From Concept

## Goal

根据 `docs/concept-art/布局.png` 重新整理 `scenes/main/Main.tscn`，让主场景以高度图大地形为底，移除与高度图、水域、远山布局冲突的旧拼块，并用可替换 box 预制体标注缺失模型位置。

## Scope

- 保留主流程关键场景：`Town`、`MountainTrial`、玩家生成、UI、飞行路线与基础水体。
- 移除旧的局部地面拼块和走廊拼块：`TownGround`、`SuburbGround`、`MountainGround`、`ConnectionCorridor` 中的 Path/Cliff 拼接结构。
- 新增布局占位 prefab，用于城墙、农田、码头、水岸、远山、山门/建筑群等后续模型替换。
- 新增文档标注布局分区、坐标和后续模型对接规则。
- 更新地形测试中对主场景结构的断言。

## Affected Files

- `scenes/main/Main.tscn`
- `scenes/prefabs/layout/LayoutBoxPlaceholder.tscn`
- `docs/art/main-layout-from-concept.md`
- `tests/test_terrain.gd`

## Implementation Steps

- [x] Create a reusable `LayoutBoxPlaceholder` scene with neutral material and collision-free box mesh.
- [x] Rewrite `Main.tscn` terrain/layout section: keep `HeightmapTerrain` and `WorldBoundary`, remove conflicting old ground/corridor instances, add concept-aligned placeholder groups.
- [x] Add documentation that maps each placeholder group to the concept image and future model replacement path.
- [x] Update `tests/test_terrain.gd` to validate the new layout anchors and absence of old conflict nodes.
- [x] Run `godot --headless --xr-mode off --path . --check-only --quit`.
- [x] Run `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` and record any pre-existing unrelated failures.

## Verification Notes

- `godot --headless --xr-mode off --path . --check-only --quit` exited 0. Headless Beehave debugger messages were printed.
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 969 assertions`. Existing warning/error output remains from TownNpc test setup, spell hit effect curve data, model UID fallback, Beehave capture cleanup, and resource leak reporting.

## Verification Criteria

- `Main.tscn` loads and contains `TerrainContainer/HeightmapTerrain` and `TerrainContainer/WorldBoundary`.
- Old conflict nodes `TownGround`, `SuburbGround`, `MountainGround`, and `ConnectionCorridor` are absent from `Main.tscn`.
- New `ConceptLayout` contains named groups for town walls, town districts, fields, waterfront, riverbeds/banks, mountain backdrop, and trial route.
- Placeholder boxes are collision-free visual markers that can be replaced by model scenes later.
- Documentation explains the placeholder naming and replacement process.
- Godot scene validation exits 0.
